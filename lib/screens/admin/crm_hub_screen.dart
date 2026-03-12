import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:vishal_gold/services/analytics_service.dart';
import 'package:vishal_gold/services/firebase_service.dart';
import 'package:vishal_gold/constants/app_colors.dart';
import 'package:vishal_gold/providers/auth_provider.dart';

class CRMHubScreen extends StatefulWidget {
  const CRMHubScreen({super.key});

  @override
  State<CRMHubScreen> createState() => _CRMHubScreenState();
}

class _CRMHubScreenState extends State<CRMHubScreen> {
  final AnalyticsService _analyticsService = AnalyticsService();
  final FirebaseService _firebaseService = FirebaseService();
  bool _isLoading = false;
  List<Map<String, dynamic>> _segmentedUsers = [];
  String _selectedSegment = 'All';

  static const _kSegments = ['All', 'Inactive (30+ days)', 'Top 1% Customers'];

  @override
  void initState() {
    super.initState();
    _loadSegment('All');
  }

  Future<void> _loadSegment(String segment) async {
    setState(() => _isLoading = true);
    try {
      if (segment == 'Inactive (30+ days)') {
        _segmentedUsers = await _analyticsService.getInactiveUsers(30);
      } else if (segment == 'Top 1% Customers') {
        _segmentedUsers = await _analyticsService.getTopCustomers();
      } else {
        final snapshot = await _analyticsService.firestore
            .collection('users')
            .limit(20)
            .get();
        _segmentedUsers = snapshot.docs.map((doc) {
          final data = doc.data();
          data['uid'] = doc.id;
          return data;
        }).toList();
      }
      _selectedSegment = segment;
    } catch (e) {
      debugPrint('Error loading segment: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _sendWhatsApp(String phone, String name) async {
    final message =
        'Hello $name, we missed you at Vishal Gold! Check out our latest designs.';
    final url = 'https://wa.me/$phone?text=${Uri.encodeComponent(message)}';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  void _openBroadcastModal({Map<String, dynamic>? singleUser}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PushNotificationSheet(
        users: singleUser != null ? [singleUser] : _segmentedUsers,
        segment: singleUser != null ? 'direct' : _selectedSegment,
        firebaseService: _firebaseService,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: Text(
          'Smart CRM Hub',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        actions: [
          if (_segmentedUsers.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: () => _openBroadcastModal(),
                icon: const Icon(
                  Icons.campaign_rounded,
                  color: AppColors.gold,
                  size: 18,
                ),
                label: Text(
                  'Broadcast (${_segmentedUsers.length})',
                  style: GoogleFonts.outfit(
                    color: AppColors.gold,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          _buildSegmentSelector(),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.gold),
                  )
                : _buildUserList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentSelector() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _kSegments.length,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          final s = _kSegments[index];
          final isSelected = _selectedSegment == s;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ChoiceChip(
              label: Text(s),
              selected: isSelected,
              onSelected: (_) => _loadSegment(s),
              selectedColor: AppColors.gold,
              backgroundColor: Colors.white10,
              labelStyle: TextStyle(
                color: isSelected ? Colors.black : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildUserList() {
    if (_segmentedUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.white12),
            const SizedBox(height: 16),
            Text(
              'No users in this segment',
              style: GoogleFonts.outfit(color: Colors.white38, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: _segmentedUsers.length,
      itemBuilder: (context, index) {
        final user = _segmentedUsers[index];
        final name = user['name'] ?? 'Unknown User';
        final phone = user['phoneNumber'] ?? '';
        final lastLogin = user['lastLogin'] != null
            ? (user['lastLogin'] as dynamic).toDate().toString().split(' ')[0]
            : 'Never';

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.gold.withValues(alpha: 0.1),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Last seen: $lastLogin',
                      style: GoogleFonts.outfit(
                        color: Colors.white38,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (phone.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.message_rounded, color: Colors.green),
                  onPressed: () => _sendWhatsApp(phone, name),
                  tooltip: 'WhatsApp',
                  iconSize: 22,
                ),
              IconButton(
                icon: const Icon(
                  Icons.notifications_active_rounded,
                  color: AppColors.gold,
                ),
                onPressed: () => _openBroadcastModal(singleUser: user),
                tooltip: 'Send Push Notification',
                iconSize: 22,
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Push Notification Bottom Sheet ───────────────────────────────────────────
class _PushNotificationSheet extends StatefulWidget {
  final List<Map<String, dynamic>> users;
  final String segment;
  final FirebaseService firebaseService;

  const _PushNotificationSheet({
    required this.users,
    required this.segment,
    required this.firebaseService,
  });

  @override
  State<_PushNotificationSheet> createState() => _PushNotificationSheetState();
}

class _PushNotificationSheetState extends State<_PushNotificationSheet> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_titleCtrl.text.trim().isEmpty || _bodyCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title and message are required')),
      );
      return;
    }

    setState(() => _sending = true);
    try {
      final adminId =
          context.read<AuthProvider>().currentUser?.uid ?? 'unknown';
      final userIds = widget.users
          .map((u) => (u['uid'] ?? u['id'] ?? '') as String)
          .where((id) => id.isNotEmpty)
          .toList();

      final sent = await widget.firebaseService.sendCrmPushToUsers(
        userIds: userIds,
        title: _titleCtrl.text.trim(),
        body: _bodyCtrl.text.trim(),
        performedBy: adminId,
        segment: widget.segment,
      );

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✅ Notification queued for $sent user${sent == 1 ? '' : 's'}',
          ),
          backgroundColor: Colors.green[700],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSingle = widget.users.length == 1;
    final targetName = isSingle
        ? (widget.users.first['name'] ?? 'this user')
        : '${widget.users.length} users';

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.notifications_active_rounded,
                  color: AppColors.gold,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isSingle ? 'Direct Push' : 'Broadcast Push',
                      style: GoogleFonts.playfairDisplay(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Sending to $targetName',
                      style: GoogleFonts.outfit(
                        color: AppColors.gold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Title field
          _buildField(
            _titleCtrl,
            'Notification Title',
            'e.g. New Collection Alert!',
          ),
          const SizedBox(height: 16),
          _buildField(
            _bodyCtrl,
            'Message',
            'e.g. Check out our latest Diwali designs...',
            maxLines: 3,
          ),
          const SizedBox(height: 24),

          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _sending ? null : _send,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: _sending
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.black,
                      ),
                    )
                  : Text(
                      isSingle
                          ? 'Send Notification'
                          : 'Broadcast to $targetName',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(
    TextEditingController ctrl,
    String label,
    String hint, {
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            color: Colors.white60,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: ctrl,
          maxLines: maxLines,
          style: GoogleFonts.outfit(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.outfit(color: Colors.white24),
            filled: true,
            fillColor: const Color(0xFF252525),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }
}
