import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:vishal_gold/services/analytics_service.dart';
import 'package:provider/provider.dart';
import 'package:vishal_gold/constants/app_colors.dart';
import 'package:vishal_gold/models/admin.dart';
import 'package:vishal_gold/models/market_settings.dart';
import 'package:vishal_gold/providers/auth_provider.dart';
import 'package:vishal_gold/screens/admin/audit_logs_screen.dart';
import 'package:vishal_gold/screens/admin/category_management_screen.dart';
import 'package:vishal_gold/screens/admin/product_management_screen.dart';
import 'package:vishal_gold/screens/admin/sub_admin_management_screen.dart';
import 'package:vishal_gold/screens/admin/subcategory_management_screen.dart';
import 'package:vishal_gold/screens/admin/banner_management_screen.dart';
import 'package:vishal_gold/screens/admin/fcm_console_screen.dart';
import 'package:vishal_gold/providers/preview_provider.dart';
import 'package:vishal_gold/screens/home/home_screen.dart';
import 'package:vishal_gold/services/firebase_service.dart';

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
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F), // Deep black background
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMarketTicker(),
                  const SizedBox(height: 24),
                  _buildSectionHeader('Catalog Management'),
                  const SizedBox(height: 16),
                  _buildManagementGrid([
                    _MenuAction(
                      title: 'Products',
                      icon: Icons.inventory_2_outlined,
                      color: const Color(0xFFFFA726),
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
                      color: const Color(0xFFAB47BC),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const SubcategoryManagementScreen(category: null),
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 32),
                  _buildSectionHeader('Operations & Marketing'),
                  const SizedBox(height: 16),
                  _buildManagementGrid([
                    _MenuAction(
                      title: 'Market Rates',
                      icon: Icons.currency_rupee_rounded,
                      color: const Color(0xFFFFD700),
                      onTap: () => _openGoldRateController(context),
                    ),
                    _MenuAction(
                      title: 'Banners',
                      icon: Icons.photo_library_outlined,
                      color: const Color(0xFFEC407A),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const BannerManagementScreen(),
                        ),
                      ),
                    ),
                    _MenuAction(
                      title: 'Inventory',
                      icon: Icons.inventory_outlined,
                      color: const Color(0xFF26A69A),
                      onTap: () => _openWeightAnalytics(context),
                    ),
                    _MenuAction(
                      title: 'Analytics Hub',
                      icon: Icons.insights_rounded,
                      color: const Color(0xFF7E57C2),
                      onTap: () => _openAnalyticsHub(context),
                    ),
                    _MenuAction(
                      title: 'Send Alerts',
                      icon: Icons.campaign_rounded,
                      color: const Color(0xFFEF5350),
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
                  _buildSectionHeader('System Administration'),
                  const SizedBox(height: 16),
                  _buildManagementGrid([
                    _MenuAction(
                      title: 'Admins',
                      icon: Icons.admin_panel_settings_outlined,
                      color: const Color(0xFF66BB6A),
                      onTap: () {
                        if (_currentAdmin.role == 'super') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SubAdminManagementScreen(),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Super Admin access required'),
                            ),
                          );
                        }
                      },
                    ),
                    _MenuAction(
                      title: 'Audit Logs',
                      icon: Icons.history_rounded,
                      color: const Color(0xFFEF5350),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AuditLogsScreen(),
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 32),
                  _buildStatsSection(),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildPublishBar(),
    );
  }

  Widget _buildPublishBar() {
    return Consumer<PreviewProvider>(
      builder: (context, preview, _) {
        if (preview.pendingChangesCount == 0) return const SizedBox.shrink();
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1C),
            border: Border(
              top: BorderSide(color: AppColors.gold.withOpacity(0.4), width: 1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.gold.withOpacity(0.5)),
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
      },
    );
  }

  Future<void> _publishChanges(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1C),
        title: const Text(
          'Publish All Changes?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'This will apply all staged changes to live data immediately. This cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: Colors.black,
            ),
            child: const Text('Publish'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      final firebaseService = FirebaseService();
      await firebaseService.publishAllChanges(_currentAdmin.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ All changes published successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Failed to publish: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _discardChanges(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1C),
        title: const Text(
          'Discard All Changes?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'This will permanently delete all staged changes. This cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      final firebaseService = FirebaseService();
      await firebaseService.discardAllChanges(_currentAdmin.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🗑️ All staged changes discarded.'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Failed to discard: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: const Color(0xFF141414),
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.gold.withOpacity(0.15),
                const Color(0xFF141414),
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -30,
                top: -30,
                child: Icon(
                  Icons.admin_panel_settings,
                  size: 200,
                  color: AppColors.gold.withOpacity(0.03),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => _openEditProfile(context),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.gold, width: 2),
                        ),
                        child: CircleAvatar(
                          radius: 35,
                          backgroundColor: const Color(0xFF1E1E1E),
                          child: Text(
                            _currentAdmin.fullName.isNotEmpty
                                ? _currentAdmin.fullName[0].toUpperCase()
                                : 'A',
                            style: GoogleFonts.outfit(
                              fontSize: 28,
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
                            'Hello, ${_currentAdmin.fullName.split(' ')[0]}',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.white,
                            ),
                          ),
                          Text(
                            _currentAdmin.role.toUpperCase(),
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              color: AppColors.gold,
                              letterSpacing: 2,
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
      ),
      actions: [
        IconButton(
          icon: Consumer<PreviewProvider>(
            builder: (context, preview, _) => Icon(
              preview.isPreviewMode
                  ? Icons.visibility
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
                  content: Text('Preview Mode Active - Browsing as End User'),
                  backgroundColor: AppColors.gold,
                ),
              );
            }
          },
          tooltip: 'Preview Application',
        ),
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: AppColors.gold),
          onPressed: _refreshStats,
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
                title: const Text(
                  'Log Out',
                  style: TextStyle(color: AppColors.gold),
                ),
                content: const Text(
                  'Are you sure you want to exit?',
                  style: TextStyle(color: Colors.white70),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text(
                      'Logout',
                      style: TextStyle(color: Colors.red),
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
        ),
      ],
    );
  }

  Widget _buildMarketTicker() {
    return StreamBuilder<MarketSettings?>(
      stream: _firebaseService.getMarketSettings(),
      builder: (context, snapshot) {
        final settings = snapshot.data;
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.trending_up,
                        color: Colors.green,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Live Market Rates',
                        style: GoogleFonts.outfit(
                          color: AppColors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  if (settings != null)
                    Text(
                      'Updated: ${settings.updatedAt.toString().split(' ')[1].split('.')[0]}',
                      style: GoogleFonts.outfit(
                        color: Colors.white38,
                        fontSize: 10,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildTickerItem('24K', settings?.goldRate24K ?? 0),
                  _buildTickerDivider(),
                  _buildTickerItem('22K', settings?.goldRate22K ?? 0),
                  _buildTickerDivider(),
                  _buildTickerItem('18K', settings?.goldRate18K ?? 0),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTickerItem(String label, double rate) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            color: AppColors.gold,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '₹${rate.toStringAsFixed(0)}',
          style: GoogleFonts.outfit(
            color: AppColors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTickerDivider() {
    return Container(height: 30, width: 1, color: Colors.white10);
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.white.withOpacity(0.9),
      ),
    );
  }

  Widget _buildManagementGrid(List<_MenuAction> actions) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.6,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return InkWell(
          onTap: action.onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(action.icon, color: action.color, size: 28),
                const SizedBox(height: 10),
                Text(
                  action.title,
                  style: GoogleFonts.outfit(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('System Overview'),
        const SizedBox(height: 16),
        if (_loadingStats)
          const Center(child: CircularProgressIndicator(color: AppColors.gold))
        else
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.2,
            children: [
              _buildStatItem(
                'Products',
                '${_stats['products']}',
                Icons.inventory_2_outlined,
              ),
              _buildStatItem(
                'Total Admins',
                '${_stats['admins']}',
                Icons.people_outline,
              ),
              _buildStatItem(
                'Categories',
                '${_stats['categories']}',
                Icons.category_outlined,
              ),
              _buildStatItem(
                'Sub-Cats',
                '${_stats['subcategories']}',
                Icons.account_tree_outlined,
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gold.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.gold.withOpacity(0.5)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    color: AppColors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    color: Colors.white38,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openGoldRateController(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF141414),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _MarketRatesSheet(admin: _currentAdmin),
      ),
    );
  }

  void _openWeightAnalytics(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF141414),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _WeightAnalyticsSheet(),
    );
  }

  void _openAnalyticsHub(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF141414),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _AnalyticsHubSheet(),
    );
  }

  void _openEditProfile(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF141414),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
        fillColor: Colors.white.withOpacity(0.03),
      ),
      validator: (v) => v!.isEmpty ? 'Required' : null,
    );
  }
}

