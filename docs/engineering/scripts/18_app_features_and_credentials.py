"""
18_app_features_and_credentials.py
Full Application Feature Reference & Credentials Guide — Vishal Jewelers App
"""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from doc_utils import *

OUT = os.path.join(os.path.dirname(__file__), "..", "client_delivery",
                   "18_App_Features_And_Credentials_Reference.docx")
os.makedirs(os.path.dirname(OUT), exist_ok=True)
doc = new_document()

add_cover(doc,
    title    = "App Features & Credentials Reference",
    subtitle = "Vishal Jewelers App — Complete Feature Inventory & Access Guide",
    version  = "v1.0",
    prepared_for = "Vishal Jewelers Management & IT Team",
    prepared_by  = "Engineering Delivery Team"
)

add_toc_placeholder(doc, [
    ("Document Purpose",                          3),
    ("User Roles & Default Credentials",          4),
    ("Authentication System",                     5),
    ("Splash Screen & App Entry",                 6),
    ("Customer Application — Feature Reference",  7),
    ("Admin Panel — Feature Reference",          12),
    ("Settings & Profile — Shared Features",     17),
    ("Notifications System",                     18),
    ("Background Services & Integrations",       19),
    ("Database & Infrastructure Overview",       20),
    ("Responsive Layout System",                 21),
    ("Authorization & Sign-Off",                 22),
])

# ── 1. PURPOSE ────────────────────────────────────────────────────────────────
add_h1(doc, "1. Document Purpose")
add_body(doc, (
    "This document is the single authoritative reference for every feature implemented in the "
    "Vishal Jewelers application, covering both the Customer-facing app and the Administrator Panel. "
    "It records all system credentials, default login values, user roles, access levels, "
    "every screen and its capabilities, all backend services, and infrastructure details."
))
add_note(doc, "CONFIDENTIALITY",
    "Sections containing credentials must be treated as strictly confidential. Store this "
    "document in a password-protected location and rotate any credentials shown here after "
    "the initial handover.")

# ── 2. USER ROLES & DEFAULT CREDENTIALS ──────────────────────────────────────
add_h1(doc, "2. User Roles & Default Credentials")
add_h2(doc, "2.1 Role Matrix")
add_table(doc,
    headers=["Role", "Auth Method", "Access Level", "Created By"],
    rows=[
        ["CUSTOMER",    "OTP (Firebase Phone Auth)",   "Customer app only",                   "Self-registration on first OTP login"],
        ["WHOLESALER",  "OTP (Firebase Phone Auth)",   "Customer app + wholesale pricing",    "Self-registration; fills company details on first login"],
        ["ADMIN",       "Email + Password (Firebase)", "Full Admin Panel",                    "Created by SUPER_ADMIN"],
        ["SUPER_ADMIN", "Email + Password (Firebase)", "Admin Panel + sub-admin management",  "Provisioned manually in Firestore"],
    ]
)

add_h2(doc, "2.2 System Accounts & Core Credentials")
add_note(doc, "CRITICAL", "Do not lose these credentials. They provide root access to Google services, Firebase, and Gmail.")
add_table(doc,
    headers=["Account Type", "ID / Email", "Password / Key"],
    rows=[
        ["Gmail & Firebase Console", "vishalgoldapp@gmail.com", "VishalJewelers123$%^"],
    ]
)

add_h2(doc, "2.3 Default Super Admin Credentials")
add_note(doc, "IMPORTANT",
    "These are the initial Super Admin credentials. Change the password immediately after first login.")
add_table(doc,
    headers=["Field", "Default Value"],
    rows=[
        ["Email",          "admin@vishalgold.com"],
        ["Password",       "Vishal!@#456"],
        ["Role",           "SUPER_ADMIN"],
        ["Firestore Path", "admins/{adminDocumentId}"],
    ]
)

add_h2(doc, "2.4 Admin Account — Firestore Fields")
add_table(doc,
    headers=["Field", "Type", "Description"],
    rows=[
        ["uid",         "String",    "Firebase Auth UID"],
        ["email",       "String",    "Login email address"],
        ["name",        "String",    "Display name on dashboard"],
        ["role",        "String",    "'ADMIN' or 'SUPER_ADMIN'"],
        ["createdAt",   "Timestamp", "Account creation time"],
        ["permissions", "Map",       "Optional granular permission flags"],
    ]
)

add_h2(doc, "2.5 Customer / Wholesaler Account — Firestore Fields")
add_table(doc,
    headers=["Field", "Type", "Description"],
    rows=[
        ["uid",               "String",    "Firebase Auth UID"],
        ["phone",             "String",    "Verified mobile number (E.164 format)"],
        ["name / fullName",   "String",    "User display name"],
        ["email",             "String",    "Optional email"],
        ["role",              "String",    "'USER' or 'WHOLESALER'"],
        ["company_name",      "String",    "Wholesaler business name"],
        ["address",           "String",    "Wholesaler address"],
        ["city",              "String",    "Wholesaler city"],
        ["profile_image_url", "String",    "Firebase Storage URL for profile picture"],
        ["createdAt",         "Timestamp", "First login timestamp"],
        ["fcmToken",          "String",    "Latest FCM device token for push notifications"],
        ["whatsapp",          "String",    "Optional WhatsApp number"],
    ]
)

