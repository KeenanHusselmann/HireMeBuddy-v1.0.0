import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/utils/logger.dart';

/// Service to trigger FCM notifications via Supabase Edge Functions
/// NOTE: All direct edge function calls are disabled - database triggers handle notifications automatically
class FcmTriggerService {
  static final FcmTriggerService _instance = FcmTriggerService._internal();
  factory FcmTriggerService() => _instance;
  FcmTriggerService._internal();

  final _supabase = Supabase.instance.client;
  final _logger = AppLogger();

  /// Send notification when a new message is sent
  /// NOTE: Database trigger (notify_new_message) handles this automatically
  Future<void> notifyNewMessage({
    required String recipientProfileId,
    required String senderName,
    required String messageContent,
    required String messageId,
    String? conversationId,
  }) async {
    _logger.info('Message notification will be sent by database trigger');
  }

  /// Send notification when a new booking is created
  /// NOTE: Database trigger (notify_new_booking) handles this automatically
  Future<void> notifyNewBooking({
    required String providerProfileId,
    required String clientName,
    required String bookingId,
    required double totalPrice,
    required String bookingDate,
    required String bookingTime,
  }) async {
    _logger.info('Booking notification will be sent by database trigger');
  }

  /// Send notification when booking status changes
  /// NOTE: Database trigger (notify_booking_status_change) handles this automatically
  Future<void> notifyBookingStatusChange({
    required String clientProfileId,
    required String providerName,
    required String bookingId,
    required String newStatus,
  }) async {
    _logger.info('Status change notification will be sent by database trigger');
  }

  /// Send notification for payment received
  /// NOTE: Database trigger should handle this (if trigger exists)
  Future<void> notifyPaymentReceived({
    required String providerProfileId,
    required String clientName,
    required double amount,
    required String paymentId,
  }) async {
    _logger.info('Payment notification should be sent by database trigger');
  }
}
