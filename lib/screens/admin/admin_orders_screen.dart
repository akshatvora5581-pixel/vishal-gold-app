import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vishal_gold/constants/app_colors.dart';
import 'package:vishal_gold/models/notification.dart';
import 'package:vishal_gold/services/firebase_service.dart';
import 'package:vishal_gold/models/order.dart' as app_order;

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  String _filterStatus = 'all';

  // Pagination state
  final List<app_order.Order> _orders = [];
  DocumentSnapshot? _lastDocument;
  bool _isLoading = false;
  bool _hasMore = true;
  final int _pageSize = 15;

  final ScrollController _scrollController = ScrollController();
  final FirebaseService _firebaseService = FirebaseService();

  static const List<String> _statuses = [
    'all',
    'pending',
    'processing',
    'shipped',
    'delivered',
    'cancelled',
  ];

  Color _statusColor(String status) {
    switch (status) {
      case 'delivered':
        return AppColors.successGreen;
      case 'cancelled':
        return AppColors.errorRed;
      case 'shipped':
        return const Color(0xFF42A5F5);
      case 'processing':
        return const Color(0xFFFFB300);
      default:
        return AppColors.gold;
    }
  }

  Future<void> _updateStatus(
    BuildContext context,
    String orderId,
    String currentStatus,
    String? userId,
  ) async {
    final statuses = [
      'pending',
      'processing',
      'shipped',
      'delivered',
      'cancelled',
    ];

    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.grey.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Update Order Status',
                style: GoogleFonts.playfairDisplay(
                  color: AppColors.gold,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 16),
              ...statuses.map((s) {
                final isSelected = s == currentStatus;
                final color = _statusColor(s);
                return ListTile(
                  leading: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: isSelected ? color : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(color: color, width: 2),
                    ),
                  ),
                  title: Text(
                    s.toUpperCase(),
                    style: GoogleFonts.outfit(
                      color: isSelected ? color : AppColors.white,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(ctx);
                    try {
                      await FirebaseFirestore.instance
                          .collection('orders')
                          .doc(orderId)
                          .update({
                            'status': s,
                            'updatedAt': FieldValue.serverTimestamp(),
                          });
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Status updated to ${s.toUpperCase()}',
                            ),
                            backgroundColor: color,
                          ),
                        );
                      }

                      // Create notification for customer
                      if (userId != null && userId != 'admin') {
                        try {
                          final firebaseService = FirebaseService();
                          await firebaseService.createDbNotification(
                            AppNotification(
                              id: '',
                              userId: userId,
                              title: 'Order Updated! 📦',
                              message:
                                  'Your order #${orderId.substring(0, 8).toUpperCase()} is now ${s.toUpperCase()}',
                              type: 'order_status',
                              relatedId: orderId,
                              createdAt: DateTime.now(),
                            ),
                          );
                        } catch (e) {
                          debugPrint(
                            'Failed to send customer notification: $e',
                          );
                        }
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to update: $e'),
                            backgroundColor: AppColors.errorRed,
                          ),
                        );
                      }
                    }
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deleteOrder(BuildContext context, String orderId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Delete Order',
          style: GoogleFonts.playfairDisplay(
            color: AppColors.gold,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this order? This action cannot be undone.',
          style: GoogleFonts.outfit(color: AppColors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'CANCEL',
              style: GoogleFonts.outfit(color: AppColors.grey),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'DELETE',
              style: GoogleFonts.outfit(
                color: AppColors.errorRed,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection('orders')
            .doc(orderId)
            .delete();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Order deleted successfully'),
              backgroundColor: AppColors.errorRed,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete order: $e'),
              backgroundColor: AppColors.errorRed,
            ),
          );
        }
      }
    }
  }

  Future<void> _launchWhatsApp(String phone) async {
    if (phone.isEmpty) return;
    final clean = phone.replaceAll(RegExp(r'\D'), '');
    final url = Uri.parse('https://wa.me/$clean');
    if (await canLaunchUrl(url)) await launchUrl(url);
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _fetchOrders();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        _hasMore) {
      _fetchOrders();
    }
  }

  Future<void> _fetchOrders() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final result = await _firebaseService.getOrdersPaginated(
        status: _filterStatus,
        limit: _pageSize,
        startAfter: _lastDocument,
      );

      final List<app_order.Order> newOrders = result['orders']
          .cast<app_order.Order>();
      _lastDocument = result['lastDocument'];

      setState(() {
        _orders.addAll(newOrders);
        _hasMore = newOrders.length == _pageSize;
      });
    } catch (e) {
      debugPrint('Error fetching orders: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onFilterChanged(String newStatus) {
    if (_filterStatus == newStatus) return;
    setState(() {
      _filterStatus = newStatus;
      _orders.clear();
      _lastDocument = null;
      _hasMore = true;
    });
    _fetchOrders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Orders Dashboard',
          style: GoogleFonts.playfairDisplay(
            color: AppColors.gold,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.surface,
        iconTheme: const IconThemeData(color: AppColors.white),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _statuses.length,
              separatorBuilder: (_, index) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final s = _statuses[i];
                final selected = _filterStatus == s;
                return GestureDetector(
                  onTap: () => _onFilterChanged(s),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.gold.withValues(alpha: 0.2)
                          : AppColors.background,
                      border: Border.all(
                        color: selected
                            ? AppColors.gold
                            : AppColors.grey.withValues(alpha: 0.3),
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      s.toUpperCase(),
                      style: GoogleFonts.outfit(
                        color: selected ? AppColors.gold : AppColors.grey,
                        fontSize: 11,
                        fontWeight: selected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _orders.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.gold),
      );
    }

    if (_orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, color: AppColors.grey, size: 64),
            const SizedBox(height: 16),
            Text(
              _filterStatus == 'all'
                  ? 'No orders yet'
                  : 'No $_filterStatus orders',
              style: GoogleFonts.outfit(
                color: AppColors.textSecondary,
                fontSize: 18,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        _onFilterChanged(_filterStatus);
      },
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _orders.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _orders.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(color: AppColors.gold),
              ),
            );
          }
          final order = _orders[index];
          // Convert Order model back to Map for compatibility with existing _buildOrderCard
          // Internal fields like id need to be passed separately or mapped
          final data = order.toJson();
          return _buildOrderCard(context, order.id, data);
        },
      ),
    );
  }

  Widget _buildOrderCard(
    BuildContext context,
    String orderId,
    Map<String, dynamic> data,
  ) {
    final status = data['status'] as String? ?? 'pending';
    final totalItems = data['totalItems'] ?? 0;

    // Legacy support: if subTotalAmount is missing, totalAmount was used for totalNetWeight
    final subTotalAmount = data['subTotalAmount'] as num?;
    final totalNetWeight =
        data['totalNetWeight'] ??
        (subTotalAmount == null ? data['totalAmount'] : 0.0) ??
        0.0;
    final totalGrossWeight = data['totalGrossWeight'] ?? 0.0;
    final itemsList = data['items'] as List<dynamic>? ?? [];

    // Customer info
    final customerName = data['customerName'] as String? ?? 'Unknown Customer';
    final customerPhone = data['customerPhone'] as String? ?? '';
    final customerWhatsApp =
        data['customerWhatsApp'] as String? ?? customerPhone;
    final customerEmail = data['customerEmail'] as String? ?? '';
    final customerAddress = data['customerAddress'] as String? ?? '';
    final customerCity = data['customerCity'] as String? ?? '';
    final customerCompany = data['customerCompany'] as String? ?? '';

    // Date
    dynamic rawDate = data['createdAt'];
    String date = 'Unknown Date';
    if (rawDate is Timestamp) {
      date = DateFormat('MMM dd, yyyy - hh:mm a').format(rawDate.toDate());
    } else if (rawDate is String) {
      try {
        date = DateFormat(
          'MMM dd, yyyy - hh:mm a',
        ).format(DateTime.parse(rawDate));
      } catch (_) {}
    }

    final statusColor = _statusColor(status);

    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
        title: Row(
          children: [
            Expanded(
              child: Text(
                'Order #${orderId.substring(0, 8).toUpperCase()}',
                style: GoogleFonts.playfairDisplay(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => _updateStatus(
                context,
                orderId,
                status,
                data['userId'] as String?,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      status.toUpperCase(),
                      style: GoogleFonts.outfit(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.edit, size: 10, color: statusColor),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => _deleteOrder(context, orderId),
              icon: const Icon(
                Icons.delete_outline,
                color: AppColors.errorRed,
                size: 22,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              tooltip: 'Delete Order',
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.person_outline,
                    size: 14,
                    color: AppColors.gold,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    customerName,
                    style: GoogleFonts.outfit(
                      color: AppColors.gold,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                '$date  •  $totalItems Items',
                style: GoogleFonts.outfit(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.background.withValues(alpha: 0.6),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Customer Info Section ──
                _sectionHeader('👤 Customer Information'),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Column(
                    children: [
                      if (customerPhone.isNotEmpty)
                        _infoRow(
                          icon: Icons.phone_outlined,
                          label: 'Phone',
                          value: customerPhone,
                          trailing: customerWhatsApp.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.chat,
                                    color: Color(0xFF25D366),
                                    size: 20,
                                  ),
                                  onPressed: () =>
                                      _launchWhatsApp(customerWhatsApp),
                                  tooltip: 'WhatsApp',
                                )
                              : null,
                        ),
                      if (customerEmail.isNotEmpty)
                        _infoRow(
                          icon: Icons.email_outlined,
                          label: 'Email',
                          value: customerEmail,
                        ),
                      if (customerAddress.isNotEmpty || customerCity.isNotEmpty)
                        _infoRow(
                          icon: Icons.location_on_outlined,
                          label: 'Address',
                          value: [
                            customerAddress,
                            customerCity,
                          ].where((s) => s.isNotEmpty).join(', '),
                        ),
                      if (customerCompany.isNotEmpty)
                        _infoRow(
                          icon: Icons.business_outlined,
                          label: 'Company',
                          value: customerCompany,
                        ),
                    ],
                  ),
                ),

                // ── Order Items Section ──
                _sectionHeader('📦 Order Items'),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Column(
                    children: [
                      ...itemsList.map((item) {
                        final m = item as Map<String, dynamic>;
                        final qty = m['quantity'] ?? 1;
                        final tag = m['tagNumber'] ?? '-';
                        final name = m['name'] ?? m['categoryDisplay'] ?? '';
                        final gw =
                            (m['grossWeight'] as num?)?.toStringAsFixed(3) ??
                            '-';
                        final nw =
                            (m['netWeight'] as num?)?.toStringAsFixed(3) ?? '-';
                        final unitPrice = m['unitPrice'] as num?;
                        final priceAtOrder = m['priceAtOrder'] as num?;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: AppColors.gold.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.diamond_outlined,
                                    color: AppColors.gold,
                                    size: 16,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${qty}x  $tag',
                                      style: GoogleFonts.outfit(
                                        color: AppColors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (name.isNotEmpty)
                                      Text(
                                        name,
                                        style: GoogleFonts.outfit(
                                          color: AppColors.textSecondary,
                                          fontSize: 11,
                                        ),
                                      ),
                                    Text(
                                      'GW: ${gw}g  •  NW: ${nw}g',
                                      style: GoogleFonts.outfit(
                                        color: AppColors.gold,
                                        fontSize: 11,
                                      ),
                                    ),
                                    if (priceAtOrder != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        '₹${priceAtOrder.toStringAsFixed(0)} (₹${(unitPrice ?? priceAtOrder / qty).toStringAsFixed(0)}/item)',
                                        style: GoogleFonts.outfit(
                                          color: AppColors.successGreen,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const Divider(color: Color(0xFF2E2E2E)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Gross Wt.',
                            style: GoogleFonts.outfit(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            '${(totalGrossWeight as num).toStringAsFixed(3)} g',
                            style: GoogleFonts.outfit(
                              color: AppColors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Net Wt.',
                            style: GoogleFonts.outfit(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            '${(totalNetWeight as num).toStringAsFixed(3)} g',
                            style: GoogleFonts.outfit(
                              color: AppColors.gold,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── Update Status Button ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _updateStatus(
                        context,
                        orderId,
                        status,
                        data['userId'] as String?,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold.withValues(alpha: 0.15),
                        foregroundColor: AppColors.gold,
                        side: BorderSide(
                          color: AppColors.gold.withValues(alpha: 0.4),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        minimumSize: const Size(0, 42),
                      ),
                      icon: const Icon(Icons.update, size: 16),
                      label: Text(
                        'UPDATE STATUS',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          color: AppColors.white,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.gold),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    color: AppColors.grey,
                    fontSize: 11,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    color: AppColors.white,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
