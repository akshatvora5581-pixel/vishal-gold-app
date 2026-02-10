import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:vishal_gold/constants/app_colors.dart';
import 'package:vishal_gold/providers/order_provider.dart';
import 'package:vishal_gold/models/order.dart' as app_order;

class OrderDetailScreen extends StatelessWidget {
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'ORDER DETAILS',
          style: GoogleFonts.outfit(
            color: AppColors.gold,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: FutureBuilder<app_order.Order?>(
        future: Provider.of<OrderProvider>(
          context,
          listen: false,
        ).getOrderById(orderId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.gold),
            );
          }

          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return Center(
              child: Text(
                'Order not found',
                style: GoogleFonts.outfit(color: AppColors.white),
              ),
            );
          }

          final order = snapshot.data!;
          final dateStr = DateFormat(
            'MMM dd, yyyy HH:mm',
          ).format(order.createdAt);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.black.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Order Status',
                                style: GoogleFonts.outfit(
                                  color: AppColors.grey,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                order.statusDisplay,
                                style: GoogleFonts.outfit(
                                  color: order.status == 'cancelled'
                                      ? Colors.red
                                      : order.status == 'delivered'
                                      ? Colors.green
                                      : AppColors.gold,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          _StatusIcon(status: order.status),
                        ],
                      ),
                      const Divider(color: Colors.white24, height: 32),
                      _DetailRow(
                        label: 'Order ID',
                        value: '#${order.id.toUpperCase()}',
                      ),
                      const SizedBox(height: 12),
                      _DetailRow(label: 'Date', value: dateStr),
                      const SizedBox(height: 12),
                      _DetailRow(
                        label: 'Total Items',
                        value: '${order.totalItems}',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Weights Summary
                Text(
                  'WEIGHT SUMMARY',
                  style: GoogleFonts.outfit(
                    color: AppColors.gold,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.oliveGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.oliveGreen.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _WeightItem(
                          label: 'Total Gross Weight',
                          value:
                              '${order.totalGrossWeight.toStringAsFixed(3)}g',
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: AppColors.oliveGreen.withValues(alpha: 0.3),
                      ),
                      Expanded(
                        child: _WeightItem(
                          label: 'Total Net Weight',
                          value: '${order.totalNetWeight.toStringAsFixed(3)}g',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Order Items
                Text(
                  'ORDER ITEMS',
                  style: GoogleFonts.outfit(
                    color: AppColors.gold,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: order.items?.length ?? 0,
                  itemBuilder: (context, index) {
                    final item = order.items![index];
                    return _OrderItemCard(item: item);
                  },
                ),

                if (order.adminNotes != null) ...[
                  const SizedBox(height: 24),
                  Text(
                    'ADMIN NOTES',
                    style: GoogleFonts.outfit(
                      color: AppColors.gold,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Text(
                      order.adminNotes!,
                      style: GoogleFonts.outfit(color: AppColors.grey),
                    ),
                  ),
                ],
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatusIcon extends StatelessWidget {
  final String status;
  const _StatusIcon({required this.status});

  @override
  Widget build(BuildContext context) {
    IconData iconData;
    Color color;
    switch (status.toLowerCase()) {
      case 'pending':
        iconData = Icons.timer_outlined;
        color = Colors.orange;
        break;
      case 'processing':
        iconData = Icons.settings_outlined;
        color = Colors.blue;
        break;
      case 'shipped':
        iconData = Icons.local_shipping_outlined;
        color = Colors.purple;
        break;
      case 'delivered':
        iconData = Icons.check_circle_outline;
        color = Colors.green;
        break;
      case 'cancelled':
        iconData = Icons.cancel_outlined;
        color = Colors.red;
        break;
      default:
        iconData = Icons.receipt_long;
        color = AppColors.gold;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(iconData, color: color, size: 32),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(color: AppColors.grey, fontSize: 14),
        ),
        Text(
          value,
          style: GoogleFonts.outfit(
            color: AppColors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _WeightItem extends StatelessWidget {
  final String label;
  final String value;
  const _WeightItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(color: AppColors.grey, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.outfit(
            color: AppColors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _OrderItemCard extends StatelessWidget {
  final app_order.OrderItem item;
  const _OrderItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          // Item Image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: item.imageUrls.isNotEmpty
                ? (item.imageUrls.first.startsWith('assets/')
                      ? Image.asset(
                          item.imageUrls.first,
                          width: 70,
                          height: 70,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                width: 70,
                                height: 70,
                                color: Colors.white10,
                                child: const Icon(
                                  Icons.diamond,
                                  color: AppColors.gold,
                                ),
                              ),
                        )
                      : CachedNetworkImage(
                          imageUrl: item.imageUrls.first,
                          width: 70,
                          height: 70,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            width: 70,
                            height: 70,
                            color: Colors.white10,
                            child: const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.gold,
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            width: 70,
                            height: 70,
                            color: Colors.white10,
                            child: const Icon(
                              Icons.diamond,
                              color: AppColors.gold,
                            ),
                          ),
                        ))
                : Container(
                    width: 70,
                    height: 70,
                    color: Colors.white10,
                    child: const Icon(Icons.diamond, color: AppColors.gold),
                  ),
          ),
          const SizedBox(width: 16),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.tagNumber,
                  style: GoogleFonts.outfit(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.category.replaceAll('_', ' ').toUpperCase(),
                  style: GoogleFonts.outfit(
                    color: AppColors.grey,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _Badge(text: 'GW: ${item.grossWeight}g'),
                    const SizedBox(width: 8),
                    _Badge(text: 'NW: ${item.netWeight}g'),
                  ],
                ),
              ],
            ),
          ),
          // Quantity
          Column(
            children: [
              Text(
                'Qty',
                style: GoogleFonts.outfit(color: AppColors.grey, fontSize: 12),
              ),
              Text(
                'x${item.quantity}',
                style: GoogleFonts.outfit(
                  color: AppColors.gold,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  const _Badge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: GoogleFonts.outfit(
          color: AppColors.gold,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
