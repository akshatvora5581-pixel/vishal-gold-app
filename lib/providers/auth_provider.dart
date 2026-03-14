import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vishal_gold/services/firebase_auth_service.dart';
import 'package:vishal_gold/services/firebase_service.dart';
import 'package:vishal_gold/services/local_storage_service.dart';
import 'package:vishal_gold/services/fcm_service.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:vishal_gold/services/audit_service.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuthService _authService = FirebaseAuthService();
  final FirebaseService _firebaseService = FirebaseService();
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  static const String _quickLoginOptOutKey = 'quick_login_opt_out';
  static const String _pinHashKey = 'user_pin_hash';
  static const String _adminPinRawKey = 'admin_pin_raw';
  static const String _isPinSetKey = 'is_pin_set_flag';
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _adminEmailKey = 'admin_quick_login_email';
  static const String _adminPasswordKey = 'admin_quick_login_password';
  static const String _isSetupCompleteKey = 'admin_setup_complete';

  bool _isBiometricEnabled = false;
  bool _isPinSet = false;
  bool _hasPinSetup = false;
  bool _hasOptedOutQuickLogin = false;
  bool _canCheckBiometrics = false;
  bool _isSetupComplete = false;

  User? _currentUser;
  String? _userRole;
  Map<String, dynamic>? _userProfile;
  bool _isLoading = false;

  // Getters
  User? get currentUser => _currentUser;
  String? get userRole => _userRole;
  Map<String, dynamic>? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;
  bool get isRetailer => _userRole == 'retailer';
  bool get isWholesaler => _userRole == 'wholesaler';
  bool get isAdmin => _userRole == 'admin';

  // Quick Login Getters
  bool get isBiometricEnabled => _isBiometricEnabled;
  bool get hasPinSetup => _hasPinSetup;
  bool get isPinSet => _isPinSet;
  bool get hasOptedOutQuickLogin => _hasOptedOutQuickLogin;
  bool get canCheckBiometrics => _canCheckBiometrics;
  bool get isSetupComplete => _isSetupComplete;

  AuthProvider() {
    _initializeAuth();
    _listenToAuthState();
  }

  void _listenToAuthState() {
    _authService.authStateChanges.listen((user) {
      if (_currentUser?.uid != user?.uid) {
        _currentUser = user;
        if (user != null) {
          _loadUserProfile();
        } else {
          _userProfile = null;
          _userRole = null;
        }
        notifyListeners();
      }
    });
  }

  /// Initialize authentication state
  Future<void> _initializeAuth() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Get Firebase Auth user
      _currentUser = _authService.currentUser;

      // Get user role from local storage
      _userRole = await LocalStorageService.getUserRole();

      // Check quick login settings
      await _checkQuickLoginSettings();

      // Fetch profile from Firestore if logged in
      if (_currentUser != null) {
        await _loadUserProfile();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Auth initialization error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load user profile from Firestore
  Future<void> _loadUserProfile() async {
    if (_currentUser == null) return;

    try {
      _userProfile = await _firebaseService.getUserProfile(_currentUser!.uid);

      if (_userProfile == null) {
        final localName = await LocalStorageService.getUserName();
        final localPhone = await LocalStorageService.getUserPhone();
        _userProfile = {
          'uid': _currentUser!.uid,
          'fullName': localName ?? _currentUser!.displayName ?? 'User',
          'name': localName ?? _currentUser!.displayName ?? 'User',
          'email': _currentUser!.email ?? '',
          'phone': localPhone ?? _currentUser!.phoneNumber ?? '',
          'role': _userRole ?? 'retailer',
        };
      } else {
        if (_userProfile!['fullName'] == null && _userProfile!['name'] == null) {
          final localName = await LocalStorageService.getUserName();
          if (localName != null && localName.isNotEmpty) {
            _userProfile!['fullName'] = localName;
            _userProfile!['name'] = localName;
          } else {
            _userProfile!['fullName'] = _currentUser!.displayName ?? 'User';
            _userProfile!['name'] = _currentUser!.displayName ?? 'User';
          }
        }
      }

      // Update FCM token
      await FCMService().updateUserToken(
        _currentUser!.uid,
        isAdmin: _userProfile!['isAdmin'] == true || _userRole == 'admin',
      );

      notifyListeners();
    } catch (e) {
      if (kDebugMode) debugPrint('Failed to load user profile: $e');
      // Set a fallback profile on error to prevent infinite spinner
      _userProfile = {
        'uid': _currentUser?.uid ?? '',
        'name': 'User',
        'email': _currentUser?.email ?? '',
        'role': _userRole ?? 'retailer',
      };
      notifyListeners();
    }
  }

  /// Sign out (keeps Quick Login credentials for re-auth)
  Future<void> signOut() async {
    try {
      _isLoading = true;
      notifyListeners();

      await _authService.signOut();
      await LocalStorageService.clearUserRole();

      _currentUser = null;
      _userRole = null;
      _userProfile = null;

      notifyListeners();
    } catch (e) {
      if (kDebugMode) debugPrint('Sign out error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Full admin sign-out: clears ALL security data (PIN, biometrics, stored
  /// credentials) and resets Firebase Auth. Use this for the Super Admin
  /// logout button so nothing persists.
  Future<void> signOutAdmin() async {
    try {
      _isLoading = true;
      notifyListeners();

      // 1. Firebase sign-out
      await FirebaseAuth.instance.signOut();
      await _authService.signOut();

      // 2. Clear ALL security data from secure storage
      await _secureStorage.deleteAll();

      // 3. Clear SharedPreferences flags
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_quickLoginOptOutKey);
      await prefs.remove(_isSetupCompleteKey);

      // 4. Clear local user role
      await LocalStorageService.clearUserRole();

      // 5. Reset in-memory state
      _currentUser = null;
      _userRole = null;
      _userProfile = null;
      _hasPinSetup = false;
      _isPinSet = false;
      _isBiometricEnabled = false;
      _hasOptedOutQuickLogin = false;
      _isSetupComplete = false;

      notifyListeners();
    } catch (e) {
      if (kDebugMode) debugPrint('Admin sign out error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Safe admin panel exit: clears ONLY admin-specific local flags (PIN,
  /// biometrics, quick-login credentials) WITHOUT touching Firebase Auth.
  ///
  /// Use this when the admin is exiting back to the normal user home screen,
  /// so the underlying Firebase user session remains perfectly active and the
  /// User Profile / Home screen keeps working without any "Authentication
  /// Required" errors.
  Future<void> signOutAdminSession() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Clear admin PIN & biometric flags from secure storage only.
      // Do NOT call FirebaseAuth.signOut() — the normal user session must survive.
      await _secureStorage.delete(key: _adminPinRawKey);
      await _secureStorage.delete(key: _pinHashKey);
      await _secureStorage.delete(key: _isPinSetKey);
      await _secureStorage.delete(key: _biometricEnabledKey);
      await _secureStorage.delete(key: _adminEmailKey);
      await _secureStorage.delete(key: _adminPasswordKey);

      // Clear setup flags from SharedPreferences.
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_quickLoginOptOutKey);
      await prefs.remove(_isSetupCompleteKey);

      // Reset only the admin-specific in-memory state.
      // _currentUser, _userRole, and _userProfile are deliberately preserved
      // so the normal Firebase user remains authenticated.
      _hasPinSetup = false;
      _isPinSet = false;
      _isBiometricEnabled = false;
      _hasOptedOutQuickLogin = false;
      _isSetupComplete = false;

      notifyListeners();
    } catch (e) {
      if (kDebugMode) debugPrint('Admin session exit error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sign in admin and optionally save credentials for quick login
  Future<bool> signInAdmin(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      final UserCredential credential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      if (credential.user != null) {
        _currentUser = credential.user;

        // Log the login activity
        await AuditService().logAction(
          action: 'Admin Login',
          details: 'Logged in via email/password',
          targetType: 'Auth',
        );

        // If quick login is already enabled, update the stored password/email
        // in case they changed their password.
        if (_hasPinSetup || _isBiometricEnabled) {
          await _saveQuickLoginCredentials(email, password);
        }

        await _loadUserProfile();
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) debugPrint('Admin login error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sign in using stored credentials (PIN/Biometric success callback)
  Future<bool> signInWithStoredCredentials() async {
    try {
      _isLoading = true;
      notifyListeners();

      final email = await _secureStorage.read(key: _adminEmailKey);
      final password = await _secureStorage.read(key: _adminPasswordKey);

      if (kDebugMode) {
        debugPrint(
          'Quick login attempt - Stored Email found: ${email != null}',
        );
        debugPrint(
          'Quick login attempt - Stored Password found: ${password != null}',
        );
      }

      if (email != null && password != null) {
        if (kDebugMode) debugPrint('Attempting re-auth for: $email');
        final UserCredential credential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(email: email, password: password);

        if (credential.user != null) {
          _currentUser = credential.user;

          // Log the login activity
          await AuditService().logAction(
            action: 'Quick Login',
            details: 'Logged in via stored credentials (PIN/Biometric)',
            targetType: 'Auth',
          );

          await _loadUserProfile();
          if (kDebugMode) debugPrint('Quick login re-auth SUCCESS');
          return true;
        }
      } else {
        if (kDebugMode) {
          debugPrint(
            'Quick login FAILED: Missing credentials in secure storage.',
          );
        }
      }
      return false;
    } catch (e) {
      if (kDebugMode) debugPrint('Quick login re-auth error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveQuickLoginCredentials(String email, String password) async {
    if (kDebugMode) debugPrint('Saving Quick Login credentials for: $email');
    await _secureStorage.write(key: _adminEmailKey, value: email);
    await _secureStorage.write(key: _adminPasswordKey, value: password);
    if (kDebugMode) debugPrint('Credentials securely stored.');
  }

  /// Update user profile
  Future<void> updateProfile(Map<String, dynamic> updates) async {
    if (_currentUser == null) return;

    try {
      _isLoading = true;
      notifyListeners();

      await _firebaseService.updateUserProfile(
        userId: _currentUser!.uid,
        updates: updates,
      );

      if (updates.containsKey('fullName') || updates.containsKey('name')) {
        final newName = updates['fullName'] ?? updates['name'];
        if (newName != null && newName.toString().isNotEmpty) {
          await LocalStorageService.saveUserName(newName.toString());
        }
      }

      // Reload profile
      await _loadUserProfile();
    } catch (e) {
      if (kDebugMode) debugPrint('Update profile error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh user data
  Future<void> refresh() async {
    await _initializeAuth();
  }

  // ==========================================
  // Quick Login Methods (Biometrics & PIN)
  // ==========================================

  Future<void> _checkQuickLoginSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _hasOptedOutQuickLogin = prefs.getBool(_quickLoginOptOutKey) ?? false;
      _isSetupComplete = prefs.getBool(_isSetupCompleteKey) ?? false;

      final String? pinHash = await _secureStorage.read(key: _pinHashKey);
      _hasPinSetup = pinHash != null && pinHash.isNotEmpty;

      final String? isPinSetFlag = await _secureStorage.read(key: _isPinSetKey);
      _isPinSet = isPinSetFlag == 'true';

      final String? biometricStr = await _secureStorage.read(
        key: _biometricEnabledKey,
      );
      _isBiometricEnabled = biometricStr == 'true';

      _canCheckBiometrics =
          await _localAuth.canCheckBiometrics ||
          await _localAuth.isDeviceSupported();
      notifyListeners();
    } catch (e) {
      if (kDebugMode) debugPrint('Error checking quick login settings: $e');
    }
  }

  Future<void> optOutQuickLogin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_quickLoginOptOutKey, true);
    _hasOptedOutQuickLogin = true;
    notifyListeners();
  }

  Future<void> markSetupComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isSetupCompleteKey, true);
    _isSetupComplete = true;
    notifyListeners();
  }

  // --- Biometrics ---

  Future<bool> setupBiometric(String password) async {
    try {
      if (!await _localAuth.canCheckBiometrics &&
          !await _localAuth.isDeviceSupported()) {
        return false;
      }

      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason:
            'Please authenticate to enable biometric login for Admin Console',
        persistAcrossBackgrounding: true,
        biometricOnly: true,
      );

      if (didAuthenticate) {
        await _secureStorage.write(key: _biometricEnabledKey, value: 'true');
        _isBiometricEnabled = true;

        // Also save current credentials
        final user = _currentUser ?? FirebaseAuth.instance.currentUser;
        if (user?.email != null) {
          await _saveQuickLoginCredentials(user!.email!, password);
        }

        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) debugPrint('Biometric setup error: $e');
      return false;
    }
  }

  Future<bool> authenticateWithBiometric() async {
    if (!_isBiometricEnabled) return false;
    try {
      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to access the Admin Console',
        persistAcrossBackgrounding: true,
        biometricOnly: true,
      );

      if (didAuthenticate) {
        // Assuming user is already signed in via Firebase Auth previously and session persists.
        // If we needed to re-auth Firebase, we would need to store the password securely,
        // but for now, we just trust the Biometric prompt as a lock screen over the app.
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) debugPrint('Biometric auth error: $e');
      return false;
    }
  }

  Future<void> disableBiometric() async {
    await _secureStorage.delete(key: _biometricEnabledKey);
    _isBiometricEnabled = false;
    notifyListeners();
  }

  // --- PIN Authentication ---

  String _hashPin(String pin) {
    var bytes = utf8.encode(pin);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<bool> setupPin(String pin, String password) async {
    try {
      if (pin.length != 4) return false;
      
      // Save raw PIN as requested
      await _secureStorage.write(key: _adminPinRawKey, value: pin);
      
      // Also maintain legacy hash if needed, but primarily use flag
      final String hashedPin = _hashPin(pin);
      await _secureStorage.write(key: _pinHashKey, value: hashedPin);
      await _secureStorage.write(key: _isPinSetKey, value: 'true');
      
      _hasPinSetup = true;
      _isPinSet = true;

      // Also save current credentials
      final user = _currentUser ?? FirebaseAuth.instance.currentUser;
      if (user?.email != null) {
        await _saveQuickLoginCredentials(user!.email!, password);
      }

      notifyListeners();
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('PIN setup error: $e');
      return false;
    }
  }

  Future<bool> authenticateWithPin(String pin) async {
    try {
      final String? storedPin = await _secureStorage.read(key: _adminPinRawKey);
      if (storedPin == null) {
        // Fallback to hash comparison for legacy support
        final String? storedHash = await _secureStorage.read(key: _pinHashKey);
        if (storedHash == null) return false;
        return storedHash == _hashPin(pin);
      }
      return storedPin == pin;
    } catch (e) {
      if (kDebugMode) debugPrint('PIN auth error: $e');
      return false;
    }
  }

  Future<void> clearPin() async {
    await _secureStorage.delete(key: _adminPinRawKey);
    await _secureStorage.delete(key: _pinHashKey);
    await _secureStorage.delete(key: _isPinSetKey);
    _hasPinSetup = false;
    _isPinSet = false;
    notifyListeners();
  }

  Future<void> clearQuickLogin() async {
    _isLoading = true;
    notifyListeners();

    await disableBiometric();
    await clearPin();
    await _secureStorage.delete(key: _adminEmailKey);
    await _secureStorage.delete(key: _adminPasswordKey);

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_quickLoginOptOutKey);
    _hasOptedOutQuickLogin = false;

    _isLoading = false;
    notifyListeners();
  }

  // ==========================================

  bool hasRole(String role) {
    return _userRole == role;
  }

  /// Sign in as guest (Retailer)
  Future<void> signInAsGuest() async {
    try {
      _isLoading = true;
      notifyListeners();

      await _authService.signInAnonymously();

      // Update role
      _userRole = 'retailer';
      await LocalStorageService.saveUserRole('retailer');

      await _loadUserProfile();
    } catch (e) {
      if (kDebugMode) debugPrint('Guest sign in error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get user display name
  String get displayName {
    if (_userProfile != null && _userProfile!['fullName'] != null) {
      return _userProfile!['fullName'];
    }
    if (_currentUser != null && _currentUser!.displayName != null) {
      return _currentUser!.displayName!;
    }
    return 'Guest';
  }

  /// Get user phone number
  String? get phoneNumber {
    if (_userProfile != null && _userProfile!['phone'] != null) {
      return _userProfile!['phone'];
    }
    return _currentUser?.phoneNumber;
  }
}
