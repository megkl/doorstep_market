const crypto = require("node:crypto");
const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {onSchedule} = require("firebase-functions/v2/scheduler");
const {logger} = require("firebase-functions");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore, FieldValue, Timestamp} = require("firebase-admin/firestore");
const {google} = require("googleapis");

initializeApp();

const db = getFirestore();
const packageName = "com.megnifylabs.doorstep_market";
const productId = "seller_advertising_weekly";
const allowedStates = new Set([
  "SUBSCRIPTION_STATE_ACTIVE",
  "SUBSCRIPTION_STATE_IN_GRACE_PERIOD",
  "SUBSCRIPTION_STATE_CANCELED",
]);

function tokenHash(token) {
  return crypto.createHash("sha256").update(token).digest("hex");
}

function accountHash(uid) {
  return crypto.createHash("sha256").update(uid).digest("hex");
}

async function playClient() {
  const auth = new google.auth.GoogleAuth({
    scopes: ["https://www.googleapis.com/auth/androidpublisher"],
  });
  return google.androidpublisher({version: "v3", auth});
}

async function readSubscription(purchaseToken) {
  const publisher = await playClient();
  const response = await publisher.purchases.subscriptionsv2.get({
    packageName,
    token: purchaseToken,
  });
  return response.data;
}

function verifiedEntitlement(subscription) {
  const matchingItems = (subscription.lineItems || []).filter(
    (item) => item.productId === productId && item.expiryTime,
  );
  const expiryMillis = Math.max(
    0,
    ...matchingItems.map((item) => Date.parse(item.expiryTime)),
  );
  const active =
    allowedStates.has(subscription.subscriptionState) &&
    expiryMillis > Date.now();
  return {active, expiryMillis, state: subscription.subscriptionState};
}

async function saveVerification({uid, purchaseToken, purchaseId, subscription}) {
  const hash = tokenHash(purchaseToken);
  const tokenRef = db.collection("sellerSubscriptionTokens").doc(hash);
  const userRef = db.collection("users").doc(uid);
  const entitlement = verifiedEntitlement(subscription);
  const playAccountId =
    subscription.externalAccountIdentifiers?.obfuscatedExternalAccountId;
  if (playAccountId !== accountHash(uid)) {
    throw new HttpsError(
      "permission-denied",
      "This Google Play subscription is not linked to this account.",
    );
  }

  await db.runTransaction(async (transaction) => {
    const tokenDocument = await transaction.get(tokenRef);
    const ownerUid = tokenDocument.data()?.uid;
    if (ownerUid && ownerUid !== uid) {
      throw new HttpsError(
        "permission-denied",
        "This Google Play subscription belongs to another account.",
      );
    }

    transaction.set(tokenRef, {
      uid,
      purchaseToken,
      purchaseId: purchaseId || subscription.latestOrderId || null,
      productId,
      state: entitlement.state || "SUBSCRIPTION_STATE_UNSPECIFIED",
      expiryTime: entitlement.expiryMillis
        ? Timestamp.fromMillis(entitlement.expiryMillis)
        : null,
      active: entitlement.active,
      verifiedAt: FieldValue.serverTimestamp(),
    }, {merge: true});

    transaction.set(userRef, {
      sellerAdvertisingUntil: entitlement.active
        ? Timestamp.fromMillis(entitlement.expiryMillis)
        : FieldValue.delete(),
      sellerAdvertisingPurchaseId:
        purchaseId || subscription.latestOrderId || FieldValue.delete(),
      sellerSubscriptionState:
        entitlement.state || "SUBSCRIPTION_STATE_UNSPECIFIED",
      sellerSubscriptionVerifiedAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    }, {merge: true});
  });

  return entitlement;
}

exports.verifySellerSubscription = onCall(
  {region: "us-central1"},
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Sign in before subscribing.");
    }
    const purchaseToken = request.data?.purchaseToken;
    const purchaseId = request.data?.purchaseId;
    if (typeof purchaseToken !== "string" || purchaseToken.length < 20) {
      throw new HttpsError("invalid-argument", "Invalid purchase token.");
    }

    try {
      const subscription = await readSubscription(purchaseToken);
      const entitlement = await saveVerification({
        uid: request.auth.uid,
        purchaseToken,
        purchaseId,
        subscription,
      });
      if (!entitlement.active) {
        throw new HttpsError(
          "failed-precondition",
          "The Google Play subscription is not active.",
        );
      }
      return {
        active: true,
        expiryTime: new Date(entitlement.expiryMillis).toISOString(),
      };
    } catch (error) {
      if (error instanceof HttpsError) throw error;
      logger.error("Google Play subscription verification failed", error);
      throw new HttpsError(
        "unavailable",
        "Could not verify the subscription with Google Play.",
      );
    }
  },
);

exports.recheckSellerSubscriptions = onSchedule(
  {region: "us-central1", schedule: "every 60 minutes", timeoutSeconds: 540},
  async () => {
    const snapshot = await db.collection("sellerSubscriptionTokens")
      .where("active", "==", true)
      .get();

    for (const document of snapshot.docs) {
      const record = document.data();
      try {
        const subscription = await readSubscription(record.purchaseToken);
        await saveVerification({
          uid: record.uid,
          purchaseToken: record.purchaseToken,
          purchaseId: record.purchaseId,
          subscription,
        });
      } catch (error) {
        logger.error("Scheduled subscription recheck failed", {
          tokenHash: document.id,
          error,
        });
      }
    }
  },
);
