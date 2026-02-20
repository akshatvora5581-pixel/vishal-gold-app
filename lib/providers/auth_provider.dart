import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vishal_gold/services/firebase_auth_service.dart';
import 'package:vishal_gold/services/firebase_service.dart';
import 'package:vishal_gold/services/local_storage_service.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuthService _authService = FirebaseAuthService();
  final FirebaseService _firebaseService = FirebaseService();

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

  AuthProvider() {
    _initializeAuth();
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

      // Fetch profile from Firestore if logged in
      if (_currentUser != null) {
        await _loadUserProfile();
      }
    } catch (e) {
      debugPrint('Auth initialization error: $e');
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

      // If no profile found in Firestore, create a basic one from Firebase Auth
      _userProfile ??= {
          'uid': _currentUser!.uid,
          'name': _currentUser!.displayName ?? 'User',
          'email': _currentUser!.email ?? '',
          'phone': _currentUser!.phoneNumber ?? '',
          'role': _userRole ?? 'retailer',
        };
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load user profile: $e');
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

  /// Sign out
  Future<void> signOut() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Sign out from Firebase
      await _authService.signOut();

      // Clear local storage
      await LocalStorageService.clearUserRole();

      // Clear state
      _currentUser = null;
      _userRole = null;
      _userProfile = null;

      notifyListeners();
    } catch (e) {
      debugPrint('Sign out error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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

      // Reload profile
      await _loadUserProfile();
    } catch (e) {
      debugPrint('Update profile error: $e');
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
      debugPrint('Guest sign in error: $e');
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
