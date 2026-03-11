# Vishal Gold - Android Release Instructions

## Contents
1. **app-release.apk**: Standard Android installer for direct testing on devices.
2. **app-release.aab**: Android App Bundle for uploading to the Google Play Store.
3. **vishal_gold_release.jks**: Production signing key.
4. **keystore_credentials.txt**: Passwords for the signing key.
5. **Source Code**: Full application source for archival and future development.

## Installation (APK)
- Transfer `app-release.apk` to an Android device.
- Enable "Install from Unknown Sources" in settings.
- Open the file to install the application.

## Play Store Submission (AAB)
- Log in to the Google Play Console.
- Create a new Release.
- Upload the `app-release.aab` file.
- The AAB is optimized by Google to deliver the smallest possible APK for each device.

## Source Code
- This folder contains the full Flutter project.
- To run or modify, ensure Flutter and Dart are installed on your machine.
- Run `flutter pub get` followed by `flutter run`.

Developed by: ZeroOne CodeTech
