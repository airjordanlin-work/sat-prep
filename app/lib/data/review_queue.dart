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

  static const _growthFactor = 2.5;
  static const _resetIntervalMinutes = 10;
  static const _capMinutes = 60 * 24 * 7; // one week

  /// Visible for testing only.
  ReviewItem? debugItem(String id) => _items[id];

  void record(String questionId,
      {required bool correct, required DateTime now}) {
    final existing = _items[questionId];
    final item = existing ??
        ReviewItem(
          questionId: questionId,
          dueAt: now,
          intervalMinutes: _resetIntervalMinutes,
        );

    if (correct) {
      item.consecutiveCorrect += 1;
      final grown = (item.intervalMinutes * _growthFactor).round();
      item.intervalMinutes = grown > _capMinutes ? _capMinutes : grown;
    } else {
      item.consecutiveCorrect = 0;
      item.intervalMinutes = _resetIntervalMinutes;
    }

    item.dueAt = now.add(Duration(minutes: item.intervalMinutes));
    _items[questionId] = item;
  }

  /// Returns the most overdue item that's due by [now], preferring the
  /// item with the earliest dueAt (most overdue first).
  ///
  /// If nothing has ever been recorded yet, or nothing due, this
  /// introduces the next question from [gatePool] the user hasn't seen
  /// yet. If every item in the pool has already been seen and none are
  /// due yet, it falls back to whichever seen item is due soonest, so
  /// the gate always has something to serve rather than returning null.
  Question? nextDue(DateTime now, List<Question> gatePool) {
    if (gatePool.isEmpty) return null;

    // 1. Anything actually due right now? Return the most overdue one.
    final due = _items.values.where((i) => !i.dueAt.isAfter(now)).toList()
      ..sort((a, b) => a.dueAt.compareTo(b.dueAt));
    if (due.isNotEmpty) {
      final match = gatePool.where((q) => q.id == due.first.questionId);
      if (match.isNotEmpty) return match.first;
    }

    // 2. Nothing due. Introduce something unseen, so new material still
    // enters the queue even when the review schedule is quiet.
    final unseen = gatePool.where((q) => !_items.containsKey(q.id));
    if (unseen.isNotEmpty) return unseen.first;

    // 3. Everything has been seen and nothing is due yet. The gate still
    // needs to serve something, so hand back whichever seen item is due
    // soonest, even though it's early.
    final all = _items.values.toList()
      ..sort((a, b) => a.dueAt.compareTo(b.dueAt));
    if (all.isEmpty) return null; // gatePool nonempty but nothing recorded
    final soonest = gatePool.where((q) => q.id == all.first.questionId);
    return soonest.isNotEmpty ? soonest.first : gatePool.first;
  }
}