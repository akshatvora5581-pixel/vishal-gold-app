import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vishal_jewelers/constants/app_colors.dart';
import 'package:vishal_jewelers/providers/product_provider.dart';
import 'package:vishal_jewelers/utils/app_layout.dart';
import 'package:vishal_jewelers/widgets/product/product_card.dart';
import 'package:vishal_jewelers/widgets/product/product_skeleton.dart';

class ProductListingScreen extends StatefulWidget {
  final String? category;
  final String? subcategory; // This will now receive the ID
  final String? subcategoryName; // This will receive the Display Name

  const ProductListingScreen({
    super.key,
    this.category,
    this.subcategory,
    this.subcategoryName,
  });

  @override
  State<ProductListingScreen> createState() => _ProductListingScreenState();
}

class _ProductListingScreenState extends State<ProductListingScreen> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadProductsByCategory(
            widget.category ?? 'all',
            subcategory: widget.subcategory,
          );
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<ProductProvider>().fetchMoreProducts();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _openSortSheet() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _SortFilterBottomSheet(),
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
        widget.subcategoryName ??
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
          controller: _scrollController,
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
                      icon: Icon(
                        Icons.arrow_back_ios_new,
                        color: AppColors.white,
                        size: 20,
                      ),
                      onPressed: _stopSearch,
                    )
                  : IconButton(
                      icon: Icon(
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
                          color: AppColors.white.withValues(alpha: 0.5),
                          fontSize: 16,
                        ),
                        border: InputBorder.none,
                      ),
                    )
                  : null,
              actions: [
                if (_isSearching)
                  IconButton(
                    icon: Icon(Icons.close, color: AppColors.white),
                    onPressed: _stopSearch,
                  )
                else ...[
                  // ── Sort / Filter button ───────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: GestureDetector(
                      onTap: _openSortSheet,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.black,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.tune_rounded,
                              color: AppColors.gold,
                              size: 20,
                            ),
                          ),
                          Consumer<ProductProvider>(
                            builder: (context, provider, _) {
                              if (!provider.hasActiveFilters) {
                                return const SizedBox.shrink();
                              }
                              return Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  // ── Search button ──────────────────────────────────────────
                  IconButton(
                    icon: Icon(Icons.search, color: AppColors.white),
                    onPressed: _startSearch,
                  ),
                ],
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: Consumer<ProductProvider>(
                builder: (context, provider, _) {
                  final layout = AppLayout.of(context);

                  if (provider.isLoading && provider.products.isEmpty) {
                    return SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: layout.productGridColumns,
                        childAspectRatio: layout.productCardAspectRatio,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => ProductSkeleton(),
                        childCount: 6,
                      ),
                    );
                  }

                  if (provider.error != null) {
                    return SliverFillRemaining(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.info_outline, color: AppColors.gold, size: 48),
                              const SizedBox(height: 16),
                              Text(
                                provider.error!,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.outfit(
                                  color: AppColors.gold,
                                  fontSize: 16,
                                ),
                              ),
                              TextButton(
                                onPressed: () => provider.fetchInitialProducts(),
                                child: Text('Try Again', style: TextStyle(color: AppColors.gold)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  final products = provider.products;

                  if (products.isEmpty) {
                    return SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off_rounded,
                              size: 64,
                              color: AppColors.grey.withValues(alpha: 0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _isSearching
                                  ? 'No results found'
                                  : 'No products found matching your filters',
                              style: GoogleFonts.outfit(
                                color: AppColors.textSecondary,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return AnimationLimiter(
                    key: ValueKey(
                      '${widget.subcategory ?? widget.category}_${products.length}_${provider.currentSort}',
                    ),
                    child: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: layout.productGridColumns,
                        childAspectRatio: layout.productCardAspectRatio,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (BuildContext context, int index) {
                          return AnimationConfiguration.staggeredGrid(
                            position: index,
                            duration: const Duration(milliseconds: 500),
                            columnCount: layout.productGridColumns,
                            child: ScaleAnimation(
                              child: FadeInAnimation(
                                child: RepaintBoundary(
                                  child: ProductCard(product: products[index]),
                                ),
                              ),
                            ),
                          );
                        },
                        childCount: products.length,
                      ),
                    ),
                  );
                },
              ),
            ),
            Consumer<ProductProvider>(
              builder: (context, provider, child) {
                if (provider.isFetchingMore) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.gold,
                          ),
                        ),
                      ),
                    ),
                  );
                }
                return const SliverToBoxAdapter(
                  child: SizedBox(height: 100),
                ); // bottom padding
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sort & Filter Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _SortFilterBottomSheet extends StatefulWidget {
  const _SortFilterBottomSheet();

  @override
  State<_SortFilterBottomSheet> createState() => _SortFilterBottomSheetState();
}

