import '../../core/utils/logger.dart';

/// Handles deep link navigation for push notifications
class DeepLinkHandler {
  static final DeepLinkHandler _instance = DeepLinkHandler._internal();
  factory DeepLinkHandler() => _instance;
  DeepLinkHandler._internal();

  final _logger = AppLogger();
  
  // Generic callback for navigation (supports both old and new implementations)
  void Function(String route, {Map<String, dynamic>? params})? _onNavigate;
  
  // Pending navigation to execute once callback is registered
  String? _pendingRoute;
  Map<String, dynamic>? _pendingParams;
  
  // Flag to track if navigation has been triggered (queued OR executed)
  bool _navigationTriggered = false;

  /// Register a generic navigation callback
  void registerNavigationCallback(
    void Function(String route, {Map<String, dynamic>? params}) callback
  ) {
    _onNavigate = callback;
    _logger.info('📍 Navigation callback registered');
    _logger.info('📍 Pending route at registration: $_pendingRoute');
    
    // Execute pending navigation if any with a slight delay to ensure UI is ready
    if (_pendingRoute != null) {
      final route = _pendingRoute!;
      final params = _pendingParams;
      _logger.info('🔗 Pending navigation detected: $route');
      
      // Clear immediately so we don't execute twice
      _pendingRoute = null;
      _pendingParams = null;
      
      // Use Future.delayed to ensure navigation happens after build is complete
      Future.delayed(const Duration(milliseconds: 500), () {
        try {
          _logger.info('🔗 Executing pending navigation to $route');
          callback(route, params: params);
          _logger.info('🔗 Pending navigation executed successfully');
          _navigationTriggered = false;
        } catch (e, stack) {
          _logger.error('❌ Pending navigation failed: $e', e, stack);
          _navigationTriggered = false;
        }
      });
    } else {
      _logger.info('📍 No pending navigation to execute');
    }
  }

  /// Navigate to bookings screen
  void navigateToBookings({String? bookingId}) {
    _navigationTriggered = true; // Mark navigation as triggered
    
    // ALWAYS store the route/params for dashboard to handle
    _pendingRoute = 'bookings';
    _pendingParams = bookingId != null ? {'bookingId': bookingId} : null;
    
    _logger.info('🔗 DeepLink: Bookings navigation queued (bookingId: $bookingId)');
    _logger.info('🔗 Callback registered: ${_onNavigate != null}');
    
    // If callback is already registered (app running), execute immediately
    if (_onNavigate != null) {
      _logger.info('🔗 App already running - executing navigation immediately');
      final callback = _onNavigate!;
      final params = _pendingParams;
      
      Future.delayed(const Duration(milliseconds: 100), () {
        try {
          _logger.info('🔗 Executing bookings navigation');
          callback('bookings', params: params);
          _pendingRoute = null;
          _pendingParams = null;
          _navigationTriggered = false;
        } catch (e, stack) {
          _logger.error('❌ Navigation failed: $e', e, stack);
          // Reset state to prevent stuck navigation
          _pendingRoute = null;
          _pendingParams = null;
          _navigationTriggered = false;
        }
      });
    } else {
      _logger.info('🔗 No callback yet - navigation queued for dashboard');
    }
  }

  /// Navigate to messages screen
  void navigateToMessages() {
    _navigationTriggered = true; // Mark navigation as triggered
    
    // ALWAYS store the route/params for dashboard to handle
    _pendingRoute = 'messages';
    _pendingParams = null;
    
    _logger.info('🔗 DeepLink: Messages navigation queued');
    _logger.info('🔗 Callback registered: ${_onNavigate != null}');
    
    // If callback is already registered (app running), execute immediately
    if (_onNavigate != null) {
      _logger.info('🔗 App already running - executing navigation immediately');
      final callback = _onNavigate!;
      
      Future.delayed(const Duration(milliseconds: 100), () {
        try {
          _logger.info('🔗 Executing messages navigation');
          callback('messages');
          _pendingRoute = null;
          _pendingParams = null;
          _navigationTriggered = false;
        } catch (e, stack) {
          _logger.error('❌ Navigation failed: $e', e, stack);
          // Reset state to prevent stuck navigation
          _pendingRoute = null;
          _pendingParams = null;
          _navigationTriggered = false;
        }
      });
    } else {
      _logger.info('🔗 No callback yet - navigation queued for dashboard');
    }
  }

  /// Check if there's a pending navigation (only checks pending route, not callback)
  bool get hasPendingNavigation => _pendingRoute != null || _navigationTriggered;

  /// Clear all callbacks (e.g., when screen is disposed)
  void clearCallbacks() {
    _onNavigate = null;
    _navigationTriggered = false; // Reset the flag
    _logger.info('📍 Deep link callbacks cleared');
  }
}
