"""
16_qa_test_cases.py — Generates the QA Test Cases.docx
"""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from doc_utils import *

OUT = os.path.join(os.path.dirname(__file__), "..", "client_delivery",
                   "16_QA_Test_Execution_Results.docx")
os.makedirs(os.path.dirname(OUT), exist_ok=True)

doc = new_document()

add_cover(doc,
    title    = "QA Test Execution Results",
    subtitle = "Comprehensive Test Lifecycle Report — Vishal Gold",
    version  = "v1.1",
    prepared_for = "Vishal Gold QA Stakeholders",
    prepared_by  = "Senior QA Engineer"
)

add_toc_placeholder(doc, [
    ("Module 1: Authentication", 3),
    ("Module 2: Product Listing & Search", 5),
    ("Module 3: Product Detail", 7),
    ("Module 4: Cart & Checkout", 9),
    ("Module 5: Profile & Management", 11),
    ("Module 6: Order History", 13),
    ("Module 7: Edge Cases", 15),
    ("Summary of Defects", 17),
])

# Define helpers to add tables from the test case data
def add_test_table(doc, title, rows):
    add_h1(doc, title)
    add_table(doc,
        headers=["ID", "Description", "Result", "Status"],
        rows=rows
    )

# ── 1. Authentication ───────────────────────────────────────────────────────
add_test_table(doc, "1. Authentication", [
    ["AUTH-001", "Valid phone login", "Navigated to Home correctly", "PASS"],
    ["AUTH-002", "Invalid phone format", "Validation error shown", "PASS"],
    ["AUTH-003", "OTP rate limiting", "60s countdown timer verified (Fix F-004)", "PASS"],
    ["AUTH-004", "Expired OTP", "Expiry error caught correctly", "PASS"],
    ["AUTH-005", "Incorrect OTP", "Invalid code prompt displayed", "PASS"],
    ["AUTH-006", "Guest login", "Retailer role assigned in Firestore", "PASS"],
    ["AUTH-007", "Guest permissions", "Wholesale pricing hidden correctly", "PASS"],
    ["AUTH-009", "Sign Out", "Secure storage cleared on logout (Fix F-001)", "PASS"],
    ["AUTH-010", "Admin backdoor", "Gesture removed successfully (Fix F-003)", "PASS"],
])

# ── 2. Product Listing ──────────────────────────────────────────────────────
add_test_table(doc, "2. Product Listing & Search", [
    ["PROD-001", "Category filter", "Results match selected category", "PASS"],
    ["PROD-002", "Subcategory filter", "Nested results display correctly", "PASS"],
    ["PROD-003", "Empty state UI", "Placeholder shown for no items", "PASS"],
    ["PROD-004", "Loading shimmer", "Shimmer plays during fetch", "PASS"],
    ["PROD-005", "Pull to refresh", "Firestore data re-fetched", "PASS"],
    ["PROD-007", "Filter modal", "Button non-functional (TODO in code)", "DEFERRED"],
])

# ── 3. Product Detail ───────────────────────────────────────────────────────
add_test_table(doc, "3. Product Detail", [
    ["DETAIL-001", "Image gallery", "Swipe between images verified", "PASS"],
    ["DETAIL-002", "Add to Cart", "Item added; view cart button shown", "PASS"],
    ["DETAIL-004", "Wishlist toggle", "Heart icon updates state", "PASS"],
    ["DETAIL-005", "Qty upper bound", "Capped at 99 units (Fix F-008)", "PASS"],
    ["DETAIL-007", "Spec display", "Gross/Net weights rendered correctly", "PASS"],
])

# ── 4. Cart ────────────────────────────────────────────────────────────────
add_test_table(doc, "4. Cart & Checkout", [
    ["CART-001", "View cart items", "All product info visible", "PASS"],
    ["CART-002", "Qty increment", "Subtotal updates immediately", "PASS"],
    ["CART-003", "Auto-removal", "Removed on decrement to zero", "PASS"],
    ["CART-005", "Place order", "Firestore record created; cart purged", "PASS"],
    ["CART-007", "Retailer Persistence","Cart JSON saved in SharedPrefs", "PASS"],
])

# ── 5. Profile ──────────────────────────────────────────────────────────────
add_test_table(doc, "5. Profile & Management", [
    ["PROF-001", "User info display", "Read correctly from secure storage", "PASS"],
    ["PROF-003", "Contact Us", "WhatsApp deep-link verified", "PASS"],
    ["PROF-005", "Logout flow", "Redirected to auth correctly", "PASS"],
])

# ── 6. Order History ────────────────────────────────────────────────────────
add_test_table(doc, "6. Order History", [
    ["ORD-001", "Order list", "Status badges displayed correctly", "PASS"],
    ["ORD-003", "Refresh history", "Re-synced with Firestore", "PASS"],
    ["ORD-005", "Date formatting", "Readable dates (e.g., Feb 25, 2026)", "PASS"],
])

# ── 7. Edge Cases ───────────────────────────────────────────────────────────
add_test_table(doc, "7. Edge Cases", [
    ["EDGE-001", "Airplane mode", "Connectivity snackbar shown", "PASS"],
    ["EDGE-002", "Text truncation", "Ellipsis on long product names", "PASS"],
    ["EDGE-004", "Nav stack", "Back button behavior verified", "PASS"],
])

# ── Summary of Defects ────────────────────────────────────────────────────
add_h1(doc, "Summary of Defects")
add_table(doc,
    headers=["Defect", "Severity", "Description", "Resolution Status"],
    rows=[
        ["BUG-001", "Critical", "No OTP rate limiting", "CLOSED (Fix F-004)"],
        ["BUG-002", "Critical", "PII in plaintext Prefs", "CLOSED (Fix F-001)"],
        ["BUG-003", "Low",      "Filter button non-functional", "DEFERRED (v1.1)"],
        ["BUG-004", "Medium",   "Quantity cap missing", "CLOSED (Fix F-008)"],
        ["BUG-005", "Medium",   "Hidden admin entry gesture", "CLOSED (Fix F-003)"],
    ]
)

save(doc, OUT)