add_h2(doc, "2.6 Quick-Login PIN (Admin Only)")
add_table(doc,
    headers=["Setting", "Detail"],
    rows=[
        ["PIN length",        "6 digits"],
        ["Storage",           "Device-local flutter_secure_storage (encrypted keystore on Android)"],
        ["Fallback",          "Full email + password if PIN is forgotten or after 5 failed attempts"],
        ["Biometric support", "Available if device hardware supports fingerprint / face unlock"],
        ["Scope",             "Device-specific — not synced to cloud"],
    ]
)

# ── 3. AUTHENTICATION SYSTEM ──────────────────────────────────────────────────
add_h1(doc, "3. Authentication System")
add_h2(doc, "3.1 Customer OTP Flow (phone_auth_screen.dart)")
add_numbered(doc, "Customer opens the app and is shown the Phone Auth screen.")
add_numbered(doc, "Customer enters their 10-digit Indian mobile number.")
add_numbered(doc, "Firebase sends a 6-digit OTP via SMS. Auto-read on Android (no reCAPTCHA).")
add_numbered(doc, "Customer verifies the OTP to complete login.")
add_numbered(doc, "On first login, a user document is auto-created in Firestore 'users' collection.")
add_numbered(doc, "If WHOLESALER role is detected, the Company Details screen is shown next.")

add_h2(doc, "3.2 Admin Email + Password Flow (admin_login_screen.dart)")
add_table(doc,
    headers=["Security Feature", "Implementation"],
    rows=[
        ["Email + Password",    "Firebase Authentication EmailPassword provider"],
        ["Role verification",   "Cross-checked against Firestore 'admins' collection on every login"],
        ["Quick Login PIN",     "Optional 6-digit device-local PIN (quick_login_setup_screen.dart)"],
        ["PIN Unlock Screen",   "pin_unlock_screen.dart — shown instead of full login if PIN is set"],
        ["Session persistence", "Firebase Auth token auto-refreshed across app restarts"],
        ["Logout",              "Clears Firebase token + local PIN state"],
    ]
)

add_h2(doc, "3.3 Auth-Related Screens")
add_table(doc,
    headers=["Screen File", "Purpose"],
    rows=[
        ["auth_screen.dart",            "Router that determines which auth path to show (admin vs customer)"],
        ["phone_auth_screen.dart",      "Customer OTP login — phone number entry + OTP verification"],
        ["admin_login_screen.dart",     "Admin email + password login form"],
        ["pin_unlock_screen.dart",      "Quick unlock screen for admins who have enabled PIN login"],
        ["setup_pin_screen.dart",       "Flow for setting up a new 6-digit PIN"],
        ["quick_login_setup_screen.dart","Settings screen to enable/disable/change PIN and biometric login"],
    ]
)

# ── 4. SPLASH SCREEN ──────────────────────────────────────────────────────────
add_h1(doc, "4. Splash Screen & App Entry (splash_screen.dart)")
add_body(doc, (
    "The splash screen is the very first screen shown when the app launches. It displays "
    "the Vishal Jewelers brand logo with a fade-in animation, checks the current Firebase Auth "
    "session, and automatically routes the user to the correct screen."
))
add_table(doc,
    headers=["Condition", "Routed To"],
    rows=[
        ["No active session",                       "Phone Auth screen (customer OTP login)"],
        ["Active session — role = USER/WHOLESALER", "Customer Home screen"],
        ["Active session — role = ADMIN/SUPER_ADMIN","Admin Dashboard screen"],
        ["Admin has PIN enabled",                   "PIN Unlock screen (bypasses full login)"],
    ]
)

# ── 5. CUSTOMER APPLICATION ───────────────────────────────────────────────────
add_h1(doc, "5. Customer Application — Feature Reference")
add_body(doc, (
    "The customer-facing side is a dark-themed B2B/B2C jewelry catalog and ordering platform. "
    "The bottom navigation bar provides access to five main tabs: Home, Search, Cart, Recent Designs, and Profile."
))

add_h2(doc, "5.1 Home Screen (home_screen.dart)")
add_table(doc,
    headers=["Component", "Description"],
    rows=[
        ["Banner Carousel",      "Full-width promotional banners. Each banner is linkable to a URL, product, or category. Managed by admins. Height responsive to screen width."],
        ["Category Section",     "Horizontally scrollable list of all jewelry categories with sub-category tiles below each. Adaptive card width per device."],
        ["Recent Designs Strip", "Quick-access strip showing the newest product uploads across all categories."],
        ["Gold Rate Banner",     "Displays the current gold rate as set by admin — updates live via Firestore."],
        ["Notification Bell",    "Icon in app bar showing unread notification badge count. Opens Notifications screen."],
    ]
)

add_h2(doc, "5.2 Banner Carousel (banner_carousel.dart)")
add_table(doc,
    headers=["Feature", "Detail"],
    rows=[
        ["Auto-play",         "4-second interval, wraps continuously"],
        ["Manual swipe",      "Left/right swipe gesture supported"],
        ["Page indicator",    "Smooth dot indicator (smooth_page_indicator package)"],
        ["Deep-link actions", "Opens external URL, product detail screen, or category/sub-category screen"],
        ["Responsive height", "50% of screen width on phones, scales to 35% on tablets"],
        ["Data source",       "Firestore 'banners' collection — real-time stream"],
    ]
)

