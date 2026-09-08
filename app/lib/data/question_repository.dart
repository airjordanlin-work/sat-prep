import '../models/answer_result.dart';
import '../models/progress.dart';
import '../models/question.dart';
import '../services/pass_service.dart';

/// STUB. This satisfies the call sites in `main.dart`, `home_screen.dart`,
/// and `gate_screen.dart` so the app links and runs today, but it does
/// none of the real work yet:
///
///   - `load()` should read `assets/questions.json` into [Question]
///     objects instead of using the fixed `_gateSample` list below.
///   - `sessionSummary()` / `skillStats()` should derive their return
///     values from the real review queue instead of sample data.
///   - `nextGateItem()` should pull the next *due* gate-tier item from
///     the spaced-repetition queue (`data/review_queue.dart`, not yet
///     written), not cycle a fixed list.
///   - `recordAnswer()` should actually update that queue — shorten the
///     interval on incorrect, extend it on correct, and do nothing at
///     all on tooFast (per the README, a discarded attempt isn't a rep).
///   - `registerEntryAndGetCost()`'s rolling-hour window is in-memory
///     only, so it resets on every process restart. The README's threat
///     model requires pass/entry state to be server-authoritative and
///     survive force-stop — this needs real persistence before M2.
///
/// If you already have a real `QuestionRepository`, tell me its actual
/// shape and I'll conform the screens to that instead of this stub.
class QuestionRepository {
  QuestionRepository();

  bool _loaded = false;
  int _gateCursor = 0;
  final List<DateTime> _recentEntries = [];

  Future<void> load() async {
    // TODO(M1): read and parse assets/questions.json.
    _loaded = true;
  }

  SessionQueueSummary sessionSummary() {
    _assertLoaded();
    return SessionQueueSummary.sample();
  }

  List<SkillStat> skillStats() {
    _assertLoaded();
    return SkillStat.sampleSet();
  }

  /// Next gate-tier item to serve. Cycles a fixed sample list for now.
  Question nextGateItem() {
    _assertLoaded();
    final item = _gateSample[_gateCursor % _gateSample.length];
    _gateCursor++;
    return item;
  }

  /// Records the outcome of a scored gate answer. No-op stub — real
  /// implementation writes back to the review queue.
  void recordAnswer(Question question, AnswerResult result) {
    _assertLoaded();
    // TODO(M1): update the review queue's interval for `question.id`.
  }

  /// Registers a new entry attempt against the rolling one-hour window
  /// and returns how many questions this entry costs, per
  /// [passService]'s escalation curve.
  int registerEntryAndGetCost(PassService passService) {
    final now = DateTime.now();
    _recentEntries.removeWhere(
      (t) => now.difference(t) > const Duration(hours: 1),
    );
    _recentEntries.add(now);
    return passService.costForEntry(_recentEntries.length);
  }

  void _assertLoaded() {
    assert(_loaded, 'QuestionRepository.load() must complete before use.');
  }

  static final List<Question> _gateSample = [
    Question(
      id: 'g1',
      tier: QuestionTier.gate,
      prompt: 'Solve for x: 3x + 7 = 22',
      choices: ['3', '5', '7', '9'],
      correctIndex: 1,
      explanation:
          'Subtract 7 from both sides to get 3x = 15, then divide by 3.',
    ),
    Question(
      id: 'g2',
      tier: QuestionTier.gate,
      prompt: 'In context, "austere" most nearly means:',
      choices: ['Lavish', 'Severely simple', 'Cheerful', 'Talkative'],
      correctIndex: 1,
      explanation: '"Austere" describes something stark or without ornament.',
    ),
    Question(
      id: 'g3',
      tier: QuestionTier.gate,
      prompt: 'Which is correct: "Neither the coach nor the players ___ '
          'ready."',
      choices: ['is', 'are', 'was', 'be'],
      correctIndex: 1,
      explanation: 'With "neither/nor," the verb agrees with the nearer '
          'subject — "players" is plural, so "are."',
    ),
    Question(
      id: 'g4',
      tier: QuestionTier.gate,
      prompt: 'What is 15% of 60?',
      choices: ['6', '9', '12', '15'],
      correctIndex: 1,
      explanation: '15% = 0.15, and 0.15 × 60 = 9.',
    ),
  ];
}