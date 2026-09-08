import 'package:flutter/material.dart';
import '../data/question_repository.dart';
import '../models/progress.dart';
import '../theme/palette.dart';

/// The calm surface. New material lives here — never at the gate.
///
/// Per the README's design principle #2 ("The gate is retrieval, not
/// learning"), this screen is where `session`-tier items (reading
/// passages, multi-step math) get introduced. Nothing served here is
/// timed or graded under pressure; a `question` only becomes eligible
/// for the gate's spaced-repetition queue once the user has seen it
/// here first.
///
/// Reads its data from [repo] (see `data/question_repository.dart` — a
/// stub as of this file). [queueSummary] and [skillStats] are optional
/// overrides for previews/tests; leave them null in real usage.
class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.repo,
    this.queueSummary,
    this.skillStats,
    this.onStartSession,
  });

  final QuestionRepository repo;
  final SessionQueueSummary? queueSummary;
  final List<SkillStat>? skillStats;
  final VoidCallback? onStartSession;

  @override
  Widget build(BuildContext context) {
    final summary = queueSummary ?? repo.sessionSummary();
    final stats = skillStats ?? repo.skillStats();

    return Scaffold(
      backgroundColor: AppPalette.paper,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
          children: [
            _Header(),
            const SizedBox(height: 32),
            _SessionInvite(summary: summary, onStartSession: onStartSession),
            const SizedBox(height: 40),
            _ProgressSection(stats: stats),
            const SizedBox(height: 40),
            _WeeklyRepsFooter(summary: summary),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _formatDate(DateTime.now()),
          style: const TextStyle(
            fontSize: 13,
            color: AppPalette.inkMuted,
            letterSpacing: 0.1,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'New material',
          style: TextStyle(
            fontFamily: 'Georgia',
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: AppPalette.ink,
            letterSpacing: -0.3,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          "Nothing you see here shows up at the gate until you've met it "
          'once, on your own time.',
          style: TextStyle(
            fontSize: 14,
            color: AppPalette.inkMuted,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Session invite
// ---------------------------------------------------------------------------

class _SessionInvite extends StatelessWidget {
  const _SessionInvite({required this.summary, this.onStartSession});

  final SessionQueueSummary summary;
  final VoidCallback? onStartSession;

  @override
  Widget build(BuildContext context) {
    final callback = onStartSession ??
        () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Session flow not wired up yet.')),
          );
        };

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 22),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppPalette.hairline),
          bottom: BorderSide(color: AppPalette.hairline),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  summary.totalDue == 0
                      ? 'Queue is empty'
                      : '${summary.totalDue} due for a first look',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppPalette.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  summary.dueDescription,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: AppPalette.inkMuted,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: summary.totalDue == 0 ? null : callback,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppPalette.accent,
              disabledBackgroundColor: AppPalette.hairline,
              foregroundColor: AppPalette.paper,
              elevation: 0,
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: const Text(
              'Start session',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Progress
// ---------------------------------------------------------------------------

class _ProgressSection extends StatelessWidget {
  const _ProgressSection({required this.stats});

  final List<SkillStat> stats;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "How you're doing",
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppPalette.ink,
          ),
        ),
        const SizedBox(height: 18),
        for (final stat in stats) ...[
          _SkillBar(stat: stat),
          const SizedBox(height: 18),
        ],
      ],
    );
  }
}

class _SkillBar extends StatelessWidget {
  const _SkillBar({required this.stat});

  final SkillStat stat;

  @override
  Widget build(BuildContext context) {
    final trendUp = stat.trendDelta >= 0;
    final trendColor = trendUp ? AppPalette.accent : AppPalette.down;
    final trendLabel =
        '${trendUp ? '+' : ''}${(stat.trendDelta * 100).round()}% this week';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              stat.name,
              style: const TextStyle(
                fontSize: 14.5,
                color: AppPalette.ink,
                fontWeight: FontWeight.w500,
              ),
            ),
            Row(
              children: [
                Icon(
                  trendUp ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 12,
                  color: trendColor,
                ),
                const SizedBox(width: 3),
                Text(
                  trendLabel,
                  style: TextStyle(
                    fontSize: 12,
                    color: trendColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: SizedBox(
            height: 6,
            child: Stack(
              children: [
                Container(color: AppPalette.hairline),
                FractionallySizedBox(
                  widthFactor: stat.accuracy.clamp(0.0, 1.0),
                  child: Container(color: AppPalette.accent),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${(stat.accuracy * 100).round()}% accuracy · ${stat.repsLogged} reps logged',
          style: const TextStyle(fontSize: 12, color: AppPalette.inkMuted),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Weekly reps footer
// ---------------------------------------------------------------------------

class _WeeklyRepsFooter extends StatelessWidget {
  const _WeeklyRepsFooter({required this.summary});

  final SessionQueueSummary summary;

  static const _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${summary.repsThisWeek} reps this week',
          style: const TextStyle(
            fontSize: 13,
            color: AppPalette.inkMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: List.generate(7, (i) {
            final active = summary.activeDays[i];
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Column(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: active ? AppPalette.accent : Colors.transparent,
                      border: Border.all(
                        color: active ? AppPalette.accent : AppPalette.hairline,
                        width: 1.2,
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _dayLabels[i],
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppPalette.inkMuted,
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }
}

String _formatDate(DateTime date) {
  const weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
}