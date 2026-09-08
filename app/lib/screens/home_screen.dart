import 'package:flutter/material.dart';
import '../data/question_repository.dart';

/// The calm surface. New material is introduced here, never at the gate.
/// Also where banked questions, streak, and progress live.
class HomeScreen extends StatelessWidget {
  final QuestionRepository repo;
  const HomeScreen({super.key, required this.repo});

  @override
  Widget build(BuildContext context) {
    // TODO(M1): permission status + "run gate now" debug button.
    // TODO(M2): streak counter and questions-answered total.
    return Scaffold(
      appBar: AppBar(title: const Text('Gatekeeper')),
      body: const Center(child: Text('Home')),
    );
  }
}
