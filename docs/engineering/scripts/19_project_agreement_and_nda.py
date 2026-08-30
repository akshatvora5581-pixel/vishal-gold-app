"""
19_project_agreement_and_nda.py
Project Agreement & Non-Disclosure Agreement — Vishal Jewelers App
Client: Savan Bhai Kondhia (Saar Data Services Pvt. Ltd.)
Developer: Akshat Vora (Engineering Delivery Team)
"""
import sys, os, datetime
sys.path.insert(0, os.path.dirname(__file__))
from doc_utils import *

OUT = os.path.join(os.path.dirname(__file__), "..", "client_delivery",
                   "19_Project_Agreement_And_NDA.docx")
os.makedirs(os.path.dirname(OUT), exist_ok=True)

TODAY      = datetime.date.today().strftime("%B %d, %Y")
DATE_SHORT = datetime.date.today().strftime("%d/%m/%Y")

CLIENT_NAME    = "Savan Bhai Kondhia"
CLIENT_COMPANY = "Saar Data Services Pvt. Ltd."
CLIENT_FULL    = f"{CLIENT_NAME} ({CLIENT_COMPANY})"
DEV_NAME       = "Akshat Vora"
DEV_COMPANY    = "Engineering Delivery Team"
PROJECT_NAME   = "Vishal Jewelers — B2B/B2C Jewelry Application (Android)"
TOTAL_COST     = "Rs. 26,000/- (Rupees Twenty-Six Thousand Only)"
AGREEMENT_NO   = "AGR-APP0152158-R1"

doc = new_document()

# ── COVER ──────────────────────────────────────────────────────────────────────
add_cover(doc,
    title        = "Project Agreement & Non-Disclosure Agreement",
    subtitle     = f"{PROJECT_NAME}",
    version      = "v1.0",
    date         = TODAY,
    prepared_for = CLIENT_FULL,
    prepared_by  = f"{DEV_NAME} | {DEV_COMPANY}",
)

# ── TABLE OF CONTENTS ──────────────────────────────────────────────────────────
add_toc_placeholder(doc, [
    ("Agreement Details & Parties",          3),
    ("Project Overview & Scope",             4),
    ("Functional Requirements",              5),
    ("Project Cost & Investment",            6),
    ("Payment Terms",                        7),
    ("Delivery Timeline",                    8),
    ("Change & Revision Policy",             9),
    ("Technical Architecture Summary",      10),
    ("Intellectual Property & Ownership",   11),
    ("Out-of-Scope Items",                  12),
    ("White-Label Customization Clause",    13),
    ("Reference Application Comparison",   14),
    ("Non-Disclosure Agreement (NDA)",      15),
    ("General Terms & Conditions",          17),
    ("Acceptance & Signatures",             18),
])

# ── 1. AGREEMENT DETAILS ──────────────────────────────────────────────────────
add_h1(doc, "1. Agreement Details & Parties")
add_body(doc, (
    "This Project Agreement and Non-Disclosure Agreement ('Agreement') is entered into as of "
    f"the date of signing between the following parties:"
))
add_table(doc,
    headers=["Field", "Details"],
    rows=[
        ["Agreement Number",     AGREEMENT_NO],
        ["Agreement Date",       DATE_SHORT],
        ["Project Title",        PROJECT_NAME],
        ["Client Name",          CLIENT_NAME],
        ["Client Company",       CLIENT_COMPANY],
        ["Developer / Vendor",   DEV_NAME],
        ["Development Firm",     DEV_COMPANY],
        ["Total Project Value",  TOTAL_COST],
        ["Estimated Duration",   "30 Working Days from advance payment and requirement confirmation"],
        ["Reference Quotation",  "Q No. APP0152158-R1 dated 28/01/2026"],
    ]
)
add_note(doc, "BINDING AGREEMENT",
    "By signing this document, both parties agree to be legally bound by all terms, "
    "clauses, and conditions stated herein. This document supersedes any prior verbal "
    "or written communications regarding the scope, cost, or delivery of this project.")

