import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vishal_jewelers/constants/app_colors.dart';

class FAQScreen extends StatelessWidget {
  const FAQScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final faqs = [
      {
        'question': 'How do I check the daily gold rate?',
        'answer': 'The live gold and silver rates are displayed prominently on the home screen dashboard. They are updated in real-time based on international market values.'
      },
      {
        'question': 'How can I place an order?',
        'answer': 'You can place an order by navigating to the "Order" tab, selecting your desired product category, and following the prompts to enter specifications.'
      },
      {
        'question': 'Is my data secure?',
        'answer': 'Yes, we use industry-standard encryption and Firebase secure authentication to protect your account and personal information.'
      },
      {
        'question': 'How do I contact support?',
        'answer': 'You can reach us via WhatsApp or Email directly through the Support Hub screen in your profile settings.'
      },
      {
        'question': 'What are the payment options?',
        'answer': 'We currently support bank transfers and RTGS/NEFT for wholesale orders. Retail payment options are coming soon.'
      },
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'FAQ',
          style: GoogleFonts.playfairDisplay(
            color: AppColors.gold,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.surface,
        iconTheme: IconThemeData(color: AppColors.gold),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: faqs.length,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider.withValues(alpha: 0.1)),
            ),
            child: ExpansionTile(
              shape: const RoundedRectangleBorder(side: BorderSide.none),
              iconColor: AppColors.gold,
              collapsedIconColor: AppColors.gold,
              title: Text(
                faqs[index]['question']!,
                style: GoogleFonts.outfit(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Text(
                    faqs[index]['answer']!,
                    style: GoogleFonts.outfit(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
