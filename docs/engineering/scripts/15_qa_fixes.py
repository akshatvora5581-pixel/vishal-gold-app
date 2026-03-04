"""
15_qa_fixes.py — Generates the QA Fixes Log.docx
"""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from doc_utils import *

OUT = os.path.join(os.path.dirname(__file__), "..", "client_delivery",
                   "15_QA_Fixes_Log_Enterprise.docx")
os.makedirs(os.path.dirname(OUT), exist_ok=True)

doc = new_document()

add_cover(doc,
    title    = "QA Fixes Log",
    subtitle = "Remediation & Bug Resolution Registry — Vishal Gold",
    version  = "v1.1",
    prepared_for = "Vishal Gold QA & Engineering Teams",
    prepared_by  = "Senior Development Lead"
)

add_toc_placeholder(doc, [
    ("Fix Priority & Strategy", 3),
    ("Remediation Detail (F-001 to F-008)", 4),
    ("Iteration Status Summary", 12),
])

# ── 1. Fix Priority & Strategy ───────────────────────────────────────────────
add_h1(doc, "1. Fix Priority & Strategy")
add_body(doc, (
    "This log documents the systematic remediation of security vulnerabilities (VAPT) and "
    "functional defects (QA) identified in the Vishal Gold app. The priority for resolution "
    "follows the risk hierarchy: Critical → High → Medium → Low."
))

# ── 2. Remediation Detail ───────────────────────────────────────────────────
add_h1(doc, "2. Remediation Detail")

fixes = [
    ("Fix F-001 — PII Migration to Secure Storage",
     "Critical", ["VAPT-001", "BUG-002"],
     "PII fields (Name, Phone, etc.) were previously stored in plaintext SharedPreferences.",
     "Migrated all PII to FlutterSecureStorage using the new SecureLocalStorageService. SharedPreferences now only stores non-sensitive JSON blobs.",
     "lib/services/local_storage_service.dart, lib/providers/auth_provider.dart"),

    ("Fix F-002 — Server-Side Role Validation",
     "Critical", ["VAPT-002"],
     "Client implicitly trusted user role from local storage without Firestore verification.",
     "Auth init now fetches user role from Firestore profile. Local cache is used only as persistent fallback verified against server record.",
     "lib/providers/auth_provider.dart, lib/services/firebase_service.dart"),

    ("Fix F-003 — Admin Gesture Removal",
     "Critical", ["VAPT-003", "BUG-005"],
     "Hidden 3-second logo long-press granted undocumented access to admin login.",
     "Removed GestureDetector and related timer logic. Admin access moved to authorized deep-links and whitelisted devices.",
     "lib/screens/auth/phone_auth_screen.dart"),

    ("Fix F-004 — OTP Rate Limiting",
     "High", ["VAPT-004", "BUG-001"],
     "Rapid manual triggering of OTP requests was possible, leading to service abuse.",
     "Implemented 60-second client-side cooldown timer. Button is disabled and shows remaining countdown after request.",
     "lib/screens/auth/phone_auth_screen.dart"),

    ("Fix F-005 — Secure Cart ID Generation",
     "High", ["VAPT-005"],
     "Cart IDs were generated using predictable timestamp values.",
     "Transitioned to cryptographically random UUID v4 identifiers via the uuid package.",
     "lib/providers/cart_provider.dart"),

    ("Fix F-006 — ADB Backup & Flag Secure",
     "Medium", ["VAPT-016", "VAPT-012"],
     "Device backup enabled and screenshots permitted on sensitive profile screens.",
     "Set allowBackup='false' in Manifest. Enhanced Cart and Profile screens with FLAG_SECURE to prevent screenshots.",
     "android/app/src/main/AndroidManifest.xml"),

    ("Fix F-007 — UI Error Sanitization",
     "Medium", ["VAPT-017", "VAPT-009"],
     "Raw exception strings were exposed to users in UI snackbars/dialogs.",
     "Implemented generic error messaging for production builds while preserving detailed kDebugMode logging for development.",
     "lib/services/firebase_service.dart, lib/providers/auth_provider.dart"),

    ("Fix F-008 — Quantity Upper Bound",
     "Medium", ["BUG-004"],
     "Users could increment product quantity to unreasonable levels.",
     "Hard-capped product quantity at 99 in ProductDetailScreen with incremental validation.",
     "lib/screens/product/product_detail_screen.dart")
]

for title, severity, ids, cause, fix, files in fixes:
    add_h2(doc, title)
    add_bullet(doc, f"Severity: {severity}")
    add_bullet(doc, f"Impact IDs: {', '.join(ids)}")
    add_h3(doc, "Root Cause")
    add_body(doc, cause)
    add_h3(doc, "Fix Implemented")
    add_body(doc, fix)
    add_h3(doc, "Modules Modified")
    add_body(doc, files)

# ── 3. Iteration Status Summary ──────────────────────────────────────────────
add_h1(doc, "3. Iteration Status Summary")
add_table(doc,
    headers=["Iteration", "Fixes", "Critical Rem.", "High Rem.", "Verification"],
    rows=[
        ["1", "8", "0", "0", "Retest PASS ✓"]
    ]
)

add_body(doc, "All Critical and High severity findings identified in initial assessment have been verified as resolved.")

save(doc, OUT)
