"""
04_credentials_handover.py — Infrastructure & Credentials Handover Document
"""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from doc_utils import *

OUT = os.path.join(os.path.dirname(__file__), "..", "client_delivery",
                   "04_Credentials_And_Infrastructure_Handover.docx")
os.makedirs(os.path.dirname(OUT), exist_ok=True)

doc = new_document()

add_cover(doc,
    title    = "Credentials & Infrastructure Handover",
    subtitle = "Vishal Gold App — Technical Asset Transfer Document",
    version  = "v1.0",
    prepared_for = "Vishal Gold IT / Management",
    prepared_by  = "Engineering Delivery Team"
)

add_toc_placeholder(doc, [
    ("Purpose & Confidentiality", 3),
    ("Firebase Project Overview", 4),
    ("Account & Access Transfers", 5),
    ("Android Signing Keystore", 6),
    ("Source Code Repository", 7),
    ("Third-Party Services Summary", 8),
    ("Post-Transfer Action Checklist", 9),
    ("Authorization & Sign-Off", 10),
])

# ── 1. Purpose ────────────────────────────────────────────────────────────────
add_h1(doc, "1. Purpose & Confidentiality")
add_body(doc, (
    "This document serves as the formal record of all technical assets, credentials, and "
    "infrastructure configurations transferred from the Engineering Delivery Team to the client, "
    "Vishal Gold, upon project completion. It is intended to be handled as a highly confidential "
    "document, shared only with designated technical and management personnel at Vishal Gold."
))
add_note(doc, "CONFIDENTIALITY WARNING",
    "This document must not be stored in public cloud drives, shared via unencrypted email, "
    "or disclosed to any third party. It should be securely stored in a password-protected "
    "location. The Engineering team strongly recommends transferring credentials through a "
    "password manager rather than maintaining them in document form.")
add_body(doc, (
    "Upon completion of the handover, the Engineering team will revoke its own access to all "
    "project systems. The client will be the sole owner of all described assets from that point forward."
))

# ── 2. Firebase Project Overview ──────────────────────────────────────────────
add_h1(doc, "2. Firebase Project Overview")
add_body(doc, (
    "The Vishal Gold application is built on Google Firebase, a managed backend-as-a-service "
    "platform. The following Firebase services are active in the project and are critical to "
    "the application's operation."
))
add_table(doc,
    headers=["Firebase Service", "Purpose", "Current Plan"],
    rows=[
        ["Firebase Authentication",   "User login via OTP and admin email/password", "Spark (Free)"],
        ["Cloud Firestore",            "Primary NoSQL database for all app data",     "Spark (Free)"],
        ["Firebase Storage",           "Product images and sample order attachments", "Spark (Free)"],
        ["Firebase Cloud Messaging",   "Push notifications to users",                 "Free"],
        ["Firebase Analytics",         "User behavior tracking and crash reporting",  "Free"],
    ]
)
add_body(doc, (
    "The Spark (free) plan has usage quotas. As the user base grows, an upgrade to the Blaze "
    "(pay-as-you-go) plan will be required. Please refer to the Scalability & Cost Projection "
    "document for detailed thresholds and estimated costs."
))

# ── 3. Account & Access Transfers ─────────────────────────────────────────────
add_h1(doc, "3. Account & Access Transfers")
add_h2(doc, "3.1 Firebase Console Access")
add_body(doc, (
    "Firebase project ownership will be transferred to the client's Google Account. The following "
    "steps describe the transfer process, which must be completed by the Engineering team in "
    "coordination with the client's designated IT contact."
))
add_numbered(doc, "The client provides the Gmail address that will become the Project Owner.")
add_numbered(doc, "The Engineering team navigates to Firebase Console → Project Settings → Users and Permissions.")
add_numbered(doc, "The client's Gmail address is added as a new member with the 'Owner' role.")
add_numbered(doc, "The client accepts the invitation via email.")
add_numbered(doc, "The Engineering team removes itself from project access.")

add_h2(doc, "3.2 Google Play Console")
add_body(doc, (
    "If the application is to be published on the Google Play Store, the client must have an "
    "active Google Play Developer account (one-time registration fee: USD 25). The signed Android "
    "app bundle (AAB) file will be provided by the Engineering team for the client to upload. "
    "The Play Console account is set up entirely by the client — the Engineering team does not "
    "have access to the client's Play Console unless explicitly granted."
))

