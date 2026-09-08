# 0001: Gate at launch, not mid-session

## Status
Accepted. Reverses the original design.

## Context
The first design interrupted the user every 5 minutes of continuous
scrolling, timed to fire shortly after a swipe so it would land between
videos.

## Decision
Shield the app at launch instead. Answering grants a timed pass.

## Reasons
1. iOS cannot deliver mid-session interruption reliably.
   DeviceActivitySchedule has a 15-minute minimum interval, thresholds
   under ~5 minutes are unreliable because background daemons batch
   execution, and recent iOS has documented threshold bugs.
2. Neither platform exposes when a video ends, so the "fire between
   Reels" behavior was guesswork.
3. It buys nothing. With a 5-minute pass a long binge is impossible
   either way.

## Consequences
A determined user can re-enter repeatedly. Escalating cost within a
rolling hour is the mitigation.