# ── 2. PROJECT OVERVIEW ───────────────────────────────────────────────────────
add_h1(doc, "2. Project Overview & Scope")
add_body(doc, (
    "This Agreement governs the end-to-end development of a custom-built Gold Jewellery "
    "Android Application ('the Application') for the Client. The development is aligned "
    "with the functional and UI structure of an existing reference application, while "
    "implementing client-specific requirements, features, and business logic as outlined "
    "in this document."
))
add_body(doc, (
    "The Application is engineered with a secure, scalable, and role-driven architecture, "
    "ensuring performance, reliability, and long-term maintainability. The codebase, "
    "authentication logic, and backend handling are entirely rebuilt from scratch — "
    "no proprietary code from the reference application is reused or redistributed."
))

add_h2(doc, "2.1 Scope of Work")
add_body(doc, "The following deliverables are included in this Agreement:")
add_numbered(doc, "Detailed requirement engineering and validation")
add_numbered(doc, "Premium UI/UX design aligned with gold jewellery business aesthetics and brand")
add_numbered(doc, "Native Android application development (Flutter framework)")
add_numbered(doc, "Firebase backend integration (Firestore, Firebase Auth, Firebase Storage, FCM)")
add_numbered(doc, "OTP-based authentication system for customers and wholesalers")
add_numbered(doc, "Email & Password authentication for admin users")
add_numbered(doc, "Role-Based Access Control (RBAC) — Customer, Wholesaler, Admin, Super Admin")
add_numbered(doc, "Full product catalog management system (categories, sub-categories, products, images)")
add_numbered(doc, "Admin dashboard with analytics, CRM hub, banner management, flash sale creator")
add_numbered(doc, "Push notification system via Firebase Cloud Messaging (FCM)")
add_numbered(doc, "Cart system with admin WhatsApp and FCM alerts on order placement")
add_numbered(doc, "Sample/custom order flow with image upload and real-time status tracking")
add_numbered(doc, "Design-to-Social promotional export tool")
add_numbered(doc, "Comprehensive QA, dynamic testing, and bug fixing")
add_numbered(doc, "Production-ready APK / AAB build delivery")
add_numbered(doc, "Complete source code handover (subject to full payment)")

# ── 3. FUNCTIONAL REQUIREMENTS ────────────────────────────────────────────────
add_h1(doc, "3. Functional Requirements")

add_h2(doc, "3.1 Super Admin / Admin Features")
add_body(doc, "The Super Admin and Admin will have control over the application including:")
add_bullet(doc, "Create and manage sub-admin accounts with granular permission flags")
add_bullet(doc, "Add, update, and delete products with multi-image support")
add_bullet(doc, "Add and manage Main Categories and Sub-Categories (with images and sort ordering)")
add_bullet(doc, "Upload, activate, deactivate, and reorder promotional banners")
add_bullet(doc, "Update live gold rate — visible to all customers in real-time")
add_bullet(doc, "Manage and update order status (Pending → In Progress → Completed / Cancelled)")
add_bullet(doc, "View and respond to sample orders with customer reference images")
add_bullet(doc, "Receive FCM push notification + Firestore DB notification when a customer places a cart order")
add_bullet(doc, "Send targeted push notifications to customer segments from CRM Hub or FCM Console")
add_bullet(doc, "Analytics dashboard — order volume, revenue trend, top categories, customer growth")
add_bullet(doc, "Immutable audit trail and audit log of all admin actions")
add_bullet(doc, "Flash Sale Creator — create time-bound discounts with optional push notifications")
add_bullet(doc, "Design-to-Social exporter for WhatsApp and Instagram promotions")
add_bullet(doc, "Admin Preview Mode — stage and preview changes before publishing to live catalog")

add_h2(doc, "3.2 User Roles & Authentication")
add_table(doc,
    headers=["Role", "Login Method", "Access Level"],
    rows=[
        ["CUSTOMER",    "Mobile Number + OTP",      "Customer app — retail pricing"],
        ["WHOLESALER",  "Mobile Number + OTP",      "Customer app — wholesale pricing + company profile"],
        ["ADMIN",       "Email + Password (Firebase)","Full Admin Panel"],
        ["SUPER_ADMIN", "Email + Password + optional 6-digit PIN",
         "Full Admin Panel + Sub-Admin Management"],
    ]
)