add_h2(doc, "5.3 Global Search Screen (global_search_screen.dart)")
add_body(doc, (
    "A full-screen search interface accessible from the bottom navigation bar. "
    "Searches across all Categories, Sub-categories, and Products simultaneously."
))
add_table(doc,
    headers=["Feature", "Detail"],
    rows=[
        ["Search scope",        "Categories, Sub-categories, Products — all in one result list"],
        ["Search fields",       "Category name, sub-category name, product tag number, purity, category display label"],
        ["Result type badge",   "Each result shows a colour-coded badge: Category (gold), Sub-type (blue), Product (green)"],
        ["Leading thumbnail",   "Product results show product image; categories show icon"],
        ["Tap action",          "Category → SubCategories screen; Sub-cat → Product Listing; Product → Product Detail"],
        ["Auto-focus",          "Keyboard opens automatically on screen entry"],
        ["Clear button",        "X button appears in the search field to clear query instantly"],
        ["Empty state",         "Illustrated 'Search for anything' prompt when field is empty"],
        ["No results state",    "Friendly 'No results for...' message"],
    ]
)

add_h2(doc, "5.4 Cart Screen (cart_screen.dart)")
add_body(doc, (
    "The shopping cart. Customers add products from the Product Detail screen. "
    "The cart persists within the session and supports quantity adjustments."
))
add_table(doc,
    headers=["Feature", "Detail"],
    rows=[
        ["Cart item list",       "Each item shows product image, tag number, category, and quantity controls (+/-)"],
        ["Remove item",          "Delete button on each item to remove it from cart"],
        ["Item count summary",   "Bottom bar shows total item count"],
        ["Place Order button",   "Confirms and submits the cart as an order to Firestore"],
        ["Order confirmation dialog", "Shows item count warning before placing; admin is notified"],
        ["Admin FCM notification",    "On order placement, a push notification is sent to the admin FCM token"],
        ["Admin DB notification",     "A persistent notification record is also stored in Firestore for the admin inbox"],
        ["WhatsApp alert",       "After order is placed, a pre-formatted WhatsApp message is sent to the admin support number"],
        ["Empty state",          "Illustrated empty cart with 'Browse Designs' button"],
        ["Post-order routing",   "Navigates to Order Confirmation screen on success"],
    ]
)

add_h2(doc, "5.5 Product Listing Screen (product_listing_screen.dart)")
add_table(doc,
    headers=["Feature", "Detail"],
    rows=[
        ["Grid layout",          "2 columns on phone, 3 on large phone, 4 on tablet"],
        ["Skeleton loading",     "Animated shimmer cards while data loads from Firestore"],
        ["Staggered animations", "Scale + fade-in on first render (flutter_staggered_animations)"],
        ["Wholesale pricing",    "WHOLESALER role sees wholesale price; regular users see retail price"],
        ["Hero animation",       "Product image animates smoothly between list and detail screens"],
        ["SliverAppBar",         "Collapsible header with category/sub-category name and expandedHeight adaptive to screen size"],
    ]
)

add_h2(doc, "5.6 Product Detail Screen (product_detail_screen.dart)")
add_table(doc,
    headers=["Feature", "Detail"],
    rows=[
        ["Image gallery",        "Swipeable multi-image gallery with full-screen zoom support"],
        ["Full-screen viewer",   "Tapping an image opens full_screen_photo_viewer.dart with pinch-to-zoom"],
        ["Product metadata",     "Tag number, category, sub-category, weight (gross/net), purity, making charges"],
        ["Role-based pricing",   "Retail price for customers; wholesale price for WHOLESALER role"],
        ["Add to Cart",          "Adds the product to cart with quantity 1; increments if already in cart"],
        ["Place Sample Order",   "Navigates to Sample Order screen for custom/reference-based ordering"],
        ["Share product",        "Native Android share sheet to send product info"],
        ["Admin controls",       "ADMIN/SUPER_ADMIN users see Edit and Delete buttons on this screen"],
    ]
)

add_h2(doc, "5.7 Full Screen Photo Viewer (full_screen_photo_viewer.dart)")
add_table(doc,
    headers=["Feature", "Detail"],
    rows=[
        ["Pinch-to-zoom",    "InteractiveViewer with full zoom support on product images"],
        ["Swipe to dismiss", "Vertical swipe gesture closes the viewer"],
        ["Dark backdrop",    "Pure black background for best image contrast"],
        ["Hero animation",   "Image hero-animates from product detail into the viewer"],
    ]
)

add_h2(doc, "5.8 Sample / Custom Order Flow")
add_table(doc,
    headers=["Screen / Step", "Description"],
    rows=[
        ["category_designs_screen.dart",
         "Browse customer-uploaded reference designs for a given category. Grid layout (2–4 cols). Full-screen image viewer on tap."],
        ["sample_order_screen.dart",
         "Multi-step order form: select category & sub-category, enter quantity/size/notes, upload reference images (device gallery OR existing Firestore product image), and submit."],
        ["order_confirmation_screen.dart",
         "Success screen shown after an order is submitted. Displays the order ID and a summary. Navigates user back to Home."],
    ]
)

add_h2(doc, "5.9 Order History Screen (order_history_screen.dart)")
add_table(doc,
    headers=["Feature", "Detail"],
    rows=[
        ["Order list",        "All orders placed by the logged-in customer, newest first"],
        ["Status badge",      "Colour-coded: Pending (amber), In Progress (blue), Completed (green), Cancelled (red)"],
        ["Real-time updates", "Admin status changes reflect instantly via Firestore stream"],
        ["Order Detail tap",  "Tap any order to open full detail with submitted images and notes"],
    ]
)

