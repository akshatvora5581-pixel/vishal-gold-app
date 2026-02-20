import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vishal_gold/services/firebase_auth_service.dart';
import 'package:vishal_gold/services/firebase_service.dart';
import 'package:vishal_gold/constants/app_colors.dart';
import 'package:vishal_gold/screens/home/home_screen.dart';

class PhoneAuthScreen extends StatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final FirebaseAuthService _authService = FirebaseAuthService();
  final FirebaseService _firebaseService = FirebaseService();

  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _nameController = TextEditingController();

  // Design Focus
  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _otpFocus = FocusNode();
  final FocusNode _nameFocus = FocusNode();

  String? _verificationId;
  bool _otpSent = false;
  bool _loading = false;
  String? _errorMessage;
  bool _showNameField = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _nameController.dispose();
    _phoneFocus.dispose();
    _otpFocus.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  Future<void> _sendOTP() async {
    if (_phoneController.text.isEmpty) {
      setState(() => _errorMessage = 'Please enter phone number');
      return;
    }

    String phoneNumber = _phoneController.text.trim();
    if (!phoneNumber.startsWith('+')) {
      phoneNumber = '+91$phoneNumber'; // Default to India
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    await _authService.sendOTP(
      phoneNumber: phoneNumber,
      onCodeSent: (verificationId) {
        setState(() {
          _verificationId = verificationId;
          _otpSent = true;
          _loading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('OTP sent successfully!'),
              backgroundColor: AppColors.gold,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _errorMessage = error;
            _loading = false;
          });
        }
      },
      onAutoVerified: (user) async {
        await _handleUserLogin(user);
      },
    );
  }

  Future<void> _verifyOTP() async {
    if (_otpController.text.isEmpty || _verificationId == null) {
      setState(() => _errorMessage = 'Please enter OTP');
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      UserCredential? userCredential = await _authService.verifyOTP(
        verificationId: _verificationId!,
        smsCode: _otpController.text.trim(),
      );

      if (userCredential != null && userCredential.user != null) {
        await _handleUserLogin(userCredential.user!);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _handleUserLogin(User user) async {
    try {
      Map<String, dynamic>? userData = await _firebaseService.getUserProfile(
        user.uid,
      );

      if (userData == null) {
        setState(() {
          _showNameField = true;
          _loading = false;
        });
      } else {
        _navigateToHome();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load user data';
          _loading = false;
        });
      }
    }
  }

  Future<void> _completeRegistration() async {
    if (_nameController.text.isEmpty) {
      setState(() => _errorMessage = 'Please enter your name');
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      String userId = _authService.currentUserId!;
      await _firebaseService.saveUserProfile(
        userId: userId,
        userData: {
          'fullName': _nameController.text.trim(),
          'phone': _authService.getUserPhoneNumber(),
          'userType': 'retailer',
          'isActive': true,
        },
      );
      _navigateToHome();
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to create profile: ${e.toString()}';
          _loading = false;
        });
      }
    }
  }

  void _navigateToHome() {
    if (mounted) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo Section
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.gold, width: 2),
                    boxShadow: [
                      BoxShadow(
                        // ignore: deprecated_member_use
                        color: AppColors.gold.withOpacity(0.2),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(25),
                  child: Image.asset(
                    'assets/logo.png',
                    fit: BoxFit.contain,
                    color: AppColors
                        .gold, // Optional: Tint logo gold if it's transparent white/black
                  ),
                ),

                const SizedBox(height: 40),

                Text(
                  'VISHAL GOLD',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.gold,
                    letterSpacing: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 10),

                Text(
                  'Exclusive Jewelry Collection',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    letterSpacing: 1.0,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 60),

                // Error Message
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      // ignore: deprecated_member_use
                      color: AppColors.errorRed.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        // ignore: deprecated_member_use
                        color: AppColors.errorRed.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: AppColors.errorRed,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: AppColors.errorRed),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Content
                if (_showNameField)
                  _buildProfileCompletionView()
                else if (_otpSent)
                  _buildOtpVerificationView()
                else
                  _buildPhoneLoginView(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneLoginView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTextField(
          controller: _phoneController,
          label: 'Mobile Number',
          hint: '9876543210',
          icon: Icons.phone_iphone_rounded,
          focusNode: _phoneFocus,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 30),
        _buildPrimaryButton(
          text: 'CONTINUE',
          onPressed: _loading ? null : _sendOTP,
          isLoading: _loading,
        ),
      ],
    );
  }

  Widget _buildOtpVerificationView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Verification Code sent to',
          style: GoogleFonts.outfit(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        Text(
          _phoneController.text,
          style: GoogleFonts.outfit(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 30),
        _buildTextField(
          controller: _otpController,
          label: 'Enter OTP',
          hint: '123456',
          icon: Icons.lock_outline_rounded,
          focusNode: _otpFocus,
          keyboardType: TextInputType.number,
          maxLength: 6,
        ),
        const SizedBox(height: 30),
        _buildPrimaryButton(
          text: 'VERIFY & LOGIN',
          onPressed: _loading ? null : _verifyOTP,
          isLoading: _loading,
        ),
        const SizedBox(height: 20),
        TextButton(
          onPressed: _loading ? null : _sendOTP,
          child: Text(
            'RESEND OTP',
            style: GoogleFonts.outfit(
              color: AppColors.gold,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileCompletionView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Complete Your Profile',
          style: GoogleFonts.playfairDisplay(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.white,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 30),
        _buildTextField(
          controller: _nameController,
          label: 'Full Name',
          hint: 'Enter your business name',
          icon: Icons.person_outline_rounded,
          focusNode: _nameFocus,
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 30),
        _buildPrimaryButton(
          text: 'START EXPLORING',
          onPressed: _loading ? null : _completeRegistration,
          isLoading: _loading,
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    FocusNode? focusNode,
    TextInputType? keyboardType,
    int? maxLength,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.outfit(
            color: AppColors.gold,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          maxLength: maxLength,
          textCapitalization: textCapitalization,
          style: const TextStyle(color: AppColors.white, fontSize: 16),
          cursorColor: AppColors.gold,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white30),
            filled: true,
            fillColor: AppColors.surface,
            prefixIcon: Icon(icon, color: AppColors.gold),
            counterText: '',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.gold, width: 1),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryButton({
    required String text,
    required VoidCallback? onPressed,
    required bool isLoading,
  }) {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.black,
          elevation: 5,
          // ignore: deprecated_member_use
          shadowColor: AppColors.gold.withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation(AppColors.black),
                ),
              )
            : Text(
                text,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
      ),
    );
  }
}