class _MarketRatesSheet extends StatefulWidget {
  final Admin admin;
  const _MarketRatesSheet({required this.admin});

  @override
  State<_MarketRatesSheet> createState() => _MarketRatesSheetState();
}

class _MarketRatesSheetState extends State<_MarketRatesSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _rate24KController;
  late TextEditingController _rate22KController;
  late TextEditingController _rate18KController;
  final FirebaseService _firebaseService = FirebaseService();
  bool _loading = false;
  MarketSettings? _currentSettings;

  @override
  void initState() {
    super.initState();
    _rate24KController = TextEditingController();
    _rate22KController = TextEditingController();
    _rate18KController = TextEditingController();
    _fetchCurrentRates();
  }

  Future<void> _fetchCurrentRates() async {
    _firebaseService.getMarketSettings().first.then((settings) {
      if (settings != null && mounted) {
        setState(() {
          _currentSettings = settings;
          _rate24KController.text = settings.goldRate24K.toString();
          _rate22KController.text = settings.goldRate22K.toString();
          _rate18KController.text = settings.goldRate18K.toString();
        });
      }
    });
  }

  @override
  void dispose() {
    _rate24KController.dispose();
    _rate22KController.dispose();
    _rate18KController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final newSettings = MarketSettings(
        goldRate24K: double.parse(_rate24KController.text),
        goldRate22K: double.parse(_rate22KController.text),
        goldRate18K: double.parse(_rate18KController.text),
        updatedAt: DateTime.now(),
      );

      await _firebaseService.updateMarketSettings(
        settings: newSettings,
        performedBy: widget.admin.id,
      );

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
              'Update Market Rates',
              style: GoogleFonts.playfairDisplay(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.gold,
              ),
            ),
            const SizedBox(height: 8),
            if (_currentSettings != null)
              Text(
                'Last updated: ${_currentSettings!.updatedAt.toString().split('.')[0]}',
                style: const TextStyle(color: Colors.white38, fontSize: 12),
              ),
            const SizedBox(height: 24),
            _buildRateInput(_rate24KController, '24K Gold Rate'),
            const SizedBox(height: 16),
            _buildRateInput(_rate22KController, '22K Gold Rate'),
            const SizedBox(height: 16),
            _buildRateInput(_rate18KController, '18K Gold Rate'),
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
                      'Broadcast New Rates',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildRateInput(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white38),
        prefixText: '₹ ',
        prefixStyle: const TextStyle(color: AppColors.gold),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white10),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.gold),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.03),
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
          FutureBuilder<Map<String, double>>(
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

              return Expanded(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.gold.withOpacity(0.2),
                            AppColors.gold.withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.gold.withOpacity(0.2),
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
                ),
              );
            },
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
              ? AppColors.gold.withOpacity(0.1)
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
    // Assuming months are already sorted by AnalyticsService or sorting them here
    // sortedKeys.sort((a, b) => ...); // Simplified sorted display

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
                color: AppColors.gold.withOpacity(0.1),
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
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
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
                  color: AppColors.gold.withOpacity(0.1),
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