class _SortFilterBottomSheetState extends State<_SortFilterBottomSheet> {
  late ProductSortOrder _selectedSort;
  late InventoryStatusFilter _selectedInventory;
  RangeValues _weightRange = const RangeValues(0, 5000);

  @override
  void initState() {
    super.initState();
    final provider = context.read<ProductProvider>();
    _selectedSort = provider.currentSort;
    _selectedInventory = provider.inventoryStatusFilter;
    _weightRange = RangeValues(
      provider.minWeightFilter ?? 0,
      provider.maxWeightFilter ?? 5000,
    );
  }

  void _apply() {
    final provider = context.read<ProductProvider>();
    provider.sortProducts(_selectedSort);
    provider.setInventoryStatusFilter(_selectedInventory);
    provider.setWeightRange(
      _weightRange.start == 0 ? null : _weightRange.start,
      _weightRange.end == 5000 ? null : _weightRange.end,
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Sort & Filter',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.gold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      context.read<ProductProvider>().clearAllFilters();
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Reset All',
                      style: GoogleFonts.outfit(color: AppColors.errorRed),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Sort Section
              _buildSectionTitle('Sort By'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _sortChip('Newest', ProductSortOrder.newestFirst),
                  _sortChip('Tag (A-Z)', ProductSortOrder.tagAsc),
                  _sortChip('Tag (Z-A)', ProductSortOrder.tagDesc),
                  _sortChip('Weight (L-H)', ProductSortOrder.weightAsc),
                  _sortChip('Weight (H-L)', ProductSortOrder.weightDesc),
                ],
              ),
              const SizedBox(height: 28),

              // Inventory Section
              _buildSectionTitle('Inventory Status'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _inventoryChip('All', InventoryStatusFilter.all),
                  _inventoryChip('In Stock', InventoryStatusFilter.inStock),
                  _inventoryChip('Sold Out', InventoryStatusFilter.soldOut),
                  _inventoryChip('On Order', InventoryStatusFilter.onOrder),
                ],
              ),
              const SizedBox(height: 28),

              // Weight Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSectionTitle('Weight Range (g)'),
                  Text(
                    '${_weightRange.start.toInt()} - ${_weightRange.end.toInt()}${_weightRange.end >= 5000 ? '+' : ''}',
                    style: GoogleFonts.outfit(color: AppColors.gold),
                  ),
                ],
              ),
              RangeSlider(
                values: _weightRange,
                min: 0,
                max: 5000,
                divisions: 50,
                activeColor: AppColors.gold,
                inactiveColor: AppColors.gold.withValues(alpha: 0.1),
                onChanged: (v) => setState(() => _weightRange = v),
              ),
              const SizedBox(height: 32),

              // Apply Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _apply,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'APPLY FILTERS',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.outfit(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: AppColors.white.withValues(alpha: 0.6),
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _sortChip(String label, ProductSortOrder order) {
    final selected = _selectedSort == order;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (v) => setState(() => _selectedSort = order),
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.gold.withValues(alpha: 0.2),
      labelStyle: GoogleFonts.outfit(
        color: selected ? AppColors.gold : AppColors.white,
        fontSize: 14,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? AppColors.gold : Colors.transparent,
        ),
      ),
    );
  }

  Widget _inventoryChip(String label, InventoryStatusFilter filter) {
    final selected = _selectedInventory == filter;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (v) => setState(() => _selectedInventory = filter),
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.gold.withValues(alpha: 0.2),
      labelStyle: GoogleFonts.outfit(
        color: selected ? AppColors.gold : AppColors.white,
        fontSize: 14,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? AppColors.gold : Colors.transparent,
        ),
      ),
    );
  }
}
