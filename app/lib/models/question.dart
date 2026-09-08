/// A single question.
///
/// [tier] decides where an item may be served. Gate items must be
/// answerable in roughly 15 seconds. Anything longer is session-only,
/// because the gate fires when the user has the least patience.
enum QuestionTier { gate, session }

enum Section { reading, writing, math }

class Question {
  final String id;
  final Section section;
  final String skill;
  final int difficulty; // 1..5
  final QuestionTier tier;
  final String stem;
  final List<String> choices;
  final int correctIndex;
  final String explanation;

  const Question({
    required this.id,
    required this.section,
    required this.skill,
    required this.difficulty,
    required this.tier,
    required this.stem,
    required this.choices,
    required this.correctIndex,
    required this.explanation,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] as String,
      section: Section.values.byName(json['section'] as String),
      skill: json['skill'] as String,
      difficulty: json['difficulty'] as int,
      tier: QuestionTier.values.byName(json['tier'] as String),
      stem: json['stem'] as String,
      choices: (json['choices'] as List).cast<String>(),
      correctIndex: json['correct_index'] as int,
      explanation: json['explanation'] as String,
    );
  }
}
