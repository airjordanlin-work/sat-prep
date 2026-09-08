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
| Spaced-repetition review queue | In progress (M1) |
| Supabase schema + server-side grading | Planned (M2) |
| Content generation pipeline | Planned (M2) |
| iOS Screen Time shield | Planned (M3), pending Apple entitlement |
| Motivation layer | Partly M2, rest M4 |

Sections marked **[planned]** describe intended behavior, not shipped behavior.

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
   serves the next item due from the
   user's spaced-repetition queue
            │
            ▼
   correct        → 5-minute pass
   wrong          → 90-second pass, explanation shown, item requeued
   under 2 sec    → not counted, question re-serves
            │
      pass expires
            │
            ▼
      shield returns
```

Cost escalates within a rolling hour: first entry free, then 1, 2, 3 questions, plateauing at 3.

---

## Design principles

**1. Gate at launch, never mid-session.** Friction lands at a natural boundary. The app never interrupts an in-progress scroll.

**2. The gate is retrieval, not learning.** It serves items already seen, from the user's review queue. New material is introduced only in the calm in-app session, never at the moment of least patience. This is what keeps gate answers under ~15 seconds.

**3. Gate on engagement, not correctness.** A wrong answer still grants entry, just less of it. Never lock someone out for being bad at the thing they're learning.

**4. Tax intent, not time.** First entry in an hour is free. The fourth is expensive. Checking a message and starting a binge are different behaviors.

**5. The user sets their own tax.** Pass length and question count are user-configurable. Self-imposed friction is tolerated; imposed friction gets deleted.

**6. Reps, not tolls.** Progress must visibly accumulate or the questions read as pure punishment.

---

## Design problems and how they're handled

Recorded because the reasoning is the interesting part of this project.

**Cognitive load at the worst moment.** A full SAT reading question is 30 to 90 seconds of hard work demanded when executive function is lowest. Handled by tiering the item bank: `gate` items (vocabulary in context, single-sentence grammar, one-step algebra, formula recall) target under 15 seconds. `session` items (reading passages, multi-step math) are never served at the gate.

**Free guessing.** If a wrong answer still grants entry, tapping randomly is optimal. Handled two ways: a wrong answer grants a 90-second pass instead of 5 minutes, and it shortens the review interval so the item returns sooner. Guessing costs future gate time rather than triggering a lockout. A sub-2-second answer is discarded entirely and the question re-serves.

**Escalation vs the escape hatch.** A full-day disable is a prize worth grinding for, which pushes the heaviest user toward turning the app off. There is no day pass. The 10-question quiz buys a 2-hour **extended pass**, once per day, with a cooldown before it activates.

**Self-selection.** Students who install a self-imposed blocker are already motivated, so the pilot will flatter itself. Not fixable, so it's measured: signup records a `cohort` field, and the pilot recruits both volunteers and a few skeptics. Retention is reported separately.

**Friction with no counterweight.** Every mechanic here is unpleasant and uninstalling is one tap. The cheap half of the motivation layer (streak, questions-answered total) moves into M2 so the pilot is not testing pure friction.

---

## Platform notes

### iOS

- `com.apple.developer.family-controls` is granted by request, not by checkbox, and requires a paid Apple Developer Program membership. Development builds can generally run on your own device; **distribution, including TestFlight, requires approval.** File before writing Swift.
- Use `.individual` authorization. The user shields their own device.
- The shield is drawn by `ShieldConfigurationExtension`: title, subtitle, icon, up to two buttons. It cannot render a quiz. `ShieldActionExtension` opens the main app, where the quiz runs.
- Pass expiry is a `DeviceActivityEvent` whose threshold equals the pass length. Thresholds under ~5 minutes are unreliable, so **5 minutes is the iOS floor**. The 90-second wrong-answer pass is Android-only; on iOS a wrong answer grants the floor with a shorter review interval as the penalty instead.
- `DeviceActivitySchedule` minimum interval is 15 minutes. Use one day-long schedule and express all timing as event thresholds inside it.
- The monitor extension has roughly a 6 MB memory budget and cannot be relied on for network calls. It writes one shield command to a named `ManagedSettingsStore` shared via App Group.
- Threshold delivery is unreliable (early fires, missed fires). Treat `eventDidReachThreshold` as a wake-up signal, not proof time elapsed. Backstop with a foreground recheck of `pass_expires_at`.
- Screen Time does not work in the Simulator. Physical device only.
- A mismatched App Group identifier across targets is the most common cause of shields that look applied but never take effect.

**Managed accounts.** A Child Account is required under 13 and available up to 18. At 13-17 a parent can set and lock a Screen Time passcode, and the teen needs the organizer's permission to leave the family group. If a tester has a parent-held passcode they don't know, they cannot authorize this app. Onboarding must detect and explain this rather than dead-ending.

### Android

- A foreground service polls `UsageStatsManager` for the current foreground package and launches a full-screen Activity over blocked apps.
- **No `AccessibilityService`.** See `docs/decisions/0002`.
- `PACKAGE_USAGE_STATS` and `SYSTEM_ALERT_WINDOW` must be granted by hand in Settings.
- Poll-based detection means the gate can appear a second or two after launch.

### Threat model

Friction, not enforcement. Uninstalling defeats it and no defense is planned. Pass state is server-authoritative so it survives reboot, force-stop, and local tampering. That is the whole guarantee.

---

## Repo layout

```
gatekeeper/
├─ .coderabbit.yaml            PR review config
├─ .github/workflows/ci.yml    analyze + test on PR
├─ app/
│  ├─ pubspec.yaml
│  ├─ assets/questions.json    M1 seed bank
│  ├─ lib/
│  │  ├─ main.dart
│  │  ├─ models/
│  │  │  ├─ question.dart      tier: gate | session
│  │  │  └─ answer_result.dart correct | incorrect | tooFast
│  │  ├─ data/
│  │  │  ├─ question_repository.dart
│  │  │  └─ review_queue.dart  spaced repetition
│  │  ├─ services/
│  │  │  ├─ pass_service.dart  pass length + escalation
│  │  │  └─ gate_channel.dart  MethodChannel bridge
│  │  └─ screens/
│  │     ├─ gate_screen.dart   shown over the blocked app
│  │     └─ home_screen.dart   calm surface, new material
│  └─ android/app/src/main/
│     ├─ AndroidManifest.snippet.xml
│     └─ kotlin/com/gatekeeper/app/
│        ├─ MainActivity.kt
│        ├─ GateActivity.kt
│        ├─ GatekeeperService.kt
│        └─ UsageMonitor.kt
├─ backend/supabase/migrations/0001_init.sql
├─ pipeline/src/generate.py
└─ docs/decisions/             ADRs
```

---

## Running this

An iOS app cannot be containerized. Docker covers the backend and pipeline. The mobile app needs a real toolchain and blocking needs a real device.

### Tier 1: watch it (30 seconds)

`docs/demo.mp4` shows the Android gate firing and clearing. **Recommended path for reviewers.** Interception cannot be shown in a browser or simulator.

### Tier 2: quiz UI in a browser (2 minutes)

```bash
git clone https://github.com/<you>/gatekeeper.git
cd gatekeeper/app
flutter pub get
flutter run -d chrome --dart-define=DEMO_MODE=true
```

Bundled questions, no backend, no auth. No blocking, because a browser cannot block anything.

### Tier 3: full local stack (15 minutes)

```bash
cd backend
cp .env.example .env
supabase start
supabase db reset
supabase functions serve
```

Studio at `http://localhost:54323`. Then:

