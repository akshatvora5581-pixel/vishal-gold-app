import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:vishal_gold/services/firebase_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `Firebase.initializeApp()` here as well.
  debugPrint('Handling a background message: ${message.messageId}');
}

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseService _firebaseService = FirebaseService();

  Future<void> initialize() async {
    // Request permissions for iOS and higher Android levels
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted notification permission');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      debugPrint('User granted provisional notification permission');
    } else {
      debugPrint('User declined or has not accepted notification permission');
    }

    // Set background messaging handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Listen to foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint(
          'Message also contained a notification: ${message.notification!.title}',
        );
      }
    });

    // Handle initial message if app was opened from a notification
    RemoteMessage? initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageTap(initialMessage);
    }

    // Handle messages when app is in background but not terminated
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);

    // Listen for token refresh
    _fcm.onTokenRefresh.listen((newToken) {
      debugPrint('FCM Token Refreshed: $newToken');
      // We'll need a way to know the current UID to update it in Firestore
      // For now, it will be handled when the app restarts or user logs in.
    });
  }

  void _handleMessageTap(RemoteMessage message) {
    debugPrint('App opened from notification: ${message.messageId}');
    // Logic for navigation based on message data can be added here
  }

  Future<String?> getToken() async {
    try {
      String? token = await _fcm.getToken();
      debugPrint('FCM Token: $token');
      return token;
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
      return null;
    }
  }

  Future<void> subscribeToTopic(String topic) async {
    await _fcm.subscribeToTopic(topic);
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _fcm.unsubscribeFromTopic(topic);
  }

  Future<void> updateUserToken(String uid, {bool isAdmin = false}) async {
    String? token = await getToken();
    if (token != null) {
      await _firebaseService.updateFcmToken(uid, token, isAdmin: isAdmin);
    }
  }
}
