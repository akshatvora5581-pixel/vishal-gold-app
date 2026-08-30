import 'package:flutter/material.dart';
import 'package:vishal_jewelers/widgets/common/shimmer_widget.dart';

class ProductSkeleton extends StatelessWidget {
  const ProductSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E), // AppColors.surface
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2C2C2C), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image Area Skeleton
          Expanded(
            // Removed const
            flex: 4,
            child: ShimmerWidget.rectangular(height: double.infinity),
          ),
          // Details Area Skeleton
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerWidget.rectangular(height: 14, width: 80),
                      const SizedBox(height: 6),
                      ShimmerWidget.rectangular(height: 10, width: 60),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
