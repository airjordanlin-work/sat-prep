import 'package:flutter/services.dart';

/// Bridge to the native blocking layer.
///
/// Android (M1): the foreground service calls [onGateRequested] when a
/// blocked package comes to the foreground.
/// iOS (M4): ShieldActionExtension opens the app, which calls the same
/// path. Keep this interface platform-agnostic.
class GateChannel {
  static const _channel = MethodChannel('com.gatekeeper.app/gate');

  /// Native asks Dart to show the gate.
  static void onGateRequested(void Function(String package) handler) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'gateRequested') {
        handler(call.arguments as String? ?? 'unknown');
      }
    });
  }

  /// Dart tells native the pass is granted and for how long.
  static Future<void> grantPass(Duration duration) =>
      _channel.invokeMethod('grantPass', {'seconds': duration.inSeconds});

  static Future<bool> hasRequiredPermissions() async =>
      await _channel.invokeMethod<bool>('hasPermissions') ?? false;

  static Future<void> openPermissionSettings() =>
      _channel.invokeMethod('openPermissionSettings');
}
