"""
08_data_privacy_policy.py — Data Privacy Policy
"""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from doc_utils import *

OUT = os.path.join(os.path.dirname(__file__), "..", "client_delivery",
                   "08_Data_Privacy_Policy.docx")
os.makedirs(os.path.dirname(OUT), exist_ok=True)

doc = new_document()

add_cover(doc,
    title    = "Data Privacy Policy",
    subtitle = "Vishal Jewelers App — User Data Collection, Use & Protection Policy",
    version  = "v1.0",
    prepared_for = "Vishal Jewelers — All Users",
    prepared_by  = "Engineering Delivery Team"
)

add_toc_placeholder(doc, [
    ("Introduction & Scope", 3),
    ("Data We Collect", 4),
    ("How We Use Your Data", 5),
    ("Data Sharing & Third Parties", 6),
    ("Data Storage & Security", 7),
    ("User Rights", 8),
    ("Data Retention", 9),
    ("Changes to This Policy", 10),
    ("Contact Information", 10),
])

add_h1(doc, "1. Introduction & Scope")
add_body(doc, (
    "Vishal Jewelers operates the Vishal Jewelers mobile application (hereinafter referred to as 'the App'), "
    "a digital commerce platform for the gold and fine jewelry trade. This Data Privacy Policy "
    "describes the types of personal data we collect from users of the App, the purposes for which "
    "that data is used, and the measures we take to protect it. This policy applies to all users "
    "of the App, including Retailers, Wholesalers, and Administrators, regardless of location."
))
add_body(doc, (
    "By using the Vishal Jewelers App, you consent to the data practices described in this policy. "
    "If you do not agree with any aspect of this policy, you should discontinue use of the App "
    "and contact us to request deletion of any data already collected."
))

add_h1(doc, "2. Data We Collect")
add_h2(doc, "2.1 Data You Provide Directly")
add_body(doc, (
    "When you register and use the Vishal Jewelers App, you voluntarily provide certain information "
    "that we require to deliver the service."
))
add_table(doc,
    headers=["Data Type", "Example", "Required?"],
    rows=[
        ["Mobile Phone Number", "+91 98765 43210",    "Yes — used as your unique account identifier"],
        ["Full Name",           "Rajesh Mehta",       "Yes — for account personalisation"],
        ["City",                "Surat",              "Yes — for regional catalog filtering"],
        ["State",               "Gujarat",            "Yes — for geographical account tagging"],
        ["User Role",           "Retailer / Wholesaler","Yes — determines feature access level"],
        ["Profile Photo",       "Optional upload",    "No — only if you choose to add one"],
    ]
)

add_h2(doc, "2.2 Data Collected Automatically")
add_body(doc, (
    "In addition to information you directly provide, the App automatically collects certain "
    "technical data necessary for its operation and security."
))
add_table(doc,
    headers=["Data Type", "Purpose"],
    rows=[
        ["Firebase UID",           "Unique anonymous identifier assigned by Firebase Authentication"],
        ["FCM Token",              "Device token used to deliver push notifications"],
        ["App usage events",       "Firebase Analytics — anonymous and aggregated, used for app improvement"],
        ["Crash reports",          "Firebase Crashlytics — technical data on app failures, no PII included"],
        ["Cart & wishlist items",  "Products you add to cart or wishlist, stored to maintain your session"],
        ["Order data",             "Products ordered, quantities, and order status for order history"],
    ]
)

add_h2(doc, "2.3 Sample Order Data")
add_body(doc, (
    "If you place a Sample Order, you may optionally provide a reference image. This image is "
    "uploaded to a secured Firebase Storage bucket. It is used solely by the Vishal Jewelers team "
    "to process your custom jewelry request and is not shared with any third party."
))

add_h1(doc, "3. How We Use Your Data")
add_body(doc, (
    "Vishal Jewelers uses the personal data collected for the following specific and limited purposes."
))
add_numbered(doc, "Account Management: To create, maintain, and secure your user account.")
add_numbered(doc, "Authentication: To verify your identity via OTP and provide secure access to the App.")
add_numbered(doc, "Service Delivery: To fulfil orders, process sample requests, and maintain your cart and wishlist.")
add_numbered(doc, "Push Notifications: To send you updates on order status, new collections, and promotions.")
add_numbered(doc, "Catalog Personalisation: To display locally relevant products and pricing.")
add_numbered(doc, "App Improvement: To analyze anonymous usage patterns and improve the App's performance and features.")
add_numbered(doc, "Security: To detect, investigate, and prevent fraudulent or unauthorized activity.")

