import 'package:flutter/services.dart';

/// Reads a one-shot pending route written by an App Intent or Spotlight tap.
class NavigationService {
  static const _channel = MethodChannel('jsx.app/navigation');

  /// Returns the pending route string and clears it, or null if none.
  static Future<String?> getPendingRoute() async {
    try {
      return await _channel.invokeMethod<String>('getPendingRoute');
    } on PlatformException catch (_) {
      return null;
    }
  }
}