add_h2(doc, "3.3 GitHub Repository")
add_body(doc, (
    "The complete Flutter source code is maintained in a private GitHub repository. Repository "
    "access will be transferred by inviting the client's GitHub account as a repository owner "
    "or by transferring the repository to the client's GitHub organization."
))
add_table(doc,
    headers=["Action", "Responsible Party"],
    rows=[
        ["Provide client GitHub username/org name",  "Client"],
        ["Transfer repository ownership",             "Engineering Team"],
        ["Verify client access",                      "Client"],
        ["Remove Engineering team access (optional)", "Client / Engineering Team"],
    ]
)

# ── 4. Android Signing Keystore ───────────────────────────────────────────────
add_h1(doc, "4. Android Signing Keystore")
add_body(doc, (
    "Every Android application must be digitally signed with a unique cryptographic keystore to "
    "be published on the Google Play Store. The signing keystore generated for the Vishal Gold "
    "application is a critical asset and must be preserved with the utmost care. Loss of this "
    "keystore means the application can never be updated on the Play Store under the same "
    "package identity."
))
add_table(doc,
    headers=["Keystore Attribute", "Value"],
    rows=[
        ["File Name",      "vishal_gold_release.jks"],
        ["Key Alias",      "[TO BE PROVIDED SECURELY]"],
        ["Store Password", "[TO BE PROVIDED SECURELY]"],
        ["Key Password",   "[TO BE PROVIDED SECURELY]"],
        ["Validity",       "25 years from date of generation"],
    ]
)
add_note(doc, "CRITICAL",
    "Store the keystore file and all associated passwords in a secure, backed-up location such as "
    "a hardware key vault or an enterprise password manager. Never commit this file to a version "
    "control system. If the keystore is lost, the app cannot be updated on Play Store and a new "
    "package identifier will be required.")

# ── 5. Source Code Repository ─────────────────────────────────────────────────
add_h1(doc, "5. Source Code Repository")
add_table(doc,
    headers=["Attribute", "Detail"],
    rows=[
        ["Platform",      "GitHub (private repository)"],
        ["Repository URL","[TO BE PROVIDED]"],
        ["Primary Branch","main"],
        ["Flutter Version","3.32.0 (pinned)"],
        ["Dart SDK",      "^3.9.2"],
    ]
)
add_body(doc, (
    "The repository includes the complete Flutter source code, all asset files, the engineering "
    "documentation folder, and the Android native project files. It does not include "
    "google-services.json (which must be placed manually per the Developer Guide) or the "
    "signing keystore (provided separately). A full README.md is present at the root of the "
    "repository with setup instructions."
))

# ── 6. Third-Party Services ───────────────────────────────────────────────────
add_h1(doc, "6. Third-Party Services Summary")
add_table(doc,
    headers=["Service", "Used For", "Account Owner", "Free Tier Limit"],
    rows=[
        ["Firebase (Google)",  "Full backend",                   "To be transferred", "See Firebase Pricing"],
        ["Google Play Console","App distribution",               "Client",            "USD 25 one-time"],
        ["Google Fonts",       "Typography (CDN, no account)",   "N/A — Public CDN",  "Unlimited"],
        ["GitHub",             "Source code hosting",            "To be transferred", "Private repos free"],
    ]
)

# ── 7. Post-Transfer Checklist ────────────────────────────────────────────────
add_h1(doc, "7. Post-Transfer Action Checklist")
add_body(doc, (
    "Once the formal handover is complete, the client's designated IT/technical contact must "
    "complete the following actions to fully secure and activate ownership of the project."
))
add_numbered(doc, "Accept Firebase project owner invitation and verify console access.")
add_numbered(doc, "Store the signing keystore file and passwords in a secure password manager.")
add_numbered(doc, "Download google-services.json from the Firebase Console and store securely (do not commit to git).")
add_numbered(doc, "Verify GitHub repository access and clone the source code successfully.")
add_numbered(doc, "Rotate the Firebase API keys if they were ever exposed in version control (see VAPT-007).")
add_numbered(doc, "Deploy Firestore security rules from the VAPT_Report_After.md document.")
add_numbered(doc, "Upgrade Firebase plan to Blaze before launching to production users (to avoid quota blocks).")
add_numbered(doc, "Create a Google Play Developer account and upload the provided AAB for Play Store submission.")

add_signature_block(doc, [
    ("Client IT Representative",  "Vishal Gold"),
    ("Delivery Engineer",         "Engineering Delivery Team"),
])

save(doc, OUT)
