"""
02_user_manual.py — Generates the User Manual.docx for Retailers and Wholesalers
"""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from doc_utils import *

OUT = os.path.join(os.path.dirname(__file__), "..", "client_delivery",
                   "02_User_Manual.docx")
os.makedirs(os.path.dirname(OUT), exist_ok=True)

doc = new_document()

add_cover(doc,
    title    = "User Manual",
    subtitle = "Vishal Jewelers App — Retailer & Wholesaler Guide",
    version  = "v1.0",
    prepared_for = "Vishal Jewelers Customers",
    prepared_by  = "Engineering Delivery Team"
)

add_toc_placeholder(doc, [
    ("Introduction", 3),
    ("Getting Started — Download & Installation", 4),
    ("Understanding User Roles", 5),
    ("Account Registration & Login", 6),
    ("Browsing the Product Catalog", 7),
    ("Product Details", 8),
    ("Managing Your Cart", 9),
    ("Wishlist", 10),
    ("Placing a Sample Order", 11),
    ("Order History", 12),
    ("Your Profile", 13),
    ("Notifications", 14),
    ("Troubleshooting & FAQs", 15),
])

# ── 1. Introduction ─────────────────────────────────────────────────────────
add_h1(doc, "1. Introduction")
add_body(doc, (
    "Welcome to Vishal Jewelers, the premier digital catalog and commerce platform designed exclusively "
    "for the gold and fine jewelry trade. The Vishal Jewelers application connects jewelry wholesalers "
    "and retailers in a seamless, secure, and efficient digital environment. Whether you are "
    "a wholesale buyer reviewing the latest inventory or a retail customer exploring curated collections, "
    "this application provides a rich, intuitive experience tailored to your role."
))
add_body(doc, (
    "This manual provides step-by-step guidance for all features available to Retailer and Wholesaler "
    "users. Administrative functionality is documented in a separate Admin Manual. If you encounter "
    "any difficulty not addressed in this guide, please contact your account representative or "
    "refer to the Troubleshooting section at the end of this document."
))

# ── 2. Download & Installation ───────────────────────────────────────────────
add_h1(doc, "2. Getting Started — Download & Installation")
add_body(doc, (
    "The Vishal Jewelers application is available exclusively for Android devices. The following steps "
    "describe how to download and install the application for first-time use."
))
add_h2(doc, "2.1 System Requirements")
add_table(doc,
    headers=["Requirement", "Minimum"],
    rows=[
        ["Operating System", "Android 6.0 (Marshmallow) or later"],
        ["Storage",          "50 MB free space"],
        ["Internet",         "Active internet connection required"],
        ["RAM",              "2 GB or more recommended"],
    ]
)
add_h2(doc, "2.2 Installation Steps")
add_numbered(doc, "Search for 'Vishal Jewelers' on the Google Play Store, or scan the QR code provided by your account representative.")
add_numbered(doc, "Tap the Install button. The application will download and install automatically.")
add_numbered(doc, "Once installed, tap Open to launch the application.")
add_numbered(doc, "Grant the requested permissions: SMS (for OTP verification) and Notifications (for order updates).")

# ── 3. Understanding User Roles ──────────────────────────────────────────────
add_h1(doc, "3. Understanding User Roles")
add_body(doc, (
    "Vishal Jewelers serves two primary user types, each with a distinct experience tailored to their "
    "business needs. The application automatically adjusts the available features and pricing "
    "information based on your registered role."
))
add_table(doc,
    headers=["Feature", "Retailer", "Wholesaler"],
    rows=[
        ["Browse Product Catalog",        "✓", "✓"],
        ["View Product Details & Images", "✓", "✓"],
        ["Add to Cart",                   "✓", "✓"],
        ["Wishlist",                      "✓", "✓"],
        ["Cart Persists Across Devices",  "✗", "✓"],
        ["Wholesale Pricing View",        "✗", "✓"],
        ["Sample Order Placement",        "✓", "✓"],
        ["Order History",                 "✓", "✓"],
    ]
)
add_note(doc, "Note",
         "Retailer carts are saved on the current device only. If you uninstall and reinstall the app, "
         "your cart will be cleared. Wholesaler carts are saved securely in the cloud and will be "
         "restored upon login on any device.")

