import 'package:flutter/material.dart';
import '../data/question_repository.dart';
import '../services/pass_service.dart';

/// The screen that appears over the blocked app.
///
/// Must not be dismissible by the back button. On Android the native
/// Activity also sets FLAG_SECURE-adjacent behavior; this is the Dart
/// half of that.
class GateScreen extends StatefulWidget {
  final QuestionRepository repo;
  final String blockedPackage;

  const GateScreen({
    super.key,
    required this.repo,
    required this.blockedPackage,
  });

  @override
  State<GateScreen> createState() => _GateScreenState();
}

class _GateScreenState extends State<GateScreen> {
  //final _pass = PassService();

  // TODO(M1):
  //  1. Ask ReviewQueue for the next due item (fall back to a new
  //     gate-tier question).
  //  2. Start a stopwatch on build to measure timeTaken.
  //  3. On tap, call PassService.submit.
  //  4. tooFast   -> re-serve, no penalty message
  //     incorrect -> show explanation, Continue button, short pass
  //     correct   -> grant full pass, pop
  //  5. Repeat for PassService.questionsOwed() questions.

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: const Scaffold(
        body: Center(child: Text('Gate')),
      ),
    );
  }
}
