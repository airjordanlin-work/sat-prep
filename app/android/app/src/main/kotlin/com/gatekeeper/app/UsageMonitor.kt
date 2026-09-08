package com.gatekeeper.app

import android.app.usage.UsageStatsManager
import android.content.Context

/**
 * Reads the current foreground package.
 *
 * UsageStatsManager is coarse and lags slightly. That is accepted:
 * the gate appearing a second after launch is fine. The alternative,
 * AccessibilityService, gives faster detection but pulls in a Play
 * Console accessibility declaration and real policy risk. See
 * docs/decisions/0002-no-accessibility-service.md
 */
class UsageMonitor(private val context: Context) {

    private val usageStats =
        context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager

    /**
     * TODO(M1): implement.
     * Query UsageEvents over the last few seconds, walk them, and return
     * the package of the most recent MOVE_TO_FOREGROUND event.
     * Return null if nothing moved.
     *
     * Do not use queryUsageStats with INTERVAL_DAILY here. It aggregates
     * and will not tell you what is in front right now.
     */
    fun currentForegroundPackage(now: Long): String? {
        throw NotImplementedError()
    }

    /** True if the user has granted PACKAGE_USAGE_STATS in Settings. */
    fun hasUsageAccess(): Boolean {
        // TODO(M1): AppOpsManager.checkOpNoThrow(OPSTR_GET_USAGE_STATS, ...)
        throw NotImplementedError()
    }
}
