import 'package:flutter/material.dart';
import 'package:vishal_gold/constants/app_colors.dart';
import 'package:vishal_gold/screens/order/sample_order_screen.dart';

class CustomOrderFAB extends StatelessWidget {
  const CustomOrderFAB({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SampleOrderScreen()),
        );
      },
      backgroundColor: AppColors.black,
      foregroundColor: AppColors.gold,
      tooltip: 'Place Sample Order',
      shape: const CircleBorder(
        side: BorderSide(color: AppColors.gold, width: 1.5),
      ),
      child: const Icon(Icons.add_shopping_cart, color: AppColors.gold),
    );
  }
}
