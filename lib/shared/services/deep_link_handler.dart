import 'package:flutter/material.dart';

/// Service to handle deep linking from push notifications
/// This is a singleton that can be accessed from anywhere to trigger navigation
class DeepLinkHandler {
  static final DeepLinkHandler _instance = DeepLinkHandler._internal();
  factory DeepLinkHandler() => _instance;
  DeepLinkHandler._internal();
  
  // Callback to handle navigation requests
  Function(String route, {Map<String, dynamic>? params})? _onNavigate;
  
  /// Register navigation callback (called from the main app)
  void registerNavigationCallback(Function(String route, {Map<String, dynamic>? params}) callback) {
    _onNavigate = callback;
  }
  
  /// Navigate to a specific route
  void navigateTo(String route, {Map<String, dynamic>? params}) {
    if (_onNavigate != null) {
      _onNavigate!(route, params: params);
    } else {
      debugPrint('⚠️ DeepLinkHandler: No navigation callback registered');
    }
  }
  
  /// Navigate to bookings screen
  void navigateToBookings({String? bookingId}) {
    navigateTo('bookings', params: bookingId != null ? {'bookingId': bookingId} : null);
  }
  
  /// Navigate to messages screen
  void navigateToMessages({String? conversationId}) {
    navigateTo('messages', params: conversationId != null ? {'conversationId': conversationId} : null);
  }
}
