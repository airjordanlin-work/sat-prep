# 0002: UsageStatsManager, not AccessibilityService

## Status
Accepted.

## Context
AccessibilityService gives near-real-time window and scroll events.
UsageStatsManager polling is coarser and lags by a second or so.

## Decision
Use UsageStatsManager.

## Reasons
Google restricts non-accessibility use of the Accessibility API, and
wellbeing apps have been removed over it. Once the design moved to
gate-at-launch (see 0001), the fast scroll-event detection was no
longer needed, so the risk bought nothing.

## Consequences
The gate can appear a second or two after the blocked app opens.
Acceptable.