add_h2(doc, "3.3 Customer Application Features")
add_table(doc,
    headers=["Feature", "Description"],
    rows=[
        ["Home Screen",           "Animated banner carousel, category browsing, gold rate display, recent designs"],
        ["Global Search",         "Search across categories, sub-categories, and products by name or tag number"],
        ["Product Catalog",       "Responsive grid listing with skeleton loading, staggered animations, hero image"],
        ["Product Detail",        "Multi-image gallery with zoom, role-based pricing, Add to Cart, Place Sample Order"],
        ["Shopping Cart",         "Quantity controls, cart summary, Place Order with admin FCM + WhatsApp alert"],
        ["Sample Order Flow",     "Category/sub-cat selection, notes, reference image upload (gallery or Firestore product)"],
        ["Order History",         "Real-time order status tracking with colour-coded status badges"],
        ["Notifications Inbox",   "In-app notification centre with unread badge count and Mark All Read"],
        ["Upload Design",         "Wholesalers can upload new product designs (up to 4 images) for admin review"],
        ["Profile & Settings",    "Edit profile photo, name, company details; language, support, privacy policy"],
        ["Contact Us",            "Business contact details with direct WhatsApp launch button"],
    ]
)

# ── 4. PROJECT COST ───────────────────────────────────────────────────────────
add_h1(doc, "4. Project Cost & Investment")
add_body(doc, (
    "The total fixed cost agreed upon for the complete development, testing, and delivery of "
    "the Application as described in this Agreement is:"
))
add_table(doc,
    headers=["Description", "Amount (INR)"],
    rows=[
        ["Custom-built application architecture (not a generic template)",  "Included"],
        ["Firebase backend integration (Firestore, Auth, Storage, FCM)",    "Included"],
        ["Secure authentication and role management (RBAC)",                "Included"],
        ["Scalable backend-ready design",                                   "Included"],
        ["Business-grade UI/UX and performance optimization",               "Included"],
        ["Responsive layout for all Android screen sizes & tablets",        "Included"],
        ["QA, dynamic testing, and bug fixing",                             "Included"],
        ["Production APK / AAB build + source code delivery",               "Included"],
        ["TOTAL DEVELOPMENT INVESTMENT",                                    "Rs. 26,000/-"],
    ]
)
add_note(doc, "EXCLUSIONS",
    "The quoted amount excludes all third-party charges including but not limited to: "
    "Firebase Blaze plan upgrade, SMS gateway / OTP charges, Google Play Store developer "
    "account fees, domain/hosting costs, and any future maintenance or feature additions.")

# ── 5. PAYMENT TERMS ──────────────────────────────────────────────────────────
add_h1(doc, "5. Payment Terms")
add_table(doc,
    headers=["Milestone", "Amount", "Trigger"],
    rows=[
        ["Advance Payment (1st Instalment)",   "Rs. 13,000/-  (50%)",
         "Immediately upon signing this Agreement — before development begins"],
        ["Final Payment (2nd Instalment)",     "Rs. 13,000/-  (50%)",
         "Upon project completion and Client acceptance of the final build"],
        ["TOTAL",                              "Rs. 26,000/-", ""],
    ]
)
add_body(doc, (
    "Payment must be settled in full before final source code, APK/AAB build files, and "
    "Firebase project credentials are handed over to the Client. No partial deliveries of "
    "source code will be made until the full agreed amount is received. "
    "Payment terms may be mutually revised if agreed upon in writing by both parties."
))
add_note(doc, "DEFAULT",
    "If the Client delays any instalment by more than 14 calendar days without written "
    "notice, the Developer reserves the right to pause development. The timeline will "
    "be extended accordingly from the date payment is received.")