add_h2(doc, "5.10 Order Detail Screen (order_detail_screen.dart)")
add_table(doc,
    headers=["Feature", "Detail"],
    rows=[
        ["Full order info",    "Order ID, date, category, sub-category, quantity, notes, current status"],
        ["Image viewer",       "All reference images submitted with the order shown in a grid; tap to full-screen"],
        ["Status history",     "History of status changes with timestamps"],
        ["Contact admin",      "Button to contact admin via WhatsApp regarding this specific order"],
    ]
)

add_h2(doc, "5.11 Recent Designs Screen (recent_designs_screen.dart)")
add_table(doc,
    headers=["Feature", "Detail"],
    rows=[
        ["Grid layout",       "2–4 columns based on screen breakpoint"],
        ["Sort order",        "Newest products first across all categories"],
        ["Adaptive padding",  "Horizontal padding adapts per screen size via AppLayout"],
    ]
)

add_h2(doc, "5.12 All Sub-Categories Screen (all_subcategories_screen.dart)")
add_table(doc,
    headers=["Feature", "Detail"],
    rows=[
        ["Grid layout",   "3–5 columns per breakpoint (3 phone, 4 large phone, 5 tablet)"],
        ["Sub-cat card",  "Image thumbnail + sub-category name"],
        ["Tap action",    "Opens Product Listing for that sub-category"],
    ]
)

add_h2(doc, "5.13 Upload Design Screen (upload_design_screen.dart)")
add_body(doc, (
    "Allows users (primarily wholesalers) to upload a new jewelry design to the Firestore catalog "
    "for admin review and listing."
))
add_table(doc,
    headers=["Feature", "Detail"],
    rows=[
        ["Form fields",         "Tag number, gross weight, net weight, name, description"],
        ["Category selector",   "Dropdown: 84_ornaments, 92_ornaments, 92_chains"],
        ["Sub-category",        "Dynamic dropdown based on selected category"],
        ["Purity field",        "84 / 92 KT options"],
        ["Image picker",        "Multi-image picker — up to 4 images from device gallery"],
        ["Upload to Firebase",  "Images uploaded to Firebase Storage; product doc created in Firestore"],
        ["WhatsApp notify",     "Notifies admin via WhatsApp after successful upload"],
    ]
)

add_h2(doc, "5.14 Company Details Screen (company_details_screen.dart)")
add_body(doc, (
    "Shown to first-time WHOLESALER users immediately after OTP login to collect business details "
    "before granting access to the main app."
))
add_table(doc,
    headers=["Field", "Description"],
    rows=[
        ["Company Name",  "Business / shop name — required"],
        ["Address",       "Full business address — required, minimum 5 characters"],
        ["City",          "Business city — required"],
        ["Skip option",   "Wholesaler may skip and fill in details later from Profile screen"],
    ]
)

add_h2(doc, "5.15 User Info Screen (user_info_screen.dart)")
add_body(doc, (
    "Displays the logged-in customer's basic profile information in a read-only view. "
    "Accessible from in-app links and used as an info card in onboarding contexts."
))

add_h2(doc, "5.16 Contact Us Screen (contact_us_screen.dart)")
add_body(doc, (
    "Provides customers with the Vishal Jewelers business contact details including "
    "phone number, WhatsApp link, email, and business address. Includes a 'Send WhatsApp' "
    "button that pre-fills a message and launches the WhatsApp app."
))

add_h2(doc, "5.17 Policy Screen / Privacy Policy (policy_screen.dart, privacy_policy_screen.dart)")
add_body(doc, (
    "In-app display of legal documents — Privacy Policy and Terms of Use. "
    "Both screens are accessible from the Profile > Settings section. "
    "Content is rendered as a scrollable rich-text document."
))

add_h2(doc, "5.18 Notifications Screen (notifications_screen.dart)")
add_table(doc,
    headers=["Feature", "Detail"],
    rows=[
        ["Notification list",    "All notifications for the current user, newest first, from Firestore 'notifications' collection"],
        ["Unread badge",         "Gold badge count shown on the notification bell in the Home app bar"],
        ["Mark all as read",     "'Mark all as read' button appears in the app bar when there are unread items"],
        ["Notification types",   "order_update (order status changes), promotion (flash sales/offers), broadcast (admin messages)"],
        ["Timestamp",            "Human-readable relative time shown on each notification tile"],
        ["Tap action",           "Tapping a notification navigates to the relevant order or screen"],
        ["Persistent storage",   "Notifications stored in Firestore 'notifications' collection; survive app restarts"],
    ]
)

# ── 6. ADMIN PANEL ────────────────────────────────────────────────────────────
add_h1(doc, "6. Admin Panel — Feature Reference")
add_body(doc, (
    "The Admin Panel is accessible only to ADMIN and SUPER_ADMIN accounts via email + password login. "
    "It uses a dark glassmorphism UI and is divided into four management areas on the dashboard."
))