# ── 4. Account Registration & Login ─────────────────────────────────────────
add_h1(doc, "4. Account Registration & Login")
add_h2(doc, "4.1 First-Time Registration")
add_body(doc, (
    "When you open the Vishal Jewelers application for the first time, you will be presented with the "
    "authentication screen. The application uses your mobile phone number as your unique identifier."
))
add_numbered(doc, "Enter your mobile phone number in international format (e.g., +91 98765 43210).")
add_numbered(doc, "Tap the 'Send OTP' button. A one-time password will be sent to your number via SMS.")
add_numbered(doc, "Enter the six-digit OTP in the verification field. You have 60 seconds before the code expires.")
add_numbered(doc, "If you did not receive the OTP, tap 'Resend OTP' after the 60-second cooldown timer completes.")
add_numbered(doc, "Upon successful verification, if you are a new user, you will be prompted to complete your profile: enter your full name, city, and state.")
add_numbered(doc, "Your account will be created and you will be directed to the home screen.")

add_h2(doc, "4.2 Returning User Login")
add_body(doc, (
    "Returning users follow the same phone number and OTP process. Your profile and order history "
    "will be restored automatically after successful authentication. Wholesaler users will also "
    "see their saved cart items restored from the cloud."
))

add_h2(doc, "4.3 Guest / Anonymous Browsing")
add_body(doc, (
    "If you wish to browse the product catalog without registering, tap 'Continue as Guest' on the "
    "authentication screen. Guest users can view all products and collections but cannot place orders, "
    "save items permanently, or access order history. You can register at any time by tapping the "
    "profile icon and following the registration steps above."
))

# ── 5. Browsing the Product Catalog ─────────────────────────────────────────
add_h1(doc, "5. Browsing the Product Catalog")
add_body(doc, (
    "The home screen is your gateway to the entire Vishal Jewelers collection. Products are organized "
    "into categories such as Rings, Bangles, Chains, Sets, and more. Collections can be browsed "
    "horizontally by category on the home screen, or you may navigate to a full listing view for "
    "any category."
))
add_h2(doc, "5.1 Category Navigation")
add_numbered(doc, "On the Home screen, scroll horizontally across the category bar at the top.")
add_numbered(doc, "Tap any category tile to view all products in that category.")
add_numbered(doc, "Within a category, you may further filter by subcategory using the filter chips below the header.")

add_h2(doc, "5.2 Search")
add_body(doc, (
    "Tap the search icon (magnifying glass) at the top right of the catalog screen to enter "
    "search mode. Type a product name, weight, or category keyword. Results will appear in real time. "
    "Tap any result to open the product detail screen."
))

add_h2(doc, "5.3 Sorting & Filtering")
add_body(doc, (
    "Products can be sorted by weight (ascending or descending) using the Sort option in the "
    "top bar. Filters allow you to narrow results by subcategory, purity (e.g., 22K, 18K), "
    "and availability."
))

# ── 6. Product Details ───────────────────────────────────────────────────────
add_h1(doc, "6. Product Details")
add_body(doc, (
    "Tapping any product card opens the Product Detail screen, which presents a full-screen "
    "image carousel, complete specifications, and purchase options."
))
add_h2(doc, "6.1 Image Viewer")
add_body(doc, (
    "Swipe left or right across the image area to browse all product photos. Tap the image once "
    "to enter full-screen view. In full-screen mode, you may pinch-to-zoom for an up-close "
    "inspection of the design and craftsmanship."
))
add_h2(doc, "6.2 Product Specifications")
add_body(doc, (
    "The detail panel below the images displays the following information: product name, category, "
    "gross weight, net weight, purity, and availability status. Wholesaler users will additionally "
    "see pricing information based on the current market rate configured by the administrator."
))
add_h2(doc, "6.3 Adding to Cart & Wishlist")
add_body(doc, (
    "Use the quantity selector (+ and − buttons) to choose the desired quantity. The maximum "
    "quantity per item is 99 units per transaction. Tap 'Add to Cart' to add the item to your cart, "
    "or tap the heart icon to save the item to your Wishlist for later consideration."
))

# ── 7. Cart ──────────────────────────────────────────────────────────────────
add_h1(doc, "7. Managing Your Cart")
add_body(doc, (
    "The Cart screen displays all items you have selected for purchase. Access your cart at any "
    "time by tapping the cart icon in the top right corner of the application."
))
add_h2(doc, "7.1 Reviewing Cart Items")
add_body(doc, (
    "Each cart item displays the product image, name, weight, quantity, and price (Wholesaler users only). "
    "You can adjust the quantity of any item directly from the cart using the inline quantity selector."
))
add_h2(doc, "7.2 Removing Items")
add_body(doc, (
    "Swipe left on a cart item or tap the remove icon to delete it from your cart. "
    "You will be prompted to confirm before the item is removed."
))
add_h2(doc, "7.3 Order Summary")
add_body(doc, (
    "The bottom of the cart screen displays a summary panel showing the total number of items, "
    "total gross weight, and (for Wholesalers) the estimated total price. Tap 'Proceed to Order' "
    "to place your order."
))

