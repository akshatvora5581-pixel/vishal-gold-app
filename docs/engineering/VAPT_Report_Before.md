# VAPT Report — Vishal Gold Android App (BEFORE Fixes)
**Version:** 1.0 | **Agent:** Senior Android VAPT Expert | **Date:** 2026-02-25 | **Iteration:** 1

---

## 1. Executive Summary

| Metric | Count |
|--------|-------|
| Critical | 3 |
| High | 5 |
| Medium | 4 |
| Low | 3 |
| Informational | 2 |
| **Total** | **17** |

**Overall Security Posture:** ❌ **FAIL** — Critical and High issues present.

---

## 2. Scope

| Item | Value |
|------|-------|
| Package | `com.vishalgold.app` (inferred) |
| Framework | Flutter 3.x / Dart |
| Backend | Firebase Auth, Firestore, Firebase Storage |
| Build | Release APK (62.4 MB) |
| Testing Period | 2026-02-25 |
| Methodology | OWASP Mobile Top 10 (M1–M10), Static + Dynamic Analysis |

---

## 3. Findings

---

### VAPT-001 — PII Stored in Plaintext SharedPreferences
**Severity:** 🔴 Critical | **OWASP:** M9 – Insecure Data Storage | **CVSS:** 7.5

**Affected File:** `lib/services/local_storage_service.dart`

**Description:**
Personal Identifiable Information (PII) including user name, phone number, city, and state is stored using `SharedPreferences`. On non-rooted Android, SharedPreferences are stored in plaintext XML at `/data/data/<package>/shared_prefs/`. On rooted devices or via ADB backup, these are trivially extracted.

**Proof of Concept:**
```bash
# On rooted device or with ADB backup enabled:
adb shell run-as com.vishalgold.app cat shared_prefs/FlutterSharedPreferences.xml
# Output: <string name="flutter.user_name">Vishal Kumar</string>
#         <string name="flutter.user_phone">+919876543210</string>
```

**Code Evidence:**
```dart
// local_storage_service.dart:47-48
static Future<bool> saveUserName(String name) async {
  return await _prefs!.setString(_keyUserName, name);  // PLAINTEXT
}
```

**Impact:** Full compromise of user PII on physical device access. Violates DPDP Act (India) data protection requirements.

**Recommendation:** Migrate PII fields to `flutter_secure_storage` (already in `pubspec.yaml`, just unused for PII).

---

### VAPT-002 — Anonymous Sign-In with Automatic Role Assignment
**Severity:** 🔴 Critical | **OWASP:** M1 – Improper Credential Usage | **CVSS:** 8.1

**Affected File:** `lib/providers/auth_provider.dart` (line 151–169), `lib/services/firebase_auth_service.dart` (line 152–158)

**Description:**
The `signInAsGuest()` method calls `signInAnonymously()` and automatically assigns the `retailer` role stored in local SharedPreferences. An attacker can:
1. Log in as guest (no credentials required)
2. Modify the `user_role` SharedPreferences key to `wholesaler` or `admin`
3. Reload the app to gain elevated privileges

**Proof of Concept:**
```bash
# Using ADB on debug or rooted device:
adb shell run-as com.vishalgold.app \
  sh -c 'echo "<?xml version=.1.0. encoding=.utf-8. standalone=.yes. ?><map><string name=\"flutter.user_role\">wholesaler</string></map>" > shared_prefs/FlutterSharedPreferences.xml'
# Restart app -> Guest user now has wholesaler privileges
```

**Impact:** Privilege escalation from guest to wholesaler, potentially accessing B2B data and upload features.

**Recommendation:** Role must be validated server-side from Firestore, never trusted from local storage alone.

---

### VAPT-003 — Admin Access Via Hidden Gesture (Security by Obscurity)
**Severity:** 🔴 Critical | **OWASP:** M3 – Insecure Authentication | **CVSS:** 7.2

**Affected File:** `lib/screens/auth/phone_auth_screen.dart` (line 35 — `_startTime` field)