```bash
cd ../app
flutter run \
  --dart-define=SUPABASE_URL=http://10.0.2.2:54321 \
  --dart-define=SUPABASE_ANON_KEY=<from .env>
```

`10.0.2.2` is host loopback from the Android emulator.

### Tier 4: Android on device

```bash
cd app
flutter build apk --debug
adb install build/app/outputs/flutter-apk/app-debug.apk
```

Grant both by hand:

1. Settings → Apps → Special app access → **Usage access** → Gatekeeper
2. Settings → Apps → Special app access → **Display over other apps** → Gatekeeper

```bash
adb logcat -s Gatekeeper
```

### Tier 5: iOS

**This will not build for you.** Needs macOS with Xcode 15+, a physical device, and Family Controls approved for your own team ID. The entitlement is not transferable.

---

## Configuration

| Variable | Where | Default |
| --- | --- | --- |
| `SUPABASE_URL` / `SUPABASE_ANON_KEY` | app | |
| `DEMO_MODE` | app | true |
| `ANTHROPIC_API_KEY` | pipeline | never shipped in the app |
| `PASS_LENGTH_MIN` | user-set | 5 (iOS floor 5) |
| `SHORT_PASS_SEC` | remote | 90 (Android only) |
| `GUESS_THRESHOLD_SEC` | remote | 2 |
| `FREE_ENTRIES_PER_HOUR` | remote | 1 |
| `ESCALATION_CURVE` | remote | 1,2,3 then plateau |
| `EXTENDED_PASS_HOURS` | remote | 2, once per day |

