import 'package:flutter/foundation.dart';
import 'package:vishal_gold/models/notification.dart';
import 'package:vishal_gold/services/firebase_service.dart';
import 'dart:async';

class NotificationProvider with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();

  List<AppNotification> _notifications = [];
  bool _isLoading = false;
  String? _currentUserId;
  bool? _currentIsAdmin;
  StreamSubscription<List<AppNotification>>? _subscription;

  List<AppNotification> get notifications => _notifications;
  bool get isLoading => _isLoading;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  void updateUser(String? userId, {bool isAdmin = false}) {
    init(userId, isAdmin: isAdmin);
  }

  /// Initializes listening to the user's notifications. Pass null for admin.
  void init(String? userId, {bool isAdmin = false}) {
    if (_currentUserId == userId && _currentIsAdmin == isAdmin) return;

    _currentUserId = userId;
    _currentIsAdmin = isAdmin;
    _isLoading = true;
    notifyListeners();

    _subscription?.cancel();

    Stream<List<AppNotification>> stream;
    if (isAdmin) {
      stream = _firebaseService.getAdminNotifications();
    } else if (userId != null) {
      stream = _firebaseService.getUserNotifications(userId);
    } else {
      _isLoading = false;
      notifyListeners();
      return;
    }

    _subscription = stream.listen(
      (notifs) {
        _notifications = notifs;
        _isLoading = false;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Error listening to notifications: $error');
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _firebaseService.markNotificationRead(notificationId);
      // Local state will update via stream
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  Future<void> markAllAsRead(String? userId, {bool isAdmin = false}) async {
    try {
      final unreadIds = _notifications
          .where((n) => !n.isRead)
          .map((n) => n.id)
          .toList();
      if (unreadIds.isEmpty) return;

      await _firebaseService.markNotificationsRead(unreadIds);
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
