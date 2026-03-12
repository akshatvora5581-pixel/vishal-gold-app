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
    ("Architecture & philosophy", 3),
    ("Project Structure Deep-Dive", 5),
    ("Infrastucture: Firebase & Secure Storage", 8),
    ("State Management (Provider Stack)", 11),
    ("Administrative Staging Workflow", 14),
    ("Security Architecture & VAPT Mitigation", 17),
    ("Build & Environment Configuration", 20),
    ("Developer Workflow & Standards", 23),
])

# ── 1. Architecture & Philosophy ──────────────────────────────────────────
add_h1(doc, "1. Architecture & Philosophy")
add_body(doc, (
    "The Vishal Gold application is built on a high-availability, security-first foundation. "
    "The system follows a reactive architecture where the UI is a function of the state, "
    "and the state is strictly managed through localized providers."
))

add_h2(doc, "1.1 Reactive Data Flow")
add_body(doc, (
    "We utilize the 'Provider' package for state management. This ensures a clean separation "
    "between business logic and user interface. Every major domain (Auth, Cart, Products) "
    "lives in its own ChangeNotifier singleton."
))

add_bullet(doc, "Unidirectional Data Flow: UI -> Provider Action -> Service -> Firestore.")
add_bullet(doc, "State Persistence: Critical PII is persisted in Secure Storage; catalog data in Firestore.")
add_bullet(doc, "Lazy Initialization: Providers are instantiated only when needed by the widget tree.")

# ── 2. Project Structure Deep-Dive ──────────────────────────────────────────
add_h1(doc, "2. Project Structure Deep-Dive")
add_body(doc, "The codebase is organized into atomic domains located in the lib/ folder.")

structure = [
    ("config/", "Firebase options and platform-specific configurations."),
    ("constants/", "Design tokens (colors, text styles, spacing) and API strings."),
    ("models/", "Strongly typed schemas with JSON serialization (Product, User, Order)."),
    ("providers/", "Business logic containers managing reactive state updates."),
    ("services/", "Hardware/Backend interaction layer (Firebase, LocalStorage, Analytics)."),
    ("screens/", "Feature-specific UI modules (Admin, Wholesaler, Retailer flows)."),
    ("widgets/", "Re-usable design components (AppButtons, CustomCards, Shimmers).")
]

add_table(doc,
    headers=["Directory", "Responsibility"],
    rows=structure
)

# ── 3. Infrastructure: Firebase & Secure Storage ──────────────────────────
add_h1(doc, "3. Infrastructure: Firebase & Secure Storage")
add_body(doc, "The backend is powered by Firebase, with a security layer implemented through hardware-backed storage.")

add_h2(doc, "3.1 FirebaseService")
add_body(doc, (
    "The FirebaseService (lib/services/firebase_service.dart) is the central API hub. "
    "It implements complex cloud logic including Staging, Batch Writes, and Audit Logs."
))

add_table(doc,
    headers=["Module", "Capability"],
    rows=[
        ["Staging", "Drafting changes in a separate collection for admin review."],
        ["Audit Logs", "Tracking every admin write (Admin ID, Doc ID, Action)."],
        ["Product API", "Fetching filtered streams based on status (Draft/Published)."],
        ["Order Engine", "Atomic transaction handling for high-integrity orders."]
    ]
)

add_h2(doc, "3.2 SecureLocalStorageService")
add_body(doc, (
    "Unlike standard SharedPreferences, this service uses AES encryption via flutter_secure_storage. "
    "It is mandatory for storing any string that could identify a user (UID, Token, Role)."
))

# ── 4. State Management (Provider Stack) ──────────────────────────────────
add_h1(doc, "4. State Management (Provider Stack)")
add_body(doc, "The MultiProvider setup in main.dart defines the dependency hierarchy of the application.")

add_table(doc,
    headers=["Provider", "Primary Logic", "Dependency"],
    rows=[
        ["AuthProvider", "OTP logic, Role verification, Profile sync.", "None (Root)"],
        ["ProductProvider", "Catalog streaming, Category filtering.", "Auth (Role-based price)"],
        ["CartProvider", "Local/Cloud basket sync, Item arithmetic.", "Auth (UID matching)"],
        ["PreviewProvider", "Merging staged vs live data for admin view.", "Firebase (Staging coll)"]
    ]
)

# ── 5. Administrative Staging Workflow ────────────────────────────────────
add_h1(doc, "5. Administrative Staging Workflow")
add_body(doc, "The app enforces a 'Standard Change' process to avoid catalog corruption.")

add_body(doc, "Step 1: Admin edits product or banner details.")
add_body(doc, "Step 2: Changes are written to the 'staging' collection (status=pending).")
add_body(doc, "Step 3: Admin reviews the 'Staging Preview' screen (PreviewProvider).")
add_body(doc, "Step 4: Admin clicks 'Publish All' — changes move to live collections.")

# ── 6. Security Architecture & VAPT Mitigation ───────────────────────────
add_h1(doc, "6. Security Architecture & VAPT Mitigation")
add_note(doc, "CRITICAL", "The following security controls must never be removed or bypassed.")

add_h3(doc, "VAPT-001 (PII Security)")
add_body(doc, "PII is strictly isolated in the SecureStorage provider. Raw SharedPreferences only stores UI flags.")

add_h3(doc, "VAPT-006 (Firestore Rules)")
add_body(doc, "Minimum privilege rules: Wholesalers can only read /products/; Admins can write; Others are blocked.")

add_h3(doc, "VAPT-012 (Screenshot Protection)")
add_body(doc, "The FLAG_SECURE window flag is toggled during initState on sensitive profile and cart screens.")

# ── 7. Build & Environment Configuration ────────────────────────────────
add_h1(doc, "7. Build & Environment Configuration")
add_body(doc, (
    "We use a Flavor-based setup (dev/prod) to separate Firebase projects. "
    "Release builds are optimized with R8 shrinking and obfuscation."
))

add_h2(doc, "7.1 Build Commands")
add_body(doc, "Standard Release APK: flutter build apk --release")
add_body(doc, "Optimization: Build App Bundle (AAB) for Play Store deployment.")

# ── 8. Developer Workflow & Standards ────────────────────────────────────
add_h1(doc, "8. Developer Workflow & Standards")
add_bullet(doc, "PR Pre-check: Run 'flutter analyze' before any commit.")
add_bullet(doc, "Models: Always include 'toJson' and 'fromJson' for API compatibility.")
add_bullet(doc, "UI Consistency: Reference AppColors.gold instead of specific hex codes.")
add_bullet(doc, "Logging: Use debugPrint() for dev logs; wrapped in kDebugMode check.")

save(doc, OUT)
