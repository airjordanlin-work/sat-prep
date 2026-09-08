import 'package:flutter/material.dart';
import '../data/question_repository.dart';
import '../models/answer_result.dart';
import '../models/question.dart';
import '../services/gate_channel.dart';
import '../services/pass_service.dart';
import '../theme/palette.dart';

enum _Phase { question, feedback, granted }

/// The interruption. Shown full-screen over a blocked app the instant it
/// launches (see README's core loop). Everything here follows the
/// design principles directly:
///
///   - Gate on engagement, not correctness (#3): a wrong answer still
///     grants entry, just a shorter one.
///   - Tax intent, not time (#4): [PassService.costForEntry] decides how
///     many questions this particular entry costs, via the rolling-hour
///     count in `QuestionRepository.registerEntryAndGetCost`.
///   - A sub-threshold answer doesn't count at all — it's discarded and
///     the same item is re-served, so tapping randomly fast isn't a way
///     to skip the cost.
///
/// [passService] is exposed for tests/tuning; leave it at its default
/// in real usage.
class GateScreen extends StatefulWidget {
  const GateScreen({
    super.key,
    required this.repo,
    required this.blockedPackage,
    this.passService = const PassService(),
  });

  final QuestionRepository repo;
  final String blockedPackage;
  final PassService passService;

  @override
  State<GateScreen> createState() => _GateScreenState();
}

class _GateScreenState extends State<GateScreen> {
  late int _requiredCount;
  int _answeredCount = 0;
  late Question _current;
  int? _selectedIndex;
  AnswerResult? _lastResult;
  String? _tooFastNotice;
  _Phase _phase = _Phase.question;
  final Stopwatch _stopwatch = Stopwatch();

  @override
  void initState() {
    super.initState();
    _requiredCount = widget.repo.registerEntryAndGetCost(widget.passService);
    if (_requiredCount == 0) {
      // Free entry this hour — no quiz, full pass. See design principle
      // #4: "first entry free."
      _phase = _Phase.granted;
      _lastResult = AnswerResult.correct;
    } else {
      _current = widget.repo.nextGateItem();
      _stopwatch.start();
    }
  }

  @override
  void dispose() {
    _stopwatch.stop();
    super.dispose();
  }

  void _choose(int index) {
    if (_stopwatch.elapsed < widget.passService.guessThreshold) {
      setState(() => _tooFastNotice = 'Answered too fast — try again.');
      _stopwatch
        ..reset()
        ..start();
      return;
    }
    _stopwatch.stop();

    final result =
        _current.isCorrect(index) ? AnswerResult.correct : AnswerResult.incorrect;
    widget.repo.recordAnswer(_current, result);

    setState(() {
      _selectedIndex = index;
      _lastResult = result;
      _tooFastNotice = null;
      _phase = _Phase.feedback;
    });
  }

  void _continue() {
    _answeredCount++;
    if (_answeredCount >= _requiredCount) {
      setState(() => _phase = _Phase.granted);
      return;
    }
    setState(() {
      _current = widget.repo.nextGateItem();
      _selectedIndex = null;
      _phase = _Phase.question;
      _stopwatch
        ..reset()
        ..start();
    });
  }

  Future<void> _finish() async {
    final duration = widget.passService.passLengthFor(
      _lastResult ?? AnswerResult.correct,
    );
    await GateChannel.grantPass(duration);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // The gate is a boundary, not a scrollable screen — back button
      // shouldn't quietly dismiss it without granting or denying a pass.
      canPop: false,
      child: Scaffold(
        backgroundColor: AppPalette.paper,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: switch (_phase) {
              _Phase.question => _buildQuestion(),
              _Phase.feedback => _buildFeedback(),
              _Phase.granted => _buildGranted(),
            },
          ),
        ),
      ),
    );
  }

  Widget _buildQuestion() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_requiredCount > 1)
          Text(
            'Question ${_answeredCount + 1} of $_requiredCount',
            style: const TextStyle(
              fontSize: 13,
              color: AppPalette.inkMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        const SizedBox(height: 16),
        Text(
          _current.prompt,
          style: const TextStyle(
            fontFamily: 'Georgia',
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: AppPalette.ink,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 28),
        for (var i = 0; i < _current.choices.length; i++) ...[
          _ChoiceButton(label: _current.choices[i], onTap: () => _choose(i)),
          const SizedBox(height: 12),
        ],
        if (_tooFastNotice != null) ...[
          const SizedBox(height: 4),
          Text(
            _tooFastNotice!,
            style: const TextStyle(fontSize: 13, color: AppPalette.down),
          ),
        ],
        const Spacer(),
        const Text(
          'A wrong answer still gets you in — just for less time.',
          style: TextStyle(fontSize: 12, color: AppPalette.inkMuted),
        ),
      ],
    );
  }

  Widget _buildFeedback() {
    final correct = _lastResult == AnswerResult.correct;
    final tint = correct ? AppPalette.accent : AppPalette.down;
    final isLastQuestion = _answeredCount + 1 >= _requiredCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              correct ? Icons.check_circle_outline : Icons.cancel_outlined,
              color: tint,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              correct ? 'Correct' : 'Not quite',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: tint,
              ),
            ),
          ],
        ),
        if (!correct && _current.explanation != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: tint, width: 3)),
            ),
            child: Text(
              _current.explanation!,
              style: const TextStyle(
                fontSize: 14.5,
                color: AppPalette.ink,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "It'll come back around sooner because of this one.",
            style: TextStyle(fontSize: 12.5, color: AppPalette.inkMuted),
          ),
        ],
        const Spacer(),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _continue,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppPalette.accent,
              foregroundColor: AppPalette.paper,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: Text(isLastQuestion ? 'Continue' : 'Next question'),
          ),
        ),
      ],
    );
  }

  Widget _buildGranted() {
    final duration = widget.passService.passLengthFor(
      _lastResult ?? AnswerResult.correct,
    );
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.lock_open, color: AppPalette.accent, size: 26),
        const SizedBox(height: 16),
        Text(
          "You're in for ${_formatDuration(duration)}.",
          style: const TextStyle(
            fontFamily: 'Georgia',
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: AppPalette.ink,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'The gate comes back when the pass runs out.',
          style: TextStyle(fontSize: 14, color: AppPalette.inkMuted),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _finish,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppPalette.accent,
              foregroundColor: AppPalette.paper,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: const Text('Done'),
          ),
        ),
      ],
    );
  }
}

class _ChoiceButton extends StatelessWidget {
  const _ChoiceButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            border: Border.all(color: AppPalette.hairline),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            label,
            style: const TextStyle(fontSize: 15.5, color: AppPalette.ink),
          ),
        ),
      ),
    );
  }
}

String _formatDuration(Duration d) {
  if (d.inSeconds < 60) return '${d.inSeconds} seconds';
  final minutes = d.inMinutes;
  return '$minutes minute${minutes == 1 ? '' : 's'}';
}