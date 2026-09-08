/// Outcome of one gate attempt.
///
/// Note there is no "denied" case. A wrong answer still grants entry,
/// it just grants less of it. See design principle 2.
enum AnswerOutcome {
  correct,      // full pass
  incorrect,    // short pass, item requeued sooner
  tooFast,      // under the guess threshold: not counted, re-serve
}

class AnswerResult {
  final AnswerOutcome outcome;
  final Duration passGranted;
  final String? explanation;

  const AnswerResult({
    required this.outcome,
    required this.passGranted,
    this.explanation,
  });
}
