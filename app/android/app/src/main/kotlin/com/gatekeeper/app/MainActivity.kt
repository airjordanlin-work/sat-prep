package com.gatekeeper.app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val channel = "com.gatekeeper.app/gate"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "hasPermissions" -> {
                        // TODO(M1): usage access AND overlay permission
                        result.notImplemented()
                    }
                    "openPermissionSettings" -> {
                        // TODO(M1): ACTION_USAGE_ACCESS_SETTINGS and
                        // ACTION_MANAGE_OVERLAY_PERMISSION
                        result.notImplemented()
                    }
                    "grantPass" -> {
                        // TODO(M1): store expiry, tell the service to stand down
                        result.notImplemented()
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
