import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:vishal_gold/models/user.dart' as app_models;
import 'package:vishal_gold/services/supabase_service.dart';

class AuthProvider with ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();

  app_models.User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  app_models.User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      final currentUser = _supabaseService.currentUser;
      if (currentUser != null) {
        await loadUserProfile(currentUser.id);
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _supabaseService.signUp(
        email: email,
        password: password,
        fullName: fullName,
      );

      if (response.user != null) {
        // Check if email confirmation is required
        if (response.session == null) {
          // Email confirmation is required - user created but not logged in
          _errorMessage =
              'Please check your email and click the confirmation link to complete signup';
          return true; // Signup was successful, just needs email confirmation
        }

        // User is logged in, load profile
        await loadUserProfile(response.user!.id);
        return true;
      }
      _errorMessage = 'Signup failed. Please try again.';
      return false;
    } on supabase.AuthException catch (e) {
      // Handle specific Supabase auth errors with user-friendly messages
      if (e.message.contains('rate limit') || e.message.contains('429')) {
        _errorMessage =
            'Too many signup attempts. Please wait a few minutes and try again.';
      } else if (e.message.contains('already registered') ||
          e.message.contains('already exists')) {
        _errorMessage =
            'An account with this email already exists. Please login instead.';
      } else if (e.message.contains('invalid email')) {
        _errorMessage = 'Please enter a valid email address.';
      } else if (e.message.contains('password')) {
        _errorMessage = 'Password must be at least 6 characters long.';
      } else {
        _errorMessage = e.message;
      }
      return false;
    } catch (e) {
      _errorMessage = 'An error occurred during signup: ${e.toString()}';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signIn({required String email, required String password}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _supabaseService.signIn(
        email: email,
        password: password,
      );

      if (response.user != null) {
        await loadUserProfile(response.user!.id);
        return true;
      }
      return false;
    } on supabase.AuthException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'An error occurred during login';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _supabaseService.signOut();
      _user = null;
    } catch (e) {
      _errorMessage = 'Failed to sign out';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> resetPassword(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _supabaseService.resetPassword(email);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to send reset email';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadUserProfile(String userId) async {
    try {
      final profile = await _supabaseService.getUserProfile(userId);
      _user = profile;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load user profile';
    }
  }

  Future<bool> updateUserRole(String role) async {
    if (_user == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      await _supabaseService.saveUserRole(_user!.id, role);
      _user = _user!.copyWith(userType: role);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update role';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateCompanyDetails({
    required String companyName,
    required String address,
    required String city,
  }) async {
    if (_user == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      await _supabaseService.saveCompanyDetails(
        userId: _user!.id,
        companyName: companyName,
        address: address,
        city: city,
      );

      _user = _user!.copyWith(
        companyName: companyName,
        companyAddress: address,
        city: city,
      );
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update company details';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    if (_user == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      await _supabaseService.updateUserProfile(_user!.id, data);
      await loadUserProfile(_user!.id);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update profile';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
