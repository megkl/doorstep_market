# Doorstep Market — Play closed-test release

## Release artifact

- App bundle: `build/app/outputs/bundle/release/app-release.aab`
- Application ID: `com.megnifylabs.doorstep_market`
- Version: `1.0.2` (`versionCode` 4)
- Target SDK: Android 16 / API 36

## Before uploading

Back up both signing files somewhere secure and private. Losing them can prevent
future uploads:

- `android/upload-keystore.jks`
- `android/.keystore-pass`

These files are ignored by Git and must never be committed or shared.

## Play Console closed test

1. Create the app as **Doorstep Market** and use the application ID above.
2. Complete the App access, Ads, Content rating, Target audience, Data safety,
   Privacy policy, and Store listing sections.
   - Store category: **Shopping**
   - Financial features: **My app doesn't provide any financial features**
   - Advertising ID: **Yes — Advertising or marketing**
3. Go to **Test and release → Testing → Closed testing** and create a track.
4. Upload `app-release.aab`, add release notes, review, and roll out the release.
5. Add at least 12 tester Google-account email addresses or a Google Group.
6. Share the opt-in link. Testers must opt in and remain opted in continuously
   for at least 14 days.

## Google Sign-In after the first Play upload

Play App Signing gives installed builds a second certificate that differs from
the local upload certificate. In Play Console, open **Setup → App integrity →
App signing key certificate**. Add its SHA-1 and SHA-256 fingerprints to the
Android app in Firebase Project Settings, then download the refreshed
`google-services.json` before the next bundle.

## Weekly seller advertising subscription

In Play Console, open **Monetize with Play → Products → Subscriptions** and
create a subscription with product ID `seller_advertising_weekly`. The ID must
match exactly.

Create an auto-renewing base plan with:

- Base plan ID: `weekly-50ksh`
- Billing period: one week
- Kenya price: KSh 50

Create an acquisition offer for that base plan with a single one-week free-trial
phase. Activate the subscription, base plan, and offer in every country where it
will be sold. The app automatically selects the eligible free-trial offer and
shows Google Play's localized recurring price.

The current client acknowledges purchases and promotes all of the seller's
active listings. Before production scale, verify subscription purchase tokens
and expiry on a trusted backend with the Google Play Developer API so cancelled,
expired, refunded, or fraudulent subscriptions cannot retain an entitlement.

## Future releases

Increase the build number in `pubspec.yaml` for every uploaded bundle, for
example `1.0.1+2`. Google Play rejects a reused version code.
