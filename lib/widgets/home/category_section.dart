import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vishal_jewelers/constants/app_colors.dart';
import 'package:vishal_jewelers/models/category.dart' as app_models;
import 'package:vishal_jewelers/models/subcategory.dart';
import 'package:vishal_jewelers/screens/product/product_listing_screen.dart';
import 'package:vishal_jewelers/screens/home/all_subcategories_screen.dart';
import 'package:vishal_jewelers/services/firebase_service.dart';
import 'package:vishal_jewelers/utils/app_layout.dart';
import 'package:vishal_jewelers/widgets/home/category_card.dart';
import 'package:vishal_jewelers/widgets/common/shimmer_widget.dart';

class CategorySection extends StatelessWidget {
  final app_models.Category category;

  const CategorySection({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final layout = AppLayout.of(context);
    
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseService().getSubcategories(category.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: layout.horizontalPadding,
                  vertical: 10,
                ),
                child: const ShimmerWidget.rectangular(height: 24, width: 150),
              ),
              SizedBox(
                height: layout.categoryListHeight,
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(
                    horizontal: layout.horizontalPadding,
                  ),
                  scrollDirection: Axis.horizontal,
                  itemCount: 5,
                  itemBuilder: (_, _) => const ProductCardSkeleton(),
                ),
              ),
              const SizedBox(height: 12),
            ],
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                'Something went wrong',
                style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 13),
              ),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return const SizedBox.shrink();

        final subcategories = docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return Subcategory.fromJson(data, doc.id);
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: layout.horizontalPadding,
                vertical: 10,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      category.name.toUpperCase(),
                      style: GoogleFonts.outfit(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        letterSpacing: 1.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AllSubcategoriesScreen(
                            category: category,
                            subcategories: subcategories,
                          ),
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.gold,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View All',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward_ios, size: 10),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: layout.categoryListHeight,
              child: ListView.separated(
                padding: EdgeInsets.symmetric(
                  horizontal: layout.horizontalPadding,
                ),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemCount: subcategories.length,
                itemBuilder: (context, index) {
                  final sub = subcategories[index];
                  return SizedBox(
                    width: layout.categoryCardWidth,
                    child: CategoryCard(
                      name: sub.name,
                      imagePath: sub.imageUrl,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProductListingScreen(
                              category: category.id,
                              subcategory: sub.id,
                              subcategoryName: sub.name,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }
}
