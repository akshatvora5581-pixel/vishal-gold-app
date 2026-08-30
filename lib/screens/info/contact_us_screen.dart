import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vishal_jewelers/constants/app_colors.dart';
import 'package:vishal_jewelers/widgets/common/custom_app_bar.dart';
import 'package:vishal_jewelers/services/firebase_service.dart';

class ContactUsScreen extends StatefulWidget {
  const ContactUsScreen({super.key});

  @override
  State<ContactUsScreen> createState() => _ContactUsScreenState();
}

class _ContactUsScreenState extends State<ContactUsScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  late Future<Map<String, dynamic>> _contactInfoFuture;

  @override
  void initState() {
    super.initState();
    _contactInfoFuture = _firebaseService.getGlobalContactInfo();
  }

  Future<void> _launchUrl(String urlString) async {
    final cleanUrl = urlString.trim();
    if (cleanUrl.isEmpty) return;

    final uri = Uri.tryParse(cleanUrl);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      debugPrint('Could not launch \$cleanUrl');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'CONTACT US'),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _contactInfoFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: AppColors.gold),
            );
          }

          final contactData = snapshot.data ?? {};
          final address =
              contactData['address'] ??
              '1180, Madan Gopal Haveli Marg, Old City,\\nMANEKCHOWK, Ahmedabad, 380001, Gujarat';
          final phone = contactData['phone'] ?? '+91 9898475380';
          final email = contactData['email'] ?? 'rajendragold9160@gmail.com';
          final website = contactData['website'] ?? 'https://rajendragold.com/';

          return SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
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
                                Icon(
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
                          color: AppColors.white.withValues(alpha: 0.8),
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
                        content: address,
                        onTap: () {},
                      ),
                      const SizedBox(height: 16),
                      _infoCard(
                        icon: Icons.phone,
                        title: 'Phone',
                        content: phone,
                        onTap: () => _launchUrl('tel:\$phone'),
                      ),
                      const SizedBox(height: 16),
                      _infoCard(
                        icon: Icons.email,
                        title: 'Email',
                        content: email,
                        onTap: () => _launchUrl('mailto:\$email'),
                      ),
                      const SizedBox(height: 16),
                      _infoCard(
                        icon: Icons.language,
                        title: 'Website',
                        content: website,
                        onTap: () {
                          if (!website.startsWith('http')) {
                            _launchUrl('https://\$website');
                          } else {
                            _launchUrl(website);
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
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
              color: Colors.black.withValues(alpha: 0.05),
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
                color: AppColors.gold.withValues(alpha: 0.1),
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