# ── 6. DELIVERY TIMELINE ──────────────────────────────────────────────────────
add_h1(doc, "6. Delivery Timeline")
add_body(doc, (
    "The estimated project duration is 30 working days from the date of advance payment "
    "receipt and final requirement confirmation from the Client."
))
add_table(doc,
    headers=["Phase", "Duration", "Activities"],
    rows=[
        ["Phase 1 — Requirement Gathering",     "5 working days",
         "Final requirements validation, architecture planning, environment setup"],
        ["Phase 2 — UI/UX & Frontend Development", "10 working days",
         "Screen-by-screen UI build, navigation, component library, responsive layouts"],
        ["Phase 3 — Backend & Feature Development", "10 working days",
         "Firebase integration, RBAC, product management, orders, notifications, CRM"],
        ["Phase 4 — QA, Testing & Bug Fixes",   "5 working days",
         "Dynamic testing across devices, performance checks, bug fixes, final build"],
        ["TOTAL",                               "30 working days", ""],
    ]
)
add_note(doc, "TIMELINE CONDITIONS",
    "The timeline commences only after: (a) the advance payment is received in full, and "
    "(b) all initial requirements are confirmed in writing. Delays caused by late Client "
    "feedback, content submission, or approval sign-offs will extend the timeline by the "
    "equivalent number of delayed days.")

# ── 7. CHANGE & REVISION POLICY ───────────────────────────────────────────────
add_h1(doc, "7. Change & Revision Policy")
add_table(doc,
    headers=["Change Window", "Allowance", "Cost"],
    rows=[
        ["During Development",   "Scope changes acknowledged — may impact timeline", "Assessed per change"],
        ["1st Draft Review",     "Feedback collected after first working demo",       "Included"],
        ["Post-Final Delivery (Changes 1–5)", "Up to 5 changes free of charge",      "Free"],
        ["Post-Final Delivery (Change 6+)",   "Each additional change beyond 5",     "Rs. 300/- per change"],
    ]
)
add_body(doc, (
    "A 'change' is defined as any modification, addition, or removal that goes beyond "
    "the approved scope outlined in this Agreement. Minor text edits or colour adjustments "
    "within the same screen are not counted as changes. Any change that requires new screens, "
    "new features, or backend logic changes will be treated as a separate work item and "
    "quoted independently."
))

# ── 8. TECHNICAL ARCHITECTURE ─────────────────────────────────────────────────
add_h1(doc, "8. Technical Architecture Summary")
add_table(doc,
    headers=["Layer", "Technology / Component", "Purpose"],
    rows=[
        ["Frontend",           "Flutter (Dart)",          "Cross-platform UI — Android focus; tablet-responsive layouts"],
        ["State Management",   "Provider",                "Reactive state handling across all screens"],
        ["Database",           "Cloud Firestore",         "NoSQL document store for all application data"],
        ["Authentication",     "Firebase Auth",           "OTP phone auth + Email/Password admin auth"],
        ["File Storage",       "Firebase Storage",        "Product images, banners, profile photos, order reference images"],
        ["Push Notifications", "Firebase Cloud Messaging","Targeted push notifications to customer segments and admin"],
        ["Analytics",          "Firebase Analytics",      "User behaviour, conversion funnel, business KPI tracking"],
        ["Audit Logging",      "Cloud Firestore",         "Immutable admin action log in 'audit_logs' collection"],
        ["Local Security",     "flutter_secure_storage",  "Device-local encrypted storage for admin Quick Login PIN"],
        ["External Messaging", "WhatsApp deep-link",      "Admin alerts on new orders; customer contact from orders"],
        ["Image Handling",     "image_picker + cached_network_image", "Device gallery pick + cached display for performance"],
    ]
)

