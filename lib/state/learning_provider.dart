import 'package:flutter/foundation.dart';

import '../data/mock/mock_learning.dart';
import '../data/models/learning.dart';

/// Progression pédagogique conservée en mémoire pour la session.
class LearningProvider extends ChangeNotifier {
  final Map<String, QuizResult> _results = {};
  final Set<String> _readSections = {};
  final Set<String> _studiedCategories = {};

  List<Quiz> get quizzes =>
      MockLearning.quizzes.where((q) => !q.isFinalTest).toList();

  Quiz get finalTest =>
      MockLearning.quizzes.firstWhere((q) => q.isFinalTest);

  List<RuleSection> get rules => MockLearning.rules;

  List<RoadSign> get signs => MockLearning.signs;

  Map<String, QuizResult> get results => Map.unmodifiable(_results);

  QuizResult? resultFor(String quizId) => _results[quizId];

  bool isRead(String sectionId) => _readSections.contains(sectionId);

  bool isCategoryStudied(SignCategory category) =>
      _studiedCategories.contains(category.name);

  int get completedQuizzes => _results.keys
      .where((id) => MockLearning.quizById(id)?.isFinalTest == false)
      .length;

  int get passedQuizzes =>
      _results.values.where((r) => r.passed).length;

  /// Progression globale : lectures + quiz réussis + examen final.
  double get overallProgress {
    final totalUnits = MockLearning.rules.length +
        quizzes.length +
        SignCategory.values.length +
        1;
    final done = _readSections.length +
        _results.keys
            .where((id) => _results[id]!.passed && id != finalTest.id)
            .length +
        _studiedCategories.length +
        ((_results[finalTest.id]?.passed ?? false) ? 1 : 0);
    if (totalUnits == 0) return 0;
    return (done / totalUnits).clamp(0, 1);
  }

  int get globalScore {
    if (_results.isEmpty) return 0;
    final sum = _results.values.fold(0, (s, r) => s + r.percent);
    return (sum / _results.length).round();
  }

  bool get finalTestPassed => _results[finalTest.id]?.passed ?? false;

  /// Nombre total de questions correctes toutes tentatives confondues.
  int get totalCorrect =>
      _results.values.fold(0, (s, r) => s + r.score);

  void markSectionRead(String sectionId) {
    if (_readSections.add(sectionId)) notifyListeners();
  }

  void markCategoryStudied(SignCategory category) {
    if (_studiedCategories.add(category.name)) notifyListeners();
  }

  /// Conserve le meilleur score obtenu pour chaque quiz.
  void saveResult(QuizResult result) {
    final previous = _results[result.quizId];
    if (previous == null || result.score >= previous.score) {
      _results[result.quizId] = result;
    }
    notifyListeners();
  }

  void resetProgress() {
    _results.clear();
    _readSections.clear();
    _studiedCategories.clear();
    notifyListeners();
  }
}
