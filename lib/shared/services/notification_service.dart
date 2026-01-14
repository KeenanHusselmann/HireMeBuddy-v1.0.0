import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/utils/logger.dart';
import '../../core/services/deep_link_handler.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final _logger = AppLogger();

  Future<void> initialize() async {
    // Create Android notification channels
    
    // Default channel for FCM notifications
    const defaultChannel = AndroidNotificationChannel(
      'default',
      'Default Notifications',
      description: 'Default notification channel for FCM',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );
    
    const bookingsChannel = AndroidNotificationChannel(
      'bookings_channel',
      'Bookings',
      description: 'Notifications for new bookings',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );

    const messagesChannel = AndroidNotificationChannel(
      'messages_channel',
      'Messages',
      description: 'Notifications for new messages',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );

    const notificationsChannel = AndroidNotificationChannel(
      'notifications_channel',
      'Notifications',
      description: 'General notifications for bookings, payments, etc.',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );

    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    
    await androidPlugin?.createNotificationChannel(defaultChannel);
    await androidPlugin?.createNotificationChannel(bookingsChannel);
    await androidPlugin?.createNotificationChannel(messagesChannel);
    await androidPlugin?.createNotificationChannel(notificationsChannel);

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permissions for Android 13+
    final androidPermission = await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    
    _logger.info('Android notification permission granted: $androidPermission');

    // Request permissions for iOS
    await _notifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  void _onNotificationTapped(NotificationResponse response) {
    _logger.debug('Notification tapped: ${response.payload}');
    
    // Navigate based on notification type
    final payload = response.payload;
    if (payload != null && payload == 'message') {
      // Use DeepLinkHandler to navigate
      DeepLinkHandler().navigateToMessages();
      _logger.info('Navigated to messages via DeepLinkHandler');
    }
  }

  Future<void> showBookingNotification({
    required String title,
    required String body,
    String? bookingId,
  }) async {
    _logger.debug('showBookingNotification - Title: $title, Booking ID: $bookingId');

    const androidDetails = AndroidNotificationDetails(
      'bookings_channel',
      'Bookings',
      channelDescription: 'Notifications for new bookings',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final notificationId = bookingId?.hashCode ?? DateTime.now().millisecondsSinceEpoch;

    try {
      await _notifications.show(
        notificationId,
        title,
        body,
        details,
        payload: bookingId,
      );
      _logger.debug('Booking notification shown successfully');
    } catch (e) {
      _logger.error('Error showing booking notification', e);
    }
  }

  Future<void> showMessageNotification({
    required String title,
    required String body,
    String? senderId,
  }) async {
    _logger.debug('showMessageNotification - Title: $title, Sender ID: $senderId');

    const androidDetails = AndroidNotificationDetails(
      'messages_channel',
      'Messages',
      channelDescription: 'Notifications for new messages',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final notificationId = senderId?.hashCode ?? DateTime.now().millisecondsSinceEpoch;

    try {
      await _notifications.show(
        notificationId,
        title,
        body,
        details,
        payload: senderId,
      );
      _logger.debug('Message notification shown successfully');
    } catch (e) {
      _logger.error('Error showing message notification', e);
    }
  }

  // Show general notification from notifications table
  Future<void> showGeneralNotification({
    required String title,
    required String body,
    required String type,
  }) async {
    _logger.debug('showGeneralNotification - Title: $title, Type: $type');

    const androidDetails = AndroidNotificationDetails(
      'notifications_channel',
      'Notifications',
      channelDescription: 'General notifications for bookings, payments, etc.',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Use a 32-bit safe notification ID (use hashCode or modulo to keep it small)
    final notificationId = DateTime.now().millisecondsSinceEpoch % 2147483647;

    try {
      await _notifications.show(
        notificationId,
        title,
        body,
        details,
        payload: type,
      );
      _logger.debug('General notification shown successfully');
    } catch (e) {
      _logger.error('Error showing general notification', e);
    }
  }

  // Subscribe to real-time booking changes for provider
  void subscribeToProviderBookings(String providerId) {
    final supabase = Supabase.instance.client;

    _logger.debug('Setting up booking subscription for provider: $providerId');

    supabase
        .channel('provider_bookings_$providerId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'bookings',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'provider_id',
            value: providerId,
          ),
          callback: (payload) {
            final booking = payload.newRecord;
            
            _logger.debug('New booking received, showing notification');
            showBookingNotification(
              title: '🎉 New Booking Request!',
              body: 'You have a new booking on ${booking['booking_date']} at ${booking['booking_time']}',
              bookingId: booking['id'],
            );
          },
        )
        .subscribe((status, error) {
          _logger.debug('Bookings channel status: $status');
          if (error != null) {
            _logger.error('Bookings channel error', error);
          }
        });

    _logger.info('Subscribed to bookings for provider: $providerId');
  }

  // Subscribe to notifications table for booking acceptance, payments, etc.
  void subscribeToNotifications(String profileId) {
    final supabase = Supabase.instance.client;

    _logger.debug('Setting up notifications subscription for profile: $profileId');

    supabase
        .channel('general_notifications_$profileId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: profileId,
          ),
          callback: (payload) async {
            _logger.debug('Notification callback triggered: ${payload.eventType}');
            
            final notification = payload.newRecord;
            final title = notification['title'] as String? ?? 'Notification';
            final body = notification['body'] as String? ?? '';
            final type = notification['type'] as String? ?? 'general';
            
            _logger.debug('Showing notification - Title: $title, Type: $type');
            
            await showGeneralNotification(
              title: title,
              body: body,
              type: type,
            );
          },
        )
        .subscribe((status, error) {
          _logger.debug('Notifications channel status: $status');
          if (error != null) {
            _logger.error('Notifications channel error', error);
          } else {
            _logger.info('Notifications channel subscribed successfully');
          }
        });

    _logger.info('Subscribed to notifications for profile: $profileId');
  }

  // Subscribe to real-time messages
  void subscribeToMessages(String myProfileId) {
    final supabase = Supabase.instance.client;

    _logger.debug('Setting up message subscription for profile: $myProfileId');

    supabase
        .channel('chat_messages_notifications_$myProfileId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'chat_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'receiver_id',
            value: myProfileId,
          ),
          callback: (payload) async {
            _logger.debug('Message notification callback triggered');
            
            final message = payload.newRecord;
            final senderId = message['sender_id'];
            
            // Get sender details
            try {
              final senderProfile = await supabase
                  .from('profiles')
                  .select('full_name')
                  .eq('id', senderId)
                  .single();
              
              final senderName = senderProfile['full_name'] as String? ?? 'Someone';
              final messageContent = message['content'] as String? ?? 'New message';
              
              _logger.debug('Showing message notification from: $senderName');
              showMessageNotification(
                title: '💬 $senderName',
                body: messageContent,
                senderId: senderId,
              );
            } catch (e) {
              _logger.error('Error fetching sender details', e);
              // Show notification anyway with generic message
              showMessageNotification(
                title: '💬 New Message',
                body: message['content'] as String? ?? 'You have a new message',
                senderId: senderId,
              );
            }
          },
        )
        .subscribe((status, error) {
          _logger.debug('Messages channel status: $status');
          if (error != null) {
            _logger.error('Messages channel error', error);
          }
        });

    _logger.info('Subscribed to messages for profile: $myProfileId');
  }

  // Unsubscribe from all channels
  void unsubscribeAll() {
    final supabase = Supabase.instance.client;
    supabase.removeAllChannels();
  }
}
