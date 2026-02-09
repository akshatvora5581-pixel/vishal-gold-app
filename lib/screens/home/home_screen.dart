import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vishal_gold/constants/app_colors.dart';
import 'package:vishal_gold/providers/auth_provider.dart';
import 'package:vishal_gold/providers/cart_provider.dart';
import 'package:vishal_gold/screens/notifications/notifications_screen.dart';
import 'package:vishal_gold/screens/profile/profile_screen.dart';
import 'package:vishal_gold/screens/recent/recent_designs_screen.dart';
import 'package:vishal_gold/widgets/common/custom_bottom_nav.dart';
import 'package:vishal_gold/widgets/home/custom_header.dart';
import 'package:vishal_gold/widgets/common/custom_order_fab.dart';
import 'package:vishal_gold/widgets/home/banner_carousel.dart';
import 'package:vishal_gold/widgets/home/category_section.dart';

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

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const CustomHeader(),
            // Search Bar Placeholder
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 10,
              ),
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
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                ),
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
                      category: '84_melting',
                      subcategories:
                          [
                                'Latkan 84M',
                                'Mangalsutra 84M',
                                'MS Dokiya 84M',
                                'MS Pendal 84M',
                                'Najariya 84M',
                                'Najrana Ring 84M',
                                'Nath 84M',
                                'Patla 84M',
                                'R Ladies Ring 84',
                                'Round Gents Ring 84',
                                'Rudraksh 84M',
                                'Salman Bali 84M',
                                'Set 84M',
                                'Setbutty 84',
                                'Step Butty 84',
                                'Surya Pendal 84',
                                'Tika 84M',
                                'UV Bali 84',
                                'Vertical Butty 84',
                                'Vertical Dokiya 84M',
                                'Zummar 84',
                                'Zummar Butty 84',
                                'Bachha Lucky 84M',
                                'Bajubandh 84M',
                                'Bali 84',
                                'Butty 84',
                                'China Butty 84',
                                'Fancy Kadi 84',
                                'Gents Ring 84',
                                'Gol Butty 84',
                                'J Butty 84',
                                'Kanser 84M',
                                'Kayda 84',
                                'Ladies Lucky 84M',
                                'Ladies Pendal 84M',
                                'Ladies Ring 84',
                                'Lappa Har 84',
                              ]
                              .map(
                                (sub) => {
                                  'name': sub,
                                  'image': 'assets/images/gold_chain.png',
                                },
                              )
                              .toList(),
                    ),
                    const SizedBox(height: 24),
                    CategorySection(
                      title: '92 MELTING',
                      category: '92_melting',
                      subcategories:
                          [
                                'Antiq Butty 92',
                                'Antique Dokiya 92',
                                'Bachhalucky 92M',
                                'Bajubandh 92M',
                                'Bali 92M',
                                'Butty 92M',
                                'China Butty 92',
                                'CZ Butty 92',
                                'CZ Gents Ring 92',
                                'CZ Ladies Ring 92',
                                'CZ MSP 92',
                                'CZ Pandal Butty Set',
                                'Fancy Kadi 92',
                                'Gents Ring 92M',
                                'Gol Butty 92',
                                'J Butty 92',
                                'Kanser 92M',
                                'Kayda 92',
                                'Keri Butty 92',
                                'Ladies Lucky 92M',
                                'Ladies Pendal 92M',
                                'Long Ring 92',
                                'Long Set 92',
                                'Mangalsutra 92M',
                                'MS Dokiya 92M',
                                'MS Pendal 92M',
                                'Najariya 92M',
                                'Najrana Ring 92',
                                'P. Casting GR',
                                'P. Casting LR',
                                'Patla 92M',
                                'R Ladies Ring 92',
                                'Rudraksh 92M',
                                'Set 92M',
                                'Setbutty 92',
                                'Step Butty 92',
                                'Surya Pendal 92M',
                                'Tika 92M',
                                'UV Bali 92',
                                'Vertical Butty 92',
                                'Vertical Dokiya 92M',
                                'Zummar 92M',
                                'Zummar Butty 92',
                              ]
                              .map(
                                (sub) => {
                                  'name': sub,
                                  'image': 'assets/images/gold_chain.png',
                                },
                              )
                              .toList(),
                    ),
                    const SizedBox(height: 24),
                    CategorySection(
                      title: '92 MELTING CHAINS',
                      category: '92_melting_chains',
                      subcategories:
                          [
                                'Handmade Chain 92M',
                                'Hollow 92M',
                                'Hollow Lucky 92M',
                                'Indo Hollow 92M',
                                'Lotus 92M',
                                'Nice Chain 92M',
                                'Silky 92M',
                                'Singapuri 92M',
                              ]
                              .map(
                                (sub) => {
                                  'name': sub,
                                  'image': 'assets/images/gold_chain.png',
                                },
                              )
                              .toList(),
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
