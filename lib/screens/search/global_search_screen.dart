import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vishal_gold/config/category_data.dart';
import 'package:vishal_gold/constants/app_colors.dart';
import 'package:vishal_gold/models/product.dart';
import 'package:vishal_gold/screens/home/all_subcategories_screen.dart';
import 'package:vishal_gold/screens/product/product_detail_screen.dart';
import 'package:vishal_gold/screens/product/product_listing_screen.dart';
import 'package:vishal_gold/services/firebase_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data models for the three result types
// ─────────────────────────────────────────────────────────────────────────────

enum _ResultType { category, subcategory, product }

class _SearchResult {
  final _ResultType type;
  final String title;
  final String subtitle;
  final String? imageUrl;
  // For navigation
  final String? category;
  final String? subcategory;
  final Product? product;

  const _SearchResult({
    required this.type,
    required this.title,
    required this.subtitle,
    this.imageUrl,
    this.category,
    this.subcategory,
    this.product,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class GlobalSearchScreen extends StatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  // All data loaded once
  List<Product> _allProducts = [];
  bool _loading = true;

  // Filtered results
  List<_SearchResult> _results = [];

  // Flat list of all categories
  static final List<_SearchResult> _staticCategoryResults = [
    _SearchResult(
      type: _ResultType.category,
      title: '84 MELTING',
      subtitle: '${CategoryData.subcategories84.length} sub-categories',
      category: CategoryData.category84,
      imageUrl: null,
    ),
    _SearchResult(
      type: _ResultType.category,
      title: '92 MELTING',
      subtitle: '${CategoryData.subcategories92.length} sub-categories',
      category: CategoryData.category92,
      imageUrl: null,
    ),
    _SearchResult(
      type: _ResultType.category,
      title: '92 MELTING CHAIN',
      subtitle: '${CategoryData.subcategoriesChains92.length} sub-categories',
      category: CategoryData.categoryChains92,
      imageUrl: null,
    ),
  ];

  // Build subcategory results list statically
  static List<_SearchResult> _buildSubcategoryResults() {
    final List<_SearchResult> out = [];

    for (final sub in CategoryData.subcategories84) {
      out.add(
        _SearchResult(
          type: _ResultType.subcategory,
          title: sub,
          subtitle: '84 MELTING',
          category: CategoryData.category84,
          subcategory: sub,
          imageUrl:
              CategoryData.getSubcategories(CategoryData.category84).firstWhere(
                    (m) => m['name'] == sub,
                    orElse: () => {},
                  )['image']
                  as String?,
        ),
      );
    }
    for (final sub in CategoryData.subcategories92) {
      out.add(
        _SearchResult(
          type: _ResultType.subcategory,
          title: sub,
          subtitle: '92 MELTING',
          category: CategoryData.category92,
          subcategory: sub,
          imageUrl:
              CategoryData.getSubcategories(CategoryData.category92).firstWhere(
                    (m) => m['name'] == sub,
                    orElse: () => {},
                  )['image']
                  as String?,
        ),
      );
    }
    for (final sub in CategoryData.subcategoriesChains92) {
      out.add(
        _SearchResult(
          type: _ResultType.subcategory,
          title: sub,
          subtitle: '92 MELTING CHAIN',
          category: CategoryData.categoryChains92,
          subcategory: sub,
          imageUrl:
              CategoryData.getSubcategories(
                    CategoryData.categoryChains92,
                  ).firstWhere(
                    (m) => m['name'] == sub,
                    orElse: () => {},
                  )['image']
                  as String?,
        ),
      );
    }
    return out;
  }

  static final List<_SearchResult> _staticSubResults =
      _buildSubcategoryResults();

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _controller.addListener(_onQueryChanged);
    // Auto-focus
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _focusNode.requestFocus(),
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_onQueryChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    try {
      final products = await FirebaseService().getAllProducts();
      if (mounted) {
        setState(() {
          _allProducts = products;
          _loading = false;
        });
        // Trigger initial filter (empty → show nothing)
        _onQueryChanged();
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onQueryChanged() {
    final q = _controller.text.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() => _results = []);
      return;
    }

    final List<_SearchResult> matched = [];

    // 1. Categories
    for (final cat in _staticCategoryResults) {
      if (cat.title.toLowerCase().contains(q)) {
        matched.add(cat);
      }
    }

    // 2. Subcategories
    for (final sub in _staticSubResults) {
      if (sub.title.toLowerCase().contains(q) ||
          sub.subtitle.toLowerCase().contains(q)) {
        matched.add(sub);
      }
    }

    // 3. Products — match tag number, subcategory name, category display, purity display
    for (final p in _allProducts) {
      if (p.tagNumber.toLowerCase().contains(q) ||
          p.subcategory.toLowerCase().contains(q) ||
          p.categoryDisplay.toLowerCase().contains(q) ||
          p.purityDisplay.toLowerCase().contains(q)) {
        matched.add(
          _SearchResult(
            type: _ResultType.product,
            title: p.tagNumber,
            subtitle: '${p.subcategory} · ${p.categoryDisplay}',
            imageUrl: p.imageUrls.isNotEmpty ? p.imageUrls.first : null,
            product: p,
          ),
        );
      }
    }

    setState(() => _results = matched);
  }

  void _onTap(_SearchResult result) {
    FocusScope.of(context).unfocus();
    switch (result.type) {
      case _ResultType.category:
        final subs = CategoryData.getSubcategories(result.category!);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AllSubcategoriesScreen(
              title: result.title,
              category: result.category!,
              subcategories: subs,
            ),
          ),
        );
        break;

      case _ResultType.subcategory:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductListingScreen(
              category: result.category,
              subcategory: result.subcategory,
            ),
          ),
        );
        break;

