import 'package:flutter/foundation.dart';

import '../data/mock/mock_learning.dart';
import '../data/models/learning.dart';
import '../data/repositories/sign_repository.dart';
import 'load_state.dart';

/// Progression pédagogique + CRUD des panneaux (sqflite / prefs).
class LearningProvider extends ChangeNotifier {
  LearningProvider({SignRepository? signRepository})
      : _signRepository = signRepository ?? SignRepositoryFactory.create();

  final SignRepository _signRepository;

  final Map<String, QuizResult> _results = {};
  final Set<String> _readSections = {};
  final Set<String> _studiedCategories = {};

  List<RoadSign> _signs = [];
  LoadState _signsState = LoadState.initial;
  String? _signsError;

  LoadState get signsState => _signsState;
  String? get signsError => _signsError;

  /// Quiz thématiques (vide — plus de démo). Les examens viennent d'ExamProvider.
  List<Quiz> get quizzes =>
      MockLearning.quizzes.where((q) => !q.isFinalTest).toList();

  Quiz? get finalTest {
    for (final q in MockLearning.quizzes) {
      if (q.isFinalTest) return q;
    }
    return null;
  }

  List<RuleSection> get rules => MockLearning.rules;

  /// Source de vérité : base locale (ou prefs sur web).
  List<RoadSign> get signs => List.unmodifiable(_signs);

  List<RoadSign> signsByCategory(SignCategory category) =>
      _signs.where((s) => s.category == category).toList(growable: false);

  Map<String, QuizResult> get results => Map.unmodifiable(_results);

  QuizResult? resultFor(String quizId) => _results[quizId];

  bool isRead(String sectionId) => _readSections.contains(sectionId);

  bool isCategoryStudied(SignCategory category) =>
      _studiedCategories.contains(category.name);

  int get completedQuizzes => _results.keys
      .where((id) => MockLearning.quizById(id)?.isFinalTest == false)
      .length;

  int get passedQuizzes => _results.values.where((r) => r.passed).length;

  double get overallProgress {
    final finalId = finalTest?.id;
    final totalUnits = MockLearning.rules.length +
        quizzes.length +
        SignCategory.values.length +
        (finalId != null ? 1 : 0);
    if (totalUnits == 0) {
      // Progression basée sur les catégories de panneaux étudiées uniquement.
      if (SignCategory.values.isEmpty) return 0;
      return (_studiedCategories.length / SignCategory.values.length)
          .clamp(0, 1);
    }
    final done = _readSections.length +
        _results.keys
            .where((id) => _results[id]!.passed && id != finalId)
            .length +
        _studiedCategories.length +
        ((finalId != null && (_results[finalId]?.passed ?? false)) ? 1 : 0);
    return (done / totalUnits).clamp(0, 1);
  }

  int get globalScore {
    if (_results.isEmpty) return 0;
    final sum = _results.values.fold(0, (s, r) => s + r.percent);
    return (sum / _results.length).round();
  }

  bool get finalTestPassed {
    final t = finalTest;
    if (t == null) return false;
    return _results[t.id]?.passed ?? false;
  }

  int get totalCorrect => _results.values.fold(0, (s, r) => s + r.score);

  /// Charge (et seed vide si besoin) les panneaux depuis le repository.
  Future<void> loadSigns({bool force = false}) async {
    if (_signsState == LoadState.loading) return;
    if (_signs.isNotEmpty && !force) return;

    _signsState = LoadState.loading;
    _signsError = null;
    notifyListeners();

    try {
      await _signRepository.seedIfEmpty();
      _signs = await _signRepository.getAll();
      _signsState = LoadState.success;
    } catch (e) {
      _signsError = 'Impossible de charger les panneaux.';
      _signsState = LoadState.error;
    }
    notifyListeners();
  }

  RoadSign? signById(String id) {
    for (final sign in _signs) {
      if (sign.id == id) return sign;
    }
    return null;
  }

  Future<RoadSign> createSign(RoadSign sign) async {
    final created = await _signRepository.create(sign);
    _signs = [..._signs, created]..sort((a, b) => a.name.compareTo(b.name));
    notifyListeners();
    return created;
  }

  Future<RoadSign> updateSign(RoadSign sign) async {
    final updated = await _signRepository.update(sign);
    _signs = [
      for (final s in _signs)
        if (s.id == updated.id) updated else s,
    ];
    notifyListeners();
    return updated;
  }

  Future<void> deleteSign(String id) async {
    await _signRepository.delete(id);
    _signs = _signs.where((s) => s.id != id).toList(growable: false);
    notifyListeners();
  }

  void markSectionRead(String sectionId) {
    _readSections.add(sectionId);
    notifyListeners();
  }

  void markCategoryStudied(SignCategory category) {
    _studiedCategories.add(category.name);
    notifyListeners();
  }

  void saveResult(QuizResult result) {
    _results[result.quizId] = result;
    notifyListeners();
  }

  void resetProgress() {
    _results.clear();
    _readSections.clear();
    _studiedCategories.clear();
    notifyListeners();
  }
}