add_h2(doc, "6.1 Admin Dashboard (admin_dashboard_screen.dart)")
add_table(doc,
    headers=["Dashboard Section", "Modules / Content"],
    rows=[
        ["Header (SliverAppBar)",  "Admin name, avatar, Preview Mode toggle, refresh button, logout button"],
        ["Quick Actions Strip",    "Horizontally scrollable fast-access buttons for most-used features"],
        ["Stats Strip",            "Live count cards: Products, Categories, Sub-Categories, Admins — pulled from Firestore"],
        ["Catalog Management",     "Products, Categories, Subcategories, Banners"],
        ["Operations",             "Orders, Sub-Admin Management, CRM Hub, Flash Sale Creator"],
        ["Intelligence",           "Analytics Dashboard, Audit Trail, Audit Logs"],
        ["Tools",                  "Design-to-Social Exporter, FCM Push Console"],
    ]
)
add_body(doc, (
    "The module grid is fully responsive: 2 columns on phones, 3 on large phones and foldables, "
    "4 columns on tablets. The SliverAppBar expandedHeight is 200dp on phones, 240dp on tablets."
))

add_h2(doc, "6.2 Product Management (product_management_screen.dart)")
add_table(doc,
    headers=["Feature", "Description"],
    rows=[
        ["Create Product",    "Name, category, sub-category, tag number, weight, purity, making charge %, retail price, wholesale price, multiple images"],
        ["Edit Product",      "Modify any field. Changes immediately reflect in customer listings"],
        ["Delete Product",    "Removes from Firestore and Firebase Storage"],
        ["Image Management",  "Upload multiple images; stored in Firebase Storage with URLs in Firestore"],
        ["Role-based pricing","Separate retail and wholesale price fields enforced on customer side by role"],
        ["Gold Rate linking", "Prices can be linked to live gold rate for auto-calculation"],
        ["Preview Mode",      "Stage changes and preview before publishing to live catalog"],
        ["Search & Filter",   "Search by name; filter by category and sub-category"],
        ["Admin on detail",   "Admin sees Edit + Delete on the customer-facing Product Detail screen too"],
    ]
)

add_h2(doc, "6.3 Category Management (category_management_screen.dart)")
add_table(doc,
    headers=["Feature", "Description"],
    rows=[
        ["Create",    "Add a new top-level category with name and cover image"],
        ["Edit",      "Update category name and image"],
        ["Delete",    "Remove category; warns if sub-categories or products exist under it"],
        ["Reorder",   "Drag-to-reorder categories to control display sequence in customer app"],
    ]
)

add_h2(doc, "6.4 Subcategory Management (subcategory_management_screen.dart)")
add_table(doc,
    headers=["Feature", "Description"],
    rows=[
        ["Create",         "Add sub-category under a parent category — name + image"],
        ["Edit",           "Update name, image, or parent category"],
        ["Delete",         "Remove sub-category; optionally re-assign products"],
        ["Parent linking", "Each sub-category linked to parent category via Firestore reference"],
    ]
)

add_h2(doc, "6.5 Banner Management (banner_management_screen.dart)")
add_table(doc,
    headers=["Feature", "Description"],
    rows=[
        ["Create",            "Upload banner image + configure link (URL, product ID, or category)"],
        ["Activate/Deactivate","Toggle banners on/off. Only active banners appear in the customer carousel"],
        ["Edit",              "Update image or link target"],
        ["Delete",            "Removes from Firestore and Firebase Storage"],
        ["Display order",     "Control sequence of banners in the carousel"],
    ]
)

add_h2(doc, "6.6 Admin Orders Screen (admin_orders_screen.dart)")
add_table(doc,
    headers=["Feature", "Description"],
    rows=[
        ["View all orders",    "All customer orders across all users in a sortable list"],
        ["Order detail",       "Customer info, product reference, attached images, notes, timestamps"],
        ["Status update",      "Change status: PENDING → IN_PROGRESS → COMPLETED / CANCELLED. Customer sees change in real-time via Firestore stream"],
        ["Filter by status",   "Filter orders to focus on PENDING or IN_PROGRESS items"],
        ["Customer contact",   "Tap to call or open WhatsApp with customer directly from order detail"],
        ["Image preview",      "View customer-uploaded reference images in full-screen"],
    ]
)

add_h2(doc, "6.7 Sub-Admin Management (sub_admin_management_screen.dart)")
add_note(doc, "SUPER_ADMIN only", "This module is hidden from regular ADMIN users.")
add_table(doc,
    headers=["Feature", "Description"],
    rows=[
        ["Create Admin",    "Enter name + email; system creates Firebase Auth account and Firestore admin doc"],
        ["View Admins",     "List of all active admin accounts with roles and creation dates"],
        ["Delete Admin",    "Revokes Firebase Auth + removes Firestore admin document"],
        ["Role assignment", "Assign ADMIN or SUPER_ADMIN role"],
        ["Permissions",     "Optionally restrict an admin to specific modules"],
    ]
)

add_h2(doc, "6.8 CRM Hub (crm_hub_screen.dart)")
add_table(doc,
    headers=["Feature", "Description"],
    rows=[
        ["Customer Segments",
         "Pre-built live segments with Firestore counts: All Users, Wholesalers, Retail Customers, "
         "Recent Customers (last 30 days), Inactive Customers (>90 days no activity)"],
        ["Push Notification to Segment",
         "Send FCM push notification to any segment. Enter title + body + optional image URL. "
         "Delivered to all FCM tokens in the selected segment via Firebase Cloud Messaging"],
        ["Share Promotions",
         "Upload a custom promotion image from device gallery OR select an existing Firestore product image. "
         "Export via native share sheet or Design-to-Social tool"],
        ["Live Count Dashboard",
         "Count cards for each segment update in real-time as customer registrations change"],
    ]
)

