package com.gatekeeper.app

import io.flutter.embedding.android.FlutterActivity

/**
 * Full-screen Activity shown over the blocked app. Hosts the Flutter
 * gate UI so the quiz is written once and reused on iOS.
 *
 * TODO(M1):
 *  - showWhenLocked / turnScreenOn as appropriate
 *  - override onBackPressed to no-op
 *  - exclude from recents so it cannot be swiped away
 *  - on pass granted, finish() and tell the service the expiry time
 */
class GateActivity : FlutterActivity()
