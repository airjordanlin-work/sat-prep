import 'package:flutter/material.dart';
import '../models/question.dart';
import '../theme/app_theme.dart';
import 'choice_tile.dart';

/// Pure presentation. Knows nothing about passes, scoring, or the queue.
///
/// [revealedCorrectIndex] is null while the question is live and set
/// once the answer has been scored, which is what drives the colour
/// change on the tiles.
class QuestionCard extends StatelessWidget {
  const QuestionCard({
    super.key,
    required this.question,
    required this.selectedIndex,
    required this.revealedCorrectIndex,
    required this.onChoiceTapped,
  });

  final Question question;
  final int? selectedIndex;
  final int? revealedCorrectIndex;
  final void Function(int index) onChoiceTapped;

  ChoiceState _stateFor(int i) {
    if (revealedCorrectIndex == null) {
      return selectedIndex == i ? ChoiceState.selected : ChoiceState.idle;
    }
    if (i == revealedCorrectIndex) return ChoiceState.correct;
    if (i == selectedIndex) return ChoiceState.wrong;
    return ChoiceState.idle;
  }

  @override
  Widget build(BuildContext context) {
    final locked = revealedCorrectIndex != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          question.prompt,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppTheme.gutter + 4),
        for (var i = 0; i < question.choices.length; i++)
          ChoiceTile(
            label: question.choices[i],
            state: _stateFor(i),
            onTap: locked ? null : () => onChoiceTapped(i),
          ),
      ],
    );
  }
}
