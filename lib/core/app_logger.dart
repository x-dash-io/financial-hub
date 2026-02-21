import 'package:flutter/foundation.dart';

typedef ErrorLogHook =
    void Function(String message, Object error, StackTrace stackTrace);

/// Lightweight logging utility with an optional hook for external reporting.
class AppLogger {
  static ErrorLogHook? _errorHook;

  static void setErrorHook(ErrorLogHook? hook) {
    _errorHook = hook;
  }

  static void error(String message, Object error, StackTrace stackTrace) {
    debugPrint('[FinancialHub][ERROR] $message: $error');
    debugPrintStack(stackTrace: stackTrace);
    _errorHook?.call(message, error, stackTrace);
  }
}
