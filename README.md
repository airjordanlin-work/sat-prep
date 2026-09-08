# Gatekeeper

Social media apps stay locked until you answer an SAT question. Answering buys you a short pass. When the pass runs out, the lock comes back.

Built for high school students (16+) preparing for the SAT.

---

## Status

**Pre-alpha. Nothing here is production ready.**

| Component | State |
| --- | --- |
| Flutter quiz UI + local question set | In progress (M1) |
| Android launch detection + gate | In progress (M1) |
| Supabase schema + server-side grading | Planned |
| Content generation pipeline | Planned |
| iOS Screen Time shield | Planned, pending Apple entitlement |
| Streaks, XP, achievements | Planned |
| Ten-question gatekeeper quiz | Planned |

Sections marked **[planned]** describe intended behavior, not shipped behavior. They are documented so the design is reviewable.

---

## The core loop

```
  blocked app is shielded by default
            │
     user taps it
            │
            ▼
   Gatekeeper takes over the screen
            │
   answer the question, right or wrong
   (wrong = read the explanation first)
            │
            ▼
   shield clears, timed pass starts
            │
      pass expires
            │
            ▼
      shield returns
```

Cost escalates within a rolling hour: first entry free, second costs 1 question, third costs 2, fourth costs 3.

---

## Design principles

Five rules that decide most arguments about this app.

**1. Gate at launch, never mid-session.** The app never interrupts an in-progress scroll. Friction lands at a natural boundary.

**2. Gate on engagement, not correctness.** A wrong answer still grants entry. The user just has to read the explanation first. Never lock someone out for being bad at the thing they're trying to learn.

**3. Tax intent, not time.** The first entry in an hour is free. The fourth is expensive. Checking a message and starting a binge are different behaviors and should cost differently.

**4. The user sets their own tax.** Question count and pass length are user-configurable with sane defaults. Self-imposed friction is tolerated far better than imposed friction.

**5. Reps, not tolls.** Questions must visibly accumulate into something (streak, skills mastered, progress trend) or they read as pure punishment.

---

## Why gate at launch instead of interrupting mid-scroll

The original design interrupted the user every 5 minutes of continuous scrolling, timed to fire shortly after a swipe so it would land between videos. Abandoned for three reasons:

1. **iOS cannot do it reliably.** `DeviceActivitySchedule` has a 15-minute minimum interval, and event thresholds under roughly 5 minutes are unreliable because background daemons batch execution to save battery. Recent iOS versions also have documented threshold bugs.
2. **It lands mid-video.** Neither platform exposes when a Reel ends, so any interrupt-during-session design is guessing.
3. **It buys nothing.** With a 5-minute pass, a 30-Reel binge is impossible either way.

The trade is that a determined user can re-enter repeatedly. Escalating cost is the answer to that.

---

## Platform notes

### iOS

- The `com.apple.developer.family-controls` entitlement is granted by request, not by checkbox, and requires a paid Apple Developer Program membership. Development builds can generally run on your own device; **distribution, including TestFlight, requires approval.** Request before writing Swift.
- Use `.individual` authorization. The user shields their own device, no parent-child pairing.
- The shield is drawn by `ShieldConfigurationExtension`: title, subtitle, icon, up to two buttons. It cannot render a quiz. Tapping the primary button routes through `ShieldActionExtension`, which opens the main app where the quiz runs.
- Pass expiry is a `DeviceActivityEvent` whose threshold equals the pass length. Thresholds below ~5 minutes are unreliable, so **5 minutes is the iOS floor for pass length.**
- `DeviceActivitySchedule` minimum interval is 15 minutes, so use one day-long schedule and express all timing as event thresholds inside it.
- The monitor extension has roughly a 6 MB memory budget and cannot be relied on for network calls. It does one thing: write a shield command to a named `ManagedSettingsStore` shared via App Group.
- Threshold delivery is unreliable on recent iOS (early fires, missed fires). Treat `eventDidReachThreshold` as a wake-up signal, not proof time elapsed. Backstop with a foreground recheck of `pass_expires_at`.
- Screen Time does not work in the Simulator. Physical device only.
- A mismatched App Group identifier across targets is the most common cause of shields that appear applied but never take effect.

**Managed accounts.** A Child Account is required under 13 and available up to 18. At 13-17, a parent can set and lock a Screen Time passcode, and the teen needs the organizer's permission to leave the family group. Some jurisdictions force certain settings on for under-18 accounts. If a tester's device has a parent-held passcode they don't know, they cannot authorize this app. Onboarding must detect this and explain it rather than dead-ending.

### Android

