import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vishal_jewelers/providers/auth_provider.dart';
import 'package:vishal_jewelers/services/analytics_service.dart';

class PresenceWrapper extends StatefulWidget {
  final Widget child;
  const PresenceWrapper({super.key, required this.child});

  @override
  State<PresenceWrapper> createState() => _PresenceWrapperState();
}

class _PresenceWrapperState extends State<PresenceWrapper> {
  @override
  void initState() {
    super.initState();
    _setupPresence();
  }

  void _setupPresence() {
    // Listen to auth changes and update presence
    final authProvider = context.read<AuthProvider>();
    final analyticsService = AnalyticsService();
    authProvider.addListener(() {
      final user = authProvider.currentUser;
      if (user != null) {
        analyticsService.updatePresence(
          user.uid,
          authProvider.userRole ?? 'retailer',
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
