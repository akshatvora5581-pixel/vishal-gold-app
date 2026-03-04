import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vishal_gold/providers/auth_provider.dart';
import 'package:vishal_gold/constants/app_colors.dart';
import 'package:vishal_gold/screens/auth/setup_pin_screen.dart';

class QuickLoginSetupScreen extends StatefulWidget {
  final String password;
  final VoidCallback onSkip;

  const QuickLoginSetupScreen({
    super.key,
    required this.password,
    required this.onSkip,
  });

  @override
  State<QuickLoginSetupScreen> createState() => _QuickLoginSetupScreenState();
}

class _QuickLoginSetupScreenState extends State<QuickLoginSetupScreen> {
  bool _isLoading = false;

  void _setupBiometric() async {
    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProvider.setupBiometric(widget.password);

    setState(() => _isLoading = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Biometric authentication enabled successfully!'),
        ),
      );
      widget.onSkip(); // Proceed to next screen
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Failed to setup biometric authentication. You can setup PIN instead.',
          ),
        ),
      );
    }
  }

  void _setupPin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => SetupPinScreen(
          password: widget.password,
          onSetupComplete: widget.onSkip,
        ),
      ),
    );
  }

  void _skip() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.optOutQuickLogin();
    widget.onSkip();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Quick Login Setup',
          style: TextStyle(color: AppColors.softGold),
        ),
        backgroundColor: AppColors.surface,
        iconTheme: const IconThemeData(color: AppColors.softGold),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Image.asset('assets/logo.png', height: 120, fit: BoxFit.contain),
              const SizedBox(height: 24),
              const Text(
                'Enable Quick Login',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'To make your future logins easier, you can enable Biometric (Fingerprint/FaceID) or PIN based authentication.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              if (_isLoading)
                const Center(
                  child: CircularProgressIndicator(color: AppColors.softGold),
                )
              else ...[
                if (authProvider.canCheckBiometrics) ...[
                  ElevatedButton.icon(
                    onPressed: _setupBiometric,
                    icon: const Icon(
                      Icons.fingerprint,
                      color: AppColors.background,
                    ),
                    label: const Text(
                      'Setup Biometrics',
                      style: TextStyle(
                        color: AppColors.background,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.softGold,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                OutlinedButton.icon(
                  onPressed: _setupPin,
                  icon: const Icon(Icons.pin, color: AppColors.softGold),
                  label: const Text(
                    'Setup PIN',
                    style: TextStyle(
                      color: AppColors.softGold,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.softGold),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _skip,
                  child: const Text(
                    'Skip for now',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