add_h2(doc, "6.9 Flash Sale Creator (flash_sale_creator_screen.dart)")
add_table(doc,
    headers=["Feature", "Description"],
    rows=[
        ["Create Flash Sale",     "Sale name, discount type (% or fixed), eligible product IDs, start/end datetime"],
        ["Activate / Pause",      "Enable or pause without deleting"],
        ["Customer visibility",   "Active flash sales display discount badge on product cards"],
        ["Notification trigger",  "Optionally send push notification to all customers when sale goes live"],
    ]
)

add_h2(doc, "6.10 Analytics Dashboard (analytics_dashboard_screen.dart)")
add_table(doc,
    headers=["Metric / Chart", "Description"],
    rows=[
        ["Order Volume",       "Bar/line chart — orders placed over time (daily, weekly, monthly)"],
        ["Revenue Trend",      "Estimated revenue from completed orders over time"],
        ["Top Categories",     "Pie chart of most-ordered categories"],
        ["Customer Growth",    "Line chart of new user registrations"],
        ["Wholesaler vs Retail","Order volume split by customer type"],
        ["Conversion Funnel",  "App opens → product views → orders placed"],
    ]
)

add_h2(doc, "6.11 Audit Trail & Audit Logs (audit_trail_screen.dart, audit_logs_screen.dart)")
add_table(doc,
    headers=["Feature", "Description"],
    rows=[
        ["Audit Trail",  "High-level recent admin actions grouped by date (product edits, banner changes, admin creation)"],
        ["Audit Logs",   "Detailed filterable log — filter by admin, action type, or date range"],
        ["Log fields",   "Timestamp, admin name, admin UID, action type, affected entity ID, change summary"],
        ["Immutable",    "Log entries cannot be edited or deleted — stored in read-only Firestore collection"],
        ["Service",      "audit_service.dart automatically logs every significant admin write action"],
    ]
)

add_h2(doc, "6.12 Design-to-Social Exporter (design_to_social_screen.dart)")
add_table(doc,
    headers=["Feature", "Description"],
    rows=[
        ["Template selection",    "Branded Vishal Jewelers jewelry promotion templates"],
        ["Product image embed",   "Select from Firestore product catalog OR upload from device gallery"],
        ["Custom text overlay",   "Add product name, price, or promotional message with styled typography"],
        ["Export to gallery",     "Save the finished promotional image to device photo gallery"],
        ["Share to social media", "Native Android share sheet — WhatsApp, Instagram, Facebook, etc."],
        ["Brand consistency",     "All templates use Vishal Jewelers brand colours and typography"],
    ]
)

add_h2(doc, "6.13 FCM Push Console (fcm_console_screen.dart)")
add_table(doc,
    headers=["Feature", "Description"],
    rows=[
        ["Compose",           "Enter notification title, body text, and optional image URL"],
        ["Audience selection","All Users, Wholesalers Only, Retail Customers Only, Active Customers"],
        ["Send immediately",  "Dispatches FCM notification to all tokens in selected audience"],
        ["Delivery log",      "Recent notification log — what was sent, to whom, when"],
        ["CRM integration",   "Notifications also triggerable from CRM Hub segment cards"],
    ]
)

add_h2(doc, "6.14 Admin Preview Mode (preview_provider.dart)")
add_table(doc,
    headers=["Feature", "Description"],
    rows=[
        ["Stage changes",     "Draft product/banner edits without publishing to live Firestore"],
        ["Live preview",      "Switch app to 'Preview Mode' to see staged changes as a customer"],
        ["Publish",           "Push staged changes live with a single confirm action"],
        ["Discard",           "Discard all staged changes without affecting live data"],
        ["Preview banner",    "A visible banner in the UI tells the admin they are in preview mode"],
    ]
)

# ── 7. SETTINGS & PROFILE ─────────────────────────────────────────────────────
add_h1(doc, "7. Settings & Profile — Shared Features")
add_h2(doc, "7.1 Profile Screen (profile_screen.dart)")
add_table(doc,
    headers=["Feature", "Description"],
    rows=[
        ["Profile avatar",      "Shows photo from Firebase Storage, or gold initial-letter avatar"],
        ["Role badge",          "Gold badge showing USER, WHOLESALER, ADMIN, or SUPER_ADMIN"],
        ["Account info card",   "Email, phone, company name (wholesaler), city (wholesaler)"],
        ["Edit profile link",   "Pencil icon opens Edit Profile screen"],
        ["Order History",       "Quick access link to Order History screen"],
        ["Logout button",       "Confirmation dialog then Firebase sign-out + local session clear"],
    ]
)

add_h2(doc, "7.2 Edit Profile Screen (edit_profile_screen.dart)")
add_table(doc,
    headers=["Feature", "Description"],
    rows=[
        ["Name update",         "Change display name; saved locally + to Firestore user document"],
        ["Profile photo",       "Pick from device gallery; uploaded to Firebase Storage; URL saved in Firestore"],
        ["Email update",        "Optional email field for customers"],
        ["Company details",     "Wholesaler can update company name, address, city from this screen"],
    ]
)

