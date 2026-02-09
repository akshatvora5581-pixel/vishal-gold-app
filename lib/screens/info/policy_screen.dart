import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vishal_gold/constants/app_colors.dart';
import 'package:vishal_gold/widgets/common/custom_app_bar.dart';

class PolicyScreen extends StatelessWidget {
  final String title;
  final String content;

  const PolicyScreen({super.key, required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(title: title.toUpperCase()),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            content,
            style: GoogleFonts.roboto(
              fontSize: 15,
              height: 1.6,
              color: AppColors.black.withOpacity(0.8),
            ),
          ),
        ),
      ),
    );
  }
}
