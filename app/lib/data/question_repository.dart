import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/question.dart';

/// M1: loads from bundled JSON. M2: swap the body of [load] for a
/// Supabase call. Keep the interface identical so nothing else changes.
class QuestionRepository {
  List<Question> _all = const [];

  Future<void> load() async {
    final raw = await rootBundle.loadString('assets/questions.json');
    final list = jsonDecode(raw) as List;
    _all = list.map((e) => Question.fromJson(e as Map<String, dynamic>)).toList();
  }

  Question byId(String id) => _all.firstWhere((q) => q.id == id);

  /// Gate-eligible items only. Never serve a reading passage here.
  List<Question> gatePool() =>
      _all.where((q) => q.tier == QuestionTier.gate).toList();

  List<Question> sessionPool() =>
      _all.where((q) => q.tier == QuestionTier.session).toList();
}
