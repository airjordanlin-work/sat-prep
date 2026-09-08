import '../models/answer_result.dart';

/// Owns pass length and escalating cost.
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

  DateTime? _passExpiresAt;
  final List<DateTime> _recentEntries = [];

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