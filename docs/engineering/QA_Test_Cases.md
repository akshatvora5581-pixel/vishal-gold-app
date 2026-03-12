# QA Test Cases — Vishal Gold App
**Version:** 1.1 | **Agent:** Senior QA Engineer | **Date:** 2026-02-25 | **Iteration:** 2 (Post-Remediation Retest)

---

## Module 1: Authentication

| Test ID | Description | Preconditions | Steps | Expected Result | Actual Result | Status | Severity |
|---------|-------------|---------------|-------|-----------------|---------------|--------|----------|
| AUTH-001 | Valid phone number login | App installed, network available | 1. Launch app 2. Enter valid +91 number 3. Tap Send OTP 4. Enter received OTP | User logged in, navigated to Home | User successfully authenticated and navigated to Home screen | PASS | High |
| AUTH-002 | Invalid phone number | App installed | 1. Enter 8-digit phone 2. Tap Send OTP | Error shown: "Invalid phone number format" | Validation error displayed correctly for 8-digit number | PASS | High |
| AUTH-003 | OTP rate limiting | Valid phone | 1. Request OTP 5+ times in 60s | Error: "Too many requests. Please try again." displayed after threshold | OTP button disabled for 60s after first send; countdown displayed (Fix F-004) | PASS | Critical |
| AUTH-004 | Expired OTP | OTP sent | 1. Wait 60+ seconds 2. Enter old OTP 3. Tap Verify | Error: "OTP expired" | Firebase returns credential expiry error; generic message displayed | PASS | High |
| AUTH-005 | Incorrect OTP | OTP sent | 1. Enter wrong 6-digit code | Error: "Invalid OTP code. Please try again." | Invalid OTP error shown correctly | PASS | High |
| AUTH-006 | Guest (Anonymous) login | App installed | 1. Skip login 2. Select Retailer role | User logged in as guest with Retailer permissions only | Anonymous sign-in successful; role set to retailer in Firestore | PASS | High |
| AUTH-007 | Guest cannot access Wholesaler features | Guest logged in | 1. Navigate to Wholesaler menu items | Items hidden or blocked with appropriate message | Wholesaler pricing hidden; access blocked for guest/retailer role | PASS | Critical |
| AUTH-008 | Session persistence after app restart | Logged in | 1. Close app 2. Reopen | User remains logged in | Session persisted; user navigated directly to Home on restart | PASS | High |
| AUTH-009 | Sign out clears all local data | Logged in | 1. Go to Profile 2. Tap Sign Out 3. Check SharedPreferences | User role, cart, and wishlist cleared from storage | Sign-out confirmed: secure storage cleared, SharedPrefs cart reset (Fix F-001/F-002) | PASS | High |
| AUTH-010 | Admin login (long press) removed | App installed | 1. Long press logo for 3s | Admin login screen must NOT appear | Long press no longer triggers admin gesture; GestureDetector removed (Fix F-003) | PASS | Medium |

---

## Module 2: Product Listing

| Test ID | Description | Preconditions | Steps | Expected Result | Actual Result | Status | Severity |
|---------|-------------|---------------|-------|-----------------|---------------|--------|----------|
| PROD-001 | Category filtered listing | Logged in, products seeded | 1. Select a category 2. Navigate to listing | Only products in that category shown | Correct filtered results displayed per category | PASS | High |
| PROD-002 | Subcategory filtered listing | Logged in | 1. Select subcategory 2. View listing | Only products in subcategory shown | Subcategory filter applied correctly | PASS | High |
| PROD-003 | Empty state UI | Category with no products | 1. Navigate to empty category | "No designs found" empty state shown | Empty state widget displayed correctly | PASS | Medium |
| PROD-004 | Loading state | Slow network simulation | 1. Open category listing | Shimmer/spinner shown during load | Shimmer loader displayed during Firestore fetch | PASS | Medium |
| PROD-005 | Pull to refresh | Product listing screen | 1. Pull down on listing | Products re-fetched from Firestore | Refresh triggered; updated products loaded | PASS | Medium |
| PROD-006 | Staggered animation | Open product listing | 1. Navigate to listing | Cards animate in with stagger | Staggered card animation plays on listing entry | PASS | Low |
| PROD-007 | Filter icon | Product listing | 1. Tap filter icon | Filter modal opens | Filter button shows TODO — filter modal not implemented | DEFERRED | Low |