Every default is an opening guess, not a finding.

---

## Content

Questions are generated, not copied. Official practice material is used **locally, as a reference set for prompt tuning only**, and `pipeline/reference/` is gitignored. It is free to download but not openly licensed; question text is copyrighted, formats and skill taxonomies are not.

Pipeline: generate against the published taxonomy → embedding similarity check → programmatic answer-key verification → land as `reviewed = false` → human approval before circulation.

"SAT" is a registered trademark of the College Board. Used descriptively. No affiliation claimed.

---

## Motivation layer

- **Streak and questions-answered total** (M2). Tied to days studied, never days scrolled. Streak insurance so one bad day is not permanent churn.
- **Progress view**: per-skill accuracy, trend over time.
- **Manual weekly share** before any social feature. A summary card the user sends via iMessage themselves. No linked accounts, nothing through the backend, zero privacy surface. If people share it, the mechanic is validated.
- **Accountability partner**, only if the manual share validates it. Opt-in both sides, one partner, weekly aggregates only, no per-app breakdown, no timestamps, one-tap revoke.

**No leaderboards.** They demotivate everyone outside the top few, and ranking on questions answered would reward the heaviest scroller.

---

## Known limitations

- Uninstalling removes the block. No defense planned.
- Android detection is poll-based and lags launch slightly.
- iOS pass expiry depends on unreliable system callbacks, backstopped by a foreground recheck.
- Users on a parent-locked Screen Time passcode cannot authorize the app alone.
- No user validation yet. Every retention assumption here is a hypothesis.

---

## Roadmap

Everything before M3 is platform-independent and proceeds while the entitlement request is pending.

- [ ] **Week 0.** Paid Apple Developer account. File Family Controls request. Survey testers: open Settings → Screen Time, does it ask for a passcode?
- [ ] **M1.** Flutter gate UI, seed question bank, review queue, pass and escalation logic. Android service, launch detection, full-screen gate, in-memory pass. Ends with a demo video.
- [ ] **M2.** Supabase schema, server-side grading, pass state survives reboot. Retention and cohort instrumentation. Streak counter. ~300 reviewed questions generated.
- [ ] **M3.** iOS: authorization, `FamilyActivityPicker`, shield config, shield action routing, threshold re-shield with foreground backstop.
- [ ] **M4.** Extended pass quiz, progress view, manual weekly share.
- [ ] **M5.** TestFlight pilot, 10+ users, two weeks. Retune against real retention.

**Stop line: M2 is the deliverable.** M3 onward happens only if the pilot shows retention worth building on. This is written down deliberately.
