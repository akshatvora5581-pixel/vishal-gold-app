import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing local storage using SharedPreferences
class LocalStorageService {
  static const String _keyUserRole = 'user_role';
  static const String _keyIsFirstLaunch = 'is_first_launch';
  static const String _keyUserName = 'user_name';
  static const String _keyUserCity = 'user_city';
  static const String _keyUserState = 'user_state';
  static const String _keyUserPhone = 'user_phone';
  static const String _keyIsUserInfoProvided = 'is_user_info_provided';

  static SharedPreferences? _prefs;

  /// Initialize SharedPreferences
  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Save user role (retailer or wholesaler)
  static Future<bool> saveUserRole(String role) async {
    await init();
    return await _prefs!.setString(_keyUserRole, role);
  }

  /// Get user role
  static Future<String?> getUserRole() async {
    await init();
    return _prefs!.getString(_keyUserRole);
  }

  /// Check if user has selected a role
  static Future<bool> isRoleSelected() async {
    await init();
    return _prefs!.containsKey(_keyUserRole);
  }

  /// Clear user role (for testing/logout)
  static Future<bool> clearUserRole() async {
    await init();
    return await _prefs!.remove(_keyUserRole);
  }

  /// Save user name
  static Future<bool> saveUserName(String name) async {
    await init();
    return await _prefs!.setString(_keyUserName, name);
  }

  /// Get user name
  static Future<String?> getUserName() async {
    await init();
    return _prefs!.getString(_keyUserName);
  }

  /// Save user city
  static Future<bool> saveUserCity(String city) async {
    await init();
    return await _prefs!.setString(_keyUserCity, city);
  }

  /// Get user city
  static Future<String?> getUserCity() async {
    await init();
    return _prefs!.getString(_keyUserCity);
  }

  /// Save user state
  static Future<bool> saveUserState(String state) async {
    await init();
    return await _prefs!.setString(_keyUserState, state);
  }

  /// Get user state
  static Future<String?> getUserState() async {
    await init();
    return _prefs!.getString(_keyUserState);
  }

  /// Save user phone
  static Future<bool> saveUserPhone(String phone) async {
    await init();
    return await _prefs!.setString(_keyUserPhone, phone);
  }

  /// Get user phone
  static Future<String?> getUserPhone() async {
    await init();
    return _prefs!.getString(_keyUserPhone);
  }

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

  /// Check if this is first launch
  static Future<bool> isFirstLaunch() async {
    await init();
    bool isFirst = !_prefs!.containsKey(_keyIsFirstLaunch);
    if (isFirst) {
      await _prefs!.setBool(_keyIsFirstLaunch, false);
    }
    return isFirst;
  }

  /// Clear all data (for testing/reset)
  static Future<bool> clearAll() async {
    await init();
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
