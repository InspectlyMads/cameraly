import 'package:flutter/foundation.dart';

/// Debug logger that only prints in debug mode
class DebugLogger {
  static const bool _enableLogs = kDebugMode;
  
  /// Log a debug message
  static void log(String message, {String? tag}) {
    if (_enableLogs) {
      if (tag != null) {
        debugPrint('[$tag] $message');
      } else {
        debugPrint(message);
      }
    }
  }
  
  /// Log an error message
  static void error(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    if (_enableLogs) {
      final prefix = tag != null ? '[$tag] ' : '';
      debugPrint('$prefix❌ $message');
      if (error != null) {
        debugPrint('$prefix   Error: $error');
      }
      if (stackTrace != null && kDebugMode) {
        debugPrint('$prefix   Stack trace: $stackTrace');
      }
    }
  }
  
  /// Log a warning message
  static void warning(String message, {String? tag}) {
    if (_enableLogs) {
      final prefix = tag != null ? '[$tag] ' : '';
      debugPrint('$prefix⚠️ $message');
    }
  }
  
  /// Log a success message
  static void success(String message, {String? tag}) {
    if (_enableLogs) {
      final prefix = tag != null ? '[$tag] ' : '';
      debugPrint('$prefix✅ $message');
    }
  }
  
  /// Log an info message
  static void info(String message, {String? tag}) {
    if (_enableLogs) {
      final prefix = tag != null ? '[$tag] ' : '';
      debugPrint('$prefix📍 $message');
    }
  }
}