import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
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
                return const Center(
                  child: Text(
                    'No recent designs available right now.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                );
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
}
