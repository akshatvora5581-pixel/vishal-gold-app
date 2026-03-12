"""
11_play_store_checklist.py — Play Store Submission Checklist
"""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from doc_utils import *

OUT = os.path.join(os.path.dirname(__file__), "..", "client_delivery",
                   "11_Play_Store_Submission_Checklist.docx")
os.makedirs(os.path.dirname(OUT), exist_ok=True)

doc = new_document()

add_cover(doc,
    title    = "Play Store Submission Checklist",
    subtitle = "Vishal Gold App — Pre-Submission Compliance & Readiness Checklist",
    version  = "v1.0",
    prepared_for = "Vishal Gold Marketing & IT Team",
    prepared_by  = "Engineering Delivery Team"
)

add_toc_placeholder(doc, [
    ("Overview", 3),
    ("Pre-Submission Technical Checks", 4),
    ("Play Console Account Setup", 5),
    ("Store Listing Requirements", 6),
    ("Content Rating & Policy Compliance", 7),
    ("Privacy Policy Requirements", 8),
    ("Data Safety Section", 9),
    ("Final Submission Steps", 10),
])

add_h1(doc, "1. Overview")
add_body(doc, (
    "This checklist is designed to guide the Vishal Gold team through the complete process of "
    "preparing and submitting the Vishal Gold Android application to the Google Play Store. "
    "Each section must be completed in full before proceeding to the final submission step. "
    "Google Play has rigorous review criteria, and an incomplete or non-compliant submission "
    "may result in rejection, delaying the application's availability to users."
))
add_body(doc, (
    "The checklist is organized in the recommended sequential order of completion. Mark each "
    "item as complete before advancing to the next section. Where items are interdependent, "
    "this is noted clearly."
))
add_note(doc, "Time Estimate",
    "Allow 2–3 business days for Google Play's first-time review. Store listing assets "
    "(screenshots, icon, description) should be prepared by the marketing team minimum one "
    "week before the intended submission date.")

add_h1(doc, "2. Pre-Submission Technical Checks")
add_h2(doc, "2.1 Build Verification")
add_table(doc,
    headers=["#", "Check Item", "How to Verify", "Status"],
    rows=[
        ["1", "Release AAB generated without errors",
         "'flutter build appbundle --release' completes with 0 errors", "[ ]"],
        ["2", "AAB signed with production keystore",
         "Run 'keytool -printcert -jarfile app-release.aab' and verify alias",  "[ ]"],
        ["3", "google-services.json included in build",
         "Confirm file is in android/app/ before building",                      "[ ]"],
        ["4", "Version code incremented from previous release",
         "Check versionCode in android/app/build.gradle",                        "[ ]"],
        ["5", "Version name reflects release (e.g., '1.0.0')",
         "Check versionName in android/app/build.gradle",                        "[ ]"],
        ["6", "App does not requestlegacy WRITE_EXTERNAL_STORAGE",
         "Search AndroidManifest.xml; remove if found",                          "[ ]"],
        ["7", "Minimum SDK set to API 21 (Android 5.0) or higher",
         "Check minSdkVersion in android/app/build.gradle",                      "[ ]"],
        ["8", "Target SDK set to API 34 (Android 14)",
         "Check targetSdkVersion in android/app/build.gradle",                   "[ ]"],
        ["9", "Release APK tested on physical device (smoke test passed)",
         "Install and verify all primary flows per Deployment Guide Section 9",  "[ ]"],
        ["10","'flutter analyze' returns 0 errors",
         "Run 'flutter analyze' in project root",                                 "[ ]"],
    ]
)

add_h2(doc, "2.2 Security Pre-checks")
add_table(doc,
    headers=["#", "Security Item", "Status"],
    rows=[
        ["11","Firestore security rules deployed to Firebase Console",  "[ ]"],
        ["12","Firebase API key rotated (if previously exposed in git)","[ ]"],
        ["13","google-services.json added to .gitignore",              "[ ]"],
        ["14","No hardcoded API keys or secrets in codebase",          "[ ]"],
    ]
)

add_h1(doc, "3. Play Console Account Setup")
add_table(doc,
    headers=["#", "Account Setup Item", "Notes", "Status"],
    rows=[
        ["15","Google Play Developer account created",
         "One-time USD 25 registration fee at play.google.com/console", "[ ]"],
        ["16","Developer account identity verified",
         "Google requires real name and payment method verification",    "[ ]"],
        ["17","App created in Play Console with correct package name",
         "Package name: com.vishalgold.app (confirm with Engineering)",  "[ ]"],
        ["18","Correct app type selected: App (not Game)",
         "Select in 'Create app' wizard",                               "[ ]"],
        ["19","Default language set to English (India)",
         "Can add regional languages later",                            "[ ]"],
    ]
)

