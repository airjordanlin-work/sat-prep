import '../models/answer_result.dart';

/// Pure calculator for the two numbers the gate cares about: how many
/// questions a given entry costs, and how long a pass a given answer
/// earns. Deliberately stateless — the rolling-hour entry count it needs
/// as input is tracked by the caller (currently [QuestionRepository]'s
/// `registerEntryAndGetCost`), since that bookkeeping needs to survive
/// process death per the README's threat model and doesn't belong in a
/// pure calculator.
///
/// Defaults match the README's Configuration table. All of them are
/// described there as "an opening guess, not a finding" — expect these
/// to become remote-configurable rather than hardcoded.
class PassService {
  const PassService({
    this.passLengthMinutes = 5,
    this.shortPassSeconds = 90,
    this.guessThresholdSeconds = 2,
    this.freeEntriesPerHour = 1,
    this.escalationCurve = const [1, 2, 3],
  });

  final int passLengthMinutes;
  final int shortPassSeconds;
  final int guessThresholdSeconds;
  final int freeEntriesPerHour;

  /// Cost, in questions, for each entry after the free ones. Plateaus at
  /// the last value once exhausted — e.g. [1, 2, 3] means the 2nd entry
  /// this hour costs 1 question, the 3rd costs 2, the 4th and beyond
  /// cost 3.
  final List<int> escalationCurve;

  Duration get guessThreshold => Duration(seconds: guessThresholdSeconds);

  /// [entryNumberThisHour] is 1-indexed (this is the Nth entry attempt
  /// within the current rolling hour).
  int costForEntry(int entryNumberThisHour) {
    final index = entryNumberThisHour - freeEntriesPerHour - 1;
    if (index < 0) return 0;
    if (index >= escalationCurve.length) return escalationCurve.last;
    return escalationCurve[index];
  }

  /// Pass length for a *scored* answer. Never call this with
  /// [AnswerResult.tooFast] — a discarded attempt shouldn't grant
  /// anything; callers must re-serve instead.
  Duration passLengthFor(AnswerResult result) {
    assert(
      result != AnswerResult.tooFast,
      'tooFast answers are discarded, not scored — do not grant a pass off one.',
    );
    return result == AnswerResult.correct
        ? Duration(minutes: passLengthMinutes)
        : Duration(seconds: shortPassSeconds);
  }
}