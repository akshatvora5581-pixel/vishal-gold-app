"""
17_troubleshooting_guide.py — Generates the Troubleshooting Guide.docx
"""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from doc_utils import *

OUT = os.path.join(os.path.dirname(__file__), "..", "client_delivery",
                   "17_Troubleshooting_Guide_Enterprise.docx")
os.makedirs(os.path.dirname(OUT), exist_ok=True)

doc = new_document()

add_cover(doc,
    title    = "Troubleshooting Guide",
    subtitle = "Diagnostic & Incident Resolution Manual — Vishal Gold",
    version  = "v1.1",
    prepared_for = "Vishal Gold Operations Support",
    prepared_by  = "Software Engineering Group"
)

add_toc_placeholder(doc, [
    ("Native Build & Environment Conflicts", 3),
    ("State Management (Provider) Failures", 6),
    ("Firebase Connectivity & Permissions", 9),
    ("Authentication & OTP Reliability", 12),
    ("Security Barriers & Lockouts", 15),
    ("Diagnostic Command Reference", 18),
    ("Emergency Recovery Procedure", 21),
])

# ── 1. Native Build & Environment Conflicts ────────────────────────────────
add_h1(doc, "1. Native Build & Environment Conflicts")

add_h2(doc, "1.1 Gradle Sync & Execution Failures")
add_body(doc, "Problem: Native Android builds fail with 'Could not resolve all files' or 'Gradle sync failed'.")
add_body(doc, (
    "Resolution: Run 'cd android && ./gradlew clean'. "
    "If the issue persists, delete the '.gradle' folder in the user home directory "
    "and ensure JAVA_HOME is pointing to a compatible OpenJDK (v17+)."
))

add_h2(doc, "1.2 MultiDex Constraint")
add_body(doc, "Problem: Build fails on method reference count (65k limit).")
add_body(doc, "Resolution: App is MultiDex ready. Confirm 'minSdkVersion 21' is set in build.gradle. Avoid adding oversized plugins unnecessarily.")

# ── 2. State Management (Provider) Failures ─────────────────────────────────
add_h1(doc, "2. State Management (Provider) Failures")

add_h2(doc, "2.1 ProviderNotFoundException")
add_body(doc, "Problem: App crashes with a red error screen stating the provider could not be found.")
add_body(doc, "Resolution: Ensure the widget accessing the provider is a descendant of MultiProvider in main.dart. Avoid using GlobalKeys to bypass the widget tree context.")

add_h2(doc, "2.2 LateInitializationError")
add_body(doc, "Symptoms: 'Field xxx has not been initialized'.")
add_body(doc, "Resolution: This usually occurs when LocalStorageService.init() is skipped in main(). Verify the 'await' keyword is present before the app runs.")

# ── 3. Firebase Connectivity & Permissions ───────────────────────────────
add_h1(doc, "3. Firebase Connectivity & Permissions")

add_h2(doc, "3.1 [cloud_firestore/permission-denied]")
add_body(doc, "Problem: Firestore reads/writes fail silently or with an exception.")
add_body(doc, "Resolution: Audit Firestore Security Rules. Ensure the user's UID exists in the /users/ collection with the 'wholesaler' or 'retailer' flag correctly set.")

add_h2(doc, "3.2 Cloud Storage 403 (Unauthorized)")
add_body(doc, "Problem: Admin cannot upload product images.")
add_body(doc, "Resolution: Check individual image size (>10MB may timeout). Verify admin role permissions in the Storage bucket rules.")

# ── 4. Authentication & OTP Reliability ───────────────────────────────────
add_h1(doc, "4. Authentication & OTP Reliability")

add_h2(doc, "4.1 SMS Quota/Delivery Issues")
add_body(doc, "Symptoms: OTP is not received after 60 seconds.")
add_body(doc, (
    "Resolution: 1. Confirm device phone number contains (+91). "
    "2. Check Firebase Console for 'SMS Quota Exceeded'. "
    "3. Use pre-defined Test Numbers for development to avoid hitting the live SMS quota."
))

add_h2(doc, "4.2 'Too Many Requests' Lockout")
add_body(doc, "Problem: Firebase blocks the device temporarily.")
add_body(doc, "Resolution: This is a server-side safety trigger. Wait and use the 60-second cooldown timer correctly. Do not clear app storage to bypass, as this creates a new session and potentially extends the lockout.")

# ── 5. Security Barriers & Lockouts ────────────────────────────────────────
add_h1(doc, "5. Security Barriers & Lockouts")

add_h2(doc, "5.1 Screenshot Prevention")
add_body(doc, "Observation: User reports they cannot screenshot the cart or profile.")
add_body(doc, "status: THIS IS BY DESIGN. FLAG_SECURE is active on sensitive pages to protect PII. It is not an error.")

add_h2(doc, "5.2 ADB Log Exposure")
add_body(doc, "Problem: Sensitive data appears in 'adb logcat'.")
add_body(doc, "Resolution: All debug logging must be wrapped in 'kDebugMode' or 'kProfileMode' guards and removed from the Release branch.")

# ── 6. Diagnostic Command Reference ────────────────────────────────────────
add_h1(doc, "6. Diagnostic Command Reference")

cmds = [
    ("Health Check", "flutter doctor -v"),
    ("State Inspection", "flutter pub global run devtools"),
    ("Native Logs", "adb logcat -s flutter"),
    ("Clean Build", "flutter clean && flutter pub get"),
    ("Release Test", "flutter run --release")
]

add_table(doc,
    headers=["Action", "Command"],
    rows=cmds
)

# ── 7. Emergency Recovery Procedure ────────────────────────────────────────
add_h1(doc, "7. Emergency Recovery Procedure")
add_body(doc, "In cases of systemic instability or inconsistent local state:")
add_body(doc, "1. Clear App Data: Settings -> Apps -> Home -> Clear Storage.")
add_body(doc, "2. Force Sync: Long-press the logo to verify the admin entry is removed (it should be).")
add_body(doc, "3. Re-Authentiate: Perform a full login cycle to re-establish secure tokens.")

save(doc, OUT)
