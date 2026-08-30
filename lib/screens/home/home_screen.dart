import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:vishal_jewelers/constants/app_colors.dart';
import 'package:vishal_jewelers/providers/auth_provider.dart';
import 'package:vishal_jewelers/providers/cart_provider.dart';
import 'package:vishal_jewelers/screens/notifications/notifications_screen.dart';
import 'package:vishal_jewelers/screens/profile/profile_screen.dart';
import 'package:vishal_jewelers/screens/recent/recent_designs_screen.dart';
import 'package:vishal_jewelers/widgets/common/custom_bottom_nav.dart';
import 'package:vishal_jewelers/widgets/common/custom_order_fab.dart';
import 'package:vishal_jewelers/widgets/common/global_cart_icon.dart';
import 'package:vishal_jewelers/widgets/home/banner_carousel.dart';
import 'package:vishal_jewelers/widgets/home/category_section.dart';
import 'package:vishal_jewelers/models/category.dart' as app_models;
import 'package:vishal_jewelers/services/firebase_service.dart';
import 'package:vishal_jewelers/providers/wishlist_provider.dart';
import 'package:vishal_jewelers/providers/preview_provider.dart';
import 'package:vishal_jewelers/screens/search/global_search_screen.dart';
import 'package:vishal_jewelers/utils/app_layout.dart';
import 'package:vishal_jewelers/widgets/common/shimmer_widget.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const HomeTab(),
      const RecentDesignsScreen(), // Recent designs
      const NotificationsScreen(), // Notifications
      const ProfileScreen(),
    ];
    _initializeProviders();
  }

  Future<void> _initializeProviders() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final wishlistProvider = Provider.of<WishlistProvider>(context, listen: false);

    if (authProvider.currentUser != null) {
      // Parallelize initialization
      await Future.wait([
        cartProvider.initialize(
          authProvider.currentUser!.uid,
          authProvider.isWholesaler,
        ),
        wishlistProvider.initialize(
          authProvider.currentUser!.uid,
          authProvider.isWholesaler,
        ),
      ]);
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Vishal Jewellers',
          style: GoogleFonts.playfairDisplay(
            color: AppColors.gold,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.surface,
        actions: const [GlobalCartIcon(), SizedBox(width: 8)],
      ),
      body: Column(
        children: [
          _buildPreviewBanner(context),
          Expanded(child: _screens[_selectedIndex]),
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
      floatingActionButton: _selectedIndex == 0 ? const CustomOrderFAB() : null,
    );
  }

  Widget _buildPreviewBanner(BuildContext context) {
    return Consumer<PreviewProvider>(
      builder: (context, preview, _) {
        if (!preview.isPreviewMode) return const SizedBox.shrink();
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          decoration: BoxDecoration(
            color: AppColors.gold,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                const Icon(Icons.visibility, color: Colors.black, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'PREVIEW MODE ACTIVE',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          letterSpacing: 1.1,
                        ),
                      ),
                      Text(
                        'Showing staged changes merged with live data.',
                        style: TextStyle(
                          color: Colors.black.withValues(alpha: 0.7),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    preview.togglePreviewMode();
                    Navigator.pop(context); // Go back to Admin Dashboard
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    backgroundColor: Colors.black.withValues(alpha: 0.1),
                  ),
                  child: const Text(
                    'EXIT',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  late final Stream<QuerySnapshot> _categoryStream;

  @override
  void initState() {
    super.initState();
    // Memoization: Initialize stream once in initState to prevent "Loading" loop on rebuilds
    _categoryStream = FirebaseService().getCategories(onlyActive: true);
  }

  @override
  Widget build(BuildContext context) {
    final layout = AppLayout.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // Top Search Bar (Floating)
                _buildSliverSearchHeader(layout),

                // Main Content
                SliverToBoxAdapter(
  
                ),

                SliverPadding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  sliver: SliverToBoxAdapter(
                    child: RepaintBoundary(child: const BannerCarousel()),
                  ),
                ),

                // Categories
                StreamBuilder<QuerySnapshot>(
                  stream: _categoryStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const ShimmerWidget.rectangular(height: 24, width: 150),
                                const SizedBox(height: 16),
                                SizedBox(
                                  height: layout.categoryListHeight,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: 5,
                                    itemBuilder: (context, index) => const ProductCardSkeleton(),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }, childCount: 3),
                      );
                    }

                    if (snapshot.hasError) {
                      return SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                            child: Column(
                              children: [
                                Icon(Icons.info_outline, color: AppColors.textSecondary, size: 40),
                                const SizedBox(height: 12),
                                Text(
                                  snapshot.error.toString(),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: AppColors.textSecondary),
                                ),
                                const SizedBox(height: 16),
                                TextButton(
                                  onPressed: () => setState(() {}),
                                  style: TextButton.styleFrom(foregroundColor: AppColors.gold),
                                  child: const Text('Tap to retry'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    final docs = snapshot.data?.docs ?? [];
                    if (docs.isEmpty) {
                      return const SliverToBoxAdapter(
                        child: Center(child: Text('No Categories Available')),
                      );
                    }

                    final categories =
                        docs.map((doc) {
                            return app_models.Category.fromJson(
                              doc.data() as Map<String, dynamic>,
                              doc.id,
                            );
                          }).toList()
                          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

                    return SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        return RepaintBoundary(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 24.0),
                            child: CategorySection(category: categories[index]),
                          ),
                        );
                      }, childCount: categories.length),
                    );
                  },
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSliverSearchHeader(AppLayout layout) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _SearchHeaderDelegate(layout: layout),
    );
  }
}

class _SearchHeaderDelegate extends SliverPersistentHeaderDelegate {
  final AppLayout layout;

  _SearchHeaderDelegate({required this.layout});

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: AppColors.background,
      padding: EdgeInsets.symmetric(
        horizontal: layout.horizontalPadding,
        vertical: 10,
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (ctx, a, b) => const GlobalSearchScreen(),
                    transitionsBuilder: (ctx, anim, _, child) =>
                        FadeTransition(opacity: anim, child: child),
                    transitionDuration: const Duration(milliseconds: 220),
                  ),
                );
              },
              child: AbsorbPointer(
                child: TextField(
                  readOnly: true,
                  decoration: InputDecoration(
                    hintText: 'Search for jewellery...',
                    prefixIcon: Icon(
                      Icons.search,
                      color: AppColors.textSecondary,
                    ),
                    fillColor: AppColors.surface,
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.gold,
                    AppColors.gold.withValues(alpha: 0.8),
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.gold.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(Icons.person, color: AppColors.black, size: 24),
            ),
          ),
        ],
      ),
    );
  }

  @override
  double get maxExtent => 68;

  @override
  double get minExtent => 68;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      false;
}
