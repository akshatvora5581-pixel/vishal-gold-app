# Troubleshooting Guide — Vishal Gold App
**Version:** 1.0 | **Last Updated:** 2026-02-25 | **Maintained by:** Engineering Team

> Structured for rapid debugging in **Development**, **Staging**, and **Production** environments.

---

## Table of Contents

1. [Environment Setup Issues](#1-environment-setup-issues)
2. [Build Failures](#2-build-failures)
3. [Runtime Errors & Crashes](#3-runtime-errors--crashes)
4. [Firebase / API / Network Issues](#4-firebase--api--network-issues)
5. [Authentication Failures](#5-authentication-failures)
6. [Dependency Conflicts](#6-dependency-conflicts)
7. [Configuration Mistakes](#7-configuration-mistakes)
8. [Performance Bottlenecks](#8-performance-bottlenecks)
9. [Security Misconfigurations](#9-security-misconfigurations)
10. [Quick Reference Commands](#10-quick-reference-commands)

---

## 1. Environment Setup Issues

### 1.1 `flutter doctor` reports missing dependencies

**Symptoms:**
- `flutter doctor` shows ✗ on Android toolchain or Xcode
- `flutter run` fails immediately with "No devices available"

**Root Cause:** Android SDK, Java, or Xcode command-line tools are not installed or not on PATH.

**Diagnostic Steps:**
```bash
flutter doctor -v
echo $JAVA_HOME         # Linux/macOS
echo $env:JAVA_HOME     # PowerShell (Windows)
```

**Resolution:**
1. Install Android Studio → SDK Tools → install `Android SDK`, `Android SDK Command-line Tools`
2. Set `ANDROID_HOME` and `JAVA_HOME` in system environment variables
3. Accept Android licenses: `flutter doctor --android-licenses`
4. On Windows, add `%ANDROID_HOME%\platform-tools` to PATH

**Prevention:** Pin Flutter SDK version in `.tool-versions` or `fvm` config. Document minimum SDK versions in `README.md`.

---

### 1.2 Flutter SDK version mismatch (Dart SDK constraint violation)

**Symptoms:**
```
The current Dart SDK version is X.Y.Z. Because vishal_gold requires SDK version ^3.9.2, it requires a newer SDK.
```

**Root Cause:** Local Flutter installation is older than the `environment.sdk` constraint in `pubspec.yaml`.

**Diagnostic Steps:**
```bash
flutter --version
dart --version
```

**Resolution:**
```bash
flutter upgrade          # Using channel stable
# OR with FVM (recommended):
fvm install 3.32.0
fvm use 3.32.0
```

**Prevention:** Use `fvm` to pin the Flutter version. Commit `.fvm/fvm_config.json` to the repo.

---

### 1.3 `google-services.json` missing

**Symptoms:**
```
FAILURE: Build failed with an exception.
> Could not resolve com.google.gms:google-services:...
```

**Root Cause:** `google-services.json` is in `.gitignore` (correctly, per VAPT-007) and was not manually placed.

**Diagnostic Steps:**
```bash
ls android/app/google-services.json
```

**Resolution:**
1. Download `google-services.json` from Firebase Console → Project Settings → Android app
2. Place at `android/app/google-services.json`
3. **Never commit** this file to git

**Prevention:** Add setup instructions to `README.md`. Use a CI secret to inject `google-services.json` at build time.

---

## 2. Build Failures

### 2.1 Kotlin incremental compilation error

**Symptoms:**
```
e: error: unresolved reference: ...
Execution failed for task ':app:compileDebugKotlin'
```

**Root Cause:** Stale build cache causing incremental Kotlin compilation to fail on changed plugin APIs.

**Diagnostic Steps:**
```bash
flutter build apk --verbose 2>&1 | tail -50
```

**Resolution:**
```bash
flutter clean
flutter pub get
cd android && ./gradlew clean && cd ..
flutter build apk
```

**Prevention:** Run `flutter clean` after switching Flutter channels or major dependency upgrades.

---

### 2.2 Multidex limit exceeded

**Symptoms:**
```
Cannot fit requested classes in a single dex file
D8: Error: Cannot read build/... (method reference count exceeds 65536)
```

**Root Cause:** App exceeds Android's 64K method reference limit. Common after adding heavy Firebase packages.

**Resolution:**
1. Enable multidex in `android/app/build.gradle`:
```groovy
android {
    defaultConfig {
        multiDexEnabled true
    }
}
dependencies {
    implementation 'com.android.support:multidex:1.0.3'
}
```

---

### 2.3 Gradle version incompatibility

**Symptoms:**
```
Could not resolve com.android.tools.build:gradle:...
```

**Diagnostic:**
```bash
cat android/build.gradle | grep classpath
cat android/gradle/wrapper/gradle-wrapper.properties
```

**Resolution:** Align versions in `android/build.gradle` and `gradle-wrapper.properties`. Check Firebase BoM compatibility matrix at [firebase.google.com/docs/android/setup](https://firebase.google.com/docs/android/setup).

---

### 2.4 `pub get` fails behind corporate proxy

**Symptoms:**
```
Got socket error trying to find package at https://pub.dev
```

**Resolution:**
```bash
export https_proxy=http://proxy.corp.com:8080
export DART_PUB_CACHE=~/.pub-cache
flutter pub get
```

---

### 2.5 Release build fails on minification (R8/ProGuard)

**Symptoms:**
```
Caused by: java.lang.ClassNotFoundException: XxxClass
```

**Root Cause:** R8 shrinks classes referenced only via reflection (common with Firebase plugins).

**Resolution:** Add rules to `android/app/proguard-rules.pro`:
```
-keep class com.google.firebase.** { *; }
-keep class io.flutter.** { *; }
-dontwarn com.google.firebase.**
```

---

## 3. Runtime Errors & Crashes

### 3.1 `setState() called after dispose()`

**Symptoms:**
```
FlutterError: setState() called after dispose()
```

**Root Cause:** An async callback completes and calls `setState()` after the widget was removed from the tree. Common in OTP and network flows.

**Diagnostic:** Look for `setState()` calls inside `async` functions without a `mounted` check.

**Resolution:** Guard every post-`await` setState call:
```dart
if (!mounted) return;
setState(() { ... });
```

**Note:** The OTP rate-limiting cooldown loop in `phone_auth_screen.dart` already applies this pattern.

---

### 3.2 `MissingPluginException` at runtime

**Symptoms:**
```
MissingPluginException(No implementation found for method ... on channel ...)
```

**Root Cause:** A Flutter plugin was added but the app was not fully rebuilt (hot reload does not register native plugins).

**Resolution:**
```bash
flutter clean
flutter pub get
flutter run         # Full rebuild required — not hot reload
```

---

### 3.3 `Null check operator used on a null value` (LateInitializationError)

**Symptoms:** `LateInitializationError: Field 'xxx' has not been initialized.` or `Null check operator used on a null value`

**Root Cause:** `LocalStorageService.init()` was not awaited before accessing `_prefs!`, or `FirebaseApp` not initialized before using Firebase services.

**Diagnostic:**
```bash
# Check main.dart initialization order
grep -n "LocalStorageService\|Firebase.initializeApp" lib/main.dart
```

**Resolution:** Ensure `main.dart` initializes in this order:
```dart
WidgetsFlutterBinding.ensureInitialized();
await Firebase.initializeApp();
await LocalStorageService.init();
```

---

### 3.4 Image loading shows blank / breaks layout

**Symptoms:** `CachedNetworkImage` shows empty space or error icon.

**Diagnostic:**
```dart
// Enable verbose image loading errors
CachedNetworkImage(
  imageUrl: url,
  errorWidget: (ctx, url, err) {
    debugPrint('Image error: $err for $url');
    return Icon(Icons.broken_image);
  },
)
```

**Resolution:**
1. Verify the URL is a valid `https://` link (Firebase Storage URLs have an expiry)
2. Check Firebase Storage rules allow public read on product images
3. Ensure `android.permission.INTERNET` is in `AndroidManifest.xml`

---

### 3.5 Cart items lost on app restart (Retailer)

**Symptoms:** Retailer adds items to cart; after closing and reopening the app, cart is empty.

**Root Cause:** `CartProvider.initialize()` was called with `userId = null`, causing it to default to local storage JSON path. If `LocalStorageService.init()` wasn't awaited before reading, `_prefs` is null and `getCart()` silently fails.

**Resolution:** Verify `AuthProvider` is fully initialized before `CartProvider.initialize()` is called in the widget tree.

---

## 4. Firebase / API / Network Issues

### 4.1 `[cloud_firestore/permission-denied]`

**Symptoms:**
```
FirebaseException ([cloud_firestore/permission-denied] The caller does not have permission to execute the specified operation.)
```

**Diagnostic:**
```bash
# Check active Firestore rules in Firebase Console
# Or use Rules Playground in Firebase Console to simulate the failing read/write
```

**Root Cause:** Firestore security rules deny the current authenticated user's operation. Common causes:
- User is not authenticated (anonymous or signed out)
- Accessing a document outside their UID scope

**Resolution (Development):** Temporarily open rules to test:
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```
**Then tighten rules before deploying to production.**

---

### 4.2 Firebase Storage upload fails

**Symptoms:** Image upload hangs indefinitely or throws `firebase_storage/unauthorized`.

**Diagnostic:**
```bash
# Check Storage rules in Firebase Console > Storage > Rules
# Verify file size — Firebase Storage free tier allows up to 5GB but individual uploads default to no limit
```

**Resolution:**
1. Ensure Storage rules allow write for authenticated users on the target path
2. Add a file size check before upload (images > 10MB should be compressed first)

---

### 4.3 FCM push notifications not received

**Symptoms:** Test notifications from Firebase Console are not delivered to device.

**Diagnostic:**
```bash
adb shell dumpsys notification --noredact | grep vishal_gold
adb logcat | grep FCM
```

**Root Cause:** FCM token is stale (not refreshed on reinstall), or notification channel not set up on Android 8+.

**Resolution:**
1. Ensure `FCMService.updateUserToken()` is called in `AuthProvider._loadUserProfile()`
2. Create notification channel for Android 8+ in `main.dart`

---

### 4.4 `SocketException: Failed host lookup`

**Symptoms:** All network requests fail with `SocketException`.

**Root Cause:** Device has no internet connection, or corporate firewall blocks `*.googleapis.com`.

**Diagnostic:**
```bash
adb shell ping 8.8.8.8
```

**Resolution:** Implement connectivity check using `connectivity_plus` package before making any network call. Display an offline banner in the UI.

---

## 5. Authentication Failures

### 5.1 OTP never received / SMS not delivered

**Symptoms:** User taps "Send OTP" and receives no SMS after 60 seconds.

**Root Cause:**
- Phone number format incorrect (missing country code)
- Firebase Auth SMS quota exhausted for the project
- Test number not in Firebase Auth > Sign-in Method > Phone > Test phone numbers

**Diagnostic:**
```bash
# In Firebase Console: Authentication > Usage > SMS quota
# Check: Authentication > Sign-in Method > Phone > Add test phone numbers for dev
```

**Resolution:**
1. Verify number format: must be `+91XXXXXXXXXX`
2. Add test numbers in Firebase console for development to avoid SMS charges
3. If quota exceeded: upgrade billing plan or wait for quota reset

---

### 5.2 `[firebase_auth/session-expired]`

**Symptoms:** OTP verification fails with session expired error.

**Root Cause:** OTP validity window (60 seconds) expired before the user entered the code.

**Resolution:** The UI already shows a 60-second cooldown before resend. Increase the `timeout` in `FirebaseAuthService.sendOTP()` if needed:
```dart
timeout: const Duration(seconds: 120),
```

---

### 5.3 `[firebase_auth/too-many-requests]`

**Symptoms:** Firebase returns too-many-requests error.

**Root Cause:** The same phone number has been used for too many OTP requests in a short period (Firebase server-side rate limiting).

**Resolution:**
- Wait 24 hours for rate limit reset
- Use a different test phone number
- The 60-second client-side cooldown (VAPT-004 fix) prevents UI-driven abuse, but does not override Firebase's server-side limits

---

### 5.4 User role is `null` after login

**Symptoms:** User logs in, but `AuthProvider.userRole` is null, causing wrong UI to render.

**Root Cause:** `LocalStorageService.getUserRole()` reads from `FlutterSecureStorage`. On first install, no role is saved yet.

**Diagnostic:**
```dart
final role = await LocalStorageService.getUserRole();
debugPrint('Role: $role'); // only in debug
```

**Resolution:** `_handleUserLogin()` in `phone_auth_screen.dart` should ensure role is saved after successful first login via Firestore profile fetch.

---

## 6. Dependency Conflicts

### 6.1 `Because X depends on Y >=A and Z depends on Y <B, version solving failed.`

**Symptoms:** `flutter pub get` fails with version solver conflict.

**Diagnostic:**
```bash
flutter pub deps
flutter pub outdated
```

**Resolution:**
```bash
# Add a dependency override in pubspec.yaml as last resort:
dependency_overrides:
  conflicting_package: ^X.Y.Z

flutter pub get
```
> ⚠️ Overrides can hide real incompatibilities. Prefer updating the conflicting dependency instead.

---

### 6.2 `flutter_secure_storage` fails on older Android (API < 23)

**Symptoms:** `PlatformException` when running on Android API 21–22.

**Root Cause:** `flutter_secure_storage` requires `minSdkVersion 23` by default.

**Resolution:** In `android/app/build.gradle`, confirm `minSdkVersion 23` (already required by Firebase Auth phone auth). If you must support API 21–22, set `keyCipherAlgorithm` option.

---

### 6.3 `uuid` package conflicts with `cloud_firestore`

**Symptoms:** Pub solver error mentioning `uuid` version constraint.

**Resolution:** `cloud_firestore` transitively pins `uuid`. Check the exact version it requires and use `dependency_overrides` only if necessary:
```yaml
dependency_overrides:
  uuid: ^4.2.1
```

---

## 7. Configuration Mistakes

### 7.1 Wrong Firebase project connected (development vs production)

**Symptoms:** Data written in dev appears in production Firestore, or vice versa.

**Root Cause:** Same `google-services.json` used across environments.

**Resolution:**
1. Create separate Firebase projects for `dev` and `prod`
2. Use Flutter flavors:
   - `android/app/src/dev/google-services.json`
   - `android/app/src/prod/google-services.json`
3. Run with `flutter run --flavor dev -t lib/main_dev.dart`

---

### 7.2 `AppColors` showing wrong brand colors

**Symptoms:** Gold color appears as yellow or purple appears instead of gold.

**Root Cause:** Constants in `app_colors.dart` have been modified or a new developer used incorrect hex values.

**Reference Colors:**
```dart
static const Color gold = Color(0xFFD4AF37);       // Metallic Gold
static const Color background = Color(0xFF1A1A1A); // Deep Charcoal
static const Color surface = Color(0xFF2A2A2A);    // Card Surface
static const Color black = Color(0xFF0D0D0D);      // Pure Black
```

---

### 7.3 Products not appearing in listing after admin upload

**Symptoms:** Admin uploads product but it doesn't show in `ProductListingScreen`.

**Root Cause:** Admin uses a staging workflow. Products written to `staging/` collection are not visible until `publishChanges()` is called.

**Resolution:**
1. In Admin Dashboard, go to Preview mode
2. Review staged changes
3. Tap "Publish" to move staged data to live `products/` collection

---

## 8. Performance Bottlenecks

### 8.1 Product listing screen stutters / drops frames

**Symptoms:** Grid scroll feels janky; Flutter performance overlay shows red bars.

**Diagnostic:**
```bash
flutter run --profile
# Then use DevTools: flutter pub global run devtools
```

**Root Cause:** `ProductCard` rebuilds on every scroll frame due to missing `const` constructors or large widget trees.

**Resolution:**
1. Make `ProductCard` a `const` widget where possible
2. Use `CachedNetworkImage` (already implemented) — do not use `Image.network` directly
3. Use `RepaintBoundary` around cards if shimmer or animation is used
4. Profile with Flutter DevTools > Performance tab

---

### 8.2 Firestore reads are too frequent (waterfall reads)

**Symptoms:** Many simultaneous Firestore reads on screen load; Firestore quota exceeded quickly.

**Root Cause:** Each `ProductCard` makes a separate Firestore query for category/extra data.

**Resolution:**
1. Batch data at the listing level: fetch all product data in a single `FirebaseService.getProducts()` call
2. Use `StreamBuilder` with a single `collection().snapshots()` stream
3. Cache Firestore results in-memory for the session using the existing `ProductProvider`

---

### 8.3 App startup time is slow (> 3 seconds cold start)

**Diagnostic:**
```bash
flutter run --trace-startup --profile
```

**Root Cause:** `LocalStorageService.init()`, `Firebase.initializeApp()`, and multiple provider inits run sequentially in `main.dart`.

**Resolution:** Parallelize independent initialization calls:
```dart
await Future.wait([
  Firebase.initializeApp(),
  LocalStorageService.init(),
]);
```

---

### 8.4 Release APK is too large (> 80MB)

**Diagnostic:**
```bash
flutter build apk --analyze-size
flutter build apk --split-per-abi   # Creates separate APKs per architecture
```

**Resolution:**
1. Use `flutter build appbundle` for Play Store (AAB splits automatically)
2. Compress assets: convert PNG → WebP for product images
3. Enable R8 shrinking in `build.gradle` (`minifyEnabled true`)

---

## 9. Security Misconfigurations

### 9.1 PII found in SharedPreferences (Pre-fix symptom)

> ✅ **Fixed in VAPT-001** — PII now stored in `FlutterSecureStorage`.

**Diagnostic (to verify fix):**
```bash
adb shell run-as com.vishalgold.app \
  cat shared_prefs/FlutterSharedPreferences.xml
# Expected: user_name, user_phone should NOT appear here
# Any such key found = regression, re-check LocalStorageService
```

---

### 9.2 Admin login screen accessible without credentials (Pre-fix symptom)

> ✅ **Fixed in VAPT-003** — Long-press gesture removed.

**Diagnostic:** Long-press logo for 5+ seconds. Admin login must NOT appear.

---

### 9.3 Firestore rules too permissive in production

**Symptom:** Any authenticated user can write any document.

**Diagnostic:**
```bash
# Firebase Console > Firestore > Rules > Rules Playground
# Simulate a write from a non-admin UID to /products/
```

**Resolution:** Deploy minimum-privilege rules (see `VAPT_Report_After.md` > VAPT-006 > recommended rules).

---

### 9.4 `google-services.json` accidentally committed to git

**Detection:**
```bash
git log --all --full-history -- "android/app/google-services.json"
git grep "google-services.json" -- .gitignore
```

**Resolution:**
```bash
# Remove from git history using BFG Repo Cleaner
bfg --delete-files google-services.json
git push --force
# Then rotate all Firebase API keys in Firebase Console
```

---

### 9.5 Debug builds with sensitive data reach staging/production

**Symptom:** `debugPrint` statements expose UIDs or auth tokens in logcat on staging builds.

**Diagnostic:**
```bash
adb logcat | grep -i "uid\|token\|phone\|auth"
```

**Resolution:** All `debugPrint` calls are wrapped with `kDebugMode` guard. Release builds strip them automatically. Verify by building a profile APK and checking logcat.

---

## 10. Quick Reference Commands

| Action | Command |
|--------|---------|
| Full clean and rebuild | `flutter clean && flutter pub get && flutter run` |
| Analyze for errors | `flutter analyze` |
| Check dependency tree | `flutter pub deps` |
| Outdated packages | `flutter pub outdated` |
| Build release APK | `flutter build apk --release` |
| Build AAB (Play Store) | `flutter build appbundle --release` |
| Run with profile mode | `flutter run --profile` |
| Open DevTools | `flutter pub global run devtools` |
| Check SharedPreferences (debug) | `adb shell run-as com.vishalgold.app cat shared_prefs/FlutterSharedPreferences.xml` |
| View device logs | `adb logcat -s flutter` |
| List connected devices | `flutter devices` |
| Accept Android licenses | `flutter doctor --android-licenses` |
| Deploy Firestore rules | `firebase deploy --only firestore:rules` |
| Deploy Storage rules | `firebase deploy --only storage` |
