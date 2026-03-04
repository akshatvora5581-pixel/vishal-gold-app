import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vishal_gold/constants/app_colors.dart';
import 'package:vishal_gold/providers/auth_provider.dart';
import 'package:vishal_gold/screens/auth/setup_pin_screen.dart';

class QuickLoginSettingsScreen extends StatefulWidget {
  const QuickLoginSettingsScreen({super.key});

  @override
  State<QuickLoginSettingsScreen> createState() =>
      _QuickLoginSettingsScreenState();
}

class _QuickLoginSettingsScreenState extends State<QuickLoginSettingsScreen> {
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<String?> _promptForPassword() async {
    _passwordController.clear();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Confirm Password',
          style: GoogleFonts.playfairDisplay(color: AppColors.gold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Please enter your admin password to enable quick login.',
              style: GoogleFonts.outfit(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Admin Password',
                hintStyle: const TextStyle(color: AppColors.textTertiary),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: AppColors.gold.withValues(alpha: 0.5),
                  ),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.gold),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'CANCEL',
              style: GoogleFonts.outfit(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, _passwordController.text),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold),
            child: Text(
              'CONFIRM',
              style: GoogleFonts.outfit(
                color: AppColors.background,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isBiometricEnabled = authProvider.isBiometricEnabled;
    final hasPinSetup = authProvider.hasPinSetup;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Quick Login Settings',
          style: GoogleFonts.playfairDisplay(
            color: AppColors.gold,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.surface,
        iconTheme: const IconThemeData(color: AppColors.gold),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Manage your quick login preferences to easily access the admin dashboard.',
              style: GoogleFonts.outfit(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 32),
            _buildSettingsCard(
              title: 'Biometric Authentication',
              subtitle: 'Use Fingerprint or FaceID to unlock',
              icon: Icons.fingerprint,
              trailing: Switch(
                value: isBiometricEnabled,
                activeThumbColor: AppColors.gold,
                onChanged: (val) async {
                  if (val) {
                    final password = await _promptForPassword();
                    if (password != null && password.isNotEmpty) {
                      await authProvider.setupBiometric(password);
                    }
                  } else {
                    await authProvider.clearQuickLogin();
                  }
                  setState(() {});
                },
              ),
            ),
            const SizedBox(height: 16),
            _buildSettingsCard(
              title: hasPinSetup ? 'Change PIN' : 'Setup PIN',
              subtitle: 'Use a 4-digit PIN to unlock',
              icon: Icons.dialpad,
              onTap: () async {
                final password = await _promptForPassword();
                if (password != null &&
                    password.isNotEmpty &&
                    context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SetupPinScreen(
                        password: password,
                        onSetupComplete: () {
                          setState(() {});
                        },
                      ),
                    ),
                  );
                }
              },
            ),
            if (isBiometricEnabled || hasPinSetup) ...[
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await authProvider.clearQuickLogin();
                    setState(() {});
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Quick login removed successfully.',
                            style: GoogleFonts.outfit(
                              color: AppColors.background,
                            ),
                          ),
                          backgroundColor: AppColors.gold,
                        ),
                      );
                    }
                  },
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppColors.errorRed,
                  ),
                  label: Text(
                    'REMOVE QUICK LOGIN',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      color: AppColors.errorRed,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: AppColors.errorRed),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard({
    required String title,
    required String subtitle,
    required IconData icon,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.1)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.gold),
        ),
        title: Text(
          title,
          style: GoogleFonts.outfit(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.outfit(
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
        ),
        trailing:
            trailing ??
            const Icon(
              Icons.arrow_forward_ios,
              color: AppColors.textTertiary,
              size: 16,
            ),
        onTap: trailing == null ? onTap : null,
      ),
    );
  }
}
