import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:vishal_gold/constants/app_colors.dart';
import 'package:vishal_gold/providers/auth_provider.dart';
import 'package:vishal_gold/screens/auth/auth_screen.dart';
import 'package:vishal_gold/screens/order/order_history_screen.dart';
import 'package:vishal_gold/services/image_picker_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _imagePickerService = ImagePickerService();
  bool _isUploadingAvatar = false;

  Future<void> _uploadProfileImage() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user == null) return;

    final source = await _imagePickerService.showImageSourcePicker(context);
    if (source == null) return;

    setState(() => _isUploadingAvatar = true);

    try {
      final url = await _imagePickerService.pickAndUploadAvatar(
        userId: authProvider.user!.id,
        source: source,
      );

      if (url != null && mounted) {
        // Update user profile with new avatar URL
        await authProvider.updateProfile({'profile_image_url': url});

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile picture updated!'),
              backgroundColor: AppColors.successGreen,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile picture: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingAvatar = false);
      }
    }
  }

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorRed,
            ),
            child: const Text('Logout'),
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
      MaterialPageRoute(builder: (context) => const AuthScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profile'),
        automaticallyImplyLeading: false,
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 24),

                  // Profile Avatar with Upload Option
                  Stack(
                    children: [
                      GestureDetector(
                        onTap: _isUploadingAvatar ? null : _uploadProfileImage,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: AppColors.oliveGreen,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.grey.withValues(alpha: 0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: _isUploadingAvatar
                              ? const Center(
                                  child: CircularProgressIndicator(
                                    color: AppColors.white,
                                    strokeWidth: 3,
                                  ),
                                )
                              : ClipOval(
                                  child:
                                      user.profileImageUrl != null &&
                                          user.profileImageUrl!.isNotEmpty
                                      ? CachedNetworkImage(
                                          imageUrl: user.profileImageUrl!,
                                          fit: BoxFit.cover,
                                          width: 120,
                                          height: 120,
                                          placeholder: (context, url) =>
                                              const Center(
                                                child:
                                                    CircularProgressIndicator(
                                                      color: AppColors.white,
                                                    ),
                                              ),
                                          errorWidget: (context, url, error) =>
                                              _buildDefaultAvatar(
                                                user.fullName,
                                              ),
                                        )
                                      : _buildDefaultAvatar(user.fullName),
                                ),
                        ),
                      ),
                      // Camera Icon Overlay
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _isUploadingAvatar
                              ? null
                              : _uploadProfileImage,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.oliveGreen,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.grey.withValues(alpha: 0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 20,
                              color: AppColors.oliveGreen,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Tap to change text
                  Text(
                    'Tap to change photo',
                    style: GoogleFonts.roboto(
                      fontSize: 12,
                      color: AppColors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // User Name
                  Text(
                    user.fullName,
                    style: GoogleFonts.montserrat(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // User Type Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.oliveGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      user.userType?.toUpperCase() ?? 'USER',
                      style: GoogleFonts.roboto(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.oliveGreen,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Contact Info
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        _InfoTile(icon: Icons.email, text: user.email),
                        if (user.phone != null && user.phone!.isNotEmpty)
                          _InfoTile(icon: Icons.phone, text: user.phone!),
                        if (user.isWholesaler) ...[
                          if (user.companyName != null)
                            _InfoTile(
                              icon: Icons.business,
                              text: user.companyName!,
                            ),
                          if (user.city != null)
                            _InfoTile(
                              icon: Icons.location_city,
                              text: user.city!,
                            ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Divider(),

                  // Menu Options
                  _MenuTile(
                    icon: Icons.history,
                    title: 'Order History',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const OrderHistoryScreen(),
                        ),
                      );
                    },
                  ),
                  _MenuTile(
                    icon: Icons.info_outline,
                    title: 'About App',
                    onTap: () {
                      showAboutDialog(
                        context: context,
                        applicationName: 'Vishal Gold',
                        applicationVersion: '1.0.0',
                        applicationLegalese: '© 2026 Vishal Gold',
                      );
                    },
                  ),
                  const Divider(),
                  _MenuTile(
                    icon: Icons.logout,
                    title: 'Logout',
                    iconColor: AppColors.errorRed,
                    onTap: () => _logout(context),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildDefaultAvatar(String name) {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : 'U',
        style: GoogleFonts.montserrat(
          fontSize: 48,
          fontWeight: FontWeight.bold,
          color: AppColors.white,
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoTile({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.oliveGreen),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: GoogleFonts.roboto(fontSize: 14))),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? iconColor;

  const _MenuTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? AppColors.oliveGreen),
      title: Text(title, style: GoogleFonts.roboto(fontSize: 16)),
      trailing: const Icon(Icons.chevron_right, color: AppColors.grey),
      onTap: onTap,
    );
  }
}
