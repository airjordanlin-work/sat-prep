import '../models/question.dart';

/// Spaced-repetition queue. This is the structural fix that makes the
/// gate fast: it serves items the user has already seen, so answering
/// is retrieval rather than learning.
///
/// A wrong answer shortens the interval, which is what makes random
/// guessing cost the user future gate time instead of being free.
class ReviewItem {
  final String questionId;
  DateTime dueAt;
  int intervalMinutes;
  int consecutiveCorrect;

  ReviewItem({
    required this.questionId,
    required this.dueAt,
    this.intervalMinutes = 10,
    this.consecutiveCorrect = 0,
  });
}

class ReviewQueue {
  final Map<String, ReviewItem> _items = {};

  /// TODO(M1): implement.
  /// Return the item with the earliest dueAt that is <= now.
  /// If nothing is due, fall back to introducing a new gate-tier
  /// question so the gate always has something to serve.
  Question? nextDue(DateTime now, List<Question> gatePool) {
    throw UnimplementedError();
  }

  /// TODO(M1): implement.
  /// Correct   -> consecutiveCorrect++, interval grows (start x2.5)
  /// Incorrect -> consecutiveCorrect = 0, interval resets to ~10 min
  /// Cap the interval so items do not disappear for weeks.
  void record(String questionId, {required bool correct, required DateTime now}) {
    throw UnimplementedError();
  }
}
