"""
03_admin_manual.py — Generates the Admin Manual.docx
"""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from doc_utils import *

OUT = os.path.join(os.path.dirname(__file__), "..", "client_delivery",
                   "03_Admin_Manual.docx")
os.makedirs(os.path.dirname(OUT), exist_ok=True)

doc = new_document()

add_cover(doc,
    title    = "Administrator Manual",
    subtitle = "Vishal Gold App — Administrator Operations Guide",
    version  = "v1.0",
    prepared_for = "Vishal Gold Administration Team",
    prepared_by  = "Engineering Delivery Team"
)

add_toc_placeholder(doc, [
    ("Introduction & Admin Access", 3),
    ("Admin Login", 4),
    ("Admin Dashboard Overview", 5),
    ("Product Management", 6),
    ("Subcategory Management", 8),
    ("Banner Management", 9),
    ("Staging & Preview Workflow", 10),
    ("Order Management", 11),
    ("Push Notifications", 12),
    ("User Management (Firestore)", 13),
    ("Security Responsibilities", 14),
])

# ── 1. Introduction ─────────────────────────────────────────────────────────
add_h1(doc, "1. Introduction & Admin Access")
add_body(doc, (
    "This manual provides authoritative guidance for administrators responsible for managing the "
    "Vishal Gold application's content, catalog, operations, and user base. Unlike regular customer "
    "users, administrators have elevated access to backend management tools through the dedicated "
    "Admin Dashboard. This dashboard is accessible only after authentication with an authorized "
    "administrator credential."
))
add_body(doc, (
    "Administrator access is granted by the Engineering team during the initial setup phase. New "
    "administrator accounts should be created exclusively through the Firebase Authentication "
    "Console and associated with the 'admin' role in Firestore. Under no circumstances should "
    "administrator credentials be shared verbally or transmitted via unsecured channels."
))
add_note(doc, "SECURITY WARNING",
    "Administrator credentials provide full write access to the product catalog and user data. "
    "Credentials must be stored in a password manager and protected with two-factor authentication "
    "on the associated Google account.")

# ── 2. Admin Login ───────────────────────────────────────────────────────────
add_h1(doc, "2. Admin Login")
add_body(doc, (
    "Access to the Admin Dashboard is available via the Admin Login screen, which is navigated to "
    "from the main authentication screen. There is no embedded shortcut or gesture for this navigation; "
    "administrators must navigate explicitly to the admin entry point."
))
add_numbered(doc, "On the authentication screen, tap the 'Admin Login' option located at the bottom of the screen.")
add_numbered(doc, "Enter your administrator email address and password in the respective fields.")
add_numbered(doc, "Tap 'Sign In'. Upon successful authentication, you will be directed to the Admin Dashboard.")
add_numbered(doc, "If login fails, verify your credentials. Do not share passwords. Contact the Engineering team to reset credentials if necessary.")

# ── 3. Dashboard Overview ────────────────────────────────────────────────────
add_h1(doc, "3. Admin Dashboard Overview")
add_body(doc, (
    "The Admin Dashboard is the central hub for all administrative operations. It presents a "
    "summary view of the application's content status, quick-access navigation cards to each "
    "management module, and broadcast notification controls. The dashboard is designed for "
    "desktop-scale interaction but remains fully functional on Android tablets and large-screen devices."
))
add_table(doc,
    headers=["Dashboard Card", "Function"],
    rows=[
        ["Product Management",     "Add, edit, and disable products across all categories"],
        ["Subcategory Management", "Add and manage subcategories within a product category"],
        ["Banner Management",      "Upload and schedule home screen promotional banners"],
        ["Preview & Publish",      "Stage and preview content changes before pushing them live"],
        ["Order Management",       "View and update the status of all customer orders"],
        ["Notifications",          "Compose and broadcast push notifications to users"],
    ]
)

# ── 4. Product Management ────────────────────────────────────────────────────
add_h1(doc, "4. Product Management")
add_h2(doc, "4.1 Adding a New Product")
add_body(doc, (
    "To add a new product to the Vishal Gold catalog, navigate to the Product Management section "
    "from the Admin Dashboard. The product creation form requires the following fields."
))
add_table(doc,
    headers=["Field", "Description", "Required"],
    rows=[
        ["Product Name",    "Descriptive name of the jewelry piece",                "Yes"],
        ["Category",        "Top-level category (e.g., Rings, Bangles, Chains)",    "Yes"],
        ["Subcategory",     "Specific subcategory within the category",             "Yes"],
        ["Gross Weight",    "Total weight in grams including stone weight",         "Yes"],
        ["Net Weight",      "Gold weight in grams excluding stones",                "Yes"],
        ["Purity",          "Gold purity (e.g., 22K, 18K, 14K)",                   "Yes"],
        ["Images",          "Upload one or more high-quality product photos",       "Yes (min. 1)"],
        ["Rodium / HUID",   "Toggle Rhodium plating and HUID hallmark flags",      "Optional"],
        ["Active Status",   "Toggle to make the product visible or hidden",         "Yes"],
    ]
)
add_numbered(doc, "Tap 'Add Product' from the Product Management screen.")
add_numbered(doc, "Fill in all required fields in the product form.")
add_numbered(doc, "Tap the image upload area to select product photos from the device gallery. You may add up to six images per product.")
add_numbered(doc, "Review all fields for accuracy, then tap 'Save Product'.")
add_numbered(doc, "The product will be staged for preview. Use the Preview workflow (Section 7) to verify and publish.")