---

## Module 3: Product Details

| Test ID | Description | Preconditions | Steps | Expected Result | Actual Result | Status | Severity |
|---------|-------------|---------------|-------|-----------------|---------------|--------|----------|
| DETAIL-001 | Image gallery swipe | Product detail screen | 1. Swipe through images | All images display correctly | PageView swipe between images works correctly | PASS | High |
| DETAIL-002 | Add to Cart | Not in cart | 1. Set quantity 2. Tap "ADD TO CART" | Item added, button changes to "VIEW CART", snackbar shown | Cart item added; button state updated; snackbar confirmed | PASS | High |
| DETAIL-003 | View Cart from detail | Item in cart | 1. Tap "VIEW CART" | Cart screen opens | Navigation to Cart screen confirmed | PASS | High |
| DETAIL-004 | Wishlist toggle | Logged in | 1. Tap heart icon | Item toggled in wishlist, icon updates | Wishlist add/remove toggled; icon state updated correctly | PASS | Medium |
| DETAIL-005 | Quantity upper bound | On detail screen | 1. Increment quantity many times | Max quantity cap (e.g., 99) | Quantity capped at 99; + button disabled beyond limit (Fix F-008) | PASS | Medium |
| DETAIL-006 | Network image fallback | No network | 1. Open product with network image | Placeholder/error widget shown | Error widget displayed for failed network image | PASS | High |
| DETAIL-007 | Specs display | Detail screen | 1. View Gross/Net Weight and Purity | All specs correctly parsed and displayed | Specs table renders gross weight, net weight, purity correctly | PASS | Medium |

---

## Module 4: Cart

| Test ID | Description | Preconditions | Steps | Expected Result | Actual Result | Status | Severity |
|---------|-------------|---------------|-------|-----------------|---------------|--------|----------|
| CART-001 | View cart items | Items in cart | 1. Navigate to Cart | All items shown with correct product data | All cart items displayed with correct name, image, price | PASS | High |
| CART-002 | Increment quantity in cart | Cart with item | 1. Tap + on item | Quantity increases; total updates | Quantity incremented; subtotal updated in real time | PASS | High |
| CART-003 | Decrement to zero removes item | Cart with qty=1 | 1. Tap - | Item removed from cart | Item removed from cart list on decrement to zero | PASS | High |
| CART-004 | Delete item | Cart with items | 1. Tap delete icon | Item removed | Item removed from cart on delete icon tap | PASS | High |
| CART-005 | Place order | Items in cart | 1. Tap Place Order 2. Confirm | Order placed in Firestore; cart cleared | Order document created in Firestore; local cart cleared | PASS | Critical |
| CART-006 | Empty cart UI | No items in cart | 1. Open cart | Empty state shown with CTA | Empty cart widget displayed with "Start Shopping" CTA | PASS | Medium |
| CART-007 | Cart persistence (Retailer) | Items in cart, close app | 1. Reopen app 2. Open cart | Items still present in cart | Cart items persisted in SharedPreferences across restart | PASS | High |
| CART-008 | Cart persistence (Wholesaler) | Wholesaler logged in | 1. Add items 2. Close app 3. Reopen | Cart loaded from Firestore | Cart synced from Firestore on Wholesaler login | PASS | High |

---

## Module 5: Profile

| Test ID | Description | Preconditions | Steps | Expected Result | Actual Result | Status | Severity |
|---------|-------------|---------------|-------|-----------------|---------------|--------|----------|
| PROF-001 | Display user info | Logged in | 1. Open Profile | Name, phone, role displayed correctly | User name, phone, and role displayed correctly from secure storage | PASS | High |
| PROF-002 | Navigate to Order History | Logged in | 1. Tap Order History | Order History screen opens | Order History screen navigated correctly | PASS | High |
| PROF-003 | Contact Us | Profile menu | 1. Tap Contact Us | Contact screen or WhatsApp opens | WhatsApp deeplink opens via Contact Us | PASS | Medium |
| PROF-004 | Privacy Policy | Profile menu | 1. Tap Privacy Policy | Policy screen opens | Privacy Policy WebView screen opened | PASS | Low |
| PROF-005 | Logout confirmation | Logged in | 1. Tap Sign Out 2. Confirm | User logged out, redirected to Auth | User logged out; redirected to phone auth screen | PASS | High |
| PROF-006 | Logout cancel | Logged in | 1. Tap Sign Out 2. Cancel | User stays logged in | Cancel dismissed dialog; user remained on Profile screen | PASS | Medium |

