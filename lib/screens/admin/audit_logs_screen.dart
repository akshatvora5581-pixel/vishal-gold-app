import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:vishal_jewelers/constants/app_colors.dart';
import 'package:vishal_jewelers/services/firebase_service.dart';

class AuditLogsScreen extends StatefulWidget {
  const AuditLogsScreen({super.key});

  @override
  State<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends State<AuditLogsScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  String? _selectedAction;
  String? _selectedTargetType;

  final List<String> _actions = [
    'CREATE_PRODUCT',
    'UPDATE_PRODUCT',
    'DELETE_PRODUCT',
    'PUBLISH_PRODUCT',
    'CREATE_CATEGORY',
    'UPDATE_CATEGORY',
    'DELETE_CATEGORY',
    'CREATE_SUBCATEGORY',
    'UPDATE_SUBCATEGORY',
    'DELETE_SUBCATEGORY',
    'CREATE_ADMIN',
    'UPDATE_ADMIN',
    'DELETE_ADMIN',
    'ADMIN_LOGIN',
  ];

  final List<String> _targetTypes = [
    'product',
    'category',
    'subcategory',
    'admin',
    'auth',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          'Admin Audit Logs',
          style: GoogleFonts.outfit(
            color: AppColors.gold,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(child: _buildLogsList()),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.surface,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  value: _selectedAction,
                  hint: 'All Actions',
                  items: _actions,
                  onChanged: (v) => setState(() => _selectedAction = v),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDropdown(
                  value: _selectedTargetType,
                  hint: 'All Types',
                  items: _targetTypes,
                  onChanged: (v) => setState(() => _selectedTargetType = v),
                ),
              ),
            ],
          ),
          if (_selectedAction != null || _selectedTargetType != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TextButton(
                onPressed: () => setState(() {
                  _selectedAction = null;
                  _selectedTargetType = null;
                }),
                child: Text(
                  'Clear Filters',
                  style: TextStyle(color: AppColors.gold),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String hint,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(
            hint,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          items: items
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Text(e, style: TextStyle(fontSize: 12)),
                ),
              )
              .toList(),
          onChanged: onChanged,
          dropdownColor: AppColors.surface,
          icon: Icon(Icons.arrow_drop_down, color: AppColors.gold),
          style: TextStyle(color: AppColors.textPrimary),
          isExpanded: true,
        ),
      ),
    );
  }

  Widget _buildLogsList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _firebaseService.getAuditLogsStream(
        action: _selectedAction,
        targetType: _selectedTargetType,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: TextStyle(color: Colors.red),
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: AppColors.gold),
          );
        }

        final logs = snapshot.data ?? [];
        if (logs.isEmpty) {
          return Center(
            child: Text(
              'No audit logs found',
              style: GoogleFonts.outfit(color: AppColors.textSecondary),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: logs.length,
          itemBuilder: (context, index) {
            final log = logs[index];
            return _buildLogCard(log);
          },
        );
      },
    );
  }

  Widget _buildLogCard(Map<String, dynamic> log) {
    final dynamic timestampData = log['timestamp'];
    DateTime? dateTime;
    if (timestampData is Timestamp) {
      dateTime = timestampData.toDate();
    } else if (timestampData is String) {
      dateTime = DateTime.tryParse(timestampData);
    }
    dateTime ??= DateTime.now();

    final dateStr = DateFormat('MMM dd, yyyy HH:mm').format(dateTime);
    final action = log['action'] as String;
    final details = log['details'] as String? ?? '';
    final adminId = log['admin_id'] as String;

    Color actionColor;
    if (action.contains('CREATE')) {
      actionColor = Colors.green;
    } else if (action.contains('DELETE')) {
      actionColor = Colors.red;
    } else if (action.contains('UPDATE')) {
      actionColor = Colors.blue;
    } else {
      actionColor = AppColors.gold;
    }

    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: actionColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    action,
                    style: TextStyle(
                      color: actionColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  dateStr,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              details,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.person_outline,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  'Admin: $adminId',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            if (log['target_id'] != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Target: ${log['target_type']} (${log['target_id']})',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