add_h2(doc, "7.3 Settings — Admin Only")
add_table(doc,
    headers=["Setting Module", "Description"],
    rows=[
        ["Quick Login Settings (quick_login_settings_screen.dart)",
         "Enable/disable PIN; change or reset 6-digit PIN; toggle biometric unlock"],
        ["Security Center (security_center_screen.dart)",
         "View active sessions, recent login activity, trigger forced sign-out of all sessions"],
        ["Notification Preferences (notification_settings_screen.dart)",
         "Toggle which system events trigger in-app notifications for the admin"],
        ["Storage & Data (storage_settings_screen.dart)",
         "View and clear locally cached product images; manage offline storage usage"],
    ]
)

add_h2(doc, "7.4 Settings — All Users")
add_table(doc,
    headers=["Setting Module", "Description"],
    rows=[
        ["App Language (language_settings_screen.dart)",
         "Switch app display language. Currently supports English. Framework ready for additional locales."],
        ["Support Hub (support_hub_screen.dart)",
         "Contact Vishal Jewelers support via WhatsApp, email, or in-app link. Shows business hours."],
        ["Privacy Policy (privacy_policy_screen.dart)",
         "In-app scrollable Privacy Policy document."],
        ["Contact Us (contact_us_screen.dart)",
         "Business phone, WhatsApp, email, and address. 'Send WhatsApp' pre-fills a message."],
    ]
)

# ── 8. NOTIFICATIONS SYSTEM ───────────────────────────────────────────────────
add_h1(doc, "8. Notifications System")
add_h2(doc, "8.1 Notification Types & Triggers")
add_table(doc,
    headers=["Notification Type", "Trigger", "Audience"],
    rows=[
        ["Order Status Update", "Admin changes order status in Admin Orders screen", "Specific customer (order owner)"],
        ["New Order Alert",     "Customer places an order via Cart",               "Admin (FCM + Firestore DB notification)"],
        ["Flash Sale Live",     "Admin activates a Flash Sale",                    "All users (optional push)"],
        ["Promotional Blast",   "Admin sends from FCM Console or CRM Hub",         "Selected segment"],
        ["New Design Upload",   "User uploads a design via Upload Design screen",  "Admin (WhatsApp alert)"],
        ["Custom Broadcast",    "Admin composes in FCM Console",                   "Any selected segment"],
    ]
)

add_h2(doc, "8.2 Notification Storage")
add_table(doc,
    headers=["Field", "Type", "Description"],
    rows=[
        ["id",        "String",    "Firestore auto-generated document ID"],
        ["userId",    "String",    "Target user UID (or 'admin' for admin inbox)"],
        ["title",     "String",    "Notification headline"],
        ["message",   "String",    "Notification body text"],
        ["type",      "String",    "order_update, promotion, broadcast, new_order"],
        ["relatedId", "String",    "Order ID or product ID this notification refers to"],
        ["isRead",    "bool",      "Whether the user has read this notification"],
        ["createdAt", "Timestamp", "When the notification was created"],
    ]
)

# ── 9. BACKGROUND SERVICES & INTEGRATIONS ─────────────────────────────────────
add_h1(doc, "9. Background Services & Integrations")
add_table(doc,
    headers=["Service File", "Responsibility"],
    rows=[
        ["firebase_service.dart",
         "Central Firebase access layer. Wraps all Firestore CRUD, Firebase Storage uploads, "
         "FCM token management, banner/product/order streams, support contact lookup, "
         "and notification dispatch (sendNotificationRequest, createDbNotification)."],
        ["firebase_auth_service.dart",
         "Firebase Authentication wrapper — OTP phone auth, email/password auth, session checks, "
         "token refresh, and sign-out."],
        ["fcm_service.dart",
         "Firebase Cloud Messaging setup — handles incoming push notifications in foreground/background, "
         "updates FCM token in Firestore on token refresh, routes notification taps to correct screen."],
        ["analytics_service.dart",
         "Firebase Analytics event logging — tracks screen views, order events, search queries, "
         "product views, and custom business metrics for the Analytics Dashboard."],
        ["audit_service.dart",
         "Writes an immutable log entry to Firestore 'audit_logs' collection on every significant "
         "admin action (product/category/banner CRUD, admin creation, order status changes)."],
        ["whatsapp_service.dart",
         "Utility that constructs and launches WhatsApp deep-links (whatsapp://send or wa.me) "
         "with pre-filled messages. Used for: new order admin alerts, design upload alerts, "
         "and customer-initiated contact from Contact Us screen."],
        ["image_picker_service.dart",
         "Wrapper around the image_picker package. Provides pick-single and pick-multiple "
         "methods used across: product management image upload, profile photo update, "
         "upload design screen, and CRM promotion image selection."],
        ["local_storage_service.dart",
         "Device-local key-value storage (shared_preferences). Stores: user display name cache, "
         "app language preference, PIN-enabled flag, and offline product image cache metadata."],
    ]
)

