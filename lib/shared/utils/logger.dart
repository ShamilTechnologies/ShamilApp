import 'package:flutter/foundation.dart';

/// A simple logging utility for the application.
class Logger {
  final String tag;

  /// Creates a new logger with the given tag.
  Logger(this.tag);

  /// Log an info message.
  void info(String message) {
    if (kDebugMode) {
      print('INFO [$tag]: $message');
    }
  }

  /// Log an error message.
  void error(String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      print('ERROR [$tag]: $message');
      if (error != null) {
        print('  $error');
      }
      if (stackTrace != null) {
        print('  $stackTrace');
      }
    }
  }

  /// Log a warning message.
  void warning(String message) {
    if (kDebugMode) {
      print('WARNING [$tag]: $message');
    }
  }

  /// Log a debug message.
  void debug(String message) {
    if (kDebugMode) {
      print('DEBUG [$tag]: $message');
    }
  }
}