- A foreground service polls `UsageStatsManager` for the current foreground package. When a blocked package appears, Gatekeeper launches a full-screen Activity over it.
- **No `AccessibilityService`**, which avoids the Play Console accessibility declaration and its policy risk.
- Two permissions granted by hand through Settings: `PACKAGE_USAGE_STATS` and `SYSTEM_ALERT_WINDOW`.
- Poll-based detection means the gate can appear a second or two after the app opens.

### Threat model

Friction, not enforcement. Uninstalling defeats it and no defense is planned. Pass state is server-authoritative so it survives reboot, force-stop, and local tampering. That is the entire guarantee.

---

## Architecture

```
┌──────────────────────────────────────────────────────┐
│  Flutter app (Dart)                                  │
│    quiz UI · app picker · settings · progress · auth │
└───────────────┬──────────────────────┬───────────────┘
                │ MethodChannel        │ MethodChannel
    ┌───────────▼──────────┐  ┌────────▼─────────────┐
    │ Android (Kotlin)     │  │ iOS (Swift)          │
    │  ForegroundService   │  │  FamilyControls      │
    │  UsageStatsManager   │  │  ShieldConfig ext    │
    │  full-screen gate    │  │  ShieldAction ext    │
    │  Activity            │  │  DeviceActivity ext  │
    └──────────────────────┘  └──────────────────────┘
                │                      │
                └──────────┬───────────┘
                           │ HTTPS
              ┌────────────▼─────────────┐
              │ Supabase                 │
              │  Postgres + RLS · Auth   │
              │  Edge Functions:         │
              │    /start-attempt        │
              │    /grade-attempt        │
              │    /pass-status          │
              └────────────┬─────────────┘
                           │
              ┌────────────▼─────────────┐
              │ Content pipeline (Python)│
              │  generate → similarity   │
              │  check → key verify →    │
              │  human review            │
              └──────────────────────────┘
```

Grading is server-side. `/start-attempt` returns stems and choices with no answer key. `/grade-attempt` takes choice IDs, returns pass/fail plus explanations, and is the only thing that can write `pass_expires_at`.

---

## Running this

An iOS app cannot be containerized. Docker covers the backend and the content pipeline. The mobile app needs a real toolchain, and blocking needs a real device.

### Tier 1: watch it (30 seconds)

`docs/demo.mp4` shows the Android gate firing on app launch and clearing on an answer. **Recommended path for reviewers.** Interception cannot be shown in a browser or simulator.

### Tier 2: quiz UI in a browser (2 minutes)

```bash
git clone https://github.com/<you>/gatekeeper.git
cd gatekeeper/app
flutter pub get
flutter run -d chrome --dart-define=DEMO_MODE=true
```

Bundled questions, no backend, no auth. Quiz and grading flow only. No blocking, because a browser cannot block anything.

### Tier 3: full local stack (15 minutes)

Requires Docker and the Supabase CLI.

```bash
cd backend
cp .env.example .env
docker compose up -d
supabase db reset          # migrations + seed.sql
supabase functions serve   # :54321
```

Studio at `http://localhost:54323`. Then:

```bash
cd ../app
flutter run \
  --dart-define=SUPABASE_URL=http://10.0.2.2:54321 \
  --dart-define=SUPABASE_ANON_KEY=<from .env>
```

`10.0.2.2` is host loopback from the Android emulator. Use `localhost` for web, your LAN IP for a physical device.

### Tier 4: Android on device

```bash
cd app
flutter build apk --debug
adb install build/app/outputs/flutter-apk/app-debug.apk
```

Grant both by hand. Neither can be granted programmatically:

1. Settings → Apps → Special app access → **Usage access** → Gatekeeper
2. Settings → Apps → Special app access → **Display over other apps** → Gatekeeper

```bash
adb logcat -s Gatekeeper
```

### Tier 5: iOS

**This will not build for you.** Needs macOS with Xcode 15+, a physical device, and the Family Controls entitlement approved for your own team ID. The entitlement is not transferable, so cloning does not grant access.

```bash
cd app
flutter build ios --debug
open ios/Runner.xcworkspace
```

Set your team on `Runner` and all three extension targets. Confirm the App Group identifier matches across every target.

---

## Configuration

| Variable | Where | Meaning |
| --- | --- | --- |
| `SUPABASE_URL` | app | Backend base URL |
| `SUPABASE_ANON_KEY` | app | Public anon key |
| `DEMO_MODE` | app | Bundled questions, no network |
| `ANTHROPIC_API_KEY` | pipeline | Question generation. Never shipped in the app. |
| `PASS_LENGTH_MIN` | user + remote default | Minutes per pass (default 5, iOS floor 5) |
| `FREE_ENTRIES_PER_HOUR` | remote config | Ungated entries in a rolling hour (default 1) |
| `ESCALATION_CURVE` | remote config | Questions per entry after the free one (default 1,2,3) |
| `GATEKEEPER_LENGTH` | remote config | Questions in the full unlock quiz (default 10) |
| `GATEKEEPER_THRESHOLD` | remote config | Correct answers to pass (default 7) |
| `FAIL_LOCKOUT_MIN` | remote config | Cooldown after a failed gatekeeper quiz (default 15) |

