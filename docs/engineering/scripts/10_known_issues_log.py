"""
10_known_issues_log.py — Known Issues & Limitations Log
"""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from doc_utils import *

OUT = os.path.join(os.path.dirname(__file__), "..", "client_delivery",
                   "10_Known_Issues_And_Limitations.docx")
os.makedirs(os.path.dirname(OUT), exist_ok=True)

doc = new_document()

add_cover(doc,
    title    = "Known Issues & Limitations Log",
    subtitle = "Vishal Gold App — Defect Register at Time of Delivery",
    version  = "v1.0",
    prepared_for = "Vishal Gold Technical Team",
    prepared_by  = "Engineering Delivery Team"
)

add_toc_placeholder(doc, [
    ("Purpose", 3),
    ("Closed Issues (Resolved Before Delivery)", 4),
    ("Open Technical Issues", 5),
    ("Open Security Findings (Residual)", 6),
    ("Platform & Environmental Limitations", 7),
    ("Resolution Roadmap", 8),
])

add_h1(doc, "1. Purpose")
add_body(doc, (
    "This Known Issues and Limitations Log provides a complete, transparent register of all "
    "known defects, limitations, and deferred items at the time of the Vishal Gold application's "
    "formal delivery. It is intended to ensure that the client and all stakeholders have a "
    "clear understanding of the application's current state, enabling informed decisions "
    "regarding go-live readiness, risk acceptance, and future development priorities."
))
add_body(doc, (
    "This document is a living record that should be maintained and updated by the client's "
    "technical team after the handover date. Any new defects discovered in production should "
    "be added to this register for traceability."
))

add_h1(doc, "2. Closed Issues — Resolved Before Delivery")
add_body(doc, (
    "The following issues and defects were identified during the QA and security assessment "
    "phases and successfully resolved prior to this delivery. They are listed here for "
    "historical context and traceability."
))
add_table(doc,
    headers=["ID", "Module", "Severity", "Description", "Resolution", "Verified"],
    rows=[
        ["BUG-001","Auth",          "High",    "No OTP resend rate limiting",                  "60-second cooldown implemented",         "Yes ✓"],
        ["BUG-002","Profile",       "Critical","PII stored in plaintext SharedPreferences",    "Migrated to FlutterSecureStorage",       "Yes ✓"],
        ["BUG-003","Auth",          "Critical","Hidden admin access via long-press gesture",   "Gesture and admin redirect removed",     "Yes ✓"],
        ["BUG-004","Product Detail","Medium",  "Quantity selector had no upper limit",         "Capped at 99 units",                    "Yes ✓"],
        ["BUG-005","Cart",          "High",    "Cart item IDs were predictable timestamps",    "Replaced with UUID v4",                 "Yes ✓"],
        ["BUG-006","General",       "Low",     "debugPrint leaked exceptions in production",   "Wrapped with kDebugMode guard",         "Yes ✓"],
        ["BUG-007","Android",       "Low",     "ADB backup enabled in AndroidManifest",        "android:allowBackup=false applied",     "Yes ✓"],
    ]
)

add_h1(doc, "3. Open Technical Issues")
add_body(doc, (
    "The following technical issues are known at the time of delivery. They do not prevent "
    "the primary functionality of the application from working correctly but represent areas "
    "of improvement for future sprints."
))
add_table(doc,
    headers=["ID", "Module", "Severity", "Description", "Workaround", "Target Sprint"],
    rows=[
        ["OI-001", "Auth",           "P3 Medium", "Guest users can browse all products (no access gating)",
         "Business decision deferred: guest access is intentional for now", "Iteration 2"],
        ["OI-002", "Notifications",  "P4 Low",    "FCM token is not rotated proactively on token refresh events",
         "Firebase rotates tokens automatically; low risk until production scale", "Iteration 2"],
        ["OI-003", "Cart",           "P4 Low",    "Retailer cart cleared on app reinstall (expected behavior, not persisted)",
         "Documented in User Manual; by design for guest-like Retailer accounts", "Future Phase"],
        ["OI-004", "General",        "P4 Low",    "No offline mode; all screens require internet",
         "Users see network error messages; acceptable for B2B jewelry trade use case", "Future Phase"],
        ["OI-005", "Admin",          "P3 Medium", "Admin can publish staged changes without a secondary review step",
         "Admin team discipline required; no dual-approval workflow implemented", "Iteration 2"],
    ]
)