# ── 10. DATABASE & INFRASTRUCTURE ─────────────────────────────────────────────
add_h1(doc, "10. Database & Infrastructure Overview")
add_h2(doc, "10.1 Cloud Firestore Collections")
add_table(doc,
    headers=["Collection", "Purpose", "Key Fields"],
    rows=[
        ["users",         "Customer & wholesaler profiles",
         "uid, phone, name, role, fcmToken, company_name, address, city, createdAt"],
        ["admins",        "Admin accounts",
         "uid, email, name, role, permissions, createdAt"],
        ["categories",    "Top-level jewelry categories",
         "name, imageUrl, isActive, displayOrder"],
        ["subcategories", "Sub-categories under categories",
         "name, imageUrl, categoryId, isActive, displayOrder"],
        ["products",      "Jewelry product catalog",
         "name, tagNumber, categoryId, subcategoryId, imageUrls[], retailPrice, wholesalePrice, grossWeight, netWeight, purity, makingChargePercent"],
        ["banners",       "Home screen promotional banners",
         "imageUrl, linkType, linkValue, isActive, displayOrder"],
        ["orders",        "Customer orders (cart and sample)",
         "userId, items[], status, images[], notes, createdAt, updatedAt, customerInfo{}"],
        ["goldRate",      "Current gold rate (single doc)",
         "rate, updatedAt, updatedByAdminUid"],
        ["flashSales",    "Flash sale configs",
         "name, discountType, discountValue, productIds[], isActive, startAt, endAt"],
        ["notifications", "In-app notification inbox",
         "userId, title, message, type, relatedId, isRead, createdAt"],
        ["audit_logs",    "Immutable admin action log",
         "adminUid, adminName, action, entityId, summary, timestamp"],
    ]
)

add_h2(doc, "10.2 Firebase Storage Bucket Structure")
add_table(doc,
    headers=["Storage Path", "Contents"],
    rows=[
        ["products/{productId}/",      "Product images uploaded by admins during product creation/edit"],
        ["categories/{categoryId}/",   "Category cover images"],
        ["subcategories/{id}/",        "Sub-category thumbnail images"],
        ["banners/{bannerId}/",        "Promotional banner images"],
        ["users/{userId}/profile/",    "Customer and admin profile pictures"],
        ["orders/{orderId}/",          "Customer-uploaded reference images attached to sample orders"],
        ["designs/{userId}/",          "Designs uploaded via the Upload Design screen"],
        ["promotions/{promoId}/",      "Design-to-Social exported promotional artwork"],
    ]
)

add_h2(doc, "10.3 Firebase Services in Use")
add_table(doc,
    headers=["Firebase Service", "Purpose", "Plan"],
    rows=[
        ["Firebase Authentication",  "OTP phone auth (customers) + email/password (admins)", "Spark (Free)"],
        ["Cloud Firestore",          "Primary NoSQL database for all app data",              "Spark (Free)"],
        ["Firebase Storage",         "All images — products, banners, orders, profiles",     "Spark (Free)"],
        ["Firebase Cloud Messaging", "Push notifications to all user segments",              "Free"],
        ["Firebase Analytics",       "User behaviour tracking and business metrics",         "Free"],
    ]
)
add_note(doc, "UPGRADE NOTE",
    "The Spark (free) plan has usage quotas. Upgrade to the Blaze (pay-as-you-go) plan "
    "before going to production to avoid quota blocks on Storage and Firestore reads/writes.")

# ── 11. RESPONSIVE LAYOUT SYSTEM ──────────────────────────────────────────────
add_h1(doc, "11. Responsive Layout System (lib/utils/app_layout.dart)")
add_body(doc, (
    "A centralised AppLayout utility class adapts all grids, paddings, font sizes, card "
    "dimensions, banner heights, and navigation elements across all Android device sizes. "
    "Call AppLayout.of(context) from any widget to get device-appropriate values."
))
add_table(doc,
    headers=["Breakpoint", "Screen Width", "Product Grid", "Admin Grid", "H-Padding", "Stat Tile"],
    rows=[
        ["Small Phone",  "< 360dp",   "2 cols", "2 cols", "12dp", "125dp"],
        ["Phone",        "360–599dp", "2 cols", "2 cols", "16dp", "125dp"],
        ["Large Phone",  "600–839dp", "3 cols", "3 cols", "24dp", "150dp"],
        ["Tablet",       "≥ 840dp",   "4 cols", "4 cols", "32dp", "170dp"],
    ]
)
add_table(doc,
    headers=["Screen / Widget", "What Adapts"],
    rows=[
        ["Banner Carousel",          "Height: 50% screen width on phone → 35% on tablet"],
        ["Category Section",         "Card width 115–180dp; list height 155–220dp"],
        ["All Sub-Categories",       "Grid columns 3–5+; adaptive horizontal padding"],
        ["Product Listing",          "Grid cols 2–4; aspect ratio; skeleton grid; animation column count"],
        ["Recent Designs",           "Grid cols 2–4; adaptive padding and spacing"],
        ["Category Designs",         "Grid cols 2–4; adaptive padding"],
        ["Admin Module Grid",        "Cols 2–4; aspect ratio adapts for tile proportions"],
        ["Admin SliverAppBar",       "expandedHeight 200dp (phone) → 240dp (tablet)"],
        ["Admin Stat Tiles",         "Width 125–170dp"],
        ["Admin Body Padding",       "Horizontal padding 16dp → 32dp on tablet"],
    ]
)

# ── SIGN-OFF ──────────────────────────────────────────────────────────────────
add_signature_block(doc, [
    ("Client Representative",  "Vishal Jewelers"),
    ("Delivery Engineer",      "Engineering Delivery Team"),
])

save(doc, OUT)