Every default is an opening guess, not a finding. Retune against retention data from the pilot.

---

## Data model [planned]

```sql
questions (id, section, skill, difficulty, stem, choices jsonb,
           correct_choice, explanation, reviewed bool, created_at)

attempts (id, user_id, kind,          -- 'pass' | 'gatekeeper'
          question_ids uuid[], started_at, submitted_at,
          score, passed bool)

pass_state (user_id pk, pass_expires_at, entries_this_hour,
            consecutive_failures, disabled_until)

skill_progress (user_id, skill, accuracy, next_review_at)

retention (user_id, installed_at, last_active_at)

blocked_apps (user_id, platform, package_or_token)
```

`pass_state` is the single source of truth. Clients read, never write. RLS scopes every row to `auth.uid()`.

`skill_progress` drives spaced repetition: missed items resurface at increasing intervals, which is what makes "study while you scroll" an actual claim rather than a slogan.

`retention` exists from M2 onward. Day-1, day-3, and day-7 retention are the only numbers that say whether this works.

---

## Content

Questions are generated, not copied.

Official practice material is used **locally, as a reference set for prompt tuning only.** Never scraped into the database, committed to this repo, or shipped. It is free to download but not openly licensed, and question text is copyrighted. Formats, skill taxonomies, and difficulty calibration are not.

Pipeline:

1. Generate against the published skill taxonomy (section, skill, difficulty), not against a specific source question.
2. Embed each item, reject anything above a cosine similarity threshold to the reference set.
3. Verify math answer keys programmatically. Generated items ship wrong keys often enough that this is not optional.
4. Land as `reviewed = false`. Nothing circulates until a human approves it.

"SAT" is a registered trademark of the College Board. Used descriptively. No affiliation or endorsement claimed.

---

## Motivation layer [planned]

- **Streaks and XP** tied to days studied, never days scrolled. Streak insurance (one free miss or a repair cost) so a single bad day is not permanent churn.
- **Achievements**, client-side, mostly onboarding milestones and visible accumulation.
- **Progress view**: questions answered, per-skill accuracy, trend over time.
- **Manual weekly share** before any social feature. A summary card the user sends themselves via iMessage. No linked accounts, no data through the backend, zero privacy surface. If people share it, the mechanic is validated and a real accountability-partner feature is worth building.
- **Accountability partner**, only if the manual share validates it. Opt-in both sides, exactly one partner, weekly aggregate numbers only, no per-app breakdown, no timestamps, no raw logs, one-tap revoke.

**No leaderboards.** They motivate the top few and demotivate everyone else, and in a cohort of ~11 word-of-mouth users, being last is visible and personal. Ranking on questions answered would also reward the heaviest scroller, which inverts the product.

---

## Known limitations

- Uninstalling removes the block. No defense planned.
- Android detection is poll-based, so the gate can lag app launch slightly.
- iOS pass expiry depends on system-scheduled callbacks that are currently unreliable, backstopped by a foreground recheck.
- Users on a parent-locked Screen Time passcode cannot authorize the app without parental involvement.
- No user validation yet. Every retention assumption here is a hypothesis.

---

## Roadmap

Everything before M4 is platform-independent and proceeds while the entitlement request is pending.

- [ ] **Week 0.** Paid Apple Developer account. File Family Controls entitlement request. Survey testers: open Settings → Screen Time, does it ask for a passcode?
- [ ] **M1.** Flutter quiz UI, local question JSON, engagement-gating, escalating cost. Android: foreground service, launch detection on one hardcoded package, full-screen gate, in-memory pass. Ends with a demo video.
- [ ] **M2.** Supabase schema, server-side grading, pass state survives reboot and force-stop. Retention instrumentation.
- [ ] **M3.** Content pipeline: generation, similarity check, key verification, review CLI.
- [ ] **M4.** iOS: authorization, `FamilyActivityPicker`, shield config, shield action routing, threshold re-shield with foreground backstop.
- [ ] **M5.** Streaks, XP, achievements, progress view, manual weekly share.
- [ ] **M6.** Ten-question gatekeeper quiz, failure lockout, difficulty step-down. Spaced repetition.
- [ ] **M7.** TestFlight pilot, 10+ users, two weeks. Retune pass length and escalation curve against real retention.

**M1 + M2 is the threshold** at which this becomes a shipped, technically non-trivial project. Past M2, work improves the product more than it improves the case for it.