add_h2(doc, "4.2 Editing an Existing Product")
add_body(doc, (
    "From the Product Management list, locate the product you wish to update by scrolling the "
    "category list or using the search field. Tap the edit icon (pencil) adjacent to the product "
    "name. The same product form will open with all existing data pre-filled. Make the required "
    "changes and tap 'Update Product'."
))

add_h2(doc, "4.3 Disabling a Product")
add_body(doc, (
    "To temporarily hide a product without deleting it, edit the product and toggle the 'Active Status' "
    "switch to the Off position. Inactive products will not appear in the customer-facing catalog but "
    "will remain in the backend for reactivation at any time."
))

add_h2(doc, "4.4 Deleting a Product")
add_body(doc, (
    "Permanent deletion should be exercised with caution, as it cannot be undone. From the product "
    "detail view in the Admin Dashboard, tap the Delete button and confirm the deletion in the "
    "resulting confirmation dialog. All associated images stored in Firebase Storage will also be "
    "permanently removed."
))

# ── 5. Subcategory Management ─────────────────────────────────────────────────
add_h1(doc, "5. Subcategory Management")
add_body(doc, (
    "Subcategories allow for granular organisation of the product catalog. For example, the 'Rings' "
    "category may contain subcategories such as Solitaire, Band, Cocktail, and Engagement. Each "
    "subcategory can have a display name and an icon or image."
))
add_numbered(doc, "Navigate to Subcategory Management from the Admin Dashboard.")
add_numbered(doc, "Select the parent category for which a new subcategory is being created.")
add_numbered(doc, "Tap 'Add Subcategory', enter the display name, and optionally upload an icon image.")
add_numbered(doc, "Tap 'Save'. The subcategory will immediately become available for product assignment.")
add_note(doc, "Note",
    "Deleting a subcategory that has products assigned to it will not delete the products. "
    "The products will become uncategorized. Reassign them manually before deletion.")

# ── 6. Banner Management ──────────────────────────────────────────────────────
add_h1(doc, "6. Banner Management")
add_body(doc, (
    "Banners are promotional images displayed in the scrollable carousel at the top of the home screen. "
    "They are an effective tool for highlighting new collections, seasonal promotions, or special announcements."
))
add_numbered(doc, "Navigate to Banner Management from the Admin Dashboard.")
add_numbered(doc, "Tap 'Add Banner'. Upload a high-resolution image (recommended dimensions: 1200 × 500 pixels, JPG or PNG format).")
add_numbered(doc, "Enter an optional title or description for the banner.")
add_numbered(doc, "Use the Active toggle to control whether the banner is currently visible to customers.")
add_numbered(doc, "Banners will appear in the order they were uploaded. The most recently added active banner appears first.")
add_note(doc, "Best Practice",
    "Use images with a 16:9 or wider aspect ratio and no important content near the edges to account "
    "for different screen sizes. Avoid text-heavy banners, as they may be difficult to read on smaller screens.")

# ── 7. Staging & Preview ──────────────────────────────────────────────────────
add_h1(doc, "7. Staging & Preview Workflow")
add_body(doc, (
    "The Staging and Preview system allows administrators to prepare, review, and validate changes "
    "to the product catalog before those changes become visible to customers. This two-step "
    "publish process ensures that content quality and accuracy are maintained at all times."
))
add_h2(doc, "7.1 How Staging Works")
add_body(doc, (
    "When an administrator adds or modifies a product, the change is first written to a private "
    "'staging' area in the database. This staging area is invisible to all customer users. The "
    "administrator can then enter Preview mode to see exactly what the catalog will look like after "
    "the staged changes are applied, without any risk of prematurely exposing incomplete content."
))
add_h2(doc, "7.2 Previewing Staged Changes")
add_numbered(doc, "From the Admin Dashboard, tap 'Preview & Publish'.")
add_numbered(doc, "The application will enter Preview mode, indicated by a persistent 'PREVIEW' banner at the top of the screen.")
add_numbered(doc, "Browse the application as a customer would. All staged changes will be visible in this mode.")
add_numbered(doc, "If the preview is satisfactory, proceed to publish. If corrections are needed, exit preview, make edits, and preview again.")