add_h1(doc, "4. Data Sharing & Third Parties")
add_body(doc, (
    "Vishal Jewelers does not sell, rent, or trade your personal data with third parties. We share "
    "data only with the following categories of service providers, strictly for the purposes "
    "of operating the App on your behalf."
))
add_table(doc,
    headers=["Third Party", "Data Shared", "Purpose"],
    rows=[
        ["Google Firebase (Auth, Firestore, Storage, FCM, Analytics)",
         "Phone number, UID, FCM token, cart/order data, usage events",
         "Core backend infrastructure; subject to Google's Privacy Policy"],
        ["Google Play Store",
         "App package, device hardware attestation",
         "App distribution and update delivery"],
    ]
)
add_body(doc, (
    "All third-party service providers are bound by their own data protection policies and are "
    "certified under international data protection standards. We require that they use your data "
    "only for the purposes specified and maintain appropriate security standards."
))

add_h1(doc, "5. Data Storage & Security")
add_h2(doc, "5.1 On-Device Storage")
add_body(doc, (
    "Sensitive personal information — specifically your name, phone number, city, state, and role — "
    "is stored on your device using AES-256 encrypted storage (FlutterSecureStorage). This means "
    "that even if your device is accessed by another person, the data cannot be read without "
    "your device's biometric or PIN unlock."
))
add_h2(doc, "5.2 Cloud Storage")
add_body(doc, (
    "Your order history, cart data, and Wholesaler session data are stored in Google Cloud Firestore, "
    "a highly secure, globally distributed database operated by Google Cloud. Data in transit between "
    "the App and Firebase is encrypted using TLS 1.3. Data at rest in Firestore and Firebase Storage "
    "is encrypted using AES-256."
))
add_h2(doc, "5.3 ADB Backup Disabled")
add_body(doc, (
    "The App has been configured to prevent Android Debug Bridge (ADB) backup of its local data. "
    "This means that the locally stored encrypted profile data cannot be extracted by connecting "
    "your device to a computer, even on a device that has USB debugging enabled."
))

add_h1(doc, "6. User Rights")
add_body(doc, (
    "You have the following rights with respect to your personal data held by Vishal Jewelers."
))
add_table(doc,
    headers=["Right", "How to Exercise"],
    rows=[
        ["Right to Access",    "Contact us to request a copy of your stored personal data"],
        ["Right to Rectify",   "Update your name, city, or state in the Profile screen"],
        ["Right to Delete",    "Contact us to request deletion of your account and all associated data"],
        ["Right to Object",    "Contact us to opt out of marketing notifications or analytics tracking"],
        ["Right to Portability","Contact us to receive your data in a structured, portable format"],
    ]
)

add_h1(doc, "7. Data Retention")
add_body(doc, (
    "Active account data is retained for as long as your account is active. If you request account "
    "deletion, all personal data will be deleted from Firebase Firestore within 30 days of the request. "
    "Order data may be retained for up to 7 years for accounting and legal compliance purposes, "
    "after which it is anonymised and stripped of personal identifiers. FCM tokens are automatically "
    "refreshed and old tokens are overwritten."
))

add_h1(doc, "8. Changes to This Policy")
add_body(doc, (
    "Vishal Jewelers may update this Privacy Policy from time to time. When we make material changes, "
    "you will be notified via a push notification. The 'Version' and 'Date' on the cover page of "
    "this document will reflect the most recent update. Continued use of the App after a policy "
    "update constitutes acceptance of the revised policy."
))

add_h1(doc, "9. Contact Information")
add_body(doc, (
    "For any queries, concerns, or requests related to this Privacy Policy or your personal data, "
    "please contact the Vishal Jewelers Data Protection Representative at the following address. "
    "We will respond to all valid requests within 30 business days."
))
add_body(doc, "Contact Name: [VISHAL JEWELERS DATA PROTECTION OFFICER]")
add_body(doc, "Email: [TO BE CONFIRMED BY CLIENT]")
add_body(doc, "Phone: [TO BE CONFIRMED BY CLIENT]")
add_body(doc, "Business Address: [TO BE CONFIRMED BY CLIENT]")

save(doc, OUT)
