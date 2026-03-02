import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:vishal_gold/services/analytics_service.dart';
import 'package:provider/provider.dart';
import 'package:vishal_gold/constants/app_colors.dart';
import 'package:vishal_gold/models/admin.dart';
import 'package:vishal_gold/screens/profile/quick_login_settings_screen.dart';
import 'package:vishal_gold/providers/auth_provider.dart';
import 'package:vishal_gold/screens/admin/category_management_screen.dart';
import 'package:vishal_gold/screens/admin/product_management_screen.dart';
import 'package:vishal_gold/screens/admin/sub_admin_management_screen.dart';
import 'package:vishal_gold/screens/admin/subcategory_management_screen.dart';
import 'package:vishal_gold/screens/admin/banner_management_screen.dart';
import 'package:vishal_gold/screens/admin/admin_orders_screen.dart';
import 'package:vishal_gold/screens/admin/fcm_console_screen.dart';
import 'package:vishal_gold/providers/preview_provider.dart';
import 'package:vishal_gold/screens/home/home_screen.dart';
import 'package:vishal_gold/screens/admin/analytics_dashboard_screen.dart';
import 'package:vishal_gold/screens/admin/crm_hub_screen.dart';
import 'package:vishal_gold/screens/admin/flash_sale_creator_screen.dart';
import 'package:vishal_gold/screens/admin/design_to_social_screen.dart';
import 'package:vishal_gold/screens/admin/audit_trail_screen.dart';
import 'package:vishal_gold/screens/admin/contact_management_screen.dart';
import 'package:vishal_gold/services/firebase_service.dart';
import 'package:vishal_gold/utils/app_layout.dart';

// ── Design tokens ──────────────────────────────────────────────────────────
const _kBg = Color(0xFF080808);
const _kSurface = Color(0xFF111111);
const _kCard = Color(0xFF161616);
const _kBorderSubtle = Color(0x14FFFFFF); // white 8%
const _kGoldBorder = Color(0x26D4AF37); // gold 15%

class AdminDashboardScreen extends StatefulWidget {
  final Admin admin;

  const AdminDashboardScreen({super.key, required this.admin});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late Admin _currentAdmin;
  final FirebaseService _firebaseService = FirebaseService();
  Map<String, int> _stats = {
    'products': 0,
    'categories': 0,
    'subcategories': 0,
    'admins': 0,
  };
  bool _loadingStats = true;

  @override
  void initState() {
    super.initState();
    _currentAdmin = widget.admin;
    _refreshStats();
  }

