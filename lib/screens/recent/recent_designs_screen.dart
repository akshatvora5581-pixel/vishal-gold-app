import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vishal_gold/constants/app_colors.dart';
import 'package:vishal_gold/models/product.dart';
import 'package:vishal_gold/providers/preview_provider.dart';
import 'package:vishal_gold/services/firebase_service.dart';
import 'package:vishal_gold/utils/app_layout.dart';
import 'package:vishal_gold/widgets/common/custom_app_bar.dart';
import 'package:vishal_gold/widgets/product/product_card.dart';

class RecentDesignsScreen extends StatefulWidget {
  const RecentDesignsScreen({super.key});

  @override
  State<RecentDesignsScreen> createState() => _RecentDesignsScreenState();
}

class _RecentDesignsScreenState extends State<RecentDesignsScreen> {
  final FirebaseService _firebaseService = FirebaseService();

  @override
  Widget build(BuildContext context) {
    // Calculate threshold for exactly 24 hours ago
    final DateTime threshold = DateTime.now().subtract(const Duration(hours: 24));

    return Consumer<PreviewProvider>(
      builder: (context, previewProvider, _) {
        final status = previewProvider.isPreviewMode ? 'staged' : 'published';

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: const CustomAppBar(title: "RECENT DESIGNS"),
          body: StreamBuilder<QuerySnapshot>(
            stream: _firebaseService.getRecentProducts(
              limit: 50,
              status: status,
              threshold: threshold, // Pass the 24-hour threshold
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.gold),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              }

              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return _buildEmptyState();
              }

              final layout = AppLayout.of(context);
              return GridView.builder(
                padding: EdgeInsets.all(layout.horizontalPadding),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: layout.productGridColumns,
                  childAspectRatio: layout.productCardAspectRatio,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                ),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final product = Product.fromJson({
                    ...data,
                    'id': docs[index].id,
                  });

                  return ProductCard(product: product);
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.gold.withOpacity(0.1)),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: AppColors.gold,
              size: 48,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'NO NEW DESIGNS',
            style: GoogleFonts.playfairDisplay(
              color: AppColors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'No new designs in the last 24 hours. Check back soon for our latest collections!',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: AppColors.grey,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
