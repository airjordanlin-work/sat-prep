import 'package:flutter/material.dart';
import '../data/question_repository.dart';
import '../models/answer_result.dart';
import '../models/question.dart';
import '../services/gate_channel.dart';
import '../services/pass_service.dart';
import '../theme/app_theme.dart';
import '../widgets/explanation_panel.dart';
import '../widgets/question_card.dart';

enum _Phase { answering, revealed }

/// The screen shown over the blocked app.
///
/// Not dismissible. PopScope blocks the back gesture; the Android side
/// also excludes the Activity from recents.
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
  _Phase _phase = _Phase.answering;
  AnswerResult? _lastResult;
  bool _tooFastNotice = false;

  final _stopwatch = Stopwatch();

  @override
  void initState() {
    super.initState();
    _requiredCount = widget.repo.registerEntryAndGetCost(widget.passService);
    if (_requiredCount == 0) {
      // Free entry this hour. Grant immediately, do not show a question.
      WidgetsBinding.instance.addPostFrameCallback((_) => _grantAndClose(
            widget.passService.passLengthFor(AnswerResult.correct),
          ));
    }
    _serveNext();
  }

  void _serveNext() {
    setState(() {
      _current = widget.repo.nextGateItem();
      _selectedIndex = null;
      _phase = _Phase.answering;
      _lastResult = null;
      _stopwatch
        ..reset()
        ..start();
    });
  }

  void _choose(int index) {
    _stopwatch.stop();
    final elapsed = _stopwatch.elapsed;

    // Under the guess threshold: discard the attempt entirely and
    // re-serve. Not a penalty, just not a rep.
    if (elapsed < widget.passService.guessThreshold) {
      setState(() => _tooFastNotice = true);
      Future.delayed(const Duration(milliseconds: 900), () {
        if (!mounted) return;
        setState(() => _tooFastNotice = false);
        _serveNext();
      });
      return;
    }

    final result = _current.isCorrect(index)
        ? AnswerResult.correct
        : AnswerResult.incorrect;

    widget.repo.recordAnswer(_current, result);

    setState(() {
      _selectedIndex = index;
      _lastResult = result;
      _phase = _Phase.revealed;
    });

    // Correct answers need no explanation step. Get out of the way.
    if (result == AnswerResult.correct) {
      Future.delayed(const Duration(milliseconds: 550), _advance);
    }
  }

  void _advance() {
    if (!mounted) return;
    final answered = _answeredCount + 1;
    if (answered >= _requiredCount) {
      _grantAndClose(widget.passService.passLengthFor(_lastResult!));
      return;
    }
    setState(() => _answeredCount = answered);
    _serveNext();
  }

  Future<void> _grantAndClose(Duration length) async {
    await GateChannel.grantPass(length);
    if (mounted) Navigator.of(context).maybePop();
  }

  @override
  void dispose() {
    _stopwatch.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final showExplanation = _phase == _Phase.revealed &&
        _lastResult == AnswerResult.incorrect;

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.gutter),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ProgressDots(
                  total: _requiredCount,
                  done: _answeredCount,
                ),
                const SizedBox(height: 28),
                Expanded(
                  child: SingleChildScrollView(
                    child: AnimatedSwitcher(
                      duration: AppTheme.motion,
                      child: KeyedSubtree(
                        key: ValueKey(_current.id),
                        child: QuestionCard(
                          question: _current,
                          selectedIndex: _selectedIndex,
                          revealedCorrectIndex: _phase == _Phase.revealed
                              ? _current.correctIndex
                              : null,
                          onChoiceTapped: _choose,
                        ),
                      ),
                    ),
                  ),
                ),
                AnimatedSize(
                  duration: AppTheme.motion,
                  curve: Curves.easeOut,
                  child: _tooFastNotice
                      ? Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            'Give it a second. Same question again.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: scheme.onSurfaceVariant),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                if (showExplanation) ...[
                  const SizedBox(height: 16),
                  ExplanationPanel(
                    explanation: _current.explanation ??
                        'Review this one next time it comes up.',
                    correctChoice: _current.choices[_current.correctIndex],
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _advance,
                    child: const Text('Continue'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Only rendered when more than one question is owed, so a single-question
/// gate stays as bare as possible.
class _ProgressDots extends StatelessWidget {
  const _ProgressDots({required this.total, required this.done});

  final int total;
  final int done;

  @override
  Widget build(BuildContext context) {
    if (total <= 1) return const SizedBox(height: 8);
    final scheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < total; i++)
          AnimatedContainer(
            duration: AppTheme.motion,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: i < done ? 22 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i < done ? scheme.primary : scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
      ],
    );
  }
}