add_h2(doc, "7.3 Publishing Changes")
add_body(doc, (
    "Once the preview is approved, tap 'Publish All Changes'. This action will immediately move all "
    "staged content to the live product database, making it visible to all customers. This action "
    "cannot be undone from the application; reverting requires manual editing in the Firebase Console."
))
add_note(doc, "IMPORTANT",
    "Only one administrator should perform publish operations at a time. Simultaneous publishes by "
    "multiple administrators can result in data conflicts. Confirm with the team before publishing.")

# ── 8. Order Management ───────────────────────────────────────────────────────
add_h1(doc, "8. Order Management")
add_body(doc, (
    "All orders placed by customers, including both direct orders and sample orders, are visible "
    "in the Order Management section of the Admin Dashboard. Administrators are responsible for "
    "reviewing incoming orders and updating their status as they are processed and dispatched."
))
add_table(doc,
    headers=["Status", "Meaning", "When to Set"],
    rows=[
        ["Pending",    "Order received, awaiting review",       "Automatically on order placement"],
        ["Processing", "Order confirmed and being prepared",    "After reviewing and confirming the order"],
        ["Shipped",    "Order dispatched for delivery",         "After handing to courier or dispatch"],
        ["Delivered",  "Order received by customer",            "After confirmation of delivery"],
    ]
)
add_body(doc, (
    "To update an order status, locate the order by scrolling the order list or searching by order ID "
    "or customer phone number. Tap the order to open its detail view, then select the new status "
    "from the status selector. An automatic push notification will be sent to the customer upon "
    "status change."
))

# ── 9. Push Notifications ─────────────────────────────────────────────────────
add_h1(doc, "9. Push Notifications")
add_body(doc, (
    "Administrators can compose and broadcast push notifications to all registered app users or "
    "specific user groups. This feature is commonly used to announce new collections, promotional "
    "events, or operational updates."
))
add_numbered(doc, "From the Admin Dashboard, tap 'Send Notification'.")
add_numbered(doc, "Enter a notification title (maximum 50 characters) and body text (maximum 150 characters).")
add_numbered(doc, "Select the target audience: All Users, Wholesalers Only, or Retailers Only.")
add_numbered(doc, "Tap 'Send'. The notification will be dispatched via Firebase Cloud Messaging to all eligible devices.")
add_note(doc, "Best Practice",
    "Limit broadcasts to relevant, time-sensitive communications. Excessive or irrelevant "
    "notifications will cause users to disable notifications, reducing their value.")

# ── 10. User Management ───────────────────────────────────────────────────────
add_h1(doc, "10. User Management (via Firebase Console)")
add_body(doc, (
    "End-user account management — such as deactivating an account, resetting a user's role, or "
    "viewing sign-in history — is performed directly through the Firebase Authentication console "
    "at console.firebase.google.com. The Vishal Gold application does not expose a built-in user "
    "management interface to protect against unintended bulk operations."
))
add_table(doc,
    headers=["Task", "Location in Firebase Console"],
    rows=[
        ["View all users",            "Firebase Console → Authentication → Users"],
        ["Disable/Enable a user",     "Firebase Console → Authentication → Users → Select user → Disable"],
        ["Change user role",          "Firebase Console → Firestore → users/{uid} → edit 'role' field"],
        ["Delete a user account",     "Firebase Console → Authentication → Users → Select user → Delete"],
        ["Grant Admin Access",        "Firebase Console → Firestore → users/{uid} → set 'isAdmin: true'"],
    ]
)

# ── 11. Security Responsibilities ─────────────────────────────────────────────
add_h1(doc, "11. Security Responsibilities")
add_body(doc, (
    "As an administrator, you hold privileged access to the application and its underlying data. "
    "The following practices are mandatory and must be adhered to at all times."
))
add_numbered(doc, "Never share your administrator password with any colleague, team member, or third party.")
add_numbered(doc, "Enable two-factor authentication on the Google account used for Firebase Console access.")
add_numbered(doc, "Log out of the Admin Dashboard when not actively using it, particularly on shared devices.")
add_numbered(doc, "Report any suspicious activity — such as products appearing without your knowledge or unauthorized user role changes — to the Engineering team immediately.")
add_numbered(doc, "Do not use the staging collection as a testing ground; all staged changes should represent real, intended content updates.")
add_numbered(doc, "Ensure that google-services.json is never uploaded to public repositories or shared storage locations.")

save(doc, OUT)
