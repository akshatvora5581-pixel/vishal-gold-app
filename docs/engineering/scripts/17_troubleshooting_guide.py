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
    ("Environment & Setup", 3),
    ("Runtime & Application Errors", 4),
    ("Backend & Connectivity", 6),
    ("Authentication Issues", 8),
    ("Summary of Diagnosis Commands", 10),
])

# ── 1. Environment & Setup ──────────────────────────────────────────────────
add_h1(doc, "1. Environment & Setup")

add_h2(doc, "1.1 'flutter doctor' Failures")
add_body(doc, "Problem: Missing Android/Java dependencies preventing build launch.")
add_body(doc, "Resolution: Ensure JAVA_HOME and ANDROID_HOME environment variables are set. Run 'flutter doctor --android-licenses'.")

add_h2(doc, "1.2 Firebase Config Missing")
add_body(doc, "Problem: Build fails with 'google-services.json' not found.")
add_body(doc, "Resolution: Download config from Firebase Console and place in android/app/. Note: This file is intentionally git-ignored.")

# ── 2. Runtime & Application Errors ─────────────────────────────────────────
add_h1(doc, "2. Runtime & Application Errors")

add_h2(doc, "2.1 setState() Called After Dispose")
add_body(doc, "Symptoms: App crash during asynchronous navigation or background fetch.")
add_body(doc, "Resolution: Verify that all async callbacks are guarded with 'if (!mounted) return' before triggering UI updates.")

add_h2(doc, "2.2 Blank/Missing Product Images")
add_body(doc, "Symptoms: Products load but images show empty placeholder or error icon.")
add_body(doc, "Resolution: Verify the URL has not expired and that Firestore Storage permissions allow read access on the target path.")

# ── 3. Backend & Connectivity ───────────────────────────────────────────────
add_h1(doc, "3. Backend & Connectivity")

add_h2(doc, "3.1 Permission Denied in Firestore")
add_body(doc, "Problem: User cannot view products or place orders.")
add_body(doc, "Resolution: Audit Firestore security rules against the user's role. Confirm the user has a valid 'Wholesaler' or 'Retailer' profile document.")

add_h2(doc, "3.2 Cloud Storage Upload Failures")
add_body(doc, "Problem: Admin cannot upload banners or product images.")
add_body(doc, "Resolution: Check network stability and verify admin account is whitelisted in storage security rules.")

# ── 4. Authentication Issues ────────────────────────────────────────────────
add_h1(doc, "4. Authentication Issues")

add_h2(doc, "4.1 OTP Delivery Failures")
add_body(doc, "Problem: SMS not received by the user.")
add_body(doc, "Resolution: Confirm correct country code (+91) format. Verify Firebase SMS quota is not exhausted. Use test numbers during development.")

add_h2(doc, "4.2 Session Expiry")
add_body(doc, "Problem: User prompted to log in frequently.")
add_body(doc, "Resolution: Check token rotation settings in FCM configuration and review FirebaseAuth session timeout logic.")

# ── 5. Diagnosis Commands ──────────────────────────────────────────────────
add_h1(doc, "5. Summary of Diagnosis Commands")

cmds = [
    ("Clean Environment", "flutter clean && flutter pub get"),
    ("Analyze Code", "flutter analyze"),
    ("Log Inspection", "adb logcat -s flutter"),
    ("Inspect Storage", "adb shell run-as com.vishalgold.app cat shared_prefs/FlutterSharedPreferences.xml"),
    ("Build Release", "flutter build apk --release")
]

add_table(doc,
    headers=["Action", "Command"],
    rows=cmds
)

save(doc, OUT)
