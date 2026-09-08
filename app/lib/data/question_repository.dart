import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/answer_result.dart';
import '../models/progress.dart';
import '../models/question.dart';
import '../services/pass_service.dart';
import 'review_queue.dart';

/// Owns the question bank and the spaced-repetition queue built on top
/// of it. This is the seam between "static content" (questions.json)
/// and "per-user state" (what's due, what's been seen) — at M2 the
/// queue's storage moves server-side, but this class's public shape
/// should not need to change when that happens.
class QuestionRepository {
  QuestionRepository();

  bool _loaded = false;
  List<Question> _all = const [];
  final ReviewQueue _queue = ReviewQueue();
  final List<DateTime> _recentEntries = [];

  Future<void> load() async {
    final raw = await rootBundle.loadString('assets/questions.json');
    final list = jsonDecode(raw) as List;
    _all = list
        .map((e) => Question.fromJson(e as Map<String, dynamic>))
        .toList();
    _loaded = true;
  }

  List<Question> get _gatePool =>
      _all.where((q) => q.tier == QuestionTier.gate).toList();

  SessionQueueSummary sessionSummary() {
    _assertLoaded();
    // TODO(M2): derive from real session-tier due counts + logged reps.
    return SessionQueueSummary.sample();
  }

  List<SkillStat> skillStats() {
    _assertLoaded();
    // TODO(M2): derive from real per-skill accuracy in the queue.
    return SkillStat.sampleSet();
  }

  /// Next gate-tier item to serve, from the real spaced-repetition
  /// queue rather than a fixed cycling list.
  Question nextGateItem() {
    _assertLoaded();
    final pool = _gatePool;
    assert(pool.isNotEmpty, 'No gate-tier questions in the bank.');
    return _queue.nextDue(DateTime.now(), pool) ?? pool.first;
  }

  /// Records the outcome of a scored gate answer against the review
  /// queue. Per the README, a tooFast attempt is discarded, not scored,
  /// so it must never reach here — callers re-serve instead.
  void recordAnswer(Question question, AnswerResult result) {
    _assertLoaded();
    assert(
      result != AnswerResult.tooFast,
      'tooFast answers are discarded, not recorded.',
    );
    _queue.record(
      question.id,
      correct: result == AnswerResult.correct,
      now: DateTime.now(),
    );
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
}