  Future<void> _refreshStats() async {
    setState(() => _loadingStats = true);
    final stats = await _firebaseService.getDashboardStats();
    if (mounted) {
      setState(() {
        _stats = stats;
        _loadingStats = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final preview = context.watch<PreviewProvider>();

    return Scaffold(
      backgroundColor: _kBg,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppLayout.of(context).horizontalPadding,
                8,
                AppLayout.of(context).horizontalPadding,
                30,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick Actions strip
                  const SizedBox(height: 16),
                  _buildQuickActionsRow(),
                  const SizedBox(height: 32),

                  // Stats strip
                  _buildStatsStrip(),
                  const SizedBox(height: 32),

                  // Catalog Management
                  if (_currentAdmin.hasPermission('manage_products')) ...[
                    _buildSectionHeader(
                      'Catalog Management',
                      Icons.inventory_2_outlined,
                    ),
                    const SizedBox(height: 14),
                    _buildModuleGrid([
                      _MenuAction(
                        title: 'Products',
                        icon: Icons.inventory_2_outlined,
                        color: const Color(0xFFFFB347),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ProductManagementScreen(),
                          ),
                        ),
                      ),
                      _MenuAction(
                        title: 'Categories',
                        icon: Icons.category_outlined,
                        color: const Color(0xFF42A5F5),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CategoryManagementScreen(),
                          ),
                        ),
                      ),
                      _MenuAction(
                        title: 'Subcategories',
                        icon: Icons.account_tree_outlined,
                        color: const Color(0xFF66BB6A),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SubcategoryManagementScreen(
                              category: null,
                            ),
                          ),
                        ),
                      ),
                      _MenuAction(
                        title: 'Banners',
                        icon: Icons.photo_library_outlined,
                        color: const Color(0xFFEF5350),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const BannerManagementScreen(),
                          ),
                        ),
                      ),
                    ]),

                    const SizedBox(height: 32),
                  ],

                  // Operations & Sales
                  if (_currentAdmin.hasPermission('manage_orders') ||
                      _currentAdmin.hasPermission('manage_products') ||
                      _currentAdmin.hasPermission('view_analytics')) ...[
                    _buildSectionHeader(
                      'Operations & Sales',
                      Icons.shopping_bag_outlined,
                    ),
                    const SizedBox(height: 14),
                    _buildModuleGrid([
                      if (_currentAdmin.hasPermission('manage_orders'))
                        _MenuAction(
                          title: 'Orders',
                          icon: Icons.shopping_bag_outlined,
                          color: const Color(0xFF64B5F6),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AdminOrdersScreen(),
                            ),
                          ),
                        ),
                      if (_currentAdmin.hasPermission('manage_products'))
                        _MenuAction(
                          title: 'Inventory',
                          icon: Icons.inventory_outlined,
                          color: const Color(0xFF26A69A),
                          onTap: () => _openWeightAnalytics(context),
                        ),
                      if (_currentAdmin.hasPermission('view_analytics'))
                        _MenuAction(
                          title: 'Analytics',
                          icon: Icons.insights_rounded,
                          color: const Color(0xFFD4AF37),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AnalyticsDashboardScreen(),
                            ),
                          ),
                        ),
                      if (_currentAdmin.hasPermission('manage_products'))
                        _MenuAction(
                          title: 'Flash Sale',
                          icon: Icons.flash_on_rounded,
                          color: const Color(0xFFFF7043),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const FlashSaleCreatorScreen(),
                            ),
                          ),
                        ),
                    ]),

                    const SizedBox(height: 32),
                  ],

                  // Marketing & CRM
                  if (_currentAdmin.hasPermission('manage_users') ||
                      _currentAdmin.hasPermission('manage_products') ||
                      _currentAdmin.hasPermission('manage_settings')) ...[
                    _buildSectionHeader(
                      'Marketing & CRM',
                      Icons.campaign_rounded,
                    ),
                    const SizedBox(height: 14),
                    _buildModuleGrid([
                      if (_currentAdmin.hasPermission('manage_users'))
                        _MenuAction(
                          title: 'CRM Hub',
                          icon: Icons.people_alt_rounded,
                          color: const Color(0xFF42A5F5),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CRMHubScreen(),
                            ),
                          ),
                        ),
                      if (_currentAdmin.hasPermission('manage_products'))
                        _MenuAction(
                          title: 'Promotions',
                          icon: Icons.auto_awesome_rounded,
                          color: const Color(0xFFEC407A),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const DesignToSocialScreen(),
                            ),
                          ),
                        ),
                      if (_currentAdmin.hasPermission('manage_settings'))
                        _MenuAction(
                          title: 'Alerts',
                          icon: Icons.campaign_outlined,
                          color: const Color(0xFFD4AF37),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  AdminFCMConsoleScreen(admin: _currentAdmin),
                            ),
                          ),
                        ),
                    ]),

                    const SizedBox(height: 32),
                  ],

                  // Security & Admin
                  _buildSectionHeader(
                    'Security & Admin',
                    Icons.shield_outlined,
                  ),
                  const SizedBox(height: 14),
                  _buildModuleGrid([
                    if (_currentAdmin.hasPermission('view_analytics'))
                      _MenuAction(
                        title: 'Audit Trail',
                        icon: Icons.history_edu_rounded,
                        color: const Color(0xFF90A4AE),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AuditTrailScreen(),
                          ),
                        ),
                      ),
                    if (_currentAdmin.hasPermission('manage_settings'))
                      _MenuAction(
                        title: 'Contact Info',
                        icon: Icons.contact_mail_outlined,
                        color: const Color(0xFFAB47BC),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ContactManagementScreen(),
                            ),
                          );
                        },
                      ),
                    if (_currentAdmin.isSuperAdmin)
                      _MenuAction(
                        title: 'Admins',
                        icon: Icons.admin_panel_settings_outlined,
                        color: const Color(0xFF66BB6A),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SubAdminManagementScreen(),
                            ),
                          );
                        },
                      ),
                    _MenuAction(
                      title: 'Quick Login',
                      icon: Icons.fingerprint_rounded,
                      color: const Color(0xFF4FC3F7),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => QuickLoginSettingsScreen(),
                        ),
                      ),
                    ),
                  ]),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: preview.pendingChangesCount > 0
          ? ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 80),
              child: _buildPublishBar(preview),
            )
          : null,
    );
  }

  // ── Sliver App Bar ────────────────────────────────────────────────────────

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: AppLayout.of(context).adminHeaderHeight,
      pinned: true,
      backgroundColor: _kSurface,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Gradient backdrop
            Container(decoration: const BoxDecoration(color: _kSurface)),
            // Gold radial glow
            Positioned(
              top: -60,
              left: -40,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.gold.withValues(alpha: 0.18),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Decorative admin icon
            Positioned(
              right: -30,
              bottom: -20,
              child: Icon(
                Icons.diamond_outlined,
                size: 180,
                color: AppColors.gold.withValues(alpha: 0.04),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 70, 20, 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Avatar
                  GestureDetector(
                    onTap: () => _openEditProfile(context),
                    child: Container(
                      padding: const EdgeInsets.all(2.5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [AppColors.gold, Color(0xFF8B6914)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.gold.withValues(alpha: 0.3),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 34,
                        backgroundColor: const Color(0xFF1E1E1E),
                        child: Text(
                          _currentAdmin.fullName.isNotEmpty
                              ? _currentAdmin.fullName[0].toUpperCase()
                              : 'A',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: AppColors.gold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Welcome back,',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: Colors.white38,
                          ),
                        ),
                        Text(
                          _currentAdmin.fullName.split(' ')[0],
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Role badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.gold.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.gold.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.verified_rounded,
                                color: AppColors.gold,
                                size: 12,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                _currentAdmin.role.toUpperCase(),
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  color: AppColors.gold,
                                  letterSpacing: 1.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: Consumer<PreviewProvider>(
            builder: (context, preview, _) => Icon(
              preview.isPreviewMode
                  ? Icons.visibility_rounded
                  : Icons.visibility_off_outlined,
              color: preview.isPreviewMode ? AppColors.gold : Colors.white38,
            ),
          ),
          onPressed: () {
            final preview = context.read<PreviewProvider>();
            preview.togglePreviewMode();
            if (preview.isPreviewMode) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HomeScreen()),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Preview Mode Active — Browsing as End User'),
                  backgroundColor: AppColors.gold,
                ),
              );
            }
          },
          tooltip: 'Preview App',
        ),
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: AppColors.gold),
          onPressed: _refreshStats,
          tooltip: 'Refresh',
        ),
        IconButton(
          icon: const Icon(
            Icons.power_settings_new_rounded,
            color: AppColors.gold,
          ),
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: const Color(0xFF1A1A1A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: _kGoldBorder),
                ),
                title: Text(
                  'Log Out',
                  style: GoogleFonts.playfairDisplay(color: AppColors.gold),
                ),
                content: Text(
                  'Are you sure you want to exit?',
                  style: GoogleFonts.outfit(color: Colors.white70),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.outfit(color: Colors.white54),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(
                      'Logout',
                      style: GoogleFonts.outfit(color: Colors.redAccent),
                    ),
                  ),
                ],
              ),
            );
            if (confirm == true && mounted) {
              await context.read<AuthProvider>().signOut();
              if (mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            }
          },
          tooltip: 'Logout',
        ),
      ],
    );
  }

  // ── Quick Actions Row ────────────────────────────────────────────────────

  Widget _buildQuickActionsRow() {
    final actions = [
      if (_currentAdmin.hasPermission('manage_orders'))
        {
          'label': 'Orders',
          'icon': Icons.shopping_bag_outlined,
          'screen': const AdminOrdersScreen(),
        },
      if (_currentAdmin.hasPermission('manage_products'))
        {
          'label': 'Products',
          'icon': Icons.inventory_2_outlined,
          'screen': const ProductManagementScreen(),
        },
      if (_currentAdmin.hasPermission('manage_users'))
        {
          'label': 'CRM',
          'icon': Icons.people_alt_rounded,
          'screen': const CRMHubScreen(),
        },
      if (_currentAdmin.hasPermission('manage_settings'))
        {
          'label': 'Alerts',
          'icon': Icons.campaign_outlined,
          'screen': AdminFCMConsoleScreen(admin: _currentAdmin),
        },
      if (_currentAdmin.hasPermission('view_analytics'))
        {
          'label': 'Analytics',
          'icon': Icons.bar_chart_rounded,
          'screen': const AnalyticsDashboardScreen(),
        },
    ];

    if (actions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: GoogleFonts.outfit(
            color: Colors.white38,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: actions.map((a) {
              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => a['screen'] as Widget),
                ),
                child: Container(
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: _kCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _kBorderSubtle),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        a['icon'] as IconData,
                        color: AppColors.gold,
                        size: 16,
                      ),
                      const SizedBox(width: 7),
                      Text(
                        a['label'] as String,
                        style: GoogleFonts.outfit(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ── Stats Strip ──────────────────────────────────────────────────────────

  Widget _buildStatsStrip() {
    return SizedBox(
      height: 95,
      child: _loadingStats
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.gold),
            )
          : ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildStatTile(
                  context,
                  'Products',
                  '${_stats['products']}',
                  Icons.inventory_2_outlined,
                  const Color(0xFFFFB347),
                ),
                _buildStatTile(
                  context,
                  'Categories',
                  '${_stats['categories']}',
                  Icons.category_outlined,
                  const Color(0xFF42A5F5),
                ),
                _buildStatTile(
                  context,
                  'Sub-cats',
                  '${_stats['subcategories']}',
                  Icons.account_tree_outlined,
                  const Color(0xFF66BB6A),
                ),
                _buildStatTile(
                  context,
                  'Admins',
                  '${_stats['admins']}',
                  Icons.admin_panel_settings_outlined,
                  AppColors.gold,
                ),
              ],
            ),
    );
  }

  Widget _buildStatTile(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color accent,
  ) {
    final layout = AppLayout.of(context);
    return Container(
      width: layout.statTileWidth,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: accent, size: 15),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.bold,
              height: 1.1,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.outfit(
              color: Colors.white38,
              fontSize: 10,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  // ── Section Header ───────────────────────────────────────────────────────

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 20,
          decoration: BoxDecoration(
            color: AppColors.gold,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Icon(icon, color: AppColors.gold.withValues(alpha: 0.7), size: 16),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }

  // ── Module Grid (Glassmorphism Cards) ────────────────────────────────────

  Widget _buildModuleGrid(List<_MenuAction> actions) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = AppLayout.of(context);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: layout.adminModuleColumns,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: layout.adminModuleAspectRatio,
          ),
          itemCount: actions.length,
          itemBuilder: (context, index) {
            final action = actions[index];
            return _buildGlassCard(action);
          },
        );
      },
    );
  }

  Widget _buildGlassCard(_MenuAction action) {
    return InkWell(
      onTap: action.onTap,
      borderRadius: BorderRadius.circular(18),
      splashColor: action.color.withValues(alpha: 0.1),
      highlightColor: action.color.withValues(alpha: 0.05),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: _kCard.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: action.color.withValues(alpha: 0.18)),
              boxShadow: [
                BoxShadow(
                  color: action.color.withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Icon container with gradient
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          action.color.withValues(alpha: 0.25),
                          action.color.withValues(alpha: 0.08),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: action.color.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Icon(action.icon, color: action.color, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      action.title,
                      style: GoogleFonts.outfit(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: action.color.withValues(alpha: 0.4),
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Publish Bar ──────────────────────────────────────────────────────────

  Widget _buildPublishBar(PreviewProvider preview) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        border: Border(
          top: BorderSide(
            color: AppColors.gold.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.pending_actions,
                    color: AppColors.gold,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${preview.pendingChangesCount} staged',
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            OutlinedButton(
              onPressed: () => _discardChanges(context),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.redAccent),
                foregroundColor: Colors.redAccent,
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: const Text('Discard'),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () => _publishChanges(context),
              icon: const Icon(Icons.publish_rounded, size: 18),
              label: const Text('Publish'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(0, 48),
                backgroundColor: AppColors.gold,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _publishChanges(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1C),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: _kGoldBorder),
        ),
        title: Text(
          'Publish All Changes?',
          style: GoogleFonts.playfairDisplay(color: Colors.white),
        ),
        content: Text(
          'This will apply all staged changes to live data immediately. This cannot be undone.',
          style: GoogleFonts.outfit(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.outfit(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(0, 48),
              backgroundColor: AppColors.gold,
              foregroundColor: Colors.black,
            ),
            child: const Text('Publish'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final firebaseService = FirebaseService();
      await firebaseService.publishAllChanges(_currentAdmin.id);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('✅ All changes published successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('❌ Failed to publish: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _discardChanges(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1C),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.4)),
        ),
        title: Text(
          'Discard All Changes?',
          style: GoogleFonts.playfairDisplay(color: Colors.white),
        ),
        content: Text(
          'This will permanently delete all staged changes. This cannot be undone.',
          style: GoogleFonts.outfit(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.outfit(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(0, 48),
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final firebaseService = FirebaseService();
      await firebaseService.discardAllChanges(_currentAdmin.id);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('🗑️ All staged changes discarded.'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('❌ Failed to discard: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _openWeightAnalytics(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF141414),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _WeightAnalyticsSheet(),
    );
  }

  void _openEditProfile(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF141414),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _EditAdminProfileSheet(
          admin: _currentAdmin,
          onUpdate: (updatedAdmin) {
            setState(() => _currentAdmin = updatedAdmin);
          },
        ),
      ),
    );
  }
}

class _MenuAction {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  _MenuAction({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

class _EditAdminProfileSheet extends StatefulWidget {
  final Admin admin;
  final Function(Admin) onUpdate;

  const _EditAdminProfileSheet({required this.admin, required this.onUpdate});

  @override
  State<_EditAdminProfileSheet> createState() => _EditAdminProfileSheetState();
}

class _EditAdminProfileSheetState extends State<_EditAdminProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _whatsappController;
  late TextEditingController _secondaryEmailController;
  final FirebaseService _firebaseService = FirebaseService();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.admin.fullName);
    _whatsappController = TextEditingController(
      text: widget.admin.whatsappNumber ?? '',
    );
    _secondaryEmailController = TextEditingController(
      text: widget.admin.secondaryEmail ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _whatsappController.dispose();
    _secondaryEmailController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final updates = {
        'full_name': _nameController.text.trim(),
        'whatsapp_number': _whatsappController.text.trim(),
        'secondary_email': _secondaryEmailController.text.trim(),
      };

      await _firebaseService.updateAdminProfile(
        adminId: widget.admin.id,
        updates: updates,
      );

      final updatedAdmin = widget.admin.copyWith(
        fullName: updates['full_name'],
        whatsappNumber: updates['whatsapp_number'],
        secondaryEmail: updates['secondary_email'],
        updatedAt: DateTime.now(),
      );

      widget.onUpdate(updatedAdmin);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF141414),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Edit Profile',
              style: GoogleFonts.playfairDisplay(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.gold,
              ),
            ),
            const SizedBox(height: 24),
            _buildTextField(_nameController, 'Full Name', Icons.person_outline),
            const SizedBox(height: 16),
            _buildTextField(
              _whatsappController,
              'WhatsApp Number',
              Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              _secondaryEmailController,
              'Email',
              Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _loading ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _loading
                  ? const CircularProgressIndicator(color: AppColors.black)
                  : const Text(
                      'Save Changes',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white38),
        prefixIcon: Icon(icon, color: AppColors.gold),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white10),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.gold),
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.03),
      ),
      validator: (v) => v!.isEmpty ? 'Required' : null,
    );
  }
}

class _WeightAnalyticsSheet extends StatelessWidget {
  const _WeightAnalyticsSheet();

  @override
  Widget build(BuildContext context) {
    final firebaseService = FirebaseService();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF141414),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Inventory Analytics',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.gold,
                ),
              ),
              const Icon(Icons.analytics_outlined, color: AppColors.gold),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: FutureBuilder<Map<String, double>>(
              future: firebaseService.getWeightAnalytics(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(color: AppColors.gold),
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                  );
                }

                final analytics = snapshot.data ?? {};
                if (analytics.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: Text(
                        'No inventory data available',
                        style: TextStyle(color: Colors.white38),
                      ),
                    ),
                  );
                }

                double totalWeight = 0;
                analytics.forEach((k, v) => totalWeight += v);

                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.gold.withValues(alpha: 0.2),
                            AppColors.gold.withValues(alpha: 0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.gold.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total Net Weight',
                                style: GoogleFonts.outfit(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                '${totalWeight.toStringAsFixed(3)}g',
                                style: GoogleFonts.outfit(
                                  color: AppColors.gold,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const Icon(
                            Icons.scale_rounded,
                            color: AppColors.gold,
                            size: 32,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: firebaseService.getCategories(),
                        builder: (context, catSnapshot) {
                          final categories = catSnapshot.data?.docs ?? [];
                          return ListView.separated(
                            itemCount: categories.length,
                            separatorBuilder: (context, index) =>
                                const Divider(color: Colors.white10, height: 1),
                            itemBuilder: (context, index) {
                              final doc = categories[index];
                              final netWeight = analytics[doc.id] ?? 0.0;
                              if (netWeight == 0) {
                                return const SizedBox.shrink();
                              }

                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  doc['name'],
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                trailing: Text(
                                  '${netWeight.toStringAsFixed(3)}g',
                                  style: GoogleFonts.outfit(
                                    color: AppColors.gold,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsHubSheet extends StatefulWidget {
  const _AnalyticsHubSheet();

  @override
  State<_AnalyticsHubSheet> createState() => _AnalyticsHubSheetState();
}

class _AnalyticsHubSheetState extends State<_AnalyticsHubSheet> {
  final AnalyticsService _analyticsService = AnalyticsService();
  int _selectedIndex = 0; // 0: Trends, 1: Category, 2: Wishlist
  bool _isLoading = true;
  Map<String, int> _trends = {};
  Map<String, int> _distribution = {};
  List<Map<String, dynamic>> _trending = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final trends = await _analyticsService.getProductUploadTrends();
      final distribution = await _analyticsService.getCategoryDistribution();
      final trending = await _analyticsService.getTrendingProducts();
      if (mounted) {
        setState(() {
          _trends = trends;
          _distribution = distribution;
          _trending = trending;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF141414),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Analytics Hub',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.gold,
                    ),
                  ),
                  Text(
                    'Professional Insights',
                    style: GoogleFonts.outfit(
                      color: Colors.white38,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: AppColors.gold),
                onPressed: _loadData,
              ),
            ],
          ),
          const SizedBox(height: 24),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildTypeChip(
                  'Upload Trends',
                  _selectedIndex == 0,
                  () => setState(() => _selectedIndex = 0),
                ),
                const SizedBox(width: 12),
                _buildTypeChip(
                  'Categories',
                  _selectedIndex == 1,
                  () => setState(() => _selectedIndex = 1),
                ),
                const SizedBox(width: 12),
                _buildTypeChip(
                  'Wishlist Trends',
                  _selectedIndex == 2,
                  () => setState(() => _selectedIndex = 2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.gold),
                  )
                : _selectedIndex == 0
                ? _buildTrendChart()
                : _selectedIndex == 1
                ? _buildDistributionChart()
                : _buildWishlistTrends(),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.gold.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.gold : Colors.white10,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            color: isSelected ? AppColors.gold : Colors.white38,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildTrendChart() {
    if (_trends.isEmpty) {
      return const Center(
        child: Text(
          'No trend data available',
          style: TextStyle(color: Colors.white38),
        ),
      );
    }

    final sortedKeys = _trends.keys.toList();
    final spots = <FlSpot>[];
    for (int i = 0; i < sortedKeys.length; i++) {
      spots.add(FlSpot(i.toDouble(), _trends[sortedKeys[i]]!.toDouble()));
    }

    return Padding(
      padding: const EdgeInsets.only(right: 16, top: 16),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  int index = value.toInt();
                  if (index < 0 || index >= sortedKeys.length) {
                    return const SizedBox.shrink();
                  }
                  if (index % 2 != 0 && sortedKeys.length > 4) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      sortedKeys[index].split(' ')[0],
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 10,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppColors.gold,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.gold.withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDistributionChart() {
    if (_distribution.isEmpty) {
      return const Center(
        child: Text(
          'No distribution data available',
          style: TextStyle(color: Colors.white38),
        ),
      );
    }

    final keys = _distribution.keys.toList();

    return Padding(
      padding: const EdgeInsets.only(right: 16, top: 16),
      child: BarChart(
        BarChartData(
          barGroups: List.generate(keys.length, (i) {
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: _distribution[keys[i]]!.toDouble(),
                  color: AppColors.gold,
                  width: 16,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
              ],
            );
          }),
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  int index = value.toInt();
                  if (index < 0 || index >= keys.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      keys[index].substring(
                        0,
                        keys[index].length > 4 ? 4 : keys[index].length,
                      ),
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 10,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }

  Widget _buildWishlistTrends() {
    if (_trending.isEmpty) {
      return const Center(
        child: Text(
          'No wishlist trends available',
          style: TextStyle(color: Colors.white38),
        ),
      );
    }

    return ListView.builder(
      itemCount: _trending.length,
      padding: const EdgeInsets.only(top: 8),
      itemBuilder: (context, index) {
        final item = _trending[index];
        final productData = item['product'] as Map<String, dynamic>;
        final count = item['wishlistCount'] as int;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child:
                    productData['image_urls'] != null &&
                        (productData['image_urls'] as List).isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          productData['image_urls'][0],
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.image_not_supported_outlined,
                            color: Colors.white24,
                            size: 20,
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.image_outlined,
                        color: Colors.white24,
                        size: 20,
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      productData['tag_number'] ?? 'No Tag',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      productData['category']?.toString().toUpperCase() ?? '',
                      style: GoogleFonts.outfit(
                        color: AppColors.gold,
                        fontSize: 10,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.favorite, color: AppColors.gold, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      '$count',
                      style: GoogleFonts.outfit(
                        color: AppColors.gold,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
