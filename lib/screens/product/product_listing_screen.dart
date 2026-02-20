import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vishal_gold/constants/app_colors.dart';
import 'package:vishal_gold/providers/product_provider.dart';
import 'package:vishal_gold/widgets/product/product_card.dart';

// Brand accent for the Sort sheet
const _kBrandPurple = Color(0xFF2D0B2B);

class ProductListingScreen extends StatefulWidget {
  final String? category;
  final String? subcategory;

  const ProductListingScreen({super.key, this.category, this.subcategory});

  @override
  State<ProductListingScreen> createState() => _ProductListingScreenState();
}

class _ProductListingScreenState extends State<ProductListingScreen> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final productProvider = context.read<ProductProvider>();
      if (widget.category != null) {
        productProvider.loadProductsByCategory(
          widget.category!,
          subcategory: widget.subcategory,
        );
      } else {
        productProvider.loadProducts();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _openSortSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _SortBottomSheet(),
    );
  }

  void _startSearch() {
    setState(() => _isSearching = true);
    Future.delayed(const Duration(milliseconds: 100), () {
      _searchFocusNode.requestFocus();
    });
  }

  void _stopSearch() {
    setState(() {
      _isSearching = false;
      _searchController.clear();
    });
    context.read<ProductProvider>().searchProducts('');
    _searchFocusNode.unfocus();
  }

  void _onSearchChanged(String query) {
    context.read<ProductProvider>().searchProducts(query);
  }

  @override
  Widget build(BuildContext context) {
    final title =
        widget.subcategory ??
        widget.category?.replaceAll('_', ' ').toUpperCase() ??
        'ALL DESIGNS';

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop && _isSearching) {
          context.read<ProductProvider>().searchProducts('');
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: _isSearching ? 0 : 120.0,
              floating: false,
              pinned: true,
              backgroundColor: AppColors.background,
              elevation: 0,
              flexibleSpace: _isSearching
                  ? null
                  : FlexibleSpaceBar(
                      titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                      title: Text(
                        title.toUpperCase(),
                        style: GoogleFonts.playfairDisplay(
                          color: AppColors.gold,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          letterSpacing: 1.2,
                        ),
                      ),
                      background: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [AppColors.surface, AppColors.background],
                          ),
                        ),
                      ),
                    ),
              leading: _isSearching
                  ? IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        color: AppColors.white,
                        size: 20,
                      ),
                      onPressed: _stopSearch,
                    )
                  : IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        color: AppColors.white,
                        size: 20,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
              title: _isSearching
                  ? TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      onChanged: _onSearchChanged,
                      style: GoogleFonts.outfit(
                        color: AppColors.white,
                        fontSize: 16,
                      ),
                      cursorColor: AppColors.gold,
                      decoration: InputDecoration(
                        hintText: 'Search by tag, name…',
                        hintStyle: GoogleFonts.outfit(
                          color: AppColors.white.withOpacity(0.5),
                          fontSize: 16,
                        ),
                        border: InputBorder.none,
                      ),
                    )
                  : null,
              actions: [
                if (_isSearching)
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.white),
                    onPressed: _stopSearch,
                  )
                else ...[
                  // ── Sort / Filter button ───────────────────────────────────
                  IconButton(
                    tooltip: 'Sort',
                    icon: const Icon(
                      Icons.tune_rounded,
                      color: AppColors.gold,
                      size: 22,
                    ),
                    onPressed: _openSortSheet,
                  ),
                  // ── Search button ──────────────────────────────────────────
                  IconButton(
                    icon: const Icon(Icons.search, color: AppColors.white),
                    onPressed: _startSearch,
                  ),
                ],
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: Consumer<ProductProvider>(
                builder: (context, productProvider, child) {
                  if (productProvider.isLoading) {
                    return const SliverFillRemaining(
                      child: Center(
                        child: CircularProgressIndicator(color: AppColors.gold),
                      ),
                    );
                  }

                  final products = productProvider.products;

                  if (products.isEmpty) {
                    return SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off_rounded,
                              size: 64,
                              // ignore: deprecated_member_use
                              color: AppColors.grey.withOpacity(0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _isSearching
                                  ? 'No results found'
                                  : 'No designs found',
                              style: GoogleFonts.outfit(
                                color: AppColors.textSecondary,
                                fontSize: 16,
                              ),
                            ),
                            if (_isSearching) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Try a different keyword',
                                style: GoogleFonts.outfit(
                                  color: AppColors.textSecondary.withOpacity(
                                    0.6,
                                  ),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }

                  return AnimationLimiter(
                    child: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.7,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                      delegate: SliverChildBuilderDelegate((
                        BuildContext context,
                        int index,
                      ) {
                        return AnimationConfiguration.staggeredGrid(
                          position: index,
                          duration: const Duration(milliseconds: 500),
                          columnCount: 2,
                          child: ScaleAnimation(
                            child: FadeInAnimation(
                              child: ProductCard(product: products[index]),
                            ),
                          ),
                        );
                      }, childCount: products.length),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sort Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _SortBottomSheet extends StatefulWidget {
  const _SortBottomSheet();

  @override
  State<_SortBottomSheet> createState() => _SortBottomSheetState();
}

class _SortBottomSheetState extends State<_SortBottomSheet> {
  late ProductSortOrder _selected;

  static const List<_SortOption> _options = [
    _SortOption(ProductSortOrder.newestFirst, 'Newest First'),
    _SortOption(ProductSortOrder.tagAsc, 'TagNo (A - Z)'),
    _SortOption(ProductSortOrder.tagDesc, 'TagNo (Z - A)'),
    _SortOption(ProductSortOrder.weightAsc, 'Weight (Low - High)'),
    _SortOption(ProductSortOrder.weightDesc, 'Weight (High - Low)'),
  ];

  @override
  void initState() {
    super.initState();
    _selected = context.read<ProductProvider>().currentSort;
  }

  void _select(ProductSortOrder order) {
    setState(() => _selected = order);
    context.read<ProductProvider>().sortProducts(order);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            const SizedBox(height: 14),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 18),

            // Header
            Text(
              'Sort By',
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _kBrandPurple,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 14),

            const Divider(height: 1, thickness: 1, indent: 24, endIndent: 24),
            const SizedBox(height: 4),

            // Radio options
            for (final opt in _options)
              RadioListTile<ProductSortOrder>(
                value: opt.order,
                groupValue: _selected,
                onChanged: (v) => _select(v!),
                activeColor: _kBrandPurple,
                title: Text(
                  opt.label,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: _selected == opt.order
                        ? FontWeight.w600
                        : FontWeight.normal,
                    color: _selected == opt.order
                        ? _kBrandPurple
                        : Colors.black87,
                  ),
                ),
                dense: true,
                controlAffinity: ListTileControlAffinity.leading,
              ),

            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _SortOption {
  final ProductSortOrder order;
  final String label;
  const _SortOption(this.order, this.label);
}
