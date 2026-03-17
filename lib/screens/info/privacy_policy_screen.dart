import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vishal_gold/constants/app_colors.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'PRIVACY POLICY',
          style: GoogleFonts.playfairDisplay(
            color: AppColors.gold,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.surface,
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeading('Privacy Policy'),
            _buildBody(
              'Welcome to Vishal Jewellers. We are committed to protecting your personal information and your right to privacy. This Privacy Policy explains how we collect, use, and share information about you when you use our application.',
            ),
            _buildSubHeading('1. Information We Collect'),
            _buildBody(
              'We collect information you provide directly to us, such as when you create an account, place an order, or contact us for support. This includes:\n\n• Name and contact details (phone number, email address)\n• Account credentials\n• Order history and product preferences\n• Device information for analytics and crash reporting',
            ),
            _buildSubHeading('2. How We Use Your Information'),
            _buildBody(
              'We use the information we collect to:\n\n• Process and fulfill your orders\n• Send order confirmations and updates via WhatsApp or notifications\n• Personalize your in-app experience\n• Improve our services through analytics\n• Send promotional communications (only with your consent)',
            ),
            _buildSubHeading('3. Information Sharing'),
            _buildBody(
              'We do not sell, trade, or rent your personal information to third parties. We may share data with:\n\n• Service providers who assist with order fulfillment and payment processing\n• Firebase (Google) for data storage and analytics\n• Law enforcement when required by applicable law',
            ),
            _buildSubHeading('4. Data Security'),
            _buildBody(
              'We implement industry-standard security measures to protect your personal data. All data is stored securely using Firebase infrastructure with role-based access controls. However, no method of transmission over the internet is 100% secure.',
            ),
            _buildSubHeading('5. Data Retention'),
            _buildBody(
              'We retain your personal information for as long as your account is active or as needed to provide you services. You may request deletion of your account and data at any time by contacting us.',
            ),
            _buildSubHeading('6. WhatsApp Communications'),
            _buildBody(
              'When you place an order, we may send order details to our administrators via WhatsApp to process your request. By confirming a purchase, you consent to this communication.',
            ),
            _buildSubHeading('7. Children\'s Privacy'),
            _buildBody(
              'Our application is not directed to individuals under the age of 13. We do not knowingly collect personal information from children under 13.',
            ),
            _buildSubHeading('8. Changes to This Policy'),
            _buildBody(
              'We may update this Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this screen. Changes become effective immediately upon posting.',
            ),
            _buildSubHeading('9. Contact Us'),
            _buildBody(
              'If you have any questions about this Privacy Policy, please contact us at:\n\nVishal Jewellers\nEmail: contact@vishalgold.com\n\nLast Updated: March 2026',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeading(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        text,
        style: GoogleFonts.playfairDisplay(
          color: AppColors.gold,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSubHeading(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(
        text,
        style: GoogleFonts.outfit(
          color: AppColors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildBody(String text) {
    return Text(
      text,
      style: GoogleFonts.outfit(
        color: AppColors.textSecondary,
        fontSize: 14,
        height: 1.7,
      ),
    );
  }
}
