# Developer Guide — Vishal Gold App (Ultra-Detailed)
**Version:** 1.2 | **Last Updated:** 2026-02-25 | **Status:** Production-Ready

---

## 1. System Architecture & Core Philosophy

Vishal Gold is built as a high-performance, security-first enterprise platform. It leverages Flutter's cross-platform capabilities with a multi-layered reactive architecture.

### 1.1 Architectural Layers
1. **Presentation Layer (Widgets)**: Pure UI logic. Widgets are primarily stateless and observe state via `context.watch<T>()` or `Consumer<T>`.
2. **State Layer (Providers)**: The "brain" of the app. `ChangeNotifier` classes in `lib/providers/` manage business logic, reactive data sets, and interaction with services.
3. **Service Layer (Core Logic)**: Atomic units of functionality. `FirebaseService` handles all cloud interactions, while `LocalStorageService` manages hardware encryption.
4. **Data Layer (Models)**: Strongly typed POJO (Plain Old Java Objects) equivalents using factory constructors for JSON serialization.

### 1.2 Dependency Injection & Startup
The app uses `MultiProvider` at the root (`main.dart`) to ensure a singleton-like availability of services:
- **`AuthProvider`**: Top of the stack. All other providers depend on the current user's UID and Role.
- **`ProductProvider`**: Manages the catalog stream.
- **`CartProvider`**: Manages the persistent shopping basket.
- **`OrderProvider`**: Handles history and status updates.
- **`WishlistProvider`**: Manages user favorites.
- **`PreviewProvider`**: Specifically for Administrative staging logic.

---

## 2. Infrastructure & Services (Deep Dive)

### 2.1 FirebaseService (`lib/services/firebase_service.dart`)
This 55KB+ service is the central repository for all Cloud Firestore, Firebase Storage, and Firebase Auth bridge logic.

#### Key Modules:
- **Staging System**:
    - `stageChange()`: Adds a document to the `staging` collection instead of the live catalog.
    - `publishAllChanges()`: Atomic batch operation that moves staged data to live collections (`products`, `categories`) and clears the stage.
    - `discardAllChanges()`: Purges the `staging` collection.
- **Audit Engine**:
    - `logAdminAction()`: Automatically called by admin operations to track WHO did WHAT to WHICH document. Logs are stored in `admin_logs`.
- **Product Management**:
    - `getProducts()`: Reactive stream with status filtering (`published` vs `draft`).
    - `uploadProduct()`: Handles metadata creation with server timestamps.
- **Role Verification**:
    - `getUserProfile()` / `getAdminProfile()`: Fetches the source-of-truth role from Firestore.

### 2.2 SecureLocalStorageService (`lib/services/local_storage_service.dart`)
Replaced standard SharedPreferences for PII (Personally Identifiable Information).
- **Technology**: `flutter_secure_storage` (AES encryption).
- **Usage**: Storing `user_role`, `user_name`, and `auth_token`. Non-sensitive data like `is_first_launch` remains in standard XML storage for speed.

### 2.3 FCMService (`lib/services/fcm_service.dart`)
Handles Cloud Messaging for real-time order status updates.
- **Logic**: Tokens are matched to UID in the `users` collection.
- **Foreground/Background**: Custom handlers manage notifications across all app states.

---

## 3. Data Models & Schema Registry

| Collection | Schema | Description |
|------------|--------|-------------|
| `users` | `uid, name, phone, role, fcm_token, createdAt` | User registry and role mapping. |
| `products` | `tag_number, category, subcategory, weights, status, version` | Master product catalog. |
| `orders` | `userId, items[], totalWeight, status, timestamp` | Transaction history. |
| `categories` | `name, icon, orderIndex` | Navigation structure. |
| `admin_logs` | `adminId, action, targetId, details, timestamp` | Compliance audit trail. |
| `staging` | `collection, docId, data, change_type` | Draft changes pending approval. |

---

## 4. Security Implementation (Hardened)

Following the 2026 VAPT audit, the following security barriers are enforced:

1. **Role-Based Access Control (RBAC)**: Firestore Rules enforce that `/products/` can only be written to by users with `role == 'admin'` in the `admins` collection.
2. **PII Isolation**: All identifiable fields are stored in the secure TEE (Trusted Execution Environment) via the `SecureStorage` service.
3. **ADB Defense**: `android:allowBackup="false"` prevents data extraction via developer tools.
4. **Screenshot Prevention**: Sensitive screens use Platform Channels to toggle `FLAG_SECURE`, preventing data theft via screen capture.
5. **Rate Limiting**: `PhoneAuthScreen` implements a 60-second lockout timer on the "Send OTP" button to mitigate SMS bombing.

---

## 5. Administrative Workflow (Staging to Live)

Admin operations follow a strict **Review -> Stage -> Publish** workflow to prevent live catalog errors.

1. **Upload**: Admin uploads product images to Firebase Storage first.
2. **Metadata**: Product metadata is saved to the `products` collection with `status: 'draft'`.
3. **Staging**: Changes (updates/deletes) are logged in the `staging` collection.
4. **Preview**: The `PreviewProvider` merges live data with `staging` data in the UI so the admin can see the result EXACTLY as it will appear once published.
5. **Push**: `publishAllChanges()` commits all changes at once.

---

## 6. Screen Navigation Map

### Common
- `SplashScreen`: Initialized Firebase/Storage.
- `AuthScreen`: Handles Phone OTP login.

### Retailer / Wholesaler
- `HomeScreen`: Dashboard with banners and category shortcuts.
- `ProductListingScreen`: Grid view with high-performance `CachedNetworkImage` implementation.
- `ProductDetailScreen`: Detailed specifications and "Add to Cart" logic.
- `CartScreen`: Unified basket management.
- `OrderHistoryScreen`: Real-time status tracking from Firestore.

### Administrative
- `AdminDashboard`: Global stats and quick actions.
- `StagingScreen`: Review pending changes.
- `InventoryManager`: Full CRUD interface for the catalog.
- `AdminLogsScreen`: Searchable access to the audit trail.

---

## 7. Developer Best Practices

- **Reactive State**: Always wrap long-running async calls with `setLoading(true)` in the provider.
- **Model Integrity**: Never access map fields directly; always use the `Product.fromMap()` pattern.
- **Asset Optimization**: All icons must be in SVG format; images should be WebP where possible.
- **Coding Style**: Follow the "Pragmatic Programmer" patterns documented in `CLEAN_CODE.md`.
