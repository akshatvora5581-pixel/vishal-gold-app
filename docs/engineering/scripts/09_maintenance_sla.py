"""
09_maintenance_sla.py — Maintenance & Support SLA
"""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from doc_utils import *

OUT = os.path.join(os.path.dirname(__file__), "..", "client_delivery",
                   "09_Maintenance_And_Support_SLA.docx")
os.makedirs(os.path.dirname(OUT), exist_ok=True)

doc = new_document()

add_cover(doc,
    title    = "Maintenance & Support SLA",
    subtitle = "Vishal Gold App — Service Level Agreement for Post-Delivery Support",
    version  = "v1.0",
    prepared_for = "Vishal Gold Management",
    prepared_by  = "Engineering Delivery Team"
)

add_toc_placeholder(doc, [
    ("Agreement Overview", 3),
    ("Support Scope", 4),
    ("Support Tiers & Issue Classification", 5),
    ("Response & Resolution Commitments", 6),
    ("Support Channels & Hours", 7),
    ("Out-of-Scope Items", 8),
    ("Escalation Procedure", 9),
    ("SLA Review", 9),
    ("Authorization & Sign-Off", 10),
])

add_h1(doc, "1. Agreement Overview")
add_body(doc, (
    "This Service Level Agreement (SLA) defines the terms and conditions of post-delivery "
    "maintenance and technical support provided by the Engineering Delivery Team (hereinafter "
    "referred to as 'the Support Provider') to Vishal Gold (hereinafter referred to as 'the Client') "
    "following the formal handover of the Vishal Gold mobile application."
))
add_body(doc, (
    "This agreement becomes effective from the date of both parties' signatures on the Project "
    "Completion Report and the acceptance of this document. It supersedes any informal support "
    "commitments made during the project development phase."
))
add_table(doc,
    headers=["Attribute", "Value"],
    rows=[
        ["Agreement Start Date",  "[DATE OF SIGNATURE]"],
        ["Initial SLA Term",      "3 months (rolling renewal available)"],
        ["Support Coverage",      "Android application, Firebase backend, documentation"],
        ["Excluded Platforms",    "iOS, Web (not in scope for current project)"],
    ]
)

add_h1(doc, "2. Support Scope")
add_body(doc, (
    "The support covered under this SLA includes the identification and remediation of "
    "defects discovered in the delivered application, guidance on operating the Admin Dashboard, "
    "assistance with Firebase Console operations, and advisory support for security findings "
    "escalated from the Security Disclosure Document."
))
add_h2(doc, "2.1 Included in Scope")
add_bullet(doc, "Bug fixes for defects reproducible in the delivered codebase.")
add_bullet(doc, "Firebase configuration assistance (rules deployment, user management guidance).")
add_bullet(doc, "Minor feature adjustments (e.g., changing text, adjusting limits, color changes).")
add_bullet(doc, "Deployment assistance for production releases and hotfixes.")
add_bullet(doc, "Code review and guidance for any internal technical team working on the project.")
add_bullet(doc, "Security advisory for residual VAPT findings (consultation, not full remediation).")

add_h2(doc, "2.2 Excluded from Scope (Covered Under Separate Engagement)")
add_bullet(doc, "New feature development not present in the delivered application.")
add_bullet(doc, "iOS or web platform development.")
add_bullet(doc, "Integration with third-party ERP, inventory, or payment systems.")
add_bullet(doc, "Defects caused by client modifications to the source code after handover.")
add_bullet(doc, "Infrastructure outages attributable to Firebase or Google Cloud platform issues.")

add_h1(doc, "3. Support Tiers & Issue Classification")
add_body(doc, (
    "All issues raised by the client will be classified upon receipt according to the following "
    "severity tiers. Classification will be performed by the Support Provider in consultation "
    "with the client, taking into account business impact and user exposure."
))
add_table(doc,
    headers=["Severity", "Definition", "Example"],
    rows=[
        ["P1 — Critical", "Application unusable; major data loss or security breach in progress",
         "Authentication completely broken for all users; Firestore data exposed"],
        ["P2 — High",     "Major feature non-functional; significant business impact",
         "Cart fails to save for all Wholesalers; Admin login non-functional"],
        ["P3 — Medium",   "Feature degraded but workaround exists; moderate impact",
         "Push notifications not delivered; images load slowly"],
        ["P4 — Low",      "Minor issue; no significant business impact",
         "Minor UI misalignment; typo in system text; cosmetic issue"],
    ]
)

add_h1(doc, "4. Response & Resolution Commitments")
add_table(doc,
    headers=["Severity", "Initial Response", "Root Cause Analysis", "Resolution / Fix Deployment"],
    rows=[
        ["P1 — Critical", "2 business hours",  "4 business hours",  "24 hours (hotfix deployment)"],
        ["P2 — High",     "4 business hours",  "1 business day",    "3 business days"],
        ["P3 — Medium",   "1 business day",    "2 business days",   "7 business days"],
        ["P4 — Low",      "2 business days",   "5 business days",   "Next scheduled maintenance release"],
    ]
)
add_body(doc, (
    "Response times are measured from the time the client submits a support ticket during business "
    "hours. Tickets raised outside business hours will be treated as received at the start of the "
    "next business day (except P1 issues, for which an emergency contact protocol is in effect, "
    "as described in Section 7)."
))

add_h1(doc, "5. Support Channels & Hours")
add_h2(doc, "5.1 Business Hours")
add_body(doc, "Monday through Saturday, 10:00 AM to 7:00 PM IST (UTC+5:30). Public holidays observed.")

add_h2(doc, "5.2 Contact Channels")
add_table(doc,
    headers=["Channel", "Use Case", "Priority"],
    rows=[
        ["WhatsApp Business (designated number)", "Primary contact for all issues", "All severities"],
        ["Email (designated address)",            "Formal bug reports, change requests", "P3, P4"],
        ["Emergency Phone (designated number)",   "P1/P2 issues outside business hours", "P1, P2 only"],
    ]
)
add_note(doc, "Note",
    "Issue details and reproduction steps MUST be provided in writing (WhatsApp or email) "
    "even for phone-reported issues. Verbal-only reports cannot be acted upon.")

add_h1(doc, "6. Out-of-Scope Items")
add_body(doc, (
    "The following items are explicitly excluded from this SLA and will be quoted separately "
    "as new work engagements if the client wishes to pursue them."
))
add_table(doc,
    headers=["Item", "Reason"],
    rows=[
        ["New feature development",             "Beyond original project scope"],
        ["iOS application",                     "Not in scope; requires separate Flutter build"],
        ["Performance optimizations (major)",   "Requires architectural changes"],
        ["Third-party API integrations",        "New scope and billing required"],
        ["Client-side code errors (post-handover)", "Client assumes responsibility for modifications"],
    ]
)

add_h1(doc, "7. Escalation Procedure")
add_body(doc, (
    "If the client believes that a support issue is not being progressed in accordance with the "
    "commitments in this SLA, the following escalation path should be followed."
))
add_numbered(doc, "Level 1: Contact the assigned support engineer directly via WhatsApp and reference the open ticket ID.")
add_numbered(doc, "Level 2 (if unresolved after 24 hours): Contact the Engineering Team Project Manager directly.")
add_numbered(doc, "Level 3 (formal escalation): Submit a formal written complaint via email to the managing director of the Support Provider.")

add_h1(doc, "8. SLA Review")
add_body(doc, (
    "This SLA will be reviewed by both parties at the 3-month mark and at each renewal point. "
    "Either party may request amendments in writing with 30 days' notice. The SLA remains "
    "in force until formally terminated by either party with 30 days' written notice."
))

add_signature_block(doc, [
    ("Client Representative", "Vishal Gold"),
    ("Support Provider Lead",  "Engineering Delivery Team"),
])

save(doc, OUT)
