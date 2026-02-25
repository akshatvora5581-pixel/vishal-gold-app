# Troubleshooting Guide — Vishal Gold (Ultra-Detailed)
**Version:** 1.2 | **Last Updated:** 2026-02-25 | **Status:** Mission-Critical

---

## 1. Environment & Build Failures

### 1.1 Gradle Sync Failures (Android)
- **Symptoms**: `Could not resolve all files for configuration ':app:debugRuntimeClasspath'.`
- **Root Cause**: Proxy issues or Corrupted `~/.gradle` cache.
- **Resolution**:
    1. Run `cd android && ./gradlew clean`.
    2. Toggle `Offline Mode` in Android Studio if on restricted network.
    3. Delete `android/.gradle` and `android/build` and retry sync.

### 1.2 MultiDex / 64K Method Limit
- **Symptoms**: `Cannot fit requested classes in a single dex file.`
- **Root Cause**: Heavy Firebase libraries (Auth + Firestore + Messaging) exceed the legacy 65,536 method limit.
- **Resolution**: App is already configured for MultiDex, but ensure `minSdkVersion 21` (already set) is active in `build.gradle`.

### 1.3 Keystore / Signing Conflict
- **Symptoms**: `App not installed as package conflicts with an existing package.`
- **Root Cause**: Trying to install a Release build over a Debug build without matching certificates.
- **Resolution**: Uninstall the existing app first: `adb uninstall com.vishalgold.app`.

---

## 2. Runtime & Application State Errors

### 2.1 "ProviderNotFoundException"
- **Symptoms**: Red screen error: `Error: Could not find the correct Provider<T>...`
- **Root Cause**: Accessing a Provider from a context that is "above" it in the widget tree (e.g., trying to access `CartProvider` from a dialog launched outside the MultiProvider scope).
- **Resolution**: Ensure the widget is a descendant of `MyApp` wrap in `main.dart`. If using navigation, use the correct context passed from the listing page.

### 2.2 LateInitializationError
- **Symptoms**: `LateInitializationError: Field '_prefs' has not been initialized.`
- **Root Cause**: Accessing `LocalStorageService` before `await LocalStorageService.init()` completes in `main()`.
- **Resolution**: Ensure the `await` is present in `main.dart` and the app is not using `kDebugMode` to bypass critical init.

### 2.3 Image Loading Stutter (Jank)
- **Symptoms**: UI hangs for 100ms when scrolling the product list.
- **Root Cause**: Decoding large original JPGs from Firebase.
- **Resolution**: 
    1. Verify `CachedNetworkImage` is used with a fixed `memCacheWidth`.
    2. Admin should shrink images to < 500KB before upload.

---

## 3. Firebase & Connectivity Criticals

### 3.1 [cloud_firestore/permission-denied]
- **Symptoms**: Data fails to load; "Permission Denied" in Logcat.
- **Diagnostic**: Use Firebase Rules Playground.
- **Resolutions**:
    - **Wholesaler Access**: Check if the user document exists in `/users/{uid}` and has `isWholesaler: true`.
    - **Anonymous User**: Ensure `Retailer` flows are permitted in rules (already verified in VAPT-006).

### 3.2 Firebase Storage "Object not found"
- **Symptoms**: Image URLs return 404.
- **Root Cause**: Product metadata was saved but the image upload failed or was deleted.
- **Resolution**: Check the `image_urls` array in product Firestore doc. Verify the paths actually exist in the `GS://` bucket.

### 3.3 FCM Token Null
- **Symptoms**: Admin sends notification but specific device "not found".
- **Root Cause**: User denied notification permission on first launch.
- **Resolution**: 
    - Go to App Settings -> Notifications -> Enabled.
    - `AuthProvider` will refresh the token on the next app restart.

---

## 4. Authentication Deep-Troubleshooting

### 4.1 SMS Quota Exceeded
- **Symptoms**: `firebase_auth/quota-exceeded`
- **Root Cause**: High volume of OTP requests on the daily free tier.
- **Resolution**: 
    - Add the developer phone number to "Test Phone Numbers" in Firebase Console (unlimited free OTPs).
    - Upgrade project to Blaze (Pay-as-you-go).

### 4.2 "INVALID_ID_TOKEN"
- **Symptoms**: User logs in but Firestore reads fail immediately after.
- **Root Cause**: System clock mismatch between device and Firebase servers.
- **Resolution**: Set device time to "Automatic".

---

## 5. Security & Compliance Errors

### 5.1 "Screenshot Prevention Active"
- **Symptoms**: User reports "I cannot take a screenshot of my cart".
- **Reason**: **Expected Behavior** (VAPT-012). Secure screens prevent capture for PII safety.
- **Override (Dev Only)**: Comment out `SystemChrome.setSystemUIOverlayStyle` and `WindowManager.addFlags(LayoutParams.FLAG_SECURE)` in the specific screen's `initState`. **DO NOT COMMIT THIS.**

### 5.2 ADB Log Exposure
- **Symptoms**: Sensitive UIDs appearing in `adb logcat`.
- **Reason**: `debugPrint` used without a production guard.
- **Resolution**: Replace `print()` or `debugPrint()` with a logging wrapper that respects `kReleaseMode`.

---

## 6. Diagnostic Toolkit & Commands

| Tool | Command | Purpose |
|------|---------|---------|
| **Flutter Doctor** | `flutter doctor -v` | Validate SDK health. |
| **DevTools** | `flutter pub global run devtools` | Performance & State inspection. |
| **ADB Log** | `adb logcat -s flutter` | Real-time app logging. |
| **APK Split** | `flutter build apk --split-per-abi` | Debug size-related build errors. |
| **Rules Test** | `firebase deploy --only firestore:rules` | Apply latest security patches. |

---

## 7. Emergency Recovery Procedure

If the app enters an inconsistent state (Corrupted local DB + stale Firebase persistence):
1. **Clear Local Data**: `Settings -> Apps -> Vishal Gold -> Clear Storage`.
2. **Restart Provider**: Perform a "Hot Restart" (Shift+R) to clear `ChangeNotifier` states.
3. **Re-Auth**: Force sign out and re-verify via Phone OTP.