# ── 9. IP & OWNERSHIP ─────────────────────────────────────────────────────────
add_h1(doc, "9. Intellectual Property & Ownership")
add_h2(doc, "9.1 Client Ownership")
add_body(doc, (
    "Upon receipt of full and final payment, the Client shall receive complete ownership "
    "of the custom-developed application including: full source code, production APK/AAB builds, "
    "Firebase project configuration, and all associated digital assets created during development."
))
add_h2(doc, "9.2 Developer Rights")
add_body(doc, (
    "The Developer retains the right to reference this project as portfolio work (without "
    "disclosing proprietary business logic or Client data) unless the Client requests "
    "otherwise in writing. The Developer retains ownership of generic utility libraries, "
    "design systems, or internal tools that may have been used during development but are "
    "not specific to this project."
))
add_h2(doc, "9.3 Reference Application Disclaimer")
add_body(doc, (
    "The reference application used for functional alignment is used strictly for "
    "structural and UI reference purposes only. No proprietary source code, assets, "
    "or intellectual property from any third-party application has been reused. "
    "All code produced under this Agreement is independently authored."
))
add_body(doc, (
    "Any legal responsibility arising from brand similarity, trademark usage, Play Store "
    "listing compliance, or third-party claims related to visual similarity lies solely "
    "with the Client."
))

# ── 10. OUT-OF-SCOPE ──────────────────────────────────────────────────────────
add_h1(doc, "10. Out-of-Scope Items")
add_body(doc, (
    "The following items are explicitly excluded from this Agreement. Any of these may be "
    "added as a separate engagement with its own quotation and timeline:"
))
add_table(doc,
    headers=["Item", "Status"],
    rows=[
        ["iOS (Apple) application development",                           "OUT OF SCOPE"],
        ["Web admin panel or website development",                        "OUT OF SCOPE"],
        ["Hosting, server setup, or cloud infrastructure provisioning",   "OUT OF SCOPE"],
        ["Firebase Blaze plan upgrade costs (if usage exceeds free tier)","OUT OF SCOPE"],
        ["SMS gateway, OTP charges, or third-party API subscription fees","OUT OF SCOPE"],
        ["Google Play Store developer account creation or listing fees",  "OUT OF SCOPE"],
        ["Play Store submission, approval management, or ASO",            "OUT OF SCOPE"],
        ["Post-launch maintenance, monitoring, or bug fixes after handover","OUT OF SCOPE"],
        ["Future feature additions not defined in this Agreement",        "OUT OF SCOPE"],
        ["Marketing, advertising, or user acquisition activities",        "OUT OF SCOPE"],
    ]
)

# ── 11. WHITE-LABEL CLAUSE ────────────────────────────────────────────────────
add_h1(doc, "11. White-Label Customization Clause")
add_body(doc, (
    "If, in the future, the Client requires this application to be customized and rebranded "
    "for their own downstream customers or business partners, the following pricing applies:"
))
add_table(doc,
    headers=["Customization Type", "Included", "Fee"],
    rows=[
        ["Application name change",                      "Yes", "Rs. 1,500/- flat"],
        ["App icon / splash screen branding update",     "Yes", "Rs. 1,500/- flat"],
        ["Colour theme / brand colour adjustment",       "Yes", "Rs. 1,500/- flat"],
        ["Functional changes or new features",           "No",  "Separate quotation required"],
        ["Workflow modifications or new screens",        "No",  "Separate quotation required"],
        ["Backend logic changes",                        "No",  "Separate quotation required"],
    ]
)
add_body(doc, (
    "Each white-label instance is charged independently. The Rs. 1,500/- fee covers "
    "only the three branding elements listed above. Any scope beyond this requires a "
    "new Agreement and timeline assessment."
))

# ── 12. REFERENCE COMPARISON ──────────────────────────────────────────────────
add_h1(doc, "12. Reference Application Comparison")
add_table(doc,
    headers=["Aspect", "Reference Application", "Vishal Jewelers Application (This Project)"],
    rows=[
        ["Platform",           "Android",                    "Android (Flutter — future iOS ready)"],
        ["UI / UX Flow",       "Existing production design", "Custom redesign — dark glassmorphism gold theme"],
        ["Authentication",     "Mobile-based login",         "OTP (customers) + Email/Password (admins)"],
        ["User Roles",         "Admin / Users",              "Super Admin / Admin / Wholesaler / Customer"],
        ["Access Control",     "App-defined",                "Full RBAC with granular permission flags"],
        ["Product Management", "Available",                  "Full CRUD with multi-image, wholesale pricing, gold rate"],
        ["Category Structure", "Main & Sub Categories",      "Categories + Sub-Categories with images and sort order"],
        ["Pricing Management", "Available",                  "Retail + Wholesale pricing; gold rate live update"],
        ["Stock Notifications","Available",                  "Flash Sale creator + FCM push to segments"],
        ["Cart to Admin Alerts","Limited / App-specific",    "FCM push + Firestore DB notification + WhatsApp alert"],
        ["Analytics",          "Unknown",                    "Full Analytics Dashboard (fl_chart)"],
        ["Audit Trail",        "Not present",                "Immutable audit log for all admin actions"],
        ["CRM",                "Not present",                "CRM Hub with 5 customer segments + push targeting"],
        ["Codebase",           "Proprietary (reference only)","Fresh, custom-built — client receives full source code"],
        ["Scalability",        "Unknown",                    "Firebase backend — scales to web admin and iOS in future"],
    ]
)

