import '../models/answer_result.dart';

/// Owns pass length and escalating cost.
///
/// Config only. Mutable session state (current pass expiry, the rolling
/// entry window) deliberately does not live here, which is what lets the
/// constructor stay const. At M2 that state moves server-side anyway.
/// Keeping this class pure makes it trivially unit-testable.
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

  /// Questions owed on each successive entry past the free one.
  /// Plateaus at the last value rather than climbing without bound:
  /// absurd cost drives uninstalls, not compliance.
  final List<int> escalationCurve;

  Duration get guessThreshold => Duration(seconds: guessThresholdSeconds);

  /// [entryNumberThisHour] is 1-indexed.
  int costForEntry(int entryNumberThisHour) {
    final index = entryNumberThisHour - freeEntriesPerHour - 1;
    if (index < 0) return 0;
    if (index >= escalationCurve.length) return escalationCurve.last;
    return escalationCurve[index];
  }

  /// Pass length for a *scored* answer. Never call with
  /// [AnswerResult.tooFast]: a discarded attempt grants nothing and the
  /// caller must re-serve instead.
  Duration passLengthFor(AnswerResult result) {
    assert(
      result != AnswerResult.tooFast,
      'tooFast answers are discarded, not scored.',
    );
    return result == AnswerResult.correct
        ? Duration(minutes: passLengthMinutes)
        : Duration(seconds: shortPassSeconds);
  }
}
