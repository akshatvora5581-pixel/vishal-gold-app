import 'package:flutter/material.dart';
import 'package:vishal_gold/constants/app_colors.dart';
import 'package:vishal_gold/screens/product/product_listing_screen.dart';
import 'package:vishal_gold/widgets/home/category_card.dart';

class CategorySection extends StatelessWidget {
  final String title;
  final String category;
  final List<Map<String, String>> subcategories;

  const CategorySection({
    super.key,
    required this.title,
    required this.category,
    required this.subcategories,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title.toUpperCase(),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                  letterSpacing: 1.2,
                ),
              ),
              TextButton(
                onPressed: () {
                  // Navigate to full list or just expand
                },
                child: const Text('View All'),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 180,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemCount: subcategories.length,
            itemBuilder: (context, index) {
              final sub = subcategories[index];
              return SizedBox(
                width: 140,
                child: CategoryCard(
                  name: sub['name']!,
                  imagePath: sub['image']!,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductListingScreen(
                          category: category,
                          subcategory: sub['name'],
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
  }
}
