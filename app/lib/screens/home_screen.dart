import 'package:flutter/material.dart';
import '../data/question_repository.dart';
import '../models/progress.dart';
import '../theme/app_theme.dart';
import 'gate_screen.dart';

/// The calm surface. New material is introduced here, never at the gate.
///
/// Design intent: a page from a well-set study journal, not a dashboard.
/// One serif headline, one clear action, then quiet data.
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
      body: SafeArea(
        child: PageBody(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
                AppTheme.gutter, 32, AppTheme.gutter, 56),
            children: [
              const _Header(),
              const SizedBox(height: 28),
              _StreakStrip(summary: summary),
              const SizedBox(height: 32),
              _SessionInvite(summary: summary, onStartSession: onStartSession),
              const SizedBox(height: 44),
              _ProgressSection(stats: stats),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        label: const Text('DEBUG: open gate'),
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => GateScreen(repo: repo, blockedPackage: 'debug'),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_formatDate(DateTime.now()).toUpperCase(), style: t.labelSmall),
        const SizedBox(height: 12),
        Text('New material', style: t.displaySmall),
        const SizedBox(height: 10),
        Text(
          "Nothing here shows up at the gate until you've met it once, "
          'on your own time.',
          style: t.bodyMedium,
        ),
      ],
    );
  }
}

/// The counterweight to friction: reps have to visibly accumulate or the
/// questions read as pure tax. Streak leads because it is the number
/// people actually protect.
class _StreakStrip extends StatelessWidget {
  const _StreakStrip({required this.summary});
  final SessionQueueSummary summary;

  static const _labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  int get _streak {
    var n = 0;
    for (final active in summary.activeDays.reversed) {
      if (!active) break;
      n++;
    }
    return n;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppTheme.radius + 2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text('$_streak',
                      style: t.displaySmall
                          ?.copyWith(fontSize: 40, color: scheme.primary)),
                  const SizedBox(width: 6),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(_streak == 1 ? 'day' : 'days',
                        style: t.bodyMedium),
                  ),
                ],
              ),
              Text('${summary.repsThisWeek} reps this week',
                  style: t.bodyMedium),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              for (var i = 0; i < 7; i++)
                Padding(
                  padding: const EdgeInsets.only(left: 7),
                  child: Column(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: summary.activeDays[i]
                              ? scheme.primary
                              : Colors.transparent,
                          border: Border.all(
                            color: summary.activeDays[i]
                                ? scheme.primary
                                : scheme.outlineVariant,
                            width: 1.3,
                          ),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(_labels[i],
                          style: t.labelSmall?.copyWith(letterSpacing: 0)),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SessionInvite extends StatelessWidget {
  const _SessionInvite({required this.summary, this.onStartSession});

  final SessionQueueSummary summary;
  final VoidCallback? onStartSession;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final empty = summary.totalDue == 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Divider(height: 1, color: scheme.outlineVariant),
        const SizedBox(height: 24),
        Text(
          empty ? 'Queue is empty' : '${summary.totalDue} due for a first look',
          style: t.headlineSmall,
        ),
        const SizedBox(height: 6),
        Text(summary.dueDescription, style: t.bodyMedium),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: empty
              ? null
              : (onStartSession ??
                  () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Session flow not wired up yet.')),
                      )),
          child: const Text('Start session'),
        ),
        const SizedBox(height: 24),
        Divider(height: 1, color: scheme.outlineVariant),
      ],
    );
  }
}

class _ProgressSection extends StatelessWidget {
  const _ProgressSection({required this.stats});
  final List<SkillStat> stats;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('HOW YOU\u2019RE DOING', style: t.labelSmall),
        const SizedBox(height: 20),
        for (final s in stats) ...[
          _SkillBar(stat: s),
          const SizedBox(height: 22),
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
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final up = stat.trendDelta >= 0;
    final trendColor = up ? scheme.primary : scheme.error;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(stat.name, style: t.titleMedium)),
            Icon(up ? Icons.arrow_upward : Icons.arrow_downward,
                size: 12, color: trendColor),
            const SizedBox(width: 3),
            Text(
              '${up ? '+' : ''}${(stat.trendDelta * 100).round()}%',
              style: t.bodyMedium
                  ?.copyWith(color: trendColor, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: stat.accuracy.clamp(0.0, 1.0)),
          duration: const Duration(milliseconds: 650),
          curve: Curves.easeOutCubic,
          builder: (context, value, _) => ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 8,
              child: Stack(
                children: [
                  Container(color: scheme.outlineVariant),
                  FractionallySizedBox(
                    widthFactor: value,
                    child: Container(color: scheme.primary),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${(stat.accuracy * 100).round()}% accuracy  \u00b7  '
          '${stat.repsLogged} reps',
          style: t.bodyMedium?.copyWith(fontSize: 13),
        ),
      ],
    );
  }
}

String _formatDate(DateTime d) {
  const w = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];
  const m = ['January','February','March','April','May','June','July',
             'August','September','October','November','December'];
  return '${w[d.weekday - 1]}, ${m[d.month - 1]} ${d.day}';
}