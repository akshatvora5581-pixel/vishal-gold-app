import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vishal_gold/constants/app_colors.dart';
import 'package:vishal_gold/providers/auth_provider.dart';
import 'package:vishal_gold/providers/cart_provider.dart';
import 'package:vishal_gold/screens/notifications/notifications_screen.dart';
import 'package:vishal_gold/screens/profile/profile_screen.dart';
import 'package:vishal_gold/screens/recent/recent_designs_screen.dart';
import 'package:vishal_gold/widgets/common/custom_bottom_nav.dart';
import 'package:vishal_gold/widgets/common/custom_order_fab.dart';
import 'package:vishal_gold/widgets/home/banner_carousel.dart';
import 'package:vishal_gold/widgets/home/category_section.dart';
import 'package:vishal_gold/screens/home/all_subcategories_screen.dart';
import 'package:vishal_gold/config/category_data.dart';

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
    _loadCart();
  }

  Future<void> _loadCart() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    if (authProvider.currentUser != null) {
      await cartProvider.initialize(
        authProvider.currentUser!.uid,
        authProvider.isWholesaler,
      );
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
      body: _screens[_selectedIndex],
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
      floatingActionButton: _selectedIndex == 0 ? const CustomOrderFAB() : null,
    );
  }
}

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar and Profile Button
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 10,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search for jewelry...',
                        prefixIcon: const Icon(
                          Icons.search,
                          color: AppColors.textSecondary,
                        ),
                        fillColor: AppColors.surface,
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Profile Button
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProfileScreen(),
                        ),
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
                            AppColors.gold.withOpacity(0.8),
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.gold.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.person,
                        color: AppColors.black,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    const BannerCarousel(),
                    const SizedBox(height: 16),
                    CategorySection(
                      title: '84 MELTING',
                      category: CategoryData.category84,
                      onViewAll: () {
                        final subs = CategoryData.getSubcategories(
                          CategoryData.category84,
                        );
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AllSubcategoriesScreen(
                              title: '84 MELTING',
                              category: CategoryData.category84,
                              subcategories: subs,
                            ),
                          ),
                        );
                      },
                      subcategories: CategoryData.getSubcategories(
                        CategoryData.category84,
                      ),
                    ),
                    const SizedBox(height: 24),
                    CategorySection(
                      title: '92 MELTING',
                      category: CategoryData.category92,
                      onViewAll: () {
                        final subs = CategoryData.getSubcategories(
                          CategoryData.category92,
                        );
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AllSubcategoriesScreen(
                              title: '92 MELTING',
                              category: CategoryData.category92,
                              subcategories: subs,
                            ),
                          ),
                        );
                      },
                      subcategories: CategoryData.getSubcategories(
                        CategoryData.category92,
                      ),
                    ),
                    const SizedBox(height: 24),
                    CategorySection(
                      title: '92 MELTING CHAIN',
                      category: CategoryData.categoryChains92,
                      onViewAll: () {
                        final subs = CategoryData.getSubcategories(
                          CategoryData.categoryChains92,
                        );
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AllSubcategoriesScreen(
                              title: '92 MELTING CHAIN',
                              category: CategoryData.categoryChains92,
                              subcategories: subs,
                            ),
                          ),
                        );
                      },
                      subcategories: CategoryData.getSubcategories(
                        CategoryData.categoryChains92,
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
