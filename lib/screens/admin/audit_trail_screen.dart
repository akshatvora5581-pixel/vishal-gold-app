import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:vishal_gold/constants/app_colors.dart';
import 'package:vishal_gold/services/audit_service.dart';

class AuditTrailScreen extends StatelessWidget {
  const AuditTrailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auditService = AuditService();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Security Audit Trail',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.gold,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: auditService.getAuditLogs(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.gold),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.security_rounded,
                    size: 64,
                    color: Colors.grey[800],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No security logs found',
                    style: GoogleFonts.outfit(
                      color: Colors.grey[600],
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            );
          }

          final logs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index].data() as Map<String, dynamic>;
              final timestamp = log['timestamp'] as Timestamp?;
              final dateStr = timestamp != null
                  ? DateFormat('dd MMM, hh:mm a').format(timestamp.toDate())
                  : 'Just now';

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _getActionColor(
                          log['action'],
                        ).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getActionIcon(log['action']),
                        color: _getActionColor(log['action']),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                log['action'] ?? 'Unknown Action',
                                style: GoogleFonts.outfit(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                dateStr,
                                style: GoogleFonts.outfit(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            log['details'] ?? '',
                            style: GoogleFonts.outfit(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'BY: ${log['adminEmail'] ?? 'Unknown'}',
                            style: GoogleFonts.outfit(
                              color: AppColors.gold.withValues(alpha: 0.7),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
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
        },
      ),
    );
  }

  Color _getActionColor(String? action) {
    if (action == null) return Colors.grey;
    final a = action.toLowerCase();
    if (a.contains('delete') || a.contains('remove')) return Colors.redAccent;
    if (a.contains('create') || a.contains('add')) return Colors.greenAccent;
    if (a.contains('update') || a.contains('change')) return Colors.blueAccent;
    if (a.contains('login')) return Colors.orangeAccent;
    return AppColors.gold;
  }

  IconData _getActionIcon(String? action) {
    if (action == null) return Icons.info_outline;
    final a = action.toLowerCase();
    if (a.contains('delete')) return Icons.delete_sweep_rounded;
    if (a.contains('create')) return Icons.add_circle_outline_rounded;
    if (a.contains('update')) return Icons.edit_note_rounded;
    if (a.contains('login')) return Icons.login_rounded;
    return Icons.security_rounded;
  }
}
