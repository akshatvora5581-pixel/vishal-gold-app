import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vishal_gold/constants/app_colors.dart';
import 'package:vishal_gold/widgets/common/custom_app_bar.dart';

class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  Future<void> _launchUrl(String url) async {
    if (!await launchUrl(Uri.parse(url))) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'CONTACT US'),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppColors.black,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.gold, width: 2),
                    ),
                    child: Center(
                      child: Image.asset(
                        'assets/logo.png',
                        width: 70,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                              Icons.business,
                              size: 50,
                              color: AppColors.gold,
                            ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'SHREE RAJENDRA GOLD PALACE',
                    style: GoogleFonts.roboto(
                      color: AppColors.gold,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'VISHAL JEWELLERS',
                    style: GoogleFonts.roboto(
                      // ignore: deprecated_member_use
                      color: AppColors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _infoCard(
                    icon: Icons.location_on,
                    title: 'Address',
                    content:
                        '1180, Madan Gopal Haveli Marg, Old City,\nMANEKCHOWK, Ahmedabad, 380001, Gujarat',
                    onTap: () {},
                  ),
                  const SizedBox(height: 16),
                  _infoCard(
                    icon: Icons.phone,
                    title: 'Phone',
                    content: '+91 9898475380',
                    onTap: () => _launchUrl('tel:+919898475380'),
                  ),
                  const SizedBox(height: 16),
                  _infoCard(
                    icon: Icons.email,
                    title: 'Email',
                    content: 'rajendragold9160@gmail.com',
                    onTap: () =>
                        _launchUrl('mailto:rajendragold9160@gmail.com'),
                  ),
                  const SizedBox(height: 16),
                  _infoCard(
                    icon: Icons.language,
                    title: 'Website',
                    content: 'https://rajendragold.com/',
                    onTap: () => _launchUrl('https://rajendragold.com/'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required String title,
    required String content,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              // ignore: deprecated_member_use
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                // ignore: deprecated_member_use
                color: AppColors.gold.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.gold),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      color: AppColors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    content,
                    style: GoogleFonts.roboto(
                      fontSize: 16,
                      color: AppColors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
