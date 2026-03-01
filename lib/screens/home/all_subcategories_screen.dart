import 'package:flutter/material.dart';
import 'package:vishal_gold/constants/app_colors.dart';
import 'package:vishal_gold/models/category.dart' as app_models;
import 'package:vishal_gold/models/subcategory.dart';
import 'package:vishal_gold/utils/app_layout.dart';
import 'package:vishal_gold/widgets/common/custom_app_bar.dart';
import 'package:vishal_gold/screens/product/product_listing_screen.dart';
import 'package:vishal_gold/widgets/home/category_card.dart';

class AllSubcategoriesScreen extends StatelessWidget {
  final app_models.Category category;
  final List<Subcategory> subcategories;

  const AllSubcategoriesScreen({
    super.key,
    required this.category,
    required this.subcategories,
  });

  @override
  Widget build(BuildContext context) {
    final layout = AppLayout.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(title: category.name.toUpperCase()),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(layout.horizontalPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: layout.subcategoryGridColumns,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              itemCount: subcategories.length,
              itemBuilder: (context, index) {
                final subcategory = subcategories[index];
                return CategoryCard(
                  name: subcategory.name,
                  imagePath: subcategory.imageUrl,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductListingScreen(
                          category: category.id,
                          subcategory: subcategory.id,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