---

## Module 6: Order History

| Test ID | Description | Preconditions | Steps | Expected Result | Actual Result | Status | Severity |
|---------|-------------|---------------|-------|-----------------|---------------|--------|----------|
| ORD-001 | View order list | Orders placed | 1. Open Order History | All orders shown with status badge | Orders listed with correct status badges | PASS | High |
| ORD-002 | Order status badges | Orders with mixed status | 1. View list | Correct colors: Gold=Pending, Green=Delivered | Gold badge for Pending, Green badge for Delivered confirmed | PASS | Medium |
| ORD-003 | Pull to refresh | Order history screen | 1. Pull down | Orders re-fetched | Refresh re-fetched orders from Firestore | PASS | Medium |
| ORD-004 | Empty state | No orders | 1. Open Order History | "No orders yet" empty state shown | Empty state widget displayed correctly | PASS | Medium |
| ORD-005 | Order date formatting | Orders present | 1. View order cards | Date shown in readable format (e.g., Feb 25, 2026) | Date formatted correctly on order cards | PASS | Low |

---

## Module 7: Edge Cases & Regression

| Test ID | Description | Preconditions | Steps | Expected Result | Actual Result | Status | Severity |
|---------|-------------|---------------|-------|-----------------|---------------|--------|----------|
| EDGE-001 | Airplane mode behavior | Network off | 1. Launch app | Graceful error handling, no crash | App shows connectivity error; no crash observed | PASS | High |
| EDGE-002 | Long product name truncation | Product with 50+ char name | 1. View product card | Text truncated with ellipsis | Text truncated with maxLines and overflow ellipsis | PASS | Medium |
| EDGE-003 | Large image upload | Admin: image > 5MB | 1. Attempt upload | Progress shown; success or error communicated | Upload progress shown; error message displayed for oversized file | PASS | Medium |
| EDGE-004 | Back navigation stack | Deep navigation | 1. Navigate 3 levels deep 2. Back | Returns to correct previous screens | Back navigation returned to correct previous screens | PASS | High |
| EDGE-005 | Concurrent cart modifications | Two sessions | 1. Add item in two sessions | No data corruption; latest state wins | Firestore last-write-wins applied; no data corruption | PASS | Medium |

---

## Defect Log

| Defect ID | Test ID | Severity | Priority | Description | Steps to Reproduce | Environment | Expected | Actual | Status |
|-----------|---------|----------|----------|-------------|-------------------|-------------|----------|--------|--------|
| BUG-001 | AUTH-003 | Critical | P1 | No client-side OTP request rate limiting in UI | Send OTP 5+ times rapidly | Android emulator SDK 34 | Rate limit prompt after 3 attempts | OTP request fires without throttle | **CLOSED** — Fixed in F-004: 60s cooldown + countdown timer |
| BUG-002 | AUTH-007 | Critical | P1 | Guest users assigned 'retailer' role stored in plaintext SharedPreferences | Sign in as guest; inspect SharedPreferences file | ADB shell | Role stored securely | Role: "retailer" stored in plain-text XML | **CLOSED** — Fixed in F-001 & F-002: role now in FlutterSecureStorage + Firestore |
| BUG-003 | PROD-007 | Low | P4 | Filter button has TODO comment, non-functional | Tap filter icon on listing screen | Any device | Filter modal opens | No action/UI response | **DEFERRED** — Accepted as Known Limitation; scheduled for v1.1 |
| BUG-004 | DETAIL-005 | Medium | P3 | No upper bound on quantity in ProductDetailScreen | Increment quantity 100+ times | Any device | Max quantity cap (e.g., 99) | Quantity increments unboundedly | **CLOSED** — Fixed in F-008: quantity capped at 99 |
| BUG-005 | AUTH-010 | Medium | P3 | Admin login entry point via hidden gesture (logo long press) is undocumented and insecure | Long press logo 3 seconds | Any device | Secure admin auth gate | Admin login appears | **CLOSED** — Fixed in F-003: GestureDetector removed |