# ── 8. Wishlist ───────────────────────────────────────────────────────────────
add_h1(doc, "8. Wishlist")
add_body(doc, (
    "The Wishlist serves as a curated shortlist of products you are interested in but are not "
    "yet ready to order. Items in your Wishlist are saved persistently and can be moved to the "
    "cart at any time with a single tap. To access your Wishlist, tap the heart icon in the "
    "navigation bar."
))

# ── 9. Sample Order ───────────────────────────────────────────────────────────
add_h1(doc, "9. Placing a Sample Order")
add_body(doc, (
    "The Sample Order feature allows you to request one or more custom or prototype jewelry pieces "
    "from the Vishal Jewelers team. This is intended for custom design requests or pre-production samples."
))
add_numbered(doc, "Tap the 'Custom Order' button (gold circular button) on the home screen.")
add_numbered(doc, "Fill in the required fields: Group/Category, Item Name, Quantity, Size requirements, Estimated Weight, and any Rodium or HUID treatment preferences.")
add_numbered(doc, "Attach a reference image by tapping the image icon. You may upload a photo from your gallery.")
add_numbered(doc, "Review your entry and tap 'Place Order'. The request will be submitted to the Vishal Jewelers team.")
add_numbered(doc, "You will receive a push notification and in-app confirmation once your sample request has been reviewed.")

# ── 10. Order History ────────────────────────────────────────────────────────
add_h1(doc, "10. Order History")
add_body(doc, (
    "All orders placed through the application are recorded and accessible through the Order History "
    "screen. Navigate here via the Profile menu. Each order entry displays the order date, a list "
    "of items, total weight, and the current status on a visual timeline: Pending, Processing, "
    "Shipped, and Delivered."
))

# ── 11. Profile ───────────────────────────────────────────────────────────────
add_h1(doc, "11. Your Profile")
add_body(doc, (
    "The Profile screen is accessible by tapping the person icon in the navigation bar. It displays "
    "your registered name, phone number, city, and account type. You may update your name, city, and "
    "state from this screen. Your phone number is your account identifier and cannot be changed."
))
add_note(doc, "Privacy", "Your personal details are stored using industry-standard encrypted storage on your device and are never shared with third parties.")

# ── 12. Notifications ────────────────────────────────────────────────────────
add_h1(doc, "12. Notifications")
add_body(doc, (
    "Vishal Jewelers sends push notifications to keep you informed about your orders. You will receive "
    "notifications when: a new collection is added, your order status changes, a sample order "
    "request has been reviewed, or an important announcement is broadcast by the team. "
    "Notification preferences can be managed in your device's system settings under App Notifications."
))

# ── 13. FAQs ─────────────────────────────────────────────────────────────────
add_h1(doc, "13. Troubleshooting & FAQs")
faqs = [
    ("I did not receive my OTP.",
     "Ensure your phone has network connectivity. Check that the phone number was entered correctly with "
     "the country code (+91 for India). If the problem persists, wait 60 seconds and tap 'Resend OTP'. "
     "If still not received, contact your account representative."),
    ("My cart is empty after reinstalling the app.",
     "Retailer carts are stored locally on the device. Reinstalling clears local data. Wholesalers "
     "who are signed in will see their cloud-saved cart restored after login."),
    ("Products are not loading.",
     "Check your internet connection. The application requires an active connection to load product "
     "images and pricing from the cloud. If connectivity is confirmed and products still fail to load, "
     "close and restart the application."),
    ("I cannot see pricing information.",
     "Pricing is only visible to authenticated Wholesaler accounts. If you believe your account type "
     "is incorrect, contact your Vishal Jewelers representative to update your registration."),
    ("How do I contact support?",
     "Tap the Profile screen and select 'Contact Support', or reach out directly to your assigned "
     "Vishal Jewelers account manager via WhatsApp or phone."),
]
for q, a in faqs:
    add_h3(doc, f"Q: {q}")
    add_body(doc, f"A: {a}")

save(doc, OUT)