# ── 13. NDA ────────────────────────────────────────────────────────────────────
add_h1(doc, "13. Non-Disclosure Agreement (NDA)")
add_body(doc, (
    "This Non-Disclosure Agreement is entered into between the Developer and the Client "
    "as named in Section 1 of this document ('the Parties'). By signing this Agreement, "
    "both parties commit to the confidentiality obligations stated below."
))

add_h2(doc, "13.1 Definition of Confidential Information")
add_body(doc, (
    "For the purposes of this NDA, 'Confidential Information' means any non-public "
    "information disclosed by either party to the other, whether orally, in writing, "
    "digitally, or by any other means, which is designated as confidential or which "
    "reasonably should be understood to be confidential given the nature of the "
    "information and the circumstances of disclosure. This includes but is not limited to:"
))
add_bullet(doc, "Business plans, pricing strategies, and financial information")
add_bullet(doc, "Customer data, user lists, and business contacts")
add_bullet(doc, "Application source code, architecture decisions, and technical specifications")
add_bullet(doc, "Firebase credentials, API keys, and service account configurations")
add_bullet(doc, "Product catalog data, pricing structures, and inventory details")
add_bullet(doc, "Marketing strategies, promotional content, and business processes")
add_bullet(doc, "Any information marked 'Confidential' or communicated in a confidential context")

add_h2(doc, "13.2 Obligations of the Receiving Party")
add_body(doc, (
    "Each party agrees that they shall:"
))
add_numbered(doc, "Keep all Confidential Information strictly confidential using at least the same degree of care used to protect their own confidential information, but in no event less than reasonable care.")
add_numbered(doc, "Not disclose, publish, or share any Confidential Information with any third party without the prior written consent of the disclosing party.")
add_numbered(doc, "Use the Confidential Information solely for the purposes of fulfilling their obligations under this Project Agreement.")
add_numbered(doc, "Limit access to Confidential Information to employees, contractors, or advisors who have a strict need to know and who are bound by written confidentiality obligations no less protective than those in this Agreement.")
add_numbered(doc, "Promptly notify the disclosing party in writing upon discovery of any unauthorized use, disclosure, or breach of this NDA.")

add_h2(doc, "13.3 Exceptions")
add_body(doc, (
    "The obligations under Section 13.2 shall not apply to information that:"
))
add_bullet(doc, "Is or becomes publicly available through no fault of the receiving party;")
add_bullet(doc, "Was known by the receiving party prior to disclosure, as evidenced by written records;")
add_bullet(doc, "Is independently developed by the receiving party without use of the Confidential Information;")
add_bullet(doc, "Is lawfully received from a third party without restriction on disclosure;")
add_bullet(doc, "Is required to be disclosed by applicable law, court order, or government authority — in which case the receiving party shall give prompt written notice to allow the disclosing party to seek a protective order.")

add_h2(doc, "13.4 Developer Confidentiality Obligations")
add_body(doc, (
    "The Developer specifically undertakes to:"
))
add_bullet(doc, "Keep all Client business data, Firestore data, and credentials strictly confidential during and after development.")
add_bullet(doc, "Not access, copy, or retain any Client Firebase project data after full handover.")
add_bullet(doc, "Not share Client's customer lists, order data, wholesaler details, or pricing information with any third party.")
add_bullet(doc, "Not develop a competing application for any other gold jewellery business in the same geographic market using knowledge gained from this project, for a period of 12 months from the handover date.")
add_bullet(doc, "Delete all copies of Client credentials, API keys, and project files from Developer systems within 30 days of final handover.")