      case _ResultType.product:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(product: result.product!),
          ),
        );
        break;
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Search Bar ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  // Back button
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        size: 18,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // TextField
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      textInputAction: TextInputAction.search,
                      style: GoogleFonts.outfit(
                        color: AppColors.white,
                        fontSize: 15,
                      ),
                      cursorColor: AppColors.gold,
                      decoration: InputDecoration(
                        hintText: 'Search categories, sub-types, tag no...',
                        hintStyle: GoogleFonts.outfit(
                          // ignore: deprecated_member_use
                          color: AppColors.white.withValues(alpha: 0.4),
                          fontSize: 14,
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: AppColors.gold,
                        ),
                        suffixIcon: _controller.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: AppColors.textSecondary,
                                  size: 20,
                                ),
                                onPressed: () {
                                  _controller.clear();
                                  _focusNode.requestFocus();
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: AppColors.surface,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(28),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Loading or results ──────────────────────────────────────────
            if (_loading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.gold),
                ),
              )
            else if (_controller.text.isEmpty)
              Expanded(child: _buildEmptyPrompt())
            else if (_results.isEmpty)
              Expanded(child: _buildNoResults())
            else
              Expanded(child: _buildResultList()),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyPrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_rounded,
            size: 64,
            // ignore: deprecated_member_use
            color: AppColors.gold.withValues(alpha: 0.25),
          ),
          const SizedBox(height: 16),
          Text(
            'Search for anything',
            style: GoogleFonts.playfairDisplay(
              color: AppColors.textSecondary,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Categories, sub-types, tag numbers...',
            style: GoogleFonts.outfit(
              // ignore: deprecated_member_use
              color: AppColors.textSecondary.withValues(alpha: 0.6),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 64,
            // ignore: deprecated_member_use
            color: AppColors.grey.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No results for "${_controller.text}"',
            style: GoogleFonts.outfit(
              color: AppColors.textSecondary,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Try a different keyword',
            style: GoogleFonts.outfit(
              // ignore: deprecated_member_use
              color: AppColors.textSecondary.withValues(alpha: 0.5),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final r = _results[index];
        return _ResultTile(result: r, onTap: () => _onTap(r));
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Result tile
// ─────────────────────────────────────────────────────────────────────────────

class _ResultTile extends StatelessWidget {
  final _SearchResult result;
  final VoidCallback onTap;

  const _ResultTile({required this.result, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 5),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              // Leading icon / thumbnail
              _buildLeading(),
              const SizedBox(width: 14),
              // Title / subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        color: AppColors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      result.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        // ignore: deprecated_member_use
                        color: AppColors.textSecondary.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // Type badge
              const SizedBox(width: 8),
              _buildBadge(),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeading() {
    if (result.type == _ResultType.product && result.imageUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: result.imageUrl!.toLowerCase().contains('assets/')
            ? Image.asset(
                result.imageUrl!,
                width: 48,
                height: 48,
                fit: BoxFit.contain,
              )
            : CachedNetworkImage(
                imageUrl: result.imageUrl!,
                width: 48,
                height: 48,
                fit: BoxFit.contain,
                placeholder: (_, __) => Container(
                  color: AppColors.background,
                  width: 48,
                  height: 48,
                ),
                errorWidget: (_, __, ___) =>
                    _iconBox(Icons.image_not_supported),
              ),
      );
    }

    if (result.type == _ResultType.subcategory && result.imageUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.asset(
          result.imageUrl!,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _iconBox(Icons.diamond_outlined),
        ),
      );
    }

    // Category or fallback
    return _iconBox(
      result.type == _ResultType.category
          ? Icons.grid_view_rounded
          : Icons.diamond_outlined,
      bg: result.type == _ResultType.category
          // ignore: deprecated_member_use
          ? AppColors.gold.withValues(alpha: 0.15)
          : AppColors.background,
      iconColor: result.type == _ResultType.category
          ? AppColors.gold
          : AppColors.textSecondary,
    );
  }

  Widget _iconBox(IconData icon, {Color? bg, Color? iconColor}) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: bg ?? AppColors.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: iconColor ?? AppColors.textSecondary, size: 22),
    );
  }

  Widget _buildBadge() {
    String label;
    Color color;
    switch (result.type) {
      case _ResultType.category:
        label = 'Category';
        color = AppColors.gold;
        break;
      case _ResultType.subcategory:
        label = 'Sub-type';
        // ignore: deprecated_member_use
        color = Colors.blueAccent.withValues(alpha: 0.85);
        break;
      case _ResultType.product:
        label = 'Product';
        // ignore: deprecated_member_use
        color = Colors.greenAccent.withValues(alpha: 0.75);
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        // ignore: deprecated_member_use
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          // ignore: deprecated_member_use
          color: color.withValues(alpha: 0.4),
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
