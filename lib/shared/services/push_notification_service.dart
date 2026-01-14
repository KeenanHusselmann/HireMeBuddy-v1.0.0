import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/utils/logger.dart';
import '../../core/services/deep_link_handler.dart';
import 'notification_service.dart';

/// Background message handler (must be a top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('🔔 [BG] FCM message: ${message.messageId}');
  
  // Show notification when app is in background/terminated
  final notification = message.notification;
  final data = message.data;
  
  if (notification != null) {
    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    
    // Determine channel based on notification type
    final type = data['type'] as String? ?? 'general';
    String channelId = 'default';
    switch (type) {
      case 'booking':
      case 'new_booking':
      case 'booking_status':
        channelId = 'bookings_channel';
        break;
      case 'message':
      case 'new_message':
        channelId = 'messages_channel';
        break;
      default:
        channelId = 'notifications_channel';
    }
    
    // Show the notification
    await flutterLocalNotificationsPlugin.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelId == 'bookings_channel' ? 'Bookings' :
          channelId == 'messages_channel' ? 'Messages' : 'Notifications',
          channelDescription: 'Notification channel for $type',
          importance: Importance.high,
          priority: Priority.high,
          enableVibration: true,
          playSound: true,
        ),
      ),
      payload: data.isNotEmpty ? data['type'] : null,
    );
  }
}

class PushNotificationService {
  static final PushNotificationService _instance =
      PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final _logger = AppLogger();
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

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

    // Foreground messages: manually display notification
    // FCM does NOT automatically show notifications when app is in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      _logger.debug('FCM foreground message: ${message.messageId}');
      
      final notification = message.notification;
      final data = message.data;
      
      if (notification != null) {
        // Determine channel based on notification type
        final type = data['type'] as String? ?? 'general';
        String channelId = 'default';
        String channelName = 'Notifications';
        
        switch (type) {
          case 'booking':
          case 'new_booking':
          case 'booking_status':
            channelId = 'bookings_channel';
            channelName = 'Bookings';
            break;
          case 'message':
          case 'new_message':
            channelId = 'messages_channel';
            channelName = 'Messages';
            break;
          default:
            channelId = 'notifications_channel';
            channelName = 'Notifications';
        }
        
        // Show the notification
        await _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              channelId,
              channelName,
              channelDescription: 'Notification channel for $type',
              importance: Importance.high,
              priority: Priority.high,
              showWhen: true,
            ),
          ),
          payload: data.isNotEmpty ? data['type'] : null,
        );
        
        _logger.info('✅ Displayed foreground notification: ${notification.title}');
      }
    });

    // When user taps a notification and opens the app
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _logger.debug('FCM message opened app: ${message.messageId}');
      _handleNotificationTap(message);
    });
    
    // Check if app was opened from a terminated state via notification
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _logger.debug('FCM app opened from terminated state: ${initialMessage.messageId}');
      // Delay navigation slightly to ensure app is fully initialized
      Future.delayed(const Duration(milliseconds: 500), () {
        _handleNotificationTap(initialMessage);
      });
    }
  }
  
  /// Handle notification tap and navigate to appropriate screen
  void _handleNotificationTap(RemoteMessage message) {
    final data = message.data;
    final type = data['type'] as String?;
    final bookingId = data['booking_id'] as String?;
    
    _logger.info('🔔 Notification tapped: type=$type, bookingId=$bookingId');
    _logger.info('🔔 Full notification data: $data');
    
    // Navigate based on notification type - use DeepLinkHandler for now
    // It will queue navigation if app not ready
    switch (type) {
      case 'booking':  // Match the type from notify_new_booking trigger
      case 'new_booking':
      case 'booking_status':
        // Navigate to bookings screen
        _logger.info('📍 Navigating to bookings (bookingId: $bookingId)');
        DeepLinkHandler().navigateToBookings(bookingId: bookingId);
        break;
        
      case 'message':  // Match the type from notify_new_message trigger
      case 'new_message':
        // Navigate to messages screen
        _logger.info('📍 Navigating to messages');
        DeepLinkHandler().navigateToMessages();
        break;
        
      default:
        _logger.info('⚠️ Unknown notification type: $type - not navigating');
    }
  }

  Future<void> _saveTokenToSupabase(String? token) async {
    if (token == null) return;
    try {
      SupabaseClient client;
      try {
        client = Supabase.instance.client;
      } catch (e) {
        _logger.warning('Supabase not initialized yet — deferring token save');
        return;
      }

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


