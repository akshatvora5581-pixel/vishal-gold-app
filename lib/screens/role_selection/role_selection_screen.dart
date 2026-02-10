import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vishal_gold/constants/app_colors.dart';
import 'package:vishal_gold/constants/app_strings.dart';
import 'package:vishal_gold/services/local_storage_service.dart';
import 'package:provider/provider.dart';
import 'package:vishal_gold/providers/auth_provider.dart';
import 'package:vishal_gold/screens/auth/phone_auth_screen.dart';
import 'package:vishal_gold/screens/home/home_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  Future<void> _selectRole(BuildContext context, String role) async {
    // Save role to local storage
    await LocalStorageService.saveUserRole(role);

    if (!context.mounted) return;

    if (role == 'retailer') {
      try {
        await Provider.of<AuthProvider>(context, listen: false).signInAsGuest();
        if (!context.mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to login as guest: $e')));
      }
    } else if (role == 'wholesaler') {
      // Wholesaler - go to phone auth screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const PhoneAuthScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App Logo
                  Center(
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.white,
                      ),
                      padding: const EdgeInsets.all(10),
                      child: Image.asset(
                        AppStrings.logoPath,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Welcome Text
                  Text(
                    AppStrings.appName.toUpperCase(),
                    style: GoogleFonts.montserrat(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                      letterSpacing: 2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 60),

                  Text(
                    'CONTINUE AS:',
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.grey,
                      letterSpacing: 1,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Wholesaler Button
                  _OriginalRoleButton(
                    title: AppStrings.wholesaler.toUpperCase(),
                    onTap: () => _selectRole(context, 'wholesaler'),
                  ),
                  const SizedBox(height: 20),

                  // Retailer Button
                  _OriginalRoleButton(
                    title: AppStrings.retailer.toUpperCase(),
                    onTap: () => _selectRole(context, 'retailer'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OriginalRoleButton extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const _OriginalRoleButton({required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.black,
        foregroundColor: AppColors.gold,
        padding: const EdgeInsets.symmetric(vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }
}
