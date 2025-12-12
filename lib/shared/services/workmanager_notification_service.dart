import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:workmanager/workmanager.dart';
import '../../core/utils/logger.dart';

/// Background notification service using WorkManager for periodic checks
/// This approach works reliably on all Android versions without battery optimization issues
class WorkManagerNotificationService {
  static const String _taskName = 'checkNotifications';
  static DateTime? _lastMessageCheck;
  static DateTime? _lastBookingCheck;

  /// Initialize WorkManager and register periodic task
  static Future<void> initialize(String profileId, String userType) async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: true,
    );

    // Register periodic task (runs every 15 minutes minimum on Android)
    await Workmanager().registerPeriodicTask(
      _taskName,
      _taskName,
      frequency: const Duration(minutes: 15),
      initialDelay: const Duration(seconds: 10),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
      inputData: {
        'profileId': profileId,
        'userType': userType,
      },
    );

    logger.info('✅ WorkManager initialized for profile: $profileId');
  }

  /// Stop the background task
  static Future<void> stop() async {
    await Workmanager().cancelByUniqueName(_taskName);
    logger.info('🛑 WorkManager stopped');
  }
}

/// Top-level function required by WorkManager
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      logger.debug('📱 WorkManager: Task started - ${DateTime.now()}');
      
      final profileId = inputData?['profileId'] as String?;
      final userType = inputData?['userType'] as String?;

      if (profileId == null) {
        logger.error('❌ WorkManager: No profileId provided', Exception('No profileId'));
        return Future.value(true);
      }

      // Initialize Supabase client - Using correct project credentials
      final supabase = SupabaseClient(
        'https://vjpaolkqlumpyuxxmmvr.supabase.co',
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZqcGFvbGtxbHVtcHl1eHhtbXZyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTI5MTY3ODEsImV4cCI6MjA2ODQ5Mjc4MX0.irmIx87eljdUN5zdu3IH5aQbUxAgGbjS8d4ENgBg2Tc',
      );

      // Initialize notifications
      final notifications = FlutterLocalNotificationsPlugin();
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidSettings);
      await notifications.initialize(initSettings);

      // Check for new messages
      await _checkNewMessages(supabase, profileId, notifications);

      // Check for new bookings (if provider)
      if (userType == 'labourer' || userType == 'both') {
        await _checkNewBookings(supabase, profileId, notifications);
      }

      logger.info('✅ WorkManager: Task completed successfully');
      return Future.value(true);
    } catch (e) {
      logger.error('❌ WorkManager: Task failed', e);
      return Future.value(false);
    }
  });
}

Future<void> _checkNewMessages(
  SupabaseClient supabase,
  String profileId,
  FlutterLocalNotificationsPlugin notifications,
) async {
  try {
    final now = DateTime.now();
    final checkFrom = WorkManagerNotificationService._lastMessageCheck ?? 
                      now.subtract(const Duration(minutes: 20));
    WorkManagerNotificationService._lastMessageCheck = now;

    final response = await supabase
        .from('chat_messages')
        .select('id, sender_id, content, created_at')
        .eq('receiver_id', profileId)
        .eq('read', false)
        .gt('created_at', checkFrom.toIso8601String())
        .order('created_at', ascending: false)
        .limit(5);

    final messages = response as List<dynamic>;
    logger.debug('📨 WorkManager: Found ${messages.length} new messages');

    for (var message in messages) {
      try {
        final senderProfile = await supabase
            .from('profiles')
            .select('full_name')
            .eq('id', message['sender_id'])
            .single();

        final senderName = senderProfile['full_name'] as String? ?? 'Someone';
        final content = message['content'] as String? ?? 'New message';

        await _showNotification(
          notifications,
          title: '💬 $senderName',
          body: content,
          id: message['id'].hashCode,
        );
        
        logger.info('✅ WorkManager: Notification sent from $senderName');
      } catch (e) {
        logger.error('❌ WorkManager: Error processing message', e);
      }
    }
  } catch (e) {
    logger.error('❌ WorkManager: Check messages error', e);
  }
}

Future<void> _checkNewBookings(
  SupabaseClient supabase,
  String profileId,
  FlutterLocalNotificationsPlugin notifications,
) async {
  try {
    final now = DateTime.now();
    final checkFrom = WorkManagerNotificationService._lastBookingCheck ?? 
                      now.subtract(const Duration(minutes: 20));
    WorkManagerNotificationService._lastBookingCheck = now;

    final response = await supabase
        .from('bookings')
        .select('id, booking_date, booking_time, created_at')
        .eq('provider_id', profileId)
        .eq('status', 'pending')
        .gt('created_at', checkFrom.toIso8601String())
        .order('created_at', ascending: false)
        .limit(5);

    final bookings = response as List<dynamic>;
    logger.debug('📅 WorkManager: Found ${bookings.length} new bookings');

    for (var booking in bookings) {
      await _showNotification(
        notifications,
        title: '🎉 New Booking Request!',
        body: 'You have a new booking on ${booking['booking_date']} at ${booking['booking_time']}',
        id: booking['id'].hashCode,
      );
      
      logger.info('✅ WorkManager: Booking notification sent');
    }
  } catch (e) {
    logger.error('❌ WorkManager: Check bookings error', e);
  }
}

Future<void> _showNotification(
  FlutterLocalNotificationsPlugin notifications, {
  required String title,
  required String body,
  required int id,
}) async {
  const androidDetails = AndroidNotificationDetails(
    'messages_channel',
    'Messages',
    channelDescription: 'Notifications for new messages and bookings',
    importance: Importance.high,
    priority: Priority.high,
    enableVibration: true,
    playSound: true,
  );

  const details = NotificationDetails(android: androidDetails);
  await notifications.show(id, title, body, details);
}
