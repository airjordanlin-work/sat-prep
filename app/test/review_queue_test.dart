import 'package:flutter_test/flutter_test.dart';
import 'package:strolle/data/review_queue.dart';
import 'package:strolle/models/question.dart';

Question q(String id) => Question(
      id: id,
      tier: QuestionTier.gate,
      prompt: 'stub $id',
      choices: const ['a', 'b'],
      correctIndex: 0,
    );

void main() {
  final t0 = DateTime(2026, 1, 1, 12, 0);

  group('record', () {
    test('a correct answer pushes the item further out', () {
      final queue = ReviewQueue();
      queue.record('a', correct: true, now: t0);
      final first = queue.debugItem('a')!.intervalMinutes;

      queue.record('a', correct: true, now: t0);
      final second = queue.debugItem('a')!.intervalMinutes;

      expect(second, greaterThan(first));
    });

    test('a wrong answer brings the item back soon', () {
      final queue = ReviewQueue();
      for (var i = 0; i < 5; i++) {
        queue.record('a', correct: true, now: t0);
      }
      final grown = queue.debugItem('a')!.intervalMinutes;

      queue.record('a', correct: false, now: t0);
      final reset = queue.debugItem('a')!.intervalMinutes;

      expect(reset, lessThan(grown));
      expect(reset, lessThanOrEqualTo(15));
    });

    test('a wrong answer clears the correct streak', () {
      final queue = ReviewQueue();
      queue.record('a', correct: true, now: t0);
      queue.record('a', correct: false, now: t0);
      expect(queue.debugItem('a')!.consecutiveCorrect, 0);
    });

    test('dueAt is set forward from now by the interval', () {
      final queue = ReviewQueue();
      queue.record('a', correct: true, now: t0);
      final item = queue.debugItem('a')!;
      expect(item.dueAt.difference(t0).inMinutes, item.intervalMinutes);
    });

    test('the interval is capped so items do not vanish for weeks', () {
      final queue = ReviewQueue();
      for (var i = 0; i < 40; i++) {
        queue.record('a', correct: true, now: t0);
      }
      // Pick your own cap; this asserts one exists.
      expect(queue.debugItem('a')!.intervalMinutes, lessThanOrEqualTo(60 * 24 * 7));
    });
  });

  group('nextDue', () {
    test('returns the most overdue item first', () {
      final pool = [q('a'), q('b')];
      final queue = ReviewQueue();
      queue.record('a', correct: false, now: t0);           // due sooner
      queue.record('b', correct: true, now: t0);            // due later

      final later = t0.add(const Duration(days: 1));
      expect(queue.nextDue(later, pool)!.id, 'a');
    });

    test('introduces an unseen question when nothing is due', () {
      final pool = [q('a'), q('b')];
      final queue = ReviewQueue();
      queue.record('a', correct: true, now: t0);

      // One minute later, 'a' is not due yet.
      final soon = t0.add(const Duration(minutes: 1));
      expect(queue.nextDue(soon, pool)!.id, 'b');
    });

    test('falls back to the least-recently-due item when the pool is exhausted',
        () {
      final pool = [q('a')];
      final queue = ReviewQueue();
      queue.record('a', correct: true, now: t0);

      final soon = t0.add(const Duration(minutes: 1));
      // The gate must always have something to serve.
      expect(queue.nextDue(soon, pool), isNotNull);
    });
  });
}