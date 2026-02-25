"""
14_developer_guide.py — Generates the Developer Guide.docx
"""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from doc_utils import *

OUT = os.path.join(os.path.dirname(__file__), "..", "client_delivery",
                   "14_Developer_Guide_Enterprise.docx")
os.makedirs(os.path.dirname(OUT), exist_ok=True)

doc = new_document()

add_cover(doc,
    title    = "Developer Guide",
    subtitle = "Technical Engineering & Extension Manual — Vishal Gold",
    version  = "v1.1",
    prepared_for = "Vishal Gold Engineering Team",
    prepared_by  = "Senior Backend & Mobile Architects"
)

add_toc_placeholder(doc, [
    ("Architecture Overview", 3),
    ("Project Structure", 5),
    ("Environment Setup", 7),
    ("Dependency Management", 9),
    ("Coding Standards", 11),
    ("State Management", 13),
    ("Firebase & Data Layer", 15),
    ("Security Practices", 17),
    ("Build & Deployment", 19),
    ("Testing Workflow", 21),
])

# ── 1. Architecture Overview ────────────────────────────────────────────────
add_h1(doc, "1. Architecture Overview")
add_body(doc, (
    "Vishal Gold is an enterprise-grade B2B/B2C jewelry mobile application built on the "
    "Flutter framework with a multi-layered Firebase backend. The system is designed for "
    "high availability, secure PII handling, and scalability across large jewelry inventories."
))

add_body(doc, (
    "The application follows a clean-architecture inspired approach with strict separation "
    "between UI, state management, and the service layer. The diagram below illustrates "
    "the primary data flow and relationship between components."
))

# Note: Mermaid diagram converted to descriptive text for docx
add_bullet(doc, "UI Layer: Flutter Widgets observing state via Provider.")
add_bullet(doc, "State Layer: Providers (ChangeNotifier) managing business logic and reactive updates.")
add_bullet(doc, "Service Layer: Core logic for Firebase (Auth, Firestore, Storage) and Local Storage (SharedPreferences, SecureStorage).")
add_bullet(doc, "Backend: Firebase infrastructure (managed services).")

add_h2(doc, "1.1 User Roles & Access Control")
add_table(doc,
    headers=["Role", "Auth Type", "Storage", "Description"],
    rows=[
        ["Wholesaler", "Phone OTP", "Firestore", "Full catalog access, persistent sync."],
        ["Retailer",   "Phone / Anon", "LocalStorage", "Browsing focused, local cart persistence."],
        ["Admin",      "Credentials", "Firestore", "CMS, order mgmt, and staging preview."]
    ]
)

# ── 2. Project Structure ────────────────────────────────────────────────────
add_h1(doc, "2. Project Structure")
add_body(doc, "The repository follows a standard Flutter structure with clear domain-based separation in the lib/ folder.")

structure = [
    ("lib/main.dart", "Entry point; contains MultiProvider setup and app-wide initialization."),
    ("lib/constants/", "UI tokens — AppColors, TextStyles, and API constants."),
    ("lib/models/", "Typed Dart classes for Products, Orders, CartItems, and Users."),
    ("lib/providers/", "State containers (ChangeNotifier) for various app modules."),
    ("lib/screens/", "UI screens organized by domain (auth, home, product, cart, admin)."),
    ("lib/services/", "Backend interaction (FirebaseService) and hardware access."),
    ("lib/widgets/", "Project-wide reusable UI components."),
    ("docs/engineering/", "Comprehensive technical documentation and VAPT reports.")
]

for item, desc in structure:
    add_bullet(doc, f"{item}: {desc}")

# ── 3. Environment Setup ────────────────────────────────────────────────────
add_h1(doc, "3. Environment Setup")
add_h2(doc, "3.1 Prerequisites")
add_table(doc,
    headers=["Component", "Requirement", "Source"],
    rows=[
        ["Flutter SDK", ">= 3.32.0", "flutter.dev"],
        ["Android Studio", "Hedgehog+", "developer.android.com"],
        ["Java JDK", "17 (LTS)", "JDK Vendor distribution"],
        ["Firebase CLI", "Latest (npm)", "Firebase Console"]
    ]
)

