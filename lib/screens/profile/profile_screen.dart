import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;

import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:vishal_gold/constants/app_colors.dart';
import 'package:vishal_gold/providers/auth_provider.dart';
import 'package:vishal_gold/screens/auth/phone_auth_screen.dart';
import 'package:vishal_gold/screens/order/order_history_screen.dart';
import 'package:vishal_gold/screens/favourite/favourite_products_screen.dart';
import 'package:vishal_gold/screens/info/privacy_policy_screen.dart';
import 'package:vishal_gold/screens/profile/edit_profile_screen.dart';
import 'package:vishal_gold/screens/profile/quick_login_settings_screen.dart';

import 'package:vishal_gold/screens/settings/notification_settings_screen.dart';
import 'package:vishal_gold/screens/settings/security_center_screen.dart';
import 'package:vishal_gold/screens/settings/storage_settings_screen.dart';

import 'package:vishal_gold/screens/dev/database_cleanup_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _devTapCount = 0;
  DateTime? _lastTapTime;


  @override
  void initState() {
    super.initState();
  }

  Future<void> _launchURL(String url, {String? fallbackUrl}) async {
    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else if (fallbackUrl != null) {
        final Uri fallbackUri = Uri.parse(fallbackUrl);
        if (await canLaunchUrl(fallbackUri)) {
          await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
        } else {
          throw 'Could not launch $url';
        }
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not open the requested application.',
              style: GoogleFonts.outfit(color: AppColors.white),
            ),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  void _showSupportBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: AppColors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                'CONTACT US',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.gold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 24),
              _buildSupportTile(
                icon: Icons.chat_outlined,
                title: 'Chat on WhatsApp',
                subtitle: '+91 9909280997',
                onTap: () {
                  Navigator.pop(context);
                  _launchURL(
                    'whatsapp://send?phone=+919909280997',
                    fallbackUrl: 'https://wa.me/919909280997',
                  );
                },
              ),
              const SizedBox(height: 12),
              _buildSupportTile(
                icon: Icons.phone_outlined,
                title: 'Call Us',
                subtitle: '+91 9909280997',
                onTap: () {
                  Navigator.pop(context);
                  _launchURL('tel:+919909280997');
                },
              ),
              const SizedBox(height: 12),
              _buildSupportTile(
                icon: Icons.mail_outline,
                title: 'Email Us',
                subtitle: 'vishalgoldapp@gmail.com',
                onTap: () {
                  Navigator.pop(context);
                  _launchURL('mailto:vishalgoldapp@gmail.com');
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSupportTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.grey.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.gold, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      color: AppColors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      color: AppColors.grey,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: AppColors.grey, size: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Logout',
          style: GoogleFonts.playfairDisplay(
            color: AppColors.gold,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: GoogleFonts.outfit(color: AppColors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'CANCEL',
              style: GoogleFonts.outfit(color: AppColors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorRed,
            ),
            child: Text(
              'LOGOUT',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                color: AppColors.white,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.signOut();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const PhoneAuthScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: _buildErrorUI(
          'Authentication Required',
          'Please login to view your profile.',
          onRetry: () => Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const PhoneAuthScreen()),
            (route) => false,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Builder(
        builder: (context) {
          if (authProvider.isLoading && authProvider.userProfile == null) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.gold),
            );
          }

          if (authProvider.userProfile == null) {
            return _buildDefaultProfileUI(user);
          }

          final data = authProvider.userProfile!;
          final String name = data['fullName'] as String? ?? data['name'] as String? ?? 'Guest User';
          final String email = data['email'] as String? ?? user.email ?? 'N/A';
          final String phone = data['phone'] as String? ?? user.phoneNumber ?? 'N/A';
          final String role = (data['role'] as String? ?? 'User').toUpperCase();
          final String? profileImageUrl = data['profile_image_url'] as String?;

          return SingleChildScrollView(
            child: Column(
              children: [
                // Header Section
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 60, 24, 40),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.gold, width: 2),
                            ),
                            child: GestureDetector(
                              onTap: () {
                                final now = DateTime.now();
                                if (_lastTapTime == null ||
                                    now.difference(_lastTapTime!) >
                                        const Duration(seconds: 2)) {
                                  _devTapCount = 1;
                                } else {
                                  _devTapCount++;
                                }
                                _lastTapTime = now;

                                if (_devTapCount >= 7) {
                                  _devTapCount = 0;
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const DatabaseCleanupScreen(),
                                    ),
                                  );
                                }
                              },
                              child: CircleAvatar(
                                radius: 50,
                                backgroundColor: AppColors.background,
                                backgroundImage: (profileImageUrl?.isNotEmpty ==
                                        true)
                                    ? CachedNetworkImageProvider(profileImageUrl!)
                                    : null,
                                child: (profileImageUrl?.isNotEmpty != true)
                                    ? Text(
                                        name.isNotEmpty ? name[0].toUpperCase() : 'U',
                                        style: GoogleFonts.playfairDisplay(
                                          fontSize: 40,
                                          color: AppColors.gold,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: AppColors.white,
                              ),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const EditProfileScreen(),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.gold.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.edit,
                                color: AppColors.gold,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.gold.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          role,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.gold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Info Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      _buildSectionTitle('ACCOUNT INFO'),
                      const SizedBox(height: 16),
                      _buildInfoCard([
                        _InfoRow(
                          icon: Icons.email_outlined,
                          label: 'Email',
                          value: email,
                        ),
                        _InfoRow(
                          icon: Icons.phone_outlined,
                          label: 'Phone',
                          value: phone,
                        ),
                        if (authProvider.isWholesaler) ...[
                          _InfoRow(
                            icon: Icons.business_outlined,
                            label: 'Company',
                            value: data['company_name'] as String? ?? 'N/A',
                          ),
                          _InfoRow(
                            icon: Icons.location_city_outlined,
                            label: 'City',
                            value: data['city'] as String? ?? 'N/A',
                          ),
                        ],
                      ]),

                      const SizedBox(height: 32),
                      _buildSectionTitle('SETTINGS & SUPPORT'),
                      const SizedBox(height: 16),
                      _buildMenuCard([
                        _MenuRow(
                          icon: Icons.history,
                          title: 'Order History',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const OrderHistoryScreen(),
                            ),
                          ),
                        ),
                        // Added Favourite Product Option
                        _MenuRow(
                          icon: Icons.favorite_border,
                          title: 'Favourite Product',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const FavouriteProductsScreen(),
                            ),
                          ),
                        ),
                        if (role == 'ADMIN' || role == 'SUPER_ADMIN')
                          _MenuRow(
                            icon: Icons.security,
                            title: 'Quick Login Settings',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const QuickLoginSettingsScreen(),
                              ),
                            ),
                          ),

                        if (role == 'ADMIN' || role == 'SUPER_ADMIN')
                          _MenuRow(
                            icon: Icons.security_outlined,
                            title: 'Security Center',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SecurityCenterScreen(),
                              ),
                            ),
                          ),

                        if (role == 'ADMIN' || role == 'SUPER_ADMIN')
                          _MenuRow(
                            icon: Icons.notifications_none_outlined,
                            title: 'Notification Preferences',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const NotificationSettingsScreen(),
                              ),
                            ),
                          ),



                        if (role == 'ADMIN' || role == 'SUPER_ADMIN')
                          _MenuRow(
                            icon: Icons.storage_outlined,
                            title: 'Storage & Data',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const StorageSettingsScreen(),
                              ),
                            ),
                          ),

                        _MenuRow(
                          icon: Icons.support_agent_outlined,
                          title: 'Support Hub',
                          onTap: () => _showSupportBottomSheet(context),
                        ),
                        _MenuRow(
                          icon: Icons.privacy_tip_outlined,
                          title: 'Privacy Policy',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PrivacyPolicyScreen(),
                            ),
                          ),
                        ),
                      ]),

                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _logout(context),
                          icon:
                              const Icon(Icons.logout, color: AppColors.errorRed),
                          label: Text(
                            'LOGOUT',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              color: AppColors.errorRed,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: const BorderSide(color: AppColors.errorRed),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorUI(String title, String message, {VoidCallback? onRetry}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppColors.errorRed, size: 64),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.playfairDisplay(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: GoogleFonts.outfit(color: AppColors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.background,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: const Text('RETRY'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultProfileUI(User user) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.gold, width: 2),
              ),
              child: const Icon(Icons.person_outline,
                  color: AppColors.gold, size: 64),
            ),
            const SizedBox(height: 24),
            Text(
              'Profile Not Found',
              style: GoogleFonts.playfairDisplay(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your profile details are not set up yet. Would you like to set it up now?',
              style: GoogleFonts.outfit(color: AppColors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.background,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('SET UP PROFILE'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => _logout(context),
              child: Text(
                'LOGOUT',
                style: GoogleFonts.outfit(color: AppColors.errorRed),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: GoogleFonts.outfit(
          color: AppColors.grey,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey.withValues(alpha: 0.1)),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildMenuCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey.withValues(alpha: 0.1)),
      ),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.gold, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    color: AppColors.grey,
                    fontSize: 12,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    color: AppColors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _MenuRow({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.white, size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.outfit(color: AppColors.white, fontSize: 16),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        color: AppColors.grey,
        size: 16,
      ),
      onTap: onTap,
    );
  }
}