add_h2(doc, "13.5 Client Confidentiality Obligations")
add_body(doc, (
    "The Client specifically undertakes to:"
))
add_bullet(doc, "Not share, sell, resell, or sublicense the application source code to any third party without prior written consent from the Developer.")
add_bullet(doc, "Not reverse-engineer or decompile the application to extract proprietary logic for use in competing products.")
add_bullet(doc, "Keep any proprietary development methodologies, pricing formulas, or technical architecture details shared by the Developer confidential.")
add_bullet(doc, "Ensure all employees or agents given access to developer-provided materials (design files, source code, credentials) are bound by equivalent confidentiality obligations.")

add_h2(doc, "13.6 Duration of NDA")
add_body(doc, (
    "The confidentiality obligations under this Section 13 shall remain in full force and "
    "effect for a period of THREE (3) YEARS from the date of signing, unless extended "
    "by mutual written agreement. Obligations relating to trade secrets shall continue "
    "indefinitely until the information is no longer trade secret in nature."
))

add_h2(doc, "13.7 Remedies for Breach")
add_body(doc, (
    "Both parties acknowledge that a breach of this NDA would cause irreparable harm "
    "for which monetary damages would be an inadequate remedy. In the event of a breach "
    "or threatened breach, the injured party shall be entitled to seek immediate injunctive "
    "relief in addition to any other remedies available at law or in equity. "
    "The breaching party shall be liable for all damages, costs, and legal fees incurred "
    "by the injured party as a result of the breach."
))

# ── 14. GENERAL TERMS & CONDITIONS ────────────────────────────────────────────
add_h1(doc, "14. General Terms & Conditions")
add_numbered(doc, "This Agreement constitutes the entire understanding between the parties and supersedes all prior discussions, quotations, and communications.")
add_numbered(doc, "Any modifications to this Agreement must be made in writing and signed by both parties to be effective.")
add_numbered(doc, "The Developer is not responsible for Google Play Store approval, rejection, or policy changes affecting the Client's account.")
add_numbered(doc, "Maintenance, post-launch support, and future feature additions are not included unless agreed separately in a new written engagement.")
add_numbered(doc, "This Agreement shall be governed by and construed in accordance with the laws of India. Any disputes shall be subject to the exclusive jurisdiction of the courts in the Developer's city of operation.")
add_numbered(doc, "If any provision of this Agreement is found to be unenforceable, the remaining provisions shall continue in full force and effect.")
add_numbered(doc, "Force majeure: Neither party shall be held liable for delay or failure to perform due to causes beyond reasonable control (natural disasters, government actions, widespread technical outages).")
add_numbered(doc, f"This Quotation and Agreement was originally issued on 28/01/2026 (Quotation No. APP0152158-R1) and remains valid. Agreement execution date: {DATE_SHORT}.")
add_numbered(doc, "The Developer reserves the right to display this project as a portfolio reference unless the Client requests otherwise in writing within 30 days of project handover.")
add_numbered(doc, "All notices under this Agreement shall be served via email to the addresses provided by both parties at the time of signing.")

# ── 15. ACCEPTANCE & SIGNATURES ───────────────────────────────────────────────
add_h1(doc, "15. Acceptance & Signatures")
add_body(doc, (
    "By signing below, both parties confirm that they have read, understood, and agree "
    "to be bound by all terms, conditions, and obligations set forth in this Project "
    "Agreement and Non-Disclosure Agreement."
))
add_note(doc, "IMPORTANT",
    "This Agreement becomes legally binding only upon signature by both parties. "
    "No work will commence and no advance payment will be requested until this "
    "document is executed by both parties.")

add_signature_block(doc, [
    (f"Client — {CLIENT_NAME}",     CLIENT_COMPANY),
    (f"Developer — {DEV_NAME}",     DEV_COMPANY),
])

save(doc, OUT)