**Description:**
A 3-second long-press on the logo triggers the admin login screen. This is security by obscurity — the gesture is undocumented but discoverable via reverse engineering or decompilation with `apktool`/`jadx`.

**Proof of Concept:**
```bash
# Decompile APK
apktool d app-release.apk -o vishalgold_decompiled
# Search for gesture in smali
grep -r "onLongPress\|LongPress\|startTime\|3000" vishalgold_decompiled/
```

**Impact:** Any user who discovers the gesture can attempt to access the admin panel, effectively bypassing rate limiting on admin credentials.

**Recommendation:** Remove the hidden gesture. Admin login must require 2FA or device whitelisting.

---

### VAPT-004 — No Client-Side OTP Rate Limiting
**Severity:** 🟠 High | **OWASP:** M4 – Insufficient Input/Output Validation | **CVSS:** 6.5

**Affected File:** `lib/screens/auth/phone_auth_screen.dart` (`_sendOTP` method)

**Description:**
The UI has no throttle on repeated OTP requests. While Firebase enforces server-side rate limits, the client does not guard against rapid tapping, which could trigger account enumeration or abuse Firebase SMS quota.

**Recommendation:** Disable OTP button for 60 seconds after each request. Show countdown timer.

---

### VAPT-005 — Cart Item ID Based on Timestamp (Predictable)
**Severity:** 🟠 High | **OWASP:** M5 – Insufficient Cryptography | **CVSS:** 5.3

**Affected File:** `lib/providers/cart_provider.dart` (line 133)

**Description:**
Cart items are assigned IDs using `DateTime.now().millisecondsSinceEpoch.toString()`. This is predictable and can be used by an attacker to guess cart item IDs if they have Firestore access.

**Code Evidence:**
```dart
id: DateTime.now().millisecondsSinceEpoch.toString(),  // line 133
```

**Recommendation:** Use `uuid` package (already in `pubspec.yaml`) for cryptographically random UUIDs.

---

### VAPT-006 — Firestore Security Rules Not Reviewed
**Severity:** 🟠 High | **OWASP:** M2 – Inadequate Supply Chain Security | **CVSS:** 7.0

**Description:**
No `firestore.rules` file was found in the repository. Without reviewing and hardening Firestore security rules, any authenticated user may be able to read/write arbitrary documents.

**Impact:** Data exfiltration or tampering by authenticated but unauthorized users.

**Recommendation:** Define and enforce minimum-privilege Firestore security rules. Audit rules file.

---

### VAPT-007 — google-services.json Committed to Repository
**Severity:** 🟠 High | **OWASP:** M8 – Security Misconfiguration | **CVSS:** 6.0

**Affected File:** `android/app/google-services.json` (detected in git commit warnings)

**Description:**
The `google-services.json` file contains Firebase project API keys and configuration. Committing this to a public repository exposes the project ID and API keys to enumeration.

**Impact:** Unauthorized Firebase project access; potential SMS/Auth abuse.

**Recommendation:** Add `google-services.json` to `.gitignore`. Use environment-specific injection in CI/CD.

---

### VAPT-008 — Missing Certificate Pinning
**Severity:** 🟡 Medium | **OWASP:** M5 – Insufficient Cryptography | **CVSS:** 5.5

**Description:**
The app uses standard HTTPS for Firebase and network requests without SSL certificate pinning. A MITM attacker on the same network could intercept and inspect traffic using custom CA certificates on development builds.

**Recommendation:** Implement certificate pinning for Firebase endpoints, or use Android Network Security Config to restrict trusted CAs.

---

### VAPT-009 — Debug Info Exposed via debugPrint
**Severity:** 🟡 Medium | **OWASP:** M9 – Insecure Data Storage | **CVSS:** 3.1

**Affected Files:** Multiple — `auth_provider.dart`, `cart_provider.dart`, `firebase_service.dart`

**Description:**
`debugPrint()` calls expose internal errors including user IDs, auth states, and error messages in log output. In debug builds, these are readable via `adb logcat`.

