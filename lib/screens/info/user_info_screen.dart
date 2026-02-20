import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vishal_gold/constants/app_colors.dart';
import 'package:vishal_gold/screens/auth/phone_auth_screen.dart';
import 'package:vishal_gold/services/local_storage_service.dart';

class UserInfoScreen extends StatefulWidget {
  const UserInfoScreen({super.key});

  @override
  State<UserInfoScreen> createState() => _UserInfoScreenState();
}

class _UserInfoScreenState extends State<UserInfoScreen> {
  final _nameController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _phoneController = TextEditingController();

  final _nameFocus = FocusNode();
  final _cityFocus = FocusNode();
  final _stateFocus = FocusNode();
  final _phoneFocus = FocusNode();

  bool _loading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _phoneController.dispose();
    _nameFocus.dispose();
    _cityFocus.dispose();
    _stateFocus.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  bool _validate() {
    if (_nameController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Please enter Name/Company Name');
      return false;
    }
    if (_cityController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Please enter City');
      return false;
    }
    if (_stateController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Please enter State');
      return false;
    }
    if (_phoneController.text.trim().length != 10) {
      setState(() => _errorMessage = 'Phone number must be exactly 10 digits');
      return false;
    }
    return true;
  }

  Future<void> _submit() async {
    if (!_validate()) return;

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      await LocalStorageService.saveUserName(_nameController.text.trim());
      await LocalStorageService.saveUserCity(_cityController.text.trim());
      await LocalStorageService.saveUserState(_stateController.text.trim());
      await LocalStorageService.saveUserPhone(_phoneController.text.trim());
      await LocalStorageService.setUserInfoProvided();

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const PhoneAuthScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to save information';
          _loading = false;
        });
      }
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
                Center(
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.gold, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.gold.withOpacity(0.2),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Image.asset(
                      'assets/logo.png',
                      fit: BoxFit.contain,
                      color: AppColors.gold,
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                Text(
                  'USER INFORMATION',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.gold,
                    letterSpacing: 1.5,
                  ),
                  textAlign: TextAlign.center,
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

                _buildTextField(
                  controller: _nameController,
                  label: 'NAME / COMPANY NAME',
                  hint: 'Enter your name or business name',
                  icon: Icons.business_outlined,
                  focusNode: _nameFocus,
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 20),

                _buildTextField(
                  controller: _cityController,
                  label: 'CITY',
                  hint: 'Enter your city',
                  icon: Icons.location_city_outlined,
                  focusNode: _cityFocus,
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 20),

                _buildTextField(
                  controller: _stateController,
                  label: 'STATE',
                  hint: 'Enter your state',
                  icon: Icons.map_outlined,
                  focusNode: _stateFocus,
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 20),

                _buildTextField(
                  controller: _phoneController,
                  label: 'PHONE NUMBER',
                  hint: '10-digit mobile number',
                  icon: Icons.phone_android_outlined,
                  focusNode: _phoneFocus,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                ),
                const SizedBox(height: 40),

                _buildPrimaryButton(
                  text: 'CONTINUE',
                  onPressed: _loading ? null : _submit,
                  isLoading: _loading,
                ),
              ],
            ),
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
    FocusNode? focusNode,
    TextInputType? keyboardType,
    int? maxLength,
    TextCapitalization textCapitalization = TextCapitalization.none,
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
