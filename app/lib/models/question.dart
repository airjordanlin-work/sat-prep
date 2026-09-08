/// `gate` items must be answerable in well under 15 seconds — vocabulary
/// in context, single-sentence grammar, one-step algebra, formula recall.
/// `session` items (reading passages, multi-step math) are never served
/// at the gate; they only appear on the calm home-screen surface.
enum QuestionTier { gate, session }

class Question {
  const Question({
    required this.id,
    required this.tier,
    required this.prompt,
    required this.choices,
    required this.correctIndex,
    this.explanation,
  }) : assert(correctIndex >= 0 && correctIndex < choices.length);

  final String id;
  final QuestionTier tier;
  final String prompt;
  final List<String> choices;
  final int correctIndex;

  /// Shown on an incorrect answer. Null is allowed but discouraged for
  /// gate items — an unexplained wrong answer teaches nothing.
  final String? explanation;

  bool isCorrect(int choiceIndex) => choiceIndex == correctIndex;
}