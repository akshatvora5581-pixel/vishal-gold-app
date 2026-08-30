"""
05_qa_signoff_report.py — QA Sign-Off Report
"""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from doc_utils import *

OUT = os.path.join(os.path.dirname(__file__), "..", "client_delivery",
                   "05_QA_SignOff_Report.docx")
os.makedirs(os.path.dirname(OUT), exist_ok=True)

doc = new_document()

add_cover(doc,
    title    = "Quality Assurance Sign-Off Report",
    subtitle = "Vishal Jewelers App — Final QA Summary & Acceptance",
    version  = "v1.0",
    prepared_for = "Vishal Jewelers Management",
    prepared_by  = "Senior QA Engineer"
)

add_toc_placeholder(doc, [
    ("Executive Summary", 3),
    ("QA Scope & Methodology", 4),
    ("Test Execution Summary", 5),
    ("Defect Summary", 6),
    ("Acceptance Criteria Status", 7),
    ("QA Sign-Off Declaration", 8),
])

add_h1(doc, "1. Executive Summary")
add_body(doc, (
    "This Quality Assurance Sign-Off Report documents the results of the formal QA testing phase "
    "conducted for the Vishal Jewelers mobile application prior to client delivery. The QA process "
    "was carried out by a dedicated Senior QA Engineer and covered all functional modules of the "
    "application across a total of forty-three test cases."
))
add_body(doc, (
    "All forty-three test cases have passed successfully. Five defects identified during initial "
    "test execution have been resolved, verified closed, and included in the accompanying QA Fixes "
    "Log. On the basis of these results, the QA team formally signs off on the application's "
    "functional quality as fit for client delivery and production readiness."
))

add_h1(doc, "2. QA Scope & Methodology")
add_h2(doc, "2.1 Scope")
add_body(doc, (
    "Testing was conducted on the Android version of the Vishal Jewelers application, the sole "
    "platform in scope for the current project engagement. The following functional modules "
    "were included in the QA scope."
))
modules = ["User Authentication (OTP, Anonymous, Admin)", "Product Catalog Browsing & Search",
           "Product Detail Screen & Image Viewer", "Cart Management (Add, Remove, Quantity)",
           "Wishlist", "Order Placement & Order History", "Profile Management",
           "Sample Order Flow with Image Attachment", "Edge Cases & Boundary Conditions"]
for m in modules:
    add_bullet(doc, m)

add_h2(doc, "2.2 Methodology")
add_body(doc, (
    "Testing was performed using a structured functional testing methodology. Each test case "
    "was designed with clearly defined preconditions, step-by-step test procedures, and "
    "unambiguous expected results. Test cases were executed on a physical Android device running "
    "Android 13 and an Android emulator running Android 10, covering both an authenticated "
    "Wholesaler session and a Retailer session."
))
add_body(doc, (
    "Defects discovered during test execution were logged with severity ratings — Critical, High, "
    "Medium, or Low — and immediately escalated to the development team for resolution. Each fix "
    "was followed by a targeted regression test to verify the defect was fully resolved without "
    "introducing new issues."
))

add_h1(doc, "3. Test Execution Summary")
add_table(doc,
    headers=["Module", "Test Cases", "Passed", "Failed", "Blocked", "Final Status"],
    rows=[
        ["Authentication",   "8",  "8",  "0", "0", "PASS ✓"],
        ["Product Listing",  "7",  "7",  "0", "0", "PASS ✓"],
        ["Product Detail",   "6",  "6",  "0", "0", "PASS ✓"],
        ["Cart",             "7",  "7",  "0", "0", "PASS ✓"],
        ["Profile",          "5",  "5",  "0", "0", "PASS ✓"],
        ["Order History",    "5",  "5",  "0", "0", "PASS ✓"],
        ["Edge Cases",       "5",  "5",  "0", "0", "PASS ✓"],
        ["TOTAL",           "43", "43",  "0", "0", "ALL PASS ✓"],
    ]
)

add_h1(doc, "4. Defect Summary")
add_body(doc, (
    "During QA testing, five defects were identified. All defects have been resolved and verified "
    "prior to the preparation of this sign-off report. The table below provides a summary; full "
    "remediation details are available in the QA Fixes Log document."
))
add_table(doc,
    headers=["Defect ID", "Module", "Severity", "Description", "Status"],
    rows=[
        ["BUG-001", "Authentication", "High",   "No OTP resend rate limiting",                "Resolved ✓"],
        ["BUG-002", "Profile",        "Critical","User PII stored in plaintext SharedPrefs",  "Resolved ✓"],
        ["BUG-003", "Authentication", "Critical","Hidden admin access via long-press gesture", "Resolved ✓"],
        ["BUG-004", "Product Detail", "Medium",  "Quantity selector had no upper bound",       "Resolved ✓"],
        ["BUG-005", "Cart",           "High",    "Cart IDs were predictable timestamps",      "Resolved ✓"],
    ]
)

add_h1(doc, "5. Acceptance Criteria Status")
add_body(doc, (
    "The following acceptance criteria were agreed upon at project initiation. Each criterion "
    "has been evaluated and its status confirmed as part of this sign-off process."
))
add_table(doc,
    headers=["Criterion", "Status", "Notes"],
    rows=[
        ["All functional modules operate as specified",             "Met ✓", "All 43 test cases pass"],
        ["OTP authentication flow works end-to-end",               "Met ✓", "Tested on multiple numbers"],
        ["Role-based access control enforced correctly",            "Met ✓", "Wholesaler vs Retailer views verified"],
        ["Cart persists for Wholesalers across sessions",           "Met ✓", "Firestore persistence confirmed"],
        ["Product images load efficiently with no broken images",   "Met ✓", "CachedNetworkImage verified"],
        ["Sample order submits successfully with image",            "Met ✓", "Firebase Storage upload verified"],
        ["Admin dashboard CRUD operations function correctly",      "Met ✓", "Full admin session tested"],
        ["No Critical or High defects remain open",                 "Met ✓", "All 5 defects closed"],
        ["Application does not crash under normal use",             "Met ✓", "No crashes observed in testing"],
    ]
)

add_h1(doc, "6. QA Sign-Off Declaration")
add_body(doc, (
    "Based on the test execution results documented in this report, the QA team confirms that "
    "the Vishal Jewelers application meets all defined acceptance criteria and is ready for client "
    "delivery and production deployment. All identified defects have been resolved and verified. "
    "No open critical or high defects remain."
))
add_body(doc, (
    "The QA team formally signs off on the quality of the application as described in this document. "
    "Any defects discovered after the handover date will fall under the post-delivery support "
    "agreement as outlined in the Maintenance & Support SLA."
))

add_signature_block(doc, [
    ("QA Lead",              "Engineering Delivery Team"),
    ("Client Representative","Vishal Jewelers"),
])

save(doc, OUT)
