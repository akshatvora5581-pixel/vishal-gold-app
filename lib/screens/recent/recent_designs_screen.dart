import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vishal_gold/constants/app_colors.dart';
import 'package:vishal_gold/models/product.dart';
import 'package:vishal_gold/providers/auth_provider.dart';
import 'package:vishal_gold/services/supabase_service.dart';
import 'package:vishal_gold/widgets/product/product_card.dart';

class RecentDesignsScreen extends StatefulWidget {
  const RecentDesignsScreen({super.key});

  @override
  State<RecentDesignsScreen> createState() => _RecentDesignsScreenState();
}

class _RecentDesignsScreenState extends State<RecentDesignsScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  List<Product> _recentProducts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecentDesigns();
  }

  Future<void> _loadRecentDesigns() async {
    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final products = await _supabaseService.getRecentlyViewedProducts(
        authProvider.user!.id,
      );
      setState(() {
        _recentProducts = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Recently Viewed'),
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _recentProducts.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: 100,
                    color: AppColors.grey.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No recently viewed designs',
                    style: TextStyle(fontSize: 16, color: AppColors.grey),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadRecentDesigns,
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.7,
                ),
                itemCount: _recentProducts.length,
                itemBuilder: (context, index) {
                  return ProductCard(product: _recentProducts[index]);
                },
              ),
            ),
    );
  }
}
