import 'package:flutter/material.dart';
import 'package:vishal_gold/constants/app_colors.dart';
import 'package:vishal_gold/widgets/common/custom_app_bar.dart';
import 'package:vishal_gold/screens/product/product_listing_screen.dart';
import 'package:vishal_gold/widgets/home/category_card.dart';

class AllSubcategoriesScreen extends StatelessWidget {
  final String title;
  final String category;
  final List<Map<String, dynamic>> subcategories;

  const AllSubcategoriesScreen({
    super.key,
    required this.title,
    required this.category,
    required this.subcategories,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(title: title.toUpperCase()),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemCount: subcategories.length,
          itemBuilder: (context, index) {
            final subcategory = subcategories[index];
            return CategoryCard(
              name: subcategory['name'],
              imagePath: subcategory['image'],
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductListingScreen(
                      category: category,
                      subcategory: subcategory['name'],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
