import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vishal_gold/constants/app_colors.dart';
import 'package:vishal_gold/models/category.dart' as app_models;
import 'package:vishal_gold/models/subcategory.dart';
import 'package:vishal_gold/screens/product/product_listing_screen.dart';
import 'package:vishal_gold/screens/home/all_subcategories_screen.dart';
import 'package:vishal_gold/services/firebase_service.dart';
import 'package:vishal_gold/utils/app_layout.dart';
import 'package:vishal_gold/widgets/home/category_card.dart';

class CategorySection extends StatelessWidget {
  final app_models.Category category;

  const CategorySection({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseService().getSubcategories(category.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(color: AppColors.gold),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      category.name.toUpperCase(),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.textPrimary,
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
                    child: const Text(
                      'View All',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: AppLayout.of(context).categoryListHeight,
              child: ListView.separated(
                padding: EdgeInsets.symmetric(
                  horizontal: AppLayout.of(context).horizontalPadding,
                ),
                scrollDirection: Axis.horizontal,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemCount: subcategories.length,
                itemBuilder: (context, index) {
                  final layout = AppLayout.of(context);
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
                            builder: (context) => ProductListingScreen(
                              category: category.id,
                              subcategory: sub.id,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
