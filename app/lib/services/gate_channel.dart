import 'package:flutter/services.dart';

/// STUB. Real implementation bridges to `UsageMonitor.kt` /
/// `GatekeeperService.kt` on Android (see repo layout) via a
/// `MethodChannel`. This satisfies the call sites in `main.dart`
/// (`onGateRequested`) and `gate_screen.dart` (`grantPass`) so the app
/// links and runs, including in DEMO_MODE where there's no native
/// implementation registered at all.
class GateChannel {
  GateChannel._();

  static const _channel = MethodChannel('gatekeeper/gate');

  /// Registers [onRequested] to fire whenever the native side detects a
  /// blocked package was launched. Called once from `main.dart`.
  static void onGateRequested(void Function(String package) onRequested) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'gateRequested') {
        onRequested(call.arguments as String);
      }
      return null;
    });
  }

  /// Tells the native side to lift the shield for [length] and record
  /// `pass_expires_at`. In DEMO_MODE (no native plugin registered) this
  /// is a no-op rather than a crash.
  static Future<void> grantPass(Duration length) async {
    try {
      await _channel.invokeMethod('grantPass', length.inSeconds);
    } on MissingPluginException {
      // No native implementation yet — expected in DEMO_MODE / on
      // platforms without the Android service wired up.
    }
  }
}