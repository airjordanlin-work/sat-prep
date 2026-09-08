import '../models/answer_result.dart';

/// Owns pass length and escalating cost.
///
/// M1: in-memory, client-side. M2: this whole class becomes a thin
/// client over /grade-attempt and /pass-status. Nothing here may stay
/// client-authoritative once the backend exists, because a reboot
/// would otherwise hand out a free pass.
class PassService {
  static const fullPass = Duration(minutes: 5);
  static const shortPass = Duration(seconds: 90);
  static const guessThreshold = Duration(seconds: 2);

  /// Questions owed on the Nth entry within a rolling hour.
  /// First entry is free. Then 1, 2, 3, and plateaus at 3.
  static const escalation = [0, 1, 2, 3];

  DateTime? _passExpiresAt;
  final List<DateTime> _recentEntries = [];

  bool isPassActive(DateTime now) =>
      _passExpiresAt != null && now.isBefore(_passExpiresAt!);

  /// TODO(M1): implement.
  /// Drop entries older than one hour, then index into [escalation],
  /// clamping to the last element.
  int questionsOwed(DateTime now) {
    throw UnimplementedError();
  }

  /// TODO(M1): implement.
  /// Under guessThreshold  -> AnswerOutcome.tooFast, no pass, re-serve
  /// Correct               -> fullPass
  /// Incorrect             -> shortPass, explanation attached
  AnswerResult submit({
    required bool correct,
    required Duration timeTaken,
    required String explanation,
    required DateTime now,
  }) {
    throw UnimplementedError();
  }
}
