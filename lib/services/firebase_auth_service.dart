import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Send OTP to phone number
  Future<void> sendOTP({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onError,
    required VoidCallback onTimeout,
    Function(User user)? onAutoVerified,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),

        // Called when SMS is auto-verified (Android only)
        verificationCompleted: (PhoneAuthCredential credential) async {
          try {
            UserCredential userCredential = await _auth.signInWithCredential(
              credential,
            );
            if (onAutoVerified != null && userCredential.user != null) {
              onAutoVerified(userCredential.user!);
            }
          } catch (e) {
            onError('The app was unable to automatically verify your code. Please enter it manually below.');
          }
        },

        // Called when verification fails
        verificationFailed: (FirebaseAuthException e) {
          String errorMessage;
          switch (e.code) {
            case 'invalid-phone-number':
              errorMessage = 'Invalid phone number format.';
              break;
            case 'too-many-requests':
              errorMessage = 'Request blocked due to unusual activity or quota. Try again later.';
              break;
            case 'network-request-failed':
              errorMessage = 'Please check your internet connection.';
              break;
            case 'app-not-authorized':
              errorMessage = 'App verification failed (App Check/Play Integrity).';
              break;
            case 'web-context-cancelled':
              errorMessage = 'reCAPTCHA verification was cancelled.';
              break;
            default:
              errorMessage = e.message ?? 'Authentication failed. Please try again.';
          }
          onError(errorMessage);
        },

        // Called when OTP is sent successfully
        codeSent: (String verificationId, int? resendToken) {
          onCodeSent(verificationId);
        },

        // Called when auto-retrieval times out
        codeAutoRetrievalTimeout: (String verificationId) {
          onTimeout();
        },
      );
    } catch (e) {
      onError('Failed to send OTP: ${e.toString()}');
    }
  }

  /// Verify OTP code
  Future<UserCredential?> verifyOTP({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'invalid-verification-code':
          errorMessage = 'The OTP you entered is incorrect. Please try again.';
          break;
        case 'session-expired':
          errorMessage = 'OTP expired. Please request a new code.';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many attempts. Please try again after some time.';
          break;
        case 'network-request-failed':
          errorMessage = 'No internet connection.';
          break;
        default:
          errorMessage = 'Something went wrong. Please check your details and try again.';
      }
      throw errorMessage;
    } catch (e) {
      throw 'Failed to verify OTP: ${e.toString()}';
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Check if user is logged in
  bool isLoggedIn() {
    return _auth.currentUser != null;
  }

  /// Get user phone number
  String? getUserPhoneNumber() {
    return _auth.currentUser?.phoneNumber;
  }

  /// Resend OTP
  Future<void> resendOTP({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onError,
    required VoidCallback onTimeout,
  }) async {
    await sendOTP(
      phoneNumber: phoneNumber,
      onCodeSent: onCodeSent,
      onError: onError,
      onTimeout: onTimeout,
    );
  }

  /// Delete current user account
  Future<void> deleteAccount() async {
    try {
      await _auth.currentUser?.delete();
    } catch (e) {
      throw 'Failed to delete account: ${e.toString()}';
    }
  }

  /// Update user phone number
  Future<void> updatePhoneNumber({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      await _auth.currentUser?.updatePhoneNumber(credential);
    } catch (e) {
      throw 'Failed to update phone number: ${e.toString()}';
    }
  }

  /// Sign in anonymously
  Future<UserCredential> signInAnonymously() async {
    try {
      return await _auth.signInAnonymously();
    } catch (e) {
      throw 'Failed to sign in anonymously: ${e.toString()}';
    }
  }
}
