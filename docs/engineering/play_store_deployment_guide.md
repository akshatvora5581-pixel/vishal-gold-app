# Play Store Deployment Checklist - Vishal Jewelers

This document covers the essential settings and configurations required for a successful production deployment on the Google Play Store.

## 1. Firebase Console (Production Fine-Tuning)

### App Signing by Google Play (CRITICAL)
When you upload your App Bundle (.aab) to Google Play, Google generates a **Release SHA-256 fingerprint**.
1.  Go to **Google Play Console** → **Setup** → **App Integrity**.
2.  Copy the **SHA-256 certificate fingerprint** from the "App signing key certificate" section.
3.  Go to **Firebase Console** → Project Settings → Your Apps.
4.  Add this new SHA-256 fingerprint to your Android app (`com.vishaljewelersapp`).
> [!IMPORTANT]
> Without this, Phone Authentication (OTP) will **NOT** work on the version downloaded from the Play Store!

### App Check (Production Mode)
1.  Go to **App Check** in the Firebase Console.
2.  Switch the Android app from "Debug" provider to **Play Integrity**.
3.  Ensure you have added your project to the Google Cloud Console and enabled the Play Integrity API.

### Authentication Domains
1.  In **Authentication** → **Settings** → **Authorized domains**.
2.  Add your production URL if you use Web/Redirect-based login.

## 2. Google Play Console Settings

### Data Safety
You must declare that the app uses:
- **Phone Number** (for Auth).
- **Device IDs** (for Analytics/FCM).
- **Contact Info** (if applicable).

### Privacy Policy
A public URL for your Privacy Policy is REQUIRED.
- **Location**: Usually hosted on your website (e.g., `vishaljewelers.com/privacy-policy`).
- **Update**: Ensure it reflects the data collection policies for Firebase services.

### Permissions Notice
If your app uses background location or other sensitive permissions, ensure you have the appropriate prominent disclosures.

## 3. App Bundle (.aab) Preparation
1.  **Version Code**: Increase the `versionCode` in `pubspec.yaml` for every new release.
2.  **Signing**: Ensure you are using the `vishal_jewelers_release.jks` keystore.
3.  **Proguard/R8**: Ensure code shrinking and obfuscation are enabled in `android/app/build.gradle.kts`.

---
**Status**: DRAFT (Review required before first deployment)
