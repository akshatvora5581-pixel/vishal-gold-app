# Firebase Configuration Guide - Vishal Jewelers

This guide outlines the exact steps to migrate your Firebase backend to the new brand identity (**Vishal Jewelers**) and package name (`com.vishaljewelersapp`).

## 1. Register the New Android App
1.  Open the [Firebase Console](https://console.firebase.google.com/).
2.  Select your project: `vishal-jewelers-app`.
3.  In the **Project Overview**, click the **Add app** button (+ icon) and select **Android**.
4.  **Register App**:
    *   **Android package name**: `com.vishaljewelersapp` (MANDATORY).
    *   **App nickname**: `Vishal Jewelers Android`.
5.  Click **Register app**.

## 2. Add SHA Fingerprints (Critical for Login/OTP)
1.  After registering (or in the App settings), find the **SHA certificate fingerprints** section.
2.  Click **Add fingerprint** and add the following four keys:

### Debug Keys (Local Testing)
*   **SHA-1**: `E5:D6:EB:EF:01:F7:7E:77:6C:4A:82:20:7E:A2:65:D6:A4:81:21:81`
*   **SHA-256**: `1C:3E:A3:D7:D6:FF:E4:57:FA:C5:45:3C:1E:07:EC:53:50:F9:A5:54:82:DD:5A:D1:8C:03:57:42:D9:CC:F8:EF`

### Release Keys (Production)
*   **SHA-1**: `91:EE:B9:D3:F3:C5:17:4D:57:7A:36:BD:64:BF:4D:C4:03:81:11:B8`
*   **SHA-256**: `1D:39:D4:2A:5B:1E:CE:14:6B:E7:EA:45:39:EC:E0:1D:96:97:48:81:81:3E:A6:C3:36:B1:0B:B8:BE:88:92:2C`

## 3. Register Debug Token (For App Check)
If your app shows an "App Check FAILED" error in the logs while testing:
1.  Go to **App Check** in the Firebase Console.
2.  Go to the **Apps** tab.
3.  Click the menu (three dots) next to the `com.vishaljewelersapp` app.
4.  Select **Manage debug tokens**.
5.  Click **Add debug token** and paste: `E28D6C9E-B9EF-48C1-B3F4-5AC449EC14EB`.
6.  *Note: This matches the token currently hardcoded in your `main.dart`.*

## 4. Download Update Configuration
1.  Download the fresh `google-services.json` from the console.
2.  Replace the file located at: `android/app/google-services.json`.

## 5. Enable Additional Firebase Services
### Authentication
1. Go to **Authentication** → **Sign-in method**.
2. Click **Add new provider** and enable **Phone**.
3. (Optional) Enable **Google** if your app supports it.

### Firestore Database
1. Go to **Firestore Database** → **Rules**.
2. Ensure your rules allow the app to read/write data (use "Test Mode" only for initial setup; switch to secure rules for production).

### Cloud Storage
1. Go to **Storage** → **Rules**.
2. Ensure rules match your application requirements.

## 6. Summary of Authentication Changes
- **OTP Auto-Detection**: The 11-character hash string at the end of your SMS messages needs to be updated. Once the app is running with the new package name, you can use the `sms_autofill` plugin feature or check logs to find the new 11-digit signature and update your SMS template accordingly.
- **Authorized Domains**: If you use Social Auth (Google/Facebook), ensure the new bundle ID is allowed in the OAuth consent screen (this is usually automatic).
