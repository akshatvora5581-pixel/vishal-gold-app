import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vishal_gold/constants/app_colors.dart';
import 'package:vishal_gold/constants/app_strings.dart';
import 'package:vishal_gold/providers/auth_provider.dart';
import 'package:vishal_gold/screens/company_details/company_details_screen.dart';
import 'package:vishal_gold/screens/home/home_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  Future<void> _selectRole(BuildContext context, String role) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProvider.updateUserRole(role);

    if (!context.mounted) return;

    if (success) {
      if (role == 'wholesaler') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const CompanyDetailsScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save role'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Welcome Text
              Text(
                'Welcome to ${AppStrings.appName}!',
                style: GoogleFonts.montserrat(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.oliveGreen,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              Text(
                'I am a:',
                style: GoogleFonts.roboto(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: AppColors.black,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Wholesaler Card
              _RoleCard(
                icon: Icons.business,
                title: AppStrings.wholesaler.toUpperCase(),
                description: AppStrings.wholesalerDesc,
                onTap: () => _selectRole(context, 'wholesaler'),
              ),
              const SizedBox(height: 20),

              // Retailer Card
              _RoleCard(
                icon: Icons.store,
                title: AppStrings.retailer.toUpperCase(),
                description: AppStrings.retailerDesc,
                onTap: () => _selectRole(context, 'retailer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.oliveGreen.withValues(alpha: 0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              // ignore: deprecated_member_use
              color: AppColors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 64, color: AppColors.oliveGreen),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.roboto(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.oliveGreen,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: GoogleFonts.roboto(fontSize: 14, color: AppColors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
