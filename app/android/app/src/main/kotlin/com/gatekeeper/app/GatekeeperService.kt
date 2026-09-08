package com.gatekeeper.app

import android.app.Service
import android.content.Intent
import android.os.IBinder
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel

/**
 * Foreground service. Polls for a blocked package coming to the
 * foreground and launches GateActivity over it.
 *
 * Polling interval is a battery tradeoff. 1s feels instant and costs
 * measurably. Start at 1s for M1, measure, then back off.
 */
class GatekeeperService : Service() {

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Default)
    private lateinit var monitor: UsageMonitor

    // M1: hardcode one package. M2: read from backend.
    private val blockedPackages = setOf("com.instagram.android")

    override fun onCreate() {
        super.onCreate()
        monitor = UsageMonitor(this)
        // TODO(M1): startForeground with a low-importance notification
        // channel. Android 14 also requires a foregroundServiceType.
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // TODO(M1): launch the poll loop in `scope`.
        //  - skip entirely while a pass is active
        //  - debounce: do not re-fire while GateActivity is already up
        //  - on match, start GateActivity with FLAG_ACTIVITY_NEW_TASK
        return START_STICKY
    }

    override fun onDestroy() {
        scope.cancel()
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