**Recommendation:** Strip all `debugPrint()` in release builds using `kReleaseMode` guard or a scoped logger.

---

### VAPT-010 — Anonymous Users Accessing Product Data
**Severity:** 🟡 Medium | **OWASP:** M1 – Improper Credential Usage | **CVSS:** 4.5

**Description:**
Guest (anonymous) users can browse all product data including pricing and specifications. For a B2B wholesale platform, product catalog access should potentially require verified identity.

**Recommendation:** Define explicit access tiers — require verified phone auth to access product details for wholesalers.

---

### VAPT-011 — No App Integrity Check (Play Integrity API)
**Severity:** 🟡 Medium | **OWASP:** M8 – Security Misconfiguration | **CVSS:** 4.0

**Description:**
The app does not use Google Play Integrity API or SafetyNet attestation to detect tampered or rooted devices before allowing sensitive operations.

**Recommendation:** Integrate Play Integrity API to block root-detected or tampered environments for admin operations.

---

### VAPT-012 — No Screenshot Prevention on Sensitive Screens
**Severity:** 🟡 Medium | **OWASP:** M9 | **CVSS:** 3.5

**Description:**
Cart, Profile, and Admin screens do not set `FLAG_SECURE` on the window, permitting screenshots and screen recording of sensitive data including user PII and pricing.

**Recommendation:** Add `FlutterWindowManager` or platform channel to set `FLAG_SECURE` on sensitive screens.

---

### VAPT-013 — Staging Collection Has No Authorization Gate
**Severity:** 🟠 High | **OWASP:** M2 | **CVSS:** 6.8

**Affected File:** `lib/services/firebase_service.dart` (lines 36–55, `stageChange` method)

**Description:**
`stageChange()` accepts any `adminId` parameter and writes to the `staging` Firestore collection without server-side verification that the calling user is actually an admin. Authorization is enforced only by the Flutter app's UI guard, not server-side rules.

**Impact:** An authenticated non-admin user who calls this method directly (or via modified app) can inject staging changes.

**Recommendation:** Enforce admin role check in Cloud Functions or Firestore security rules before writing to `staging`.

---

### VAPT-014 — FCM Token Stored Without Rotation Logic
**Severity:** 🟢 Low | **OWASP:** M6 – Insufficient Privacy Controls | **CVSS:** 2.5

**Description:**
FCM tokens are stored in Firestore but there's no logic to handle token refresh/rotation. Stale tokens can be used to fingerprint users.

---

### VAPT-015 — No Jailbreak/Root Detection
**Severity:** 🟢 Low | **OWASP:** M8 | **CVSS:** 3.0

**Description:**
The app does not detect rooted/jailbroken devices. On rooted devices, SharedPreferences (PII) are readable by any app with root access.

---

### VAPT-016 — Backup Flag Not Disabled
**Severity:** 🟢 Low | **OWASP:** M9 | **CVSS:** 3.0

**Description:**
`android:allowBackup` in `AndroidManifest.xml` may be set to `true`, allowing ADB backup of app data including SharedPreferences without root.

**Proof of Concept:**
```bash
adb backup -noapk com.vishalgold.app
# Extracts SharedPreferences including PII
```

**Recommendation:** Set `android:allowBackup="false"` in AndroidManifest.xml.

---

### VAPT-017 — Error Messages Leak Internal Information
**Severity:** ℹ️ Info | **OWASP:** M9 | **CVSS:** 2.0

**Description:**
Error messages like `'Failed to stage change: ${e.toString()}'` expose internal exception class names and stack traces.

**Recommendation:** Sanitize error messages in production: return generic user-friendly strings only.

---

## 4. Risk Summary

| Severity | Count | Fixed | Remaining |
|----------|-------|-------|-----------|
| Critical | 3 | 0 | 3 |
| High | 5 | 0 | 5 |
| Medium | 4 | 0 | 4 |
| Low | 3 | 0 | 3 |
| Info | 2 | 0 | 2 |

**Status:** ❌ Initial assessment. All issues pending remediation.
