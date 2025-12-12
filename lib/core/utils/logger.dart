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
