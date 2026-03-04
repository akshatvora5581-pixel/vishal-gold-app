import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vishal_gold/constants/app_colors.dart';

class SupportHubScreen extends StatelessWidget {
  const SupportHubScreen({super.key});

  Future<void> _launchWhatsApp() async {
    final Uri url = Uri.parse(
      'https://wa.me/919999999999',
    ); // Placeholder number
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }

  Future<void> _launchEmail() async {
    final Uri url = Uri.parse('mailto:support@vishalgold.com');
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Support Hub',
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
              'How can we help you today?',
              style: GoogleFonts.outfit(
                color: AppColors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Our support team is available to assist you with any queries or issues.',
              style: GoogleFonts.outfit(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 32),
            _buildSupportCard(
              icon: Icons.chat_bubble_outline,
              title: 'WhatsApp Support',
              subtitle: 'Chat with us for quick assistance',
              onTap: _launchWhatsApp,
              color: const Color(0xFF25D366),
            ),
            const SizedBox(height: 16),
            _buildSupportCard(
              icon: Icons.email_outlined,
              title: 'Email Support',
              subtitle: 'Send us an email for detailed queries',
              onTap: _launchEmail,
              color: const Color(0xFFEA4335),
            ),
            const SizedBox(height: 16),
            _buildSupportCard(
              icon: Icons.help_outline,
              title: 'Frequently Asked Questions',
              subtitle: 'Find answers to common questions',
              onTap: () {
                // TODO: Navigate to FAQ screen
              },
              color: AppColors.gold,
            ),
            const SizedBox(height: 48),
            Center(
              child: Column(
                children: [
                  Text(
                    'Version 1.0.0',
                    style: GoogleFonts.outfit(
                      color: AppColors.textTertiary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '© 2026 Vishal Gold. All rights reserved.',
                    style: GoogleFonts.outfit(
                      color: AppColors.textTertiary,
                      fontSize: 12,
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

  Widget _buildSupportCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: AppColors.textTertiary,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