add_h1(doc, "4. Open Security Findings (Residual)")
add_body(doc, (
    "The following security findings remain open. Full details, business impact, and client "
    "action requirements are documented in the Security Disclosure Document (Document #06)."
))
add_table(doc,
    headers=["VAPT-ID", "Finding", "Severity", "Client Action", "Immediate Go-Live Blocker?"],
    rows=[
        ["VAPT-006","Firestore security rules not deployed",    "High",   "Deploy rules via Firebase CLI", "YES — must fix before go-live"],
        ["VAPT-007","google-services.json historically in git", "High",   "Rotate API key in Firebase Console", "Recommended before go-live"],
        ["VAPT-002","Server-side role validation absent",       "High",   "Resolved by VAPT-006 fix",      "Resolved by VAPT-006"],
        ["VAPT-013","Staging collection lacks auth gate",       "High",   "Resolved by VAPT-006 fix",      "Resolved by VAPT-006"],
        ["VAPT-008","No certificate pinning",                   "Medium", "Iteration 2 sprint",           "No"],
        ["VAPT-010","Guest can browse all products",            "Medium", "Business decision required",   "No"],
        ["VAPT-011","No Play Integrity API check",              "Medium", "Iteration 2 sprint",           "No"],
        ["VAPT-012","No screenshot prevention on PII screens",  "Medium", "Iteration 2 sprint",           "No"],
        ["VAPT-014","FCM token rotation not handled",           "Low",    "Iteration 2 sprint",           "No"],
        ["VAPT-015","No root/jailbreak detection",              "Low",    "Iteration 2 sprint",           "No"],
    ]
)

add_h1(doc, "5. Platform & Environmental Limitations")
add_body(doc, (
    "The following limitations are inherent to the current project scope and technology choices, "
    "and are not defects in the delivered codebase."
))
add_table(doc,
    headers=["Limitation", "Impact", "Notes"],
    rows=[
        ["Android only; no iOS", "iOS users cannot use the app", "Phase 2 engagement required"],
        ["No web portal",        "Admin Dashboard is mobile-only", "Phase 2 scope"],
        ["Firebase Spark plan quota limits", "At scale, Firestore reads/writes may be throttled",
         "Upgrade to Blaze plan before production launch; see Deployment Guide"],
        ["Firebase is the sole backend; no on-premise option",
         "Data residency may be a concern for certain regulatory environments",
         "Firebase India region (asia-south1) can be configured in Firebase Console"],
        ["No payment gateway", "Orders are placed and confirmed offline",
         "Payment integration is a Phase 2 feature"],
        ["No product stock management", "App shows products without real-time inventory",
         "Stock sync with ERP is a Phase 2 feature"],
    ]
)

add_h1(doc, "6. Resolution Roadmap")
add_body(doc, (
    "The following roadmap provides a high-level recommendation for addressing the open issues "
    "and limitations documented above. Priority is assigned based on security impact, user "
    "experience impact, and implementation complexity."
))
add_table(doc,
    headers=["Phase", "Item", "Priority", "Estimated Effort"],
    rows=[
        ["Immediate (Pre-Go-Live)",  "Deploy Firestore security rules (VAPT-006)",              "P1", "2 hours"],
        ["Immediate (Pre-Go-Live)",  "Rotate Firebase API key (VAPT-007)",                      "P1", "1 hour"],
        ["Iteration 2 (0–60 days)",  "Certificate pinning (VAPT-008)",                          "P2", "3 days"],
        ["Iteration 2 (0–60 days)",  "Screenshot prevention on Cart & Profile (VAPT-012)",      "P2", "1 day"],
        ["Iteration 2 (0–60 days)",  "Play Integrity API integration (VAPT-011)",               "P2", "3 days"],
        ["Iteration 2 (0–60 days)",  "FCM token rotation handler (VAPT-014)",                   "P3", "0.5 day"],
        ["Phase 2 (3–6 months)",     "iOS application development",                             "P2", "3 months"],
        ["Phase 2 (3–6 months)",     "Payment gateway integration",                             "P2", "6 weeks"],
        ["Phase 2 (3–6 months)",     "ERP / inventory sync",                                    "P3", "8 weeks"],
    ]
)

save(doc, OUT)
