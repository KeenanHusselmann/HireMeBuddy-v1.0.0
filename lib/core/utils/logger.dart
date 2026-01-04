import 'package:logger/logger.dart';

/// Centralized logging service for the application
/// 
/// Provides structured logging with different levels and prevents
/// sensitive data from being logged in production.
class AppLogger {
  static final AppLogger _instance = AppLogger._internal();
  late final Logger _logger;
  
  factory AppLogger() {
    return _instance;
  }
  
  AppLogger._internal() {
    _logger = Logger(
      filter: _ProductionFilter(),
      printer: PrettyPrinter(
        methodCount: 2,
        errorMethodCount: 8,
        lineLength: 120,
        colors: true,
        printEmojis: true,
        dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
      ),
      output: ConsoleOutput(),
    );
  }
  
  /// Debug level logging - only in development
  void debug(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.d(message, error: error, stackTrace: stackTrace);
  }
  
  /// Info level logging
  void info(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.i(message, error: error, stackTrace: stackTrace);
  }
  
  /// Warning level logging
  void warning(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }
  
  /// Error level logging
  void error(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }
  
  /// Fatal level logging - critical errors
  void fatal(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.f(message, error: error, stackTrace: stackTrace);
  }
  
  /// Trace level logging - very verbose
  void trace(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.t(message, error: error, stackTrace: stackTrace);
  }

  // ============ DATA SANITIZATION METHODS ============

  /// Sanitize email for logging (shows only first char and domain)
  /// Example: john.doe@gmail.com -> j***@gmail.com
  static String sanitizeEmail(String? email) {
    if (email == null || email.isEmpty) return '[empty]';
    if (!email.contains('@')) return '[invalid-email]';
    
    final parts = email.split('@');
    final username = parts[0];
    final domain = parts[1];
    
    if (username.isEmpty) return '***@$domain';
    
    // Show first character + *** + domain
    return '${username[0]}***@$domain';
  }

  /// Sanitize user ID for logging (shows first 8 characters)
  /// Example: 550e8400-e29b-41d4-a716-446655440000 -> 550e8400***
  static String sanitizeUserId(String? userId) {
    if (userId == null || userId.isEmpty) return '[empty]';
    if (userId.length <= 8) return '${userId.substring(0, userId.length ~/ 2)}***';
    return '${userId.substring(0, 8)}***';
  }

  /// Sanitize phone number for logging (shows last 4 digits)
  /// Example: +264814567890 -> ***7890
  static String sanitizePhone(String? phone) {
    if (phone == null || phone.isEmpty) return '[empty]';
    if (phone.length <= 4) return '***';
    return '***${phone.substring(phone.length - 4)}';
  }

  /// Sanitize any sensitive data map
  static Map<String, dynamic> sanitizeData(Map<String, dynamic> data) {
    final sanitized = <String, dynamic>{};
    
    final sensitiveKeys = [
      'password',
      'token',
      'apikey',
      'api_key',
      'secret',
      'authorization',
      'auth_token',
      'access_token',
      'refresh_token',
      'credit_card',
      'cvv',
      'ssn',
      'encrypted_password',
    ];
    
    data.forEach((key, value) {
      final lowerKey = key.toLowerCase();
      
      // Check if key contains sensitive information
      final isSensitive = sensitiveKeys.any((sensitive) => lowerKey.contains(sensitive));
      
      if (isSensitive) {
        sanitized[key] = '[REDACTED]';
      } else if (value is Map<String, dynamic>) {
        // Recursively sanitize nested maps
        sanitized[key] = sanitizeData(value);
      } else if (value is String && value.length > 200) {
        // Truncate very long strings to prevent log bloat
        sanitized[key] = '${value.substring(0, 200)}... [${value.length} chars]';
      } else {
        sanitized[key] = value;
      }
    });
    
    return sanitized;
  }

  /// Sanitize name (shows only first name initial and last name)
  /// Example: John Michael Doe -> J*** Doe
  static String sanitizeName(String? fullName) {
    if (fullName == null || fullName.isEmpty) return '[empty]';
    
    final parts = fullName.trim().split(' ');
    if (parts.length == 1) {
      return '${parts[0][0]}***';
    }
    
    final firstName = parts.first;
    final lastName = parts.last;
    return '${firstName[0]}*** $lastName';
  }
}

/// Production filter to disable verbose logging in release mode
class _ProductionFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    // In production (release mode), only log warnings and above
    const bool isProduction = bool.fromEnvironment('dart.vm.product');
    
    if (isProduction) {
      return event.level.index >= Level.warning.index;
    }
    
    // In development, log everything
    return true;
  }
}

// Global logger instance for easy access
final logger = AppLogger();
