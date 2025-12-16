import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/utils/logger.dart';
import 'notification_service.dart';

/// Background message handler (must be a top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // NOTE: In a real app you might re-initialize services here if needed.
  // For now we just log that a message was received in the background.
  debugPrint('🔔 [BG] FCM message: ${message.messageId}');
}

class PushNotificationService {
  static final PushNotificationService _instance =
      PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final _logger = AppLogger();
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Call once after Firebase.initializeApp()
  Future<void> init() async {
    _logger.info('Initializing PushNotificationService');

    // Request permissions (mainly needed on iOS / Android 13+)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    _logger.info('FCM permission status: ${settings.authorizationStatus}');

    // Register background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Get the FCM token for this device
    final token = await _messaging.getToken();
    _logger.info('FCM token: $token');

    // Send token to Supabase so backend can target this device
    await _saveTokenToSupabase(token);

    // Listen for token refresh
    _messaging.onTokenRefresh.listen((newToken) async {
      _logger.info('FCM token refreshed: $newToken');
      // update token in Supabase
      await _saveTokenToSupabase(newToken);
    });

    // Foreground messages: show local notifications using existing service
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _logger.debug('FCM foreground message: ${message.messageId}');

      final notification = message.notification;
      if (notification != null) {
        NotificationService().showGeneralNotification(
          title: notification.title ?? 'Notification',
          body: notification.body ?? '',
          type: message.data['type'] as String? ?? 'general',
        );
      }
    });

    // When user taps a notification and opens the app
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _logger.debug('FCM message opened app: ${message.messageId}');
      // You can inspect message.data here to navigate if needed.
    });
  }

  Future<void> _saveTokenToSupabase(String? token) async {
    if (token == null) return;
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) {
        _logger.warning('Cannot save FCM token: no authenticated user');
        return;
      }

      await client.from('device_tokens').upsert({
        'user_id': user.id,
        'token': token,
        'platform': defaultTargetPlatform.name.toLowerCase(),
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,token');

      _logger.info('FCM token saved to Supabase for user ${user.id}');
    } catch (e, st) {
      _logger.error('Error saving FCM token to Supabase', e, st);
    }
  }
}


