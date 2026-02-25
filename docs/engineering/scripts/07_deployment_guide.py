"""
07_deployment_guide.py — Deployment Guide
"""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from doc_utils import *

OUT = os.path.join(os.path.dirname(__file__), "..", "client_delivery",
                   "07_Deployment_Guide.docx")
os.makedirs(os.path.dirname(OUT), exist_ok=True)

doc = new_document()

add_cover(doc,
    title    = "Deployment Guide",
    subtitle = "Vishal Gold App — Build, Sign, and Play Store Submission",
    version  = "v1.0",
    prepared_for = "Vishal Gold Technical Team",
    prepared_by  = "Engineering Delivery Team"
)

add_toc_placeholder(doc, [
    ("Prerequisites", 3),
    ("Environment Preparation", 4),
    ("Building the Release APK/AAB", 5),
    ("Signing the Application", 6),
    ("Firebase Rules Deployment", 7),
    ("Google Play Store Submission", 8),
    ("Post-Deployment Verification", 9),
    ("Rollback Procedure", 10),
])

add_h1(doc, "1. Prerequisites")
add_body(doc, (
    "Before beginning the deployment process, ensure the following resources are available and "
    "in a confirmed, verified state. Attempting to deploy without all prerequisites in place "
    "can result in a failed submission, a mis-signed build, or an application that cannot "
    "connect to the Firebase backend."
))
add_table(doc,
    headers=["Prerequisite", "Description", "Where to Find It"],
    rows=[
        ["Flutter SDK (3.32+)",   "Installed and on system PATH",           "flutter.dev"],
        ["Android Studio / SDK",  "Android SDK API 34 installed",           "Android Studio SDK Manager"],
        ["Java JDK 17",           "JAVA_HOME environment variable set",     "developer.android.com"],
        ["google-services.json",  "Downloaded from Firebase Console",       "Firebase Console → Project Settings"],
        ["Signing Keystore (.jks)","Provided in the Credentials Handover doc", "See Document #04"],
        ["Firebase CLI",          "npm install -g firebase-tools",          "firebase.google.com/docs/cli"],
        ["Git",                   "Repository cloned and up to date",       "github.com"],
    ]
)

add_h1(doc, "2. Environment Preparation")
add_h2(doc, "2.1 Clone & Configure the Project")
add_body(doc, (
    "Begin by ensuring the repository is fully cloned and that all dependencies are resolved. "
    "The following commands should be executed from a terminal in the project root directory."
))
add_body(doc, "Step 1: Navigate to the project root.")
add_body(doc, "Step 2: Run 'flutter pub get' to install all Dart packages.")
add_body(doc, "Step 3: Place the google-services.json file into the android/app/ directory. "
              "This file must not be committed to version control.")
add_body(doc, "Step 4: Verify setup by running 'flutter doctor -v' and confirming all checks pass.")

add_h2(doc, "2.2 Configure Signing Key Reference")
add_body(doc, (
    "The application must be configured to use the release signing keystore during the build "
    "process. Create a file named 'key.properties' in the android/ directory with the following "
    "structure. Values in square brackets should be replaced with the credentials from the "
    "Credentials Handover document."
))
add_body(doc, "storePassword=[STORE_PASSWORD]")
add_body(doc, "keyPassword=[KEY_PASSWORD]")
add_body(doc, "keyAlias=[KEY_ALIAS]")
add_body(doc, "storeFile=../../keys/vishal_gold_release.jks")
add_body(doc, "(Place the .jks file in a 'keys/' folder adjacent to the project root. "
              "Ensure both key.properties and keys/ are in .gitignore.)")
add_note(doc, "SECURITY",
    "Never commit key.properties or the .jks keystore file to version control. "
    "Loss of the keystore prevents future Play Store updates.")

add_h1(doc, "3. Building the Release APK / AAB")
add_h2(doc, "3.1 Release AAB (Recommended for Play Store)")
add_body(doc, (
    "An Android App Bundle (AAB) is the recommended format for Play Store submissions as it "
    "allows Google Play to generate optimized APKs for each device configuration, resulting "
    "in smaller download sizes for end users."
))
add_body(doc, "Command: flutter build appbundle --release")
add_body(doc, "Output location: build/app/outputs/bundle/release/app-release.aab")

add_h2(doc, "3.2 Release APK (for Direct Distribution / QA)")
add_body(doc, (
    "Use a release APK for distribution outside the Play Store, such as direct installation "
    "on test devices or enterprise distribution."
))
add_body(doc, "Command: flutter build apk --release")
add_body(doc, "Command (split per CPU architecture): flutter build apk --split-per-abi --release")
add_body(doc, "Output location: build/app/outputs/flutter-apk/app-release.apk")

add_h2(doc, "3.3 Verifying the Build")
add_body(doc, (
    "After the build completes, run 'flutter analyze' to confirm there are no compilation errors. "
    "Install the release APK on a test device to perform a smoke test (see Section 9 for the "
    "verification checklist) before uploading to the Play Store."
))

