import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:vishal_gold/models/product.dart';
import 'package:vishal_gold/screens/product/product_detail_screen.dart';
import 'package:vishal_gold/services/firebase_service.dart';

// ── Background handler — must be top-level ───────────────────────────────────
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM Background] MessageId: ${message.messageId}');
}

// ── FCMService ───────────────────────────────────────────────────────────────
class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseService _firebaseService = FirebaseService();
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Set this from main.dart so deep-link navigation works from any state.
  GlobalKey<NavigatorState>? navigatorKey;

  // ── Android notification channel ────────────────────────────────────────────
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'new_stock_channel',
    'New Stock Alerts',
    description: 'Alerts when new jewelry stock is added',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  // ── initialize ──────────────────────────────────────────────────────────────
  Future<void> initialize() async {
    // 1. Request permissions
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('[FCM] Auth status: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.denied) return;

    // 2. Local notifications (for foreground display on Android)
    await _setupLocalNotifications();

    // 3. Register global background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 4. Hard Reset: Unsubscribe from sensitive topics for User App safety
    await _fcm.unsubscribeFromTopic('admins');
    await _fcm.unsubscribeFromTopic('admin_orders');
    await _fcm.unsubscribeFromTopic('all');
    debugPrint(
      '[FCM] Hard Reset: Unsubscribed from admins, admin_orders and all topics.',
    );

    // 5. Foreground messages → show local notification banner
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 6. Tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);

    // 7. Tap when app was fully terminated (Cold Start)
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('[FCM] Cold start detected with initial message.');
      // Delay slightly longer to ensure splash/main setup completes
      await Future.delayed(const Duration(milliseconds: 1500));
      _handleMessageTap(initialMessage);
    }

    // 8. Token refresh → update Firestore
    _fcm.onTokenRefresh.listen((newToken) {
      debugPrint('[FCM] Token refreshed — will be updated on next login.');
    });

    debugPrint('[FCM] Initialised.');
  }

  // ── Local notifications setup (Android channel + iOS init) ──────────────────
  Future<void> _setupLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _localNotifications.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: (response) {
        final productId = response.payload;
        if (productId != null && productId.isNotEmpty) {
          _navigateToProduct(productId);
        }
      },
    );

    // Create the Android channel
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_channel);
  }

  // ── Foreground message → local notification ──────────────────────────────────
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('[FCM Foreground] ${message.notification?.title}');
    final notification = message.notification;
    if (notification == null) return;

    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      // Pass product_id as payload so tap also deep-links
      payload: message.data['product_id'] ?? message.data['productId'],
    );
  }

  // ── Notification tap handler ──────────────────────────────────────────────
  void _handleMessageTap(RemoteMessage message) {
    debugPrint('[FCM Tap] data: ${message.data}');
    // Support both snake_case and camelCase for better flexibility
    final productId = message.data['product_id'] ?? message.data['productId'];
    if (productId != null && productId.toString().isNotEmpty) {
      _navigateToProduct(productId.toString());
    }
  }

  // ── Deep-link navigation to ProductDetailScreen ───────────────────────────
  Future<void> _navigateToProduct(String productId) async {
    if (navigatorKey?.currentContext == null) {
      debugPrint('[FCM] Navigator not ready for deep link to $productId');
      return;
    }
    try {
      final Product? product = await _firebaseService.getProductById(productId);
      if (product == null) {
        debugPrint('[FCM] Product $productId not found.');
        return;
      }
      navigatorKey!.currentState?.push(
        MaterialPageRoute(
          builder: (_) => ProductDetailScreen(product: product),
        ),
      );
      debugPrint('[FCM] Deep-linked to ProductDetailScreen for $productId');
    } catch (e) {
      debugPrint('[FCM] Deep-link error: $e');
    }
  }

  // ── Token helpers ─────────────────────────────────────────────────────────
  Future<String?> getToken() async {
    try {
      return await _fcm.getToken();
    } catch (e) {
      debugPrint('[FCM] Error getting token: $e');
      return null;
    }
  }

  Future<void> subscribeToTopic(String topic) => _fcm.subscribeToTopic(topic);

  Future<void> unsubscribeFromTopic(String topic) =>
      _fcm.unsubscribeFromTopic(topic);

  /// Saves token to Firestore and ensures topic subscription is active.
  /// Called from AuthProvider after each login.
  Future<void> updateUserToken(String uid, {bool isAdmin = false}) async {
    final token = await getToken();
    if (token != null) {
      await _firebaseService.updateFcmToken(uid, token, isAdmin: isAdmin);
    }
    if (isAdmin) {
      // Admin topic subscription is now handled strictly in the Login function
      debugPrint('[FCM] Admin token updated. Subscription handled at login.');
    } else {
      await _fcm.subscribeToTopic('all_users');
    }
  }
}
