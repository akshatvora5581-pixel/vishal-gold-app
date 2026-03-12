import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

/// Service for managing local storage.
/// PII fields (name, phone, city, state, role) use FlutterSecureStorage (encrypted).
/// Non-PII flags and JSON blobs (cart, wishlist) use SharedPreferences.
class LocalStorageService {
  // Non-PII SharedPreferences keys
  static const String _keyIsFirstLaunch = 'is_first_launch';
  static const String _keyIsUserInfoProvided = 'is_user_info_provided';
  static const String _keyHasSeenInformationPage = 'has_seen_information_page';
  static const String _keyHasSeenUserInfo = 'has_seen_user_info';

  // PII SecureStorage keys (stored encrypted)
  static const String _secureKeyUserRole = 'secure_user_role';
  static const String _secureKeyUserName = 'secure_user_name';
  static const String _secureKeyUserCity = 'secure_user_city';
  static const String _secureKeyUserState = 'secure_user_state';
  static const String _secureKeyUserPhone = 'secure_user_phone';

  static SharedPreferences? _prefs;
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions.defaultOptions,
  );

  /// Initialize SharedPreferences
  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // ==================== PII - Encrypted Secure Storage ====================

  /// Save user role securely (VAPT-001 fix: was plaintext SharedPreferences)
  static Future<void> saveUserRole(String role) async {
    await _secureStorage.write(key: _secureKeyUserRole, value: role);
  }

  /// Get user role from secure storage
  static Future<String?> getUserRole() async {
    try {
      return await _secureStorage.read(key: _secureKeyUserRole);
    } catch (e) {
      if (kDebugMode) debugPrint('SecureStorage read error: $e');
      return null;
    }
  }

  /// Check if user has selected a role
  static Future<bool> isRoleSelected() async {
    final role = await getUserRole();
    return role != null && role.isNotEmpty;
  }

  /// Clear user role securely
  static Future<void> clearUserRole() async {
    await _secureStorage.delete(key: _secureKeyUserRole);
  }

  /// Save user name securely
  static Future<void> saveUserName(String name) async {
    await _secureStorage.write(key: _secureKeyUserName, value: name);
  }

  /// Get user name
  static Future<String?> getUserName() async {
    try {
      return await _secureStorage.read(key: _secureKeyUserName);
    } catch (e) {
      return null;
    }
  }

  /// Save user city securely
  static Future<void> saveUserCity(String city) async {
    await _secureStorage.write(key: _secureKeyUserCity, value: city);
  }

  /// Get user city
  static Future<String?> getUserCity() async {
    try {
      return await _secureStorage.read(key: _secureKeyUserCity);
    } catch (e) {
      return null;
    }
  }

  /// Save user state securely
  static Future<void> saveUserState(String state) async {
    await _secureStorage.write(key: _secureKeyUserState, value: state);
  }

  /// Get user state
  static Future<String?> getUserState() async {
    try {
      return await _secureStorage.read(key: _secureKeyUserState);
    } catch (e) {
      return null;
    }
  }

  /// Save user phone securely
  static Future<void> saveUserPhone(String phone) async {
    await _secureStorage.write(key: _secureKeyUserPhone, value: phone);
  }

  /// Get user phone
  static Future<String?> getUserPhone() async {
    try {
      return await _secureStorage.read(key: _secureKeyUserPhone);
    } catch (e) {
      return null;
    }
  }

  /// Clear all PII from secure storage
  static Future<void> clearAllPII() async {
    await Future.wait([
      _secureStorage.delete(key: _secureKeyUserRole),
      _secureStorage.delete(key: _secureKeyUserName),
      _secureStorage.delete(key: _secureKeyUserCity),
      _secureStorage.delete(key: _secureKeyUserState),
      _secureStorage.delete(key: _secureKeyUserPhone),
    ]);
  }

  // ==================== Non-PII SharedPreferences ====================

  /// Mark user info as provided
  static Future<bool> setUserInfoProvided() async {
    await init();
    return await _prefs!.setBool(_keyIsUserInfoProvided, true);
  }

  /// Check if user info is provided
  static Future<bool> isUserInfoProvided() async {
    await init();
    return _prefs!.getBool(_keyIsUserInfoProvided) ?? false;
  }

  /// Mark information page as seen
  static Future<bool> setHasSeenInformationPage() async {
    await init();
    return await _prefs!.setBool(_keyHasSeenInformationPage, true);
  }

  /// Check if information page has been seen
  static Future<bool> hasSeenInformationPage() async {
    await init();
    return _prefs!.getBool(_keyHasSeenInformationPage) ?? false;
  }

  /// Mark custom user info screen as seen
  static Future<bool> setHasSeenUserInfo() async {
    await init();
    return await _prefs!.setBool(_keyHasSeenUserInfo, true);
  }

  /// Check if custom user info screen has been seen
  static Future<bool> hasSeenUserInfo() async {
    await init();
    return _prefs!.getBool(_keyHasSeenUserInfo) ?? false;
  }

  /// Check if this is first launch
  static Future<bool> isFirstLaunch() async {
    await init();
    bool isFirst = !_prefs!.containsKey(_keyIsFirstLaunch);
    if (isFirst) {
      await _prefs!.setBool(_keyIsFirstLaunch, false);
    }
    return isFirst;
  }

  /// Clear all non-PII data (for testing/reset)
  static Future<bool> clearAll() async {
    await init();
    await clearAllPII(); // also wipe PII
    return await _prefs!.clear();
  }

  /// Check if user is retailer
  static Future<bool> isRetailer() async {
    String? role = await getUserRole();
    return role == 'retailer';
  }

  /// Check if user is wholesaler
  static Future<bool> isWholesaler() async {
    String? role = await getUserRole();
    return role == 'wholesaler';
  }

  // ==================== Cart Storage (Retailers) ====================

  static const String _keyCart = 'user_cart';

  /// Save cart data (for retailers)
  static Future<bool> saveCart(String cartJson) async {
    await init();
    return await _prefs!.setString(_keyCart, cartJson);
  }

  /// Get cart data
  static Future<String?> getCart() async {
    await init();
    return _prefs!.getString(_keyCart);
  }

  /// Clear cart
  static Future<bool> clearCart() async {
    await init();
    return await _prefs!.remove(_keyCart);
  }

  // ==================== Wishlist Storage ====================

  static const String _keyWishlist = 'user_wishlist';

  /// Save wishlist data
  static Future<bool> saveWishlist(String wishlistJson) async {
    await init();
    return await _prefs!.setString(_keyWishlist, wishlistJson);
  }

  /// Get wishlist data
  static Future<String?> getWishlist() async {
    await init();
    return _prefs!.getString(_keyWishlist);
  }

  /// Clear wishlist
  static Future<bool> clearWishlist() async {
    await init();
    return await _prefs!.remove(_keyWishlist);
  }
}