add_h1(doc, "4. Signing the Application")
add_body(doc, (
    "If the build.gradle file is correctly configured to reference key.properties (as set up by "
    "the Engineering team), the release build commands above will automatically sign the output "
    "using the keystore. To verify the signing, run the following command and confirm the output "
    "shows the expected key alias and issuer."
))
add_body(doc, "Command: keytool -printcert -jarfile build/app/outputs/bundle/release/app-release.aab")
add_body(doc, (
    "Confirm the certificate subject matches the key alias provided in the Credentials Handover "
    "document. A mis-signed build will be rejected by Google Play."
))

add_h1(doc, "5. Firebase Rules Deployment")
add_body(doc, (
    "Before the application goes live to production users, the Firestore and Storage security "
    "rules must be deployed. The rules are provided in the VAPT After Report. Perform the "
    "following steps using the Firebase CLI."
))
add_numbered(doc, "Log in to Firebase CLI: Run 'firebase login' and authenticate with the project owner Google account.")
add_numbered(doc, "Set the active project: Run 'firebase use [PROJECT_ID]' substituting the actual Firebase project ID.")
add_numbered(doc, "Create a firestore.rules file in the project root with the rules from VAPT_Report_After.md Section 3.1.")
add_numbered(doc, "Deploy Firestore rules: Run 'firebase deploy --only firestore:rules'.")
add_numbered(doc, "Create a storage.rules file if Storage rules need updating.")
add_numbered(doc, "Deploy Storage rules: Run 'firebase deploy --only storage'.")
add_numbered(doc, "Verify in Firebase Console: Navigate to Firestore → Rules and confirm the rules are live.")
add_note(doc, "CRITICAL",
    "Do not skip this step. Operating with open Firestore rules in production is a Critical "
    "security vulnerability (VAPT-006). Deployment should take less than 5 minutes.")

add_h1(doc, "6. Google Play Store Submission")
add_h2(doc, "6.1 Creating a Play Store Listing")
add_body(doc, (
    "If this is the first submission for the Vishal Gold app, a new application listing must be "
    "created in the Google Play Console. Navigate to play.google.com/console, sign in with the "
    "client's Google account, and follow the 'Create app' wizard."
))
add_table(doc,
    headers=["Field", "Recommended Value"],
    rows=[
        ["App Name",        "Vishal Gold"],
        ["Default Language","English (India)"],
        ["App or Game",     "App"],
        ["Free or Paid",    "Free"],
    ]
)

add_h2(doc, "6.2 Store Listing Assets")
add_body(doc, (
    "The Play Store listing requires the following assets before the app can be published. "
    "These must be prepared by the client's marketing team and uploaded to the Play Console."
))
add_table(doc,
    headers=["Asset", "Specification"],
    rows=[
        ["App Icon",            "512×512 px, PNG, no alpha"],
        ["Feature Graphic",     "1024×500 px, JPG or PNG"],
        ["Screenshots (Phone)", "Minimum 2, maximum 8; at least 1280px on the long side"],
        ["Short Description",   "Up to 80 characters"],
        ["Full Description",    "Up to 4000 characters"],
        ["Content Rating",      "Complete the content rating questionnaire in Play Console"],
    ]
)

add_h2(doc, "6.3 Uploading the AAB")
add_numbered(doc, "In Play Console, navigate to the app's dashboard → Production → Create new release.")
add_numbered(doc, "Upload the app-release.aab file generated in Section 3.")
add_numbered(doc, "Enter the release notes for this version.")
add_numbered(doc, "Click 'Review release', address any pre-submission warnings, then click 'Start rollout to Production'.")
add_numbered(doc, "Google Play review typically takes 1–3 business days for a new app.")

add_h1(doc, "7. Post-Deployment Verification")
add_body(doc, "After deploying, perform the following smoke tests on the production build.")
tests = [
    "Log in with a Retailer phone number and confirm OTP delivery.",
    "Browse the product catalog and confirm all categories and images load.",
    "Add items to the cart and confirm quantities are bounded at 99.",
    "Log in with a Wholesaler phone number and confirm cart persistence across a sign-out/sign-in cycle.",
    "Log in as Admin and confirm the Admin Dashboard loads correctly.",
    "Add a test product in staging and publish it. Confirm it appears in the catalog.",
    "Attempt to access Firestore directly via the REST API as an unauthenticated user. Confirm it is denied.",
    "Send a test push notification and verify it is received on a device.",
]
for t in tests:
    add_numbered(doc, t)

add_h1(doc, "8. Rollback Procedure")
add_body(doc, (
    "If a critical issue is discovered immediately after a new release is published to the Play Store, "
    "the following rollback procedure should be executed to minimize user impact."
))
add_numbered(doc, "In Google Play Console, navigate to the app release and select 'Halt rollout'. This prevents the new version from reaching additional devices.")
add_numbered(doc, "If the issue is severe, select 'Roll out a previous release' to reinstate the last known good version.")
add_numbered(doc, "Notify the Engineering support team immediately with a description of the issue.")
add_numbered(doc, "Do not delete the problematic release from Play Console, as it may be needed for issue diagnosis.")
add_note(doc, "Note",
    "A rollback through Play Console does not downgrade the app on devices that have already "
    "updated. Those users will need to wait for a hotfix release.")

save(doc, OUT)
