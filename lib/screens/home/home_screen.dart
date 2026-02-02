import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vishal_gold/constants/app_colors.dart';
import 'package:vishal_gold/constants/app_strings.dart';
import 'package:vishal_gold/providers/auth_provider.dart';
import 'package:vishal_gold/providers/cart_provider.dart';
import 'package:vishal_gold/screens/cart/cart_screen.dart';
import 'package:vishal_gold/screens/notifications/notifications_screen.dart';
import 'package:vishal_gold/screens/profile/profile_screen.dart';
import 'package:vishal_gold/screens/recent/recent_designs_screen.dart';
import 'package:vishal_gold/widgets/home/banner_carousel.dart';
import 'package:vishal_gold/widgets/home/category_section.dart';
import 'package:vishal_gold/screens/upload/upload_design_screen.dart';
import 'package:image_picker/image_picker.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeTab(),
    const NotificationsScreen(),
    const ProfileScreen(),
    const RecentDesignsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  Future<void> _loadCart() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    if (authProvider.user != null) {
      await cartProvider.loadCart(authProvider.user!.id);
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _openImagePicker() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.user == null || !authProvider.user!.isWholesaler) {
      return;
    }

    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();

    if (images.isNotEmpty && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UploadDesignScreen(images: images),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isWholesaler = authProvider.user?.isWholesaler ?? false;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: AppStrings.home,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: AppStrings.newStock,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: AppStrings.profile,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: AppStrings.recent,
          ),
        ],
      ),
      floatingActionButton: isWholesaler
          ? FloatingActionButton(
              onPressed: _openImagePicker,
              backgroundColor: AppColors.oliveGreen,
              child: const Icon(Icons.add, color: AppColors.white),
            )
          : null,
    );
  }
}

// Home Tab Content
class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Image.asset(
          AppStrings.logoPath,
          height: 40,
          fit: BoxFit.contain,
        ),
        centerTitle: true,
        actions: [
          Consumer<CartProvider>(
            builder: (context, cartProvider, child) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CartScreen(),
                        ),
                      );
                    },
                  ),
                  if (cartProvider.itemCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.errorRed,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '${cartProvider.itemCount}',
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner Carousel
            const BannerCarousel(),
            const SizedBox(height: 16),

            // 84 Ornaments Section
            CategorySection(
              title: AppStrings.ornaments84,
              category: '84_ornaments',
              subcategories: const [
                {'name': 'Chains', 'image': 'assets/images/chain.webp'},
                {'name': 'Rings', 'image': 'assets/images/ring.webp'},
                {'name': 'Necklaces', 'image': 'assets/images/nackless.webp'},
                {'name': 'Bangles', 'image': 'assets/images/bangles.png'},
                {'name': 'Bracelets', 'image': 'assets/images/braclate.webp'},
                {'name': 'Earrings', 'image': 'assets/images/earrings.webp'},
              ],
            ),

            const Divider(height: 32, thickness: 1),

            // 92 Ornaments Section
            CategorySection(
              title: AppStrings.ornaments92,
              category: '92_ornaments',
              subcategories: const [
                {'name': 'Chains', 'image': 'assets/images/chain.webp'},
                {'name': 'Rings', 'image': 'assets/images/ring.webp'},
                {'name': 'Necklaces', 'image': 'assets/images/nackless.webp'},
                {'name': 'Bangles', 'image': 'assets/images/bangles.png'},
                {'name': 'Bracelets', 'image': 'assets/images/braclate.webp'},
                {'name': 'Earrings', 'image': 'assets/images/earrings.webp'},
              ],
            ),

            const Divider(height: 32, thickness: 1),

            // 92 Chains Section
            CategorySection(
              title: AppStrings.chains92,
              category: '92_chains',
              subcategories: const [
                {'name': 'Gold Chain', 'image': 'assets/images/gold_chain.png'},
                {
                  'name': 'Silver Chain',
                  'image': 'assets/images/silver_chain.png',
                },
                {
                  'name': 'Designer Chain',
                  'image': 'assets/images/designer_chain.png',
                },
                {
                  'name': 'Simple Chain',
                  'image': 'assets/images/simple_chain.png',
                },
              ],
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
