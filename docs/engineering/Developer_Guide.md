# Developer Guide — Vishal Gold App
**Version:** 1.0 | **Last Updated:** 2026-02-25 | **Audience:** New & Existing Engineers

> This guide enables any developer to confidently set up, extend, and ship changes to the Vishal Gold app **without prior project familiarity**.

---

## Table of Contents

1. [Architecture Overview](#1-architecture-overview)
2. [Project Structure](#2-project-structure)
3. [Environment Setup](#3-environment-setup)
4. [Dependency Management](#4-dependency-management)
5. [Coding Standards](#5-coding-standards)
6. [State Management](#6-state-management)
7. [Firebase & Data Layer](#7-firebase--data-layer)
8. [Security Practices](#8-security-practices)
9. [Build & Deployment](#9-build--deployment)
10. [Branching Strategy](#10-branching-strategy)
11. [Testing Workflow](#11-testing-workflow)
12. [Implementing New Features](#12-implementing-new-features)
13. [Modifying Existing Modules](#13-modifying-existing-modules)
14. [Fixing Bugs](#14-fixing-bugs)
15. [Documentation Standards](#15-documentation-standards)
16. [Review & Submission Pipeline](#16-review--submission-pipeline)

---

## 1. Architecture Overview

Vishal Gold is a **Flutter** B2B/B2C mobile application for jewelry wholesalers and retailers. It uses a **Firebase backend** with a **Provider-based state management** pattern.

```
┌─────────────────────────────────────────┐
│                  UI Layer               │
│  Screens → Widgets → Providers (watch)  │
└────────────────────┬────────────────────┘
                     │ Provider.of / Consumer
┌────────────────────▼────────────────────┐
│             State Layer (Providers)     │
│  AuthProvider  CartProvider  Product..  │
└────────────────────┬────────────────────┘
                     │ method calls
┌────────────────────▼────────────────────┐
│           Service Layer                 │
│  FirebaseService  FirebaseAuthService   │
│  LocalStorageService  FCMService        │
└────────────────────┬────────────────────┘
                     │
┌────────────────────▼────────────────────┐
│           Backend (Firebase)            │
│  Firestore   Storage   Auth   FCM       │
└─────────────────────────────────────────┘
```

### User Roles
| Role | Auth | Data Storage | Access |
|------|------|-------------|--------|
| **Wholesaler** | Firebase Phone Auth | Firestore | Full catalog, cart in Firestore, order history |
| **Retailer** | Firebase Phone Auth or Anonymous | SharedPreferences | Catalog, cart local, limited orders |
| **Admin** | Separate `AdminLoginScreen` (email + password) | Firestore | Product upload, order management, analytics |

### Key Design Patterns
- **Provider** for reactive state (not Riverpod or Bloc)
- **Dual storage strategy**: Wholesalers → Firestore; Retailers → local `SharedPreferences`
- **PII exclusively in `FlutterSecureStorage`** (see [Security Practices](#8-security-practices))
- **Staging workflow**: Admin changes go to a `staging/` Firestore collection before being published to `products/`

---

## 2. Project Structure

```
vishal_gold/
├── android/                        # Android native project
│   └── app/
│       ├── google-services.json    # ⚠️ NOT in git (add per README)
│       └── src/main/
│           └── AndroidManifest.xml
├── assets/
│   ├── images/                     # Static images (logo, placeholders)
│   └── icons/                      # SVG icons
├── lib/
│   ├── main.dart                   # App entry point, Provider setup
│   ├── constants/
│   │   └── app_colors.dart         # Brand color palette (source of truth)
│   ├── models/                     # Pure Dart data models
│   │   ├── product.dart
│   │   ├── cart_item.dart
│   │   ├── order.dart
│   │   └── ...
│   ├── providers/                  # ChangeNotifier state containers
│   │   ├── auth_provider.dart
│   │   ├── cart_provider.dart
│   │   ├── product_provider.dart
│   │   └── ...
│   ├── screens/                    # One folder per domain
│   │   ├── auth/                   # Phone auth, admin login
│   │   ├── home/                   # Home, subcategories
│   │   ├── product/                # Listing, detail, full-screen viewer
│   │   ├── cart/                   # Cart screen
│   │   ├── order/                  # Order history, sample order
│   │   ├── profile/                # User profile
│   │   ├── admin/                  # Admin dashboard, product/banner mgmt
│   │   └── upload/                 # Design upload
│   ├── services/                   # Backend interaction (no UI)
│   │   ├── firebase_service.dart   # Firestore CRUD, Storage upload
│   │   ├── firebase_auth_service.dart
│   │   ├── local_storage_service.dart  # SharedPreferences + SecureStorage
│   │   └── fcm_service.dart
│   └── widgets/                    # Reusable UI components
│       ├── common/
│       └── product/
├── docs/
│   └── engineering/                # All technical documentation lives here
│       ├── QA_Test_Cases.md
│       ├── QA_Fixes.md
│       ├── VAPT_Report_Before.md
│       ├── VAPT_Report_After.md
│       ├── Troubleshooting_Guide.md
│       └── Developer_Guide.md      # ← You are here
├── pubspec.yaml                    # Dependencies and assets
└── .agent/                         # AI agent configuration (not app code)
```

---

## 3. Environment Setup

### Prerequisites

| Tool | Required Version | Install |
|------|-----------------|---------|
| Flutter | ≥ 3.32.0 (SDK ^3.9.2) | [flutter.dev/docs/get-started](https://flutter.dev/docs/get-started) |
| Dart | Bundled with Flutter | — |
| Android Studio | Hedgehog or newer | [developer.android.com/studio](https://developer.android.com/studio) |
| Android SDK | API 34 (target), API 23 (min) | Via Android Studio SDK Manager |
| Java (JDK) | 17 (LTS) | `sdk install java 17` via SDKMAN |
| Firebase CLI | Latest | `npm install -g firebase-tools` |
| Git | 2.x | — |

### First-Time Setup

```bash
# 1. Clone the repository
git clone https://github.com/RushabhMakim3880/vishal-gold-app.git
cd vishal-gold-app

# 2. Install Flutter dependencies
flutter pub get

# 3. Place Firebase config (obtain from team lead or Firebase Console)
#    → android/app/google-services.json

# 4. Verify setup
flutter doctor -v

# 5. Run on connected device or emulator
flutter run
```

### Recommended VS Code Extensions
- **Flutter** (Dart-Code.flutter)
- **Dart** (Dart-Code.dart-code)
- **Error Lens** (usernamehw.errorlens)
- **GitLens** (eamodio.gitlens)

---

## 4. Dependency Management

### Key Dependencies

| Package | Purpose | Notes |
|---------|---------|-------|
| `provider` | State management | Use `ChangeNotifier` + `Consumer` |
| `firebase_core` | Firebase init | Must be initialized first in `main()` |
| `firebase_auth` | Phone OTP authentication | |
| `cloud_firestore` | NoSQL database | Primary data store for wholesalers |
| `firebase_storage` | File/image storage | Product images, sample orders |
| `firebase_messaging` | Push notifications | FCM integration |
| `flutter_secure_storage` | Encrypted local storage | **All PII must use this** |
| `shared_preferences` | Plain local storage | Non-PII only: cart JSON, flags |
| `uuid` | Random ID generation | Cart items use `Uuid().v4()` |
| `cached_network_image` | Efficient image loading | Use instead of `Image.network` |
| `google_fonts` | Typography | Playfair Display + Outfit |
| `flutter_staggered_animations` | List/grid entrance animations | ProductListing uses this |
| `intl` | Date/number formatting | Order dates, weight formatting |

### Adding a New Dependency

```bash
# Step 1: Search pub.dev for the package
flutter pub add package_name

# Step 2: Verify no conflicts
flutter pub deps
flutter pub outdated

# Step 3: Run the app to verify no MissingPluginException
flutter run

# Step 4: Update pubspec.yaml comment if the package has a specific purpose
```

> ⚠️ **Rule:** Never add a dependency without checking if an already-included package provides the same functionality. E.g., `uuid` is already present — don't add `nanoid` for the same purpose.

### Removing a Dependency

```bash
flutter pub remove package_name
flutter clean && flutter pub get
```

---

## 5. Coding Standards

### Language & Style

- **Dart** — follow [Effective Dart](https://dart.dev/effective-dart) guidelines
- Use `const` constructors everywhere possible for performance
- Prefer `final` over `var` unless mutation is required
- Use named parameters for functions with ≥ 3 parameters
- No `dynamic` types — always specify explicit types

### Naming Conventions

| Element | Convention | Example |
|---------|-----------|---------|
| Classes | `UpperCamelCase` | `ProductDetailScreen` |
| Files | `snake_case` | `product_detail_screen.dart` |
| Variables / fields | `lowerCamelCase` | `isLoading` |
| Constants | `lowerCamelCase` or `SCREAMING_SNAKE_CASE` if top-level | `_maxQuantity`, `kGoldColor` |
| Private members | Prefix `_` | `_authService` |
| Screen widgets | Suffix `Screen` | `CartScreen` |
| Provider classes | Suffix `Provider` | `CartProvider` |
| Service classes | Suffix `Service` | `FirebaseService` |

### Colors — Mandatory Rules

- **Never hardcode hex colors** in widget files. Always reference `AppColors`:
  ```dart
  // ✅ Correct
  color: AppColors.gold
  // ❌ Wrong
  color: Color(0xFFD4AF37)
  ```
- **Purple ban**: The brand does not use purple or violet. Any purple/violet hex is a design violation.

### Typography

Always use `GoogleFonts`:
```dart
// Headings
GoogleFonts.playfairDisplay(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.gold)
// Body / UI
GoogleFonts.outfit(fontSize: 14, color: AppColors.white)
```

### Async / Error Handling

```dart
// ✅ Always guard setState after await
Future<void> _loadData() async {
  try {
    final data = await _service.fetch();
    if (!mounted) return; // guard
    setState(() => _data = data);
  } catch (e) {
    if (kDebugMode) debugPrint('Load error: $e');
    if (!mounted) return;
    setState(() => _error = 'Something went wrong.');
  }
}
```

- **Never expose raw `e.toString()`** to the user in production builds
- Wrap all `debugPrint` with `if (kDebugMode)`

---

## 6. State Management

### Pattern: Provider with ChangeNotifier

```dart
// In main.dart — MultiProvider setup
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => AuthProvider()),
    ChangeNotifierProxyProvider<AuthProvider, CartProvider>(
      create: (_) => CartProvider(),
      update: (_, auth, cart) {
        cart?.initialize(auth.currentUser?.uid, auth.isWholesaler);
        return cart!;
      },
    ),
    // ... other providers
  ],
  child: const MyApp(),
)
```

### Reading State in Screens

```dart
// Read without rebuilding (one-time read)
final auth = context.read<AuthProvider>();

// Watch and rebuild on change
final cart = context.watch<CartProvider>();

// Granular rebuild (preferred for performance)
Consumer<CartProvider>(
  builder: (context, cart, _) => Text('${cart.itemCount}'),
)
```

### Adding a New Provider

1. Create `lib/providers/my_feature_provider.dart` extending `ChangeNotifier`
2. Register it in `MultiProvider` in `main.dart`
3. Access `context.read<MyFeatureProvider>()` or `context.watch<...>()` in screens

---

## 7. Firebase & Data Layer

### Firestore Collection Structure

```
/users/{userId}
  ├── fullName: string
  ├── phone: string
  ├── userType: "retailer" | "wholesaler" | "admin"
  ├── isActive: bool
  └── fcmToken: string

/products/{productId}
  ├── name: string
  ├── categoryId: string
  ├── subcategoryId: string
  ├── imageUrls: [string]
  ├── grossWeight: number
  ├── netWeight: number
  ├── purity: string
  └── isActive: bool

/orders/{orderId}
  ├── userId: string
  ├── items: [CartItem]
  ├── status: "pending" | "processing" | "shipped" | "delivered"
  └── createdAt: timestamp

/staging/{docId}           # Unpublished admin changes
/cart/{userId}             # Wholesaler cart (Retailer uses SharedPreferences)
/banners/{bannerId}        # Home screen banners
```

### Using FirebaseService

```dart
// Always inject via service layer — never call Firestore directly from UI
final _firebaseService = FirebaseService();

// Read
final products = await _firebaseService.getProducts(categoryId: id);

// Write
await _firebaseService.saveUserProfile(userId: uid, userData: {...});
```

### Data Storage Routing

| Data Type | User Role | Storage |
|-----------|-----------|---------|
| Cart | Wholesaler | Firestore `/cart/{uid}` |
| Cart | Retailer | `SharedPreferences` (JSON string) |
| PII (name, phone) | Any | `FlutterSecureStorage` |
| User role | Any | `FlutterSecureStorage` |
| Session flags | Any | `SharedPreferences` |

---

## 8. Security Practices

> These rules are **mandatory**. Violations will be flagged in code review.

### Rule 1: No PII in SharedPreferences

All personally identifiable information **must** use `LocalStorageService` secure methods:
```dart
// ✅ PII — use secure storage
await LocalStorageService.saveUserName(name);
await LocalStorageService.saveUserPhone(phone);
await LocalStorageService.getUserRole(); // reads from FlutterSecureStorage

// ✅ Non-PII — SharedPreferences is fine
await LocalStorageService.saveCart(cartJson);
await LocalStorageService.isFirstLaunch();
```

### Rule 2: Never Trust Client-Side Role

Always confirm the user's role from Firestore (server-side), not from local storage alone. Local storage is a **cache**, not a source of truth.

### Rule 3: Guard All Async UI Updates

```dart
if (!mounted) return;
setState(() { ... });
```

### Rule 4: Sanitize Error Messages in Production

```dart
// ✅
setState(() => _errorMessage = 'Something went wrong. Please try again.');

// ❌ Never do this
setState(() => _errorMessage = 'Failed: ${e.toString()}');
```

### Rule 5: No Hardcoded Secrets

Never hardcode API keys, Firebase project IDs, or admin credentials in Dart code. Use environment variables or Firebase Remote Config.

### Rule 6: Rate-Limit Sensitive Actions

OTP requests already have a 60-second client-side cooldown. Apply similar debounce patterns to any action that triggers paid external services (SMS, email, etc.).

---

## 9. Build & Deployment

### Debug Build (Development)

```bash
flutter run                          # Hot reload enabled
flutter run --device-id emulator-1  # Specific device
```

### Release Build

```bash
# APK (direct install / QA)
flutter build apk --release

# App Bundle (Google Play Store — preferred)
flutter build appbundle --release

# Per-ABI APKs (smaller downloads)
flutter build apk --split-per-abi --release
```

### Environment Flavors (Planned)

| Flavor | Firebase Project | Command |
|--------|----------------|---------|
| dev | `vishal-gold-dev` | `flutter run --flavor dev -t lib/main_dev.dart` |
| staging | `vishal-gold-staging` | `flutter run --flavor staging -t lib/main_staging.dart` |
| prod | `vishal-gold-prod` | `flutter build appbundle --flavor prod -t lib/main.dart` |

### Pre-Release Checklist

- [ ] `flutter analyze` → **0 errors**
- [ ] `flutter test` → all tests pass
- [ ] Release APK installed and tested on physical Android device
- [ ] Firestore security rules reviewed and deployed (`firebase deploy --only firestore:rules`)
- [ ] No `debugPrint` leaking PII in profile build (`adb logcat | grep -i uid`)
- [ ] `google-services.json` **not** committed to git (`git status android/app/`)
- [ ] Version number incremented in `pubspec.yaml`

---

## 10. Branching Strategy

### Branch Naming

| Branch | Purpose | Naming |
|--------|---------|--------|
| `main` | Production-ready code. Direct pushes forbidden. | — |
| `develop` | Integration branch. All features merge here first. | — |
| Feature | New features | `feat/product-search` |
| Bug fix | Bug fixes | `fix/cart-not-persisting` |
| Hotfix | Urgent production fixes | `hotfix/otp-rate-limit` |
| Release | Stabilization before prod merge | `release/1.1.0` |

### Workflow

```
feat/xxx → develop → release/x.x.x → main
                  ↑
              (code review + CI)
```

```bash
# Start a feature
git checkout develop
git pull origin develop
git checkout -b feat/my-feature

# Work, commit, push
git add .
git commit -m "feat(cart): add max quantity cap (BUG-004)"
git push origin feat/my-feature

# Open Pull Request: feat/my-feature → develop
```

### Commit Message Format (Conventional Commits)

```
<type>(<scope>): <short summary>

type: feat | fix | docs | style | refactor | test | chore | security
scope: auth | cart | product | profile | admin | services | providers

Examples:
feat(auth): add 60s OTP rate limiting cooldown (VAPT-004)
fix(cart): replace timestamp IDs with UUID v4 (VAPT-005)
security(storage): migrate PII to FlutterSecureStorage (VAPT-001)
docs(engineering): add Developer Guide
```

---

## 11. Testing Workflow

### Test Levels

```
Unit Tests        → lib/models/, lib/services/  (fast, no Flutter)
Widget Tests      → lib/widgets/, lib/screens/  (Flutter test environment)
Integration Tests → test/integration/            (full app on device)
```

### Running Tests

```bash
# All tests
flutter test

# Specific file
flutter test test/providers/cart_provider_test.dart

# With coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

### Writing a Unit Test

```dart
// test/providers/cart_provider_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:vishal_gold/providers/cart_provider.dart';
import 'package:vishal_gold/models/product.dart';

void main() {
  group('CartProvider', () {
    late CartProvider cart;

    setUp(() {
      cart = CartProvider();
    });

    test('addToCart increases item count', () async {
      // Arrange
      final product = Product.mock();
      // Act
      await cart.addToCart(product);
      // Assert
      expect(cart.itemCount, equals(1));
    });

    test('addToCart again increments quantity', () async {
      final product = Product.mock();
      await cart.addToCart(product);
      await cart.addToCart(product);
      expect(cart.itemCount, equals(2));
    });
  });
}
```

### QA Test Cases

All manual test cases are documented in:  
→ [`docs/engineering/QA_Test_Cases.md`](./QA_Test_Cases.md)

Run through the relevant modules before each release. Log results in the **Actual Result** and **Status** columns.

---

## 12. Implementing New Features

### Step-by-Step Guide

**Example: Adding a Wishlist count badge on the app bar**

**Step 1: Check if state already exists**
```bash
grep -r "wishlist" lib/providers/
# Found: lib/providers/wishlist_provider.dart
# WishlistProvider already has itemCount getter
```

**Step 2: Read the provider in the relevant screen**
```dart
// In home_screen.dart AppBar actions:
Consumer<WishlistProvider>(
  builder: (context, wishlist, _) => Stack(
    children: [
      IconButton(icon: Icon(Icons.favorite_outline)),
      if (wishlist.itemCount > 0)
        Positioned(
          right: 0,
          top: 0,
          child: CircleAvatar(
            radius: 8,
            backgroundColor: AppColors.gold,
            child: Text('${wishlist.itemCount}', style: TextStyle(fontSize: 10)),
          ),
        ),
    ],
  ),
),
```

**Step 3: Register in MultiProvider if new provider needed**

Skip this step if reusing existing providers.

**Step 4: Write a widget test**

```dart
// test/widgets/wishlist_badge_test.dart
testWidgets('shows badge when wishlist has items', (tester) async {
  // Setup with WishlistProvider that has items
  // Pump HomeScreen widget
  // Verify badge is visible
});
```

**Step 5: Update QA_Test_Cases.md**

Add the new feature's test cases to the appropriate module section.

---

## 13. Modifying Existing Modules

### Before Modifying Any File

1. **Check who depends on it:**
```bash
grep -r "import.*filename" lib/
```
2. **Read the file's comment header** to understand its role
3. **Check if it has a corresponding test file** in `test/`

### Safe Modification Checklist

- [ ] Understand the current behavior end-to-end before changing
- [ ] Make changes in a feature branch, not directly on `develop`
- [ ] Run `flutter analyze` before committing
- [ ] Run related tests: `flutter test test/filename_test.dart`
- [ ] Hot reload to verify UI changes, then cold restart to verify state init
- [ ] Update `docs/engineering/` if the behavior change is significant

### High-Risk Files (Require Extra Caution)

| File | Risk | Why |
|------|------|-----|
| `lib/main.dart` | High | Provider setup order affects entire app |
| `lib/services/firebase_service.dart` | High | 1800+ lines, central data layer |
| `lib/services/local_storage_service.dart` | High | PII storage — security implications |
| `lib/providers/auth_provider.dart` | High | Auth state affects all screens |
| `android/app/src/main/AndroidManifest.xml` | High | Permissions and backup settings |

---

## 14. Fixing Bugs

### Bug Fix Workflow

```bash
# 1. Create a fix branch
git checkout develop
git checkout -b fix/cart-not-persisting

# 2. Reproduce the bug locally (write a failing test first if possible)
flutter test test/providers/cart_provider_test.dart  # should fail

# 3. Fix the code

# 4. Verify the test now passes
flutter test test/providers/cart_provider_test.dart  # should pass

# 5. Run full analysis
flutter analyze

# 6. Document in QA_Fixes.md
# 7. Open PR → develop
```

### Debugging Tips

```bash
# Enable verbose logging on a specific class
export FLUTTER_LOG_LEVEL=verbose  # Not Flutter-native but useful for native logs

# View only Flutter app logs
adb logcat -s flutter

# Inspect local storage
adb shell run-as com.vishalgold.app cat shared_prefs/FlutterSharedPreferences.xml

# Use Flutter Inspector in VS Code (View > Command Palette > Flutter: Open Widget Inspector)
```

### Common Patterns for Bug Sources

| Symptom | First Place to Look |
|---------|-------------------|
| Blank screen on navigation | `ProviderNotFoundException` in `main.dart` MultiProvider |
| State not updating | Missing `notifyListeners()` in Provider |
| Crash on app resume | `setState()` after `dispose()` — missing `mounted` check |
| Data not persisted | Check which storage path is being used (Firestore vs SharedPreferences vs SecureStorage) |
| Build error | `flutter clean && flutter pub get` |

---

## 15. Documentation Standards

### When to Document

| Change Type | Required Documentation |
|------------|----------------------|
| New screen | Add test cases to `QA_Test_Cases.md` |
| Security fix | Update `QA_Fixes.md` and `VAPT_Report_After.md` |
| New API/service method | Add Dart doc comment `///` above the method |
| Architecture change | Update `Developer_Guide.md` (this file) |
| Known bug | Log in `QA_Test_Cases.md` Defect Log |
| Deployment | Update pre-release checklist in this guide |

### Dart Doc Comments

```dart
/// Fetches all products for the given [categoryId].
///
/// Returns an empty list if no products exist.
/// Throws [FirebaseException] if Firestore is unreachable.
Future<List<Product>> getProducts({required String categoryId}) async { ... }
```

### File Header Convention (New Files)

```dart
// lib/screens/wishlist/wishlist_screen.dart
// Purpose: Displays user's saved wishlist items with remove and add-to-cart actions.
// Dependencies: WishlistProvider, CartProvider, FirebaseService
// Created: 2026-02-25 | Author: <name>
```

---

## 16. Review & Submission Pipeline

### Pull Request Requirements

1. **Branch** must be up to date with `develop` (`git rebase develop`)
2. **Title** follows Conventional Commit format
3. **Description** includes:
   - What was changed and why
   - Link to QA test case or VAPT finding (if applicable)
   - Screenshots for UI changes
4. **`flutter analyze`** must pass with 0 errors
5. **Tests** must pass (`flutter test`)
6. **Security checklist** completed for any change touching auth, storage, or network

### Code Review Checklist (Reviewer)

- [ ] No PII in `SharedPreferences` (must use `LocalStorageService` secure methods)
- [ ] No raw `e.toString()` exposed to users in release builds
- [ ] All `debugPrint` wrapped with `kDebugMode`
- [ ] All async UI updates guarded with `if (!mounted) return`
- [ ] Colors reference `AppColors` (no hardcoded hex)
- [ ] No `dynamic` types without justification
- [ ] New providers registered in `main.dart`

### Merge Policy

| Target | Approvals Required | CI Must Pass |
|--------|--------------------|-------------|
| `develop` | 1 | Yes |
| `release/*` | 2 | Yes |
| `main` | 2 + Tech Lead sign-off | Yes |

---

## Appendix: AppColors Quick Reference

```dart
static const Color background = Color(0xFF1A1A1A); // Deep Charcoal
static const Color surface    = Color(0xFF2A2A2A); // Card Surface
static const Color black      = Color(0xFF0D0D0D); // Pure Black
static const Color gold       = Color(0xFFD4AF37); // Metallic Gold
static const Color white      = Color(0xFFF5F5F5); // Off-White
static const Color textSecondary = Color(0xFF9E9E9E);
static const Color errorRed   = Color(0xFFE53935);
```

## Appendix: Firestore Collection Quick Reference

| Collection | Read | Write |
|-----------|------|-------|
| `/products/` | Any authenticated user | Admin only |
| `/users/{uid}` | Owner only | Owner only |
| `/orders/{ordId}` | Owner only | Owner only |
| `/cart/{uid}` | Owner only | Owner only |
| `/staging/` | Admin only | Admin only |
| `/banners/` | Any authenticated | Admin only |
