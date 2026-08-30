# Vishal Jewelers - Android Production Release

This folder contains the production-ready build files for the Vishal Jewelers application, specifically prepared for client review and Google Play Store submission.

## Files Included

1. `VishalJewelers-Production.aab`
   - **Type:** Android App Bundle
   - **Usage:** This is the primary file required by the **Google Play Store**. You must upload this file to the Google Play Console for your production release.
   - **Why AAB?** It allows Google Play to generate and serve optimized APKs automatically for each user's specific device configuration, reducing app size.

2. `VishalJewelers-Production.apk`
   - **Type:** Android Package Kit (Universal)
   - **Usage:** This file is for direct distribution, internal testing, or manual installation (sideloading) on Android devices.
   - **Note:** Do NOT upload this to the Google Play Store.

3. `upload-keystore.jks` & `key.properties` (Provided Separately / Securely)
   - **Usage:** These are your master signing keys. 
   - ⚠️ **CRITICAL WARNING:** Keep the Keystore file and its passwords extremely secure. If lost, you will not be able to push updates to the Play Store. Do NOT commit these to public version control.

## Build Optimizations Applied
- **R8 Code Shrinking & Obfuscation:** Unused code has been stripped and variable names obfuscated to prevent reverse engineering and reduce app size.
- **Resource Shrinking:** Unused image assets and layouts have been removed.
- **Developer Metadata:** Configured for `ZeroOne CodeTech`.
- **Release Configurations Only:** No debug codes or performance-heavy analytics are left running in debug mode.

## How to Install the APK Manually
1. Transfer the `VishalJewelers-Production.apk` to your Android device via USB, Email, or Google Drive.
2. Tap the file in your device's file manager.
3. If prompted, enable "Install unknown apps" from that specific file manager or browser.
4. Click "Install".

## How to Publish to Google Play
1. Go to your [Google Play Console](https://play.google.com/console).
2. Select or create the "Vishal Jewelers" app.
3. Navigate to **Testing** or **Production** -> **Create new release**.
4. Under "App bundles", upload the `VishalJewelers-Production.aab` file.
5. Fill out your release notes and wait for Google's review.

---
*Built with ❤️ by ZeroOne CodeTech*