add_h2(doc, "3.2 Quick Start")
add_body(doc, "Run the following commands in sequence to initialize the development environment.")
add_body(doc, "1. git clone <repository-url>")
add_body(doc, "2. flutter pub get")
add_body(doc, "3. Place 'google-services.json' in android/app/")
add_body(doc, "4. flutter run")

# ── 4. Dependency Management ────────────────────────────────────────────────
add_h1(doc, "4. Dependency Management")
add_body(doc, "Core dependencies are strictly version-pinned in pubspec.yaml to ensure build repeatability.")

add_table(doc,
    headers=["Package", "Purpose", "Critically"],
    rows=[
        ["provider", "State Management", "High"],
        ["firebase_core", "Infrastructure", "High"],
        ["flutter_secure_storage", "PII Security", "Critical"],
        ["cached_network_image", "Performance", "Medium"],
        ["uuid", "Data Integrity", "Medium"]
    ]
)

# ── 5. Coding Standards ─────────────────────────────────────────────────────
add_h1(doc, "5. Coding Standards")
add_bullet(doc, "Dart Style: Adherence to 'Effective Dart' is mandatory.")
add_bullet(doc, "UI Tokens: Never hardcode hex colors; reference AppColors.gold.")
add_bullet(doc, "Typing: Avoid 'dynamic'; always use explicit types for data models.")
add_bullet(doc, "Performance: Use 'const' constructors for all stateless surfaces.")

# ── 6. State Management ─────────────────────────────────────────────────────
add_h1(doc, "6. State Management")
add_body(doc, "The application utilizes the Provider pattern for dependency injection and state updates.")
add_body(doc, "1. Read: context.read<T>() for one-time state access (e.g., inside methods).")
add_body(doc, "2. Watch: context.watch<T>() for UI-driven rebuilds.")
add_body(doc, "3. Select: context.select<T, R>() for granular subset observation.")

# ── 7. Firebase & Data Layer ────────────────────────────────────────────────
add_h1(doc, "7. Firebase & Data Layer")
add_body(doc, (
    "The data layer is abstracted behind a service-provider pattern. The UI never interacts "
    "directly with Cloud Firestore; all requests pass through FirebaseService."
))

add_table(doc,
    headers=["Collection", "Purpose", "Access Level"],
    rows=[
        ["/products/", "Live Catalog", "Auth-Read / Admin-Write"],
        ["/users/", "User Profiles", "Owner-Read/Write"],
        ["/staging/", "Draft changes", "Admin-Only"],
    ]
)

# ── 8. Security Practices ───────────────────────────────────────────────────
add_h1(doc, "8. Security Practices")
add_note(doc, "MANDATORY", "PII fields (Name, Phone, Role) must NEVER be stored in plaintext SharedPreferences. Always use SecureLocalStorageService.")

add_body(doc, "1. Secure Storage: All identifying fields encrypted at rest.")
add_body(doc, "2. Rate Limiting: 60s client-side cooldown on sensitive OTP actions.")
add_body(doc, "3. Validation: Server-side Firestore rules enforce role-based access control.")

# ── 9. Build & Deployment ───────────────────────────────────────────────────
add_h1(doc, "9. Build & Deployment")
add_body(doc, "Deployment requires a clean build and full environment check.")
add_body(doc, "Build APK: flutter build apk --release")
add_body(doc, "Build AppBundle: flutter build appbundle --release")

# ── 10. Testing Workflow ────────────────────────────────────────────────────
add_h1(doc, "10. Testing Workflow")
add_body(doc, (
    "A manual and automated testing suite must be executed prior to any release. Manual tests "
    "are documented in the QA Test Cases report. Automated tests live in the test/ directory."
))

save(doc, OUT)