add_h1(doc, "4. Store Listing Requirements")
add_h2(doc, "4.1 Visual Assets")
add_body(doc, (
    "All visual assets must be prepared by the client's marketing or design team and uploaded "
    "to the Play Console store listing editor. The specifications below are mandatory — assets "
    "not meeting these specifications will be rejected by Google Play."
))
add_table(doc,
    headers=["Asset", "Specification", "Supplied By", "Status"],
    rows=[
        ["App Icon",
         "512×512 px, 32-bit PNG with alpha; no rounded corners (Google adds them)",
         "Marketing / Engineering", "[ ]"],
        ["Feature Graphic",
         "1024×500 px, JPG or 24-bit PNG; no alpha; used as Play Store banner",
         "Marketing Team", "[ ]"],
        ["Phone Screenshots (min. 2, max. 8)",
         "Between 320 and 3840 px on shortest side; JPG or 24-bit PNG",
         "Engineering / Marketing", "[ ]"],
        ["Short Description",
         "Up to 80 characters; plain text only",
         "Marketing Team", "[ ]"],
        ["Full Description",
         "Up to 4000 characters; HTML formatting supported; include key features",
         "Marketing Team", "[ ]"],
    ]
)

add_h2(doc, "4.2 Screenshot Recommendations")
add_body(doc, (
    "Ensure screenshots cover the following key user flows to maximize conversion on the "
    "Play Store listing: (1) Home / Product Catalog, (2) Product Detail with image viewer, "
    "(3) Cart screen, (4) OTP authentication, (5) Order History timeline. "
    "Avoid using emulator screenshots — use a real flagship Android device."
))

add_h1(doc, "5. Content Rating & Policy Compliance")
add_table(doc,
    headers=["#", "Policy Item", "Expected Rating / Action", "Status"],
    rows=[
        ["20","Complete content rating questionnaire in Play Console",
         "Expected: Everyone — IARC rating for a commerce/shopping app", "[ ]"],
        ["21","Confirm app does not contain adult/gambling/dangerous content",
         "Not applicable to Vishal Gold — jewelry commerce app",        "[ ]"],
        ["22","Confirm app requests only necessary permissions",
         "Only SMS (OTP) and POST_NOTIFICATIONS are required",          "[ ]"],
        ["23","No advertisements (AdMob or third-party) in the app",
         "Confirm no ad SDKs; select 'No ads' in Play Console",         "[ ]"],
    ]
)

add_h1(doc, "6. Privacy Policy Requirements")
add_body(doc, (
    "Google Play requires all apps that collect personal data to link to a publicly accessible "
    "Privacy Policy. The Privacy Policy provided in Document #08 of this delivery package "
    "must be published on a public web page (e.g., the Vishal Gold website or a hosted "
    "Google Doc) before submission."
))
add_table(doc,
    headers=["#", "Item", "Status"],
    rows=[
        ["24","Privacy Policy published at a public URL",                  "[ ]"],
        ["25","Privacy Policy URL entered in Play Console Store Listing",  "[ ]"],
        ["26","Privacy Policy URL also entered in App Content section",    "[ ]"],
    ]
)

add_h1(doc, "7. Data Safety Section")
add_body(doc, (
    "Google Play's Data Safety section requires the publisher to declare all types of data "
    "the app collects, shares, and how it is protected. This information is displayed on the "
    "app's Play Store listing and is mandatory from Android 13 target builds onwards. "
    "The following declarations should be made in the Play Console Data Safety form."
))
add_table(doc,
    headers=["Data Type", "Collected?", "Shared?", "Encrypted?", "Optional?"],
    rows=[
        ["Phone number",        "Yes", "No",  "Yes (in transit)", "No"],
        ["Name",                "Yes", "No",  "Yes",              "No"],
        ["Device / Other IDs",  "Yes", "No",  "Yes (in transit)", "No"],
        ["In-app purchase data","No",  "No",  "N/A",              "N/A"],
        ["Photos / Videos",     "Yes (sample orders only)", "No", "Yes", "Yes"],
        ["App activity (crash logs)", "Yes", "No", "Yes",          "No"],
    ]
)
add_table(doc,
    headers=["#", "Item", "Status"],
    rows=[
        ["27","Data Safety section completed in Play Console", "[ ]"],
        ["28","All data types declared accurately",            "[ ]"],
        ["29","Privacy Policy URL linked in Data Safety form", "[ ]"],
    ]
)

add_h1(doc, "8. Final Submission Steps")
add_body(doc, "Complete all checklist items above, then follow these final submission steps.")
add_table(doc,
    headers=["#", "Step", "Notes", "Status"],
    rows=[
        ["30","Upload AAB to Play Console → Production → New Release", "Ensure AAB, not APK",    "[ ]"],
        ["31","Enter release name and release notes",
         "Example: '1.0.0 — Initial Release: Vishal Gold App'",                               "[ ]"],
        ["32","Review pre-launch report in Play Console",
         "Google Play automatically runs basic security scans — fix any Critical warnings",   "[ ]"],
        ["33","Submit for review",
         "First-time reviews take 1–3 business days; resubmissions are faster",              "[ ]"],
        ["34","Monitor Play Console for review status and respond to any policy queries",
         "Google may request additional information via email",                               "[ ]"],
        ["35","Perform post-publish smoke test on Play Store build",
         "Install from Play Store and complete flows per Deployment Guide Section 7",         "[ ]"],
    ]
)

add_note(doc, "Post-Submission",
    "Do not delete the signing keystore after submission. Every future update to the app "
    "must be signed with the same keystore. Google Play permanently links the app's identity "
    "to this key.")

save(doc, OUT)
