import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:vishal_gold/constants/app_colors.dart';
import 'package:vishal_gold/services/firebase_service.dart';
import 'package:vishal_gold/models/admin.dart';
import 'package:vishal_gold/screens/admin/admin_dashboard_screen.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final FirebaseService _firebaseService = FirebaseService();
  bool _loading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    String inputEmail = _emailController.text.trim();
    if (inputEmail == 'VishalGoldAdmin') {
      inputEmail = 'admin@vishalgold.com';
    }

    if (inputEmail.isEmpty || _passwordController.text.isEmpty) {
      setState(() => _errorMessage = 'Please enter ID/Email and password');
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      debugPrint('Attempting login for: $inputEmail');
      // 1. Authenticate with Firebase Auth
      final credential = await firebase_auth.FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: inputEmail,
            password: _passwordController.text.trim(),
          );

      debugPrint('Auth successful: ${credential.user?.uid}');

      if (credential.user != null) {
        // 2. Check if UID exists in 'admins' collection
        final adminData = await _firebaseService.getAdminProfile(
          credential.user!.uid,
          email: inputEmail,
        );

        debugPrint('Admin profile data: $adminData');

        if (adminData != null) {
          final adminId = adminData['id'] as String? ?? credential.user!.uid;
          final admin = Admin.fromJson(adminData, adminId);
          if (admin.isActive) {
            _navigateToAdminDashboard(admin);
          } else {
            setState(() => _errorMessage = 'Admin account is disabled');
            await firebase_auth.FirebaseAuth.instance.signOut();
          }
        } else {
          setState(() => _errorMessage = 'Not authorized as admin');
          await firebase_auth.FirebaseAuth.instance.signOut();
        }
      }
    } on firebase_auth.FirebaseAuthException catch (e) {
      debugPrint('Auth error code: ${e.code}');
      setState(
        () => _errorMessage = '[${e.code}] ${e.message ?? 'Login failed'}',
      );
    } catch (e) {
      debugPrint('Login error: $e');
      setState(() => _errorMessage = 'An error occurred: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _navigateToAdminDashboard(Admin admin) {
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => AdminDashboardScreen(admin: admin)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.gold),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'ADMIN ACCESS',
          style: GoogleFonts.outfit(
            color: AppColors.gold,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.security_rounded,
                size: 80,
                color: AppColors.gold,
              ),
              const SizedBox(height: 40),

              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: AppColors.errorRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.errorRed.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: AppColors.errorRed),
                    textAlign: TextAlign.center,
                  ),
                ),

              _buildTextField(
                controller: _emailController,
                label: 'ADMIN ID / EMAIL',
                hint: 'VishalGoldAdmin',
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _passwordController,
                label: 'PASSWORD',
                hint: '••••••••',
                icon: Icons.lock_outline,
                isPassword: true,
              ),
              const SizedBox(height: 40),

              _buildLoginButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
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
          obscureText: isPassword,
          style: const TextStyle(color: AppColors.white),
          cursorColor: AppColors.gold,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white30),
            filled: true,
            fillColor: AppColors.surface,
            prefixIcon: Icon(icon, color: AppColors.gold),
            border: OutlineInputBorder(
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

  Widget _buildLoginButton() {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: _loading ? null : _login,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _loading
            ? const CircularProgressIndicator(color: AppColors.black)
            : Text(
                'SYSTEM LOGIN',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
      ),
    );
  }
}
