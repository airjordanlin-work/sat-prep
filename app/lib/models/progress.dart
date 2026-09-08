/// View-model shapes for the home screen's session-invite and progress
/// sections. Deliberately separate from `question.dart` / the review
/// queue's internal representation — these are display summaries, not
/// storage shapes. [QuestionRepository] is responsible for deriving them
/// from the real question bank + review queue state.
library;

class SessionQueueSummary {
  SessionQueueSummary({
    required this.readingPassagesDue,
    required this.multiStepProblemsDue,
    required this.repsThisWeek,
    required this.activeDays,
  }) : assert(activeDays.length == 7);

  final int readingPassagesDue;
  final int multiStepProblemsDue;
  final int repsThisWeek;

  /// Monday through Sunday, true if at least one rep was logged that day.
  final List<bool> activeDays;

  int get totalDue => readingPassagesDue + multiStepProblemsDue;

  String get dueDescription {
    if (totalDue == 0) {
      return 'Check back after your next gate pass, or come back tomorrow.';
    }
    final parts = <String>[
      if (readingPassagesDue > 0)
        _plural(readingPassagesDue, 'reading passage'),
      if (multiStepProblemsDue > 0)
        _plural(multiStepProblemsDue, 'multi-step problem'),
    ];
    final joined =
        parts.length == 2 ? '${parts[0]} and ${parts[1]}' : parts.first;
    final verb = totalDue == 1 ? 'is' : 'are';
    return '$joined $verb ready.';
  }

  static String _plural(int n, String noun) => '$n $noun${n == 1 ? '' : 's'}';

  factory SessionQueueSummary.sample() => SessionQueueSummary(
        readingPassagesDue: 3,
        multiStepProblemsDue: 2,
        repsThisWeek: 38,
        activeDays: [true, true, false, true, true, true, false],
      );
}

class SkillStat {
  const SkillStat({
    required this.name,
    required this.accuracy,
    required this.trendDelta,
    required this.repsLogged,
  });

  final String name;

  /// 0.0–1.0
  final double accuracy;

  /// Signed fraction, e.g. 0.04 = "+4% this week".
  final double trendDelta;
  final int repsLogged;

  static List<SkillStat> sampleSet() => const [
        SkillStat(
          name: 'Reading comprehension',
          accuracy: 0.78,
          trendDelta: 0.03,
          repsLogged: 142,
        ),
        SkillStat(
          name: 'Grammar & usage',
          accuracy: 0.85,
          trendDelta: 0.01,
          repsLogged: 96,
        ),
        SkillStat(
          name: 'Algebra',
          accuracy: 0.62,
          trendDelta: -0.02,
          repsLogged: 118,
        ),
        SkillStat(
          name: 'Data analysis',
          accuracy: 0.70,
          trendDelta: 0.05,
          repsLogged: 64,
        ),
      ];
}