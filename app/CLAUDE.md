# Strolle frontend — context for whoever's working in app/

This file loads automatically alongside the root CLAUDE.md when working
from inside `app/`. If you're a person reading this instead of an
agent: same rules apply to you.

## Who this is for
Frontend/UI work only: widgets, screens, the question bank, theming.
Not review queue logic, not pass service logic, not backend, not
Android/iOS native code. See "Don't touch" below.

## The one rule that makes parallel work possible
**Every widget you build takes its data as constructor parameters and
calls a callback on interaction. It never reads from a service, never
holds business logic, never decides anything.**

```dart
class QuestionCard extends StatelessWidget {
  final String prompt;
  final List<String> choices;
  final void Function(int) onChoiceTapped;
}
```

Not this:

```dart
class QuestionCard extends StatelessWidget {
  // reads PassService, decides if answer is right, etc. — NO
}
```

Why: it means backend/logic changes never break your widgets, and your
widget changes never risk corrupting app state. It's also what makes
your PRs reviewable in isolation.

## Don't touch
`lib/data/review_queue.dart`, `lib/services/pass_service.dart`,
`lib/services/gate_channel.dart`, anything under `android/`, anything
under `backend/`. Not a trust thing — these are the pieces where a
subtle bug is expensive and hard to catch in review. If a task seems to
require editing one of these, stop and flag it.

## Design tone (read before styling anything)
- The gate screen is seen 20+ times a day, often mid-frustration. Calm,
  fast, high contrast. No red, no "WRONG", no punitive framing — a
  wrong answer still lets the user in, so it should never look like a
  failure state.
- The home screen is the calm surface, opened voluntarily. It can
  afford warmth, a serif headline, more breathing room.
- Tap targets are 56px minimum (`AppTheme.tapTarget`), bigger than
  Material's default 48px — this gets used one-handed, in a hurry.
- Colors and text styles always come from `Theme.of(context)`, never
  hardcoded hex values or a separate constants file. This is what keeps
  the whole app from drifting into two different-looking products and
  is what makes dark mode work for free.

## Writing gate questions (`assets/questions.json`)
You're actually studying for this test, which makes you better at this
than an LLM prompted cold. Rules:

- **Answerable in under 15 seconds.** Vocabulary in context,
  single-sentence grammar/transitions, one-step algebra, formula
  recall. No reading passages — those don't belong at the gate.
- **Write questions in your own words.** Same skill, same format as a
  real SAT question, original text. Don't copy from practice tests.
- **Explanations teach the concept**, not just restate the answer.
  "Subtract 6, then divide by 3" beats "The answer is 5."
- Match the existing schema exactly (`id`, `tier`, `prompt`, `choices`,
  `correctIndex`, `explanation`). Run `flutter test` before pushing —
  a malformed entry should fail loudly, not silently break the gate.

## Testing your own work
```bash
flutter run -d chrome --dart-define=DEMO_MODE=true   # see it
flutter analyze                                       # before every push
flutter test                                          # before every push
```
Chrome only — no device or emulator needed for anything in `app/lib/widgets`
or `app/lib/screens`.

## Git
See `docs/GIT-GUIDE.md` if you haven't already. Short version: never
commit to `main` directly (it's blocked anyway), always a new branch,
small PRs, read what CodeRabbit says before asking Jordan.