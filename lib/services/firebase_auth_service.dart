import 'package:firebase_auth/firebase_auth.dart';

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
            onError('Auto-verification failed: ${e.toString()}');
          }
        },

        // Called when verification fails
        verificationFailed: (FirebaseAuthException e) {
          String errorMessage = 'Verification failed';
          if (e.code == 'invalid-phone-number') {
            errorMessage = 'Invalid phone number format';
          } else if (e.code == 'too-many-requests') {
            errorMessage = 'Too many requests. Please try again later';
          } else {
            errorMessage = e.message ?? 'Verification failed';
          }
          onError(errorMessage);
        },

        // Called when OTP is sent successfully
        codeSent: (String verificationId, int? resendToken) {
          onCodeSent(verificationId);
        },

        // Called when auto-retrieval times out
        codeAutoRetrievalTimeout: (String verificationId) {
          // No action needed for timeout
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
      if (e.code == 'invalid-verification-code') {
        throw 'Invalid OTP code. Please try again.';
      } else if (e.code == 'session-expired') {
        throw 'OTP expired. Please request a new code.';
      } else {
        throw e.message ?? 'Verification failed';
      }
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
  }) async {
    await sendOTP(
      phoneNumber: phoneNumber,
      onCodeSent: onCodeSent,
      onError: onError,
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
