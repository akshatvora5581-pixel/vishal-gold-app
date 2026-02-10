import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vishal_gold/constants/app_colors.dart';

class WhatsAppFAB extends StatelessWidget {
  const WhatsAppFAB({super.key});

  Future<void> _launchWhatsApp() async {
    const phoneNumber = '+919999999999'; // Replace with actual number
    final Uri whatsappUrl = Uri.parse('https://wa.me/$phoneNumber');

    if (await canLaunchUrl(whatsappUrl)) {
      await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: _launchWhatsApp,
      backgroundColor: const Color(0xFF25D366), // WhatsApp green
      child: const Icon(Icons.chat, color: AppColors.white),
    );
  }
}
