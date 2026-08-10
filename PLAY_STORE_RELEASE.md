# Doorstep Market — Play closed-test release

## Release artifact

- App bundle: `build/app/outputs/bundle/release/app-release.aab`
- Application ID: `com.megnifylabs.doorstep_market`
- Version: `1.0.1` (`versionCode` 3)
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

## AdMob before production

Replace Google's sample AdMob application ID in
`android/app/src/main/AndroidManifest.xml` with the Doorstep Market Android app
ID. Build the release with the production banner unit:

```sh
flutter build appbundle --release \
  --dart-define=ADMOB_ANDROID_BANNER_ID=ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY
```

Never click live ads while testing. Debug builds use Google's official test ad
unit automatically.

## Seven-day listing boost

In Play Console, create and activate a **one-time in-app product** with product
ID `listing_boost_7_day`. The ID must match exactly. Add its price and make the
product available in the countries where Doorstep Market is distributed.

The current client completes purchases and grants a seven-day Firestore boost.
Before scaling beyond the initial test, verify purchase tokens on a trusted
backend with the Google Play Developer API to prevent fraudulent entitlements.

## Future releases

Increase the build number in `pubspec.yaml` for every uploaded bundle, for
example `1.0.1+2`. Google Play rejects a reused version code.
