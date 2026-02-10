import 'package:flutter/material.dart';
import 'package:vishal_gold/constants/app_colors.dart';

class SearchBarWidget extends StatelessWidget {
  final Function(String)? onSearch;
  final String? hintText;

  const SearchBarWidget({super.key, this.onSearch, this.hintText});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.lightGrey),
      ),
      child: TextField(
        onChanged: onSearch,
        decoration: InputDecoration(
          hintText: hintText ?? 'Search products...',
          border: InputBorder.none,
          icon: const Icon(Icons.search, color: AppColors.grey),
        ),
      ),
    );
  }
}
