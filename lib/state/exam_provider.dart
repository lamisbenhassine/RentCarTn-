import 'package:flutter/foundation.dart';

import '../data/models/exam.dart';
import '../data/repositories/exam_repository.dart';
import 'load_state.dart';

/// État admin CRUD des examens (passage utilisateur plus tard).
class ExamProvider extends ChangeNotifier {
  ExamProvider({ExamRepository? repository})
      : _repository = repository ?? ExamRepositoryFactory.create();

  final ExamRepository _repository;

  List<Exam> _exams = [];
  LoadState _state = LoadState.initial;
  String? _error;

  List<Exam> get exams => List.unmodifiable(_exams);
  LoadState get state => _state;
  String? get error => _error;

  List<Exam> get publishedExams =>
      _exams.where((e) => e.isPublished).toList(growable: false);

  List<Exam> get finalExams =>
      _exams.where((e) => e.isFinal).toList(growable: false);

  Exam? byId(String id) {
    for (final exam in _exams) {
      if (exam.id == id) return exam;
    }
    return null;
  }

  Future<void> load({bool force = false}) async {
    if (_state == LoadState.loading) return;
    if (_exams.isNotEmpty && !force) return;

    _state = LoadState.loading;
    _error = null;
    notifyListeners();

    try {
      await _repository.seedIfEmpty();
      _exams = await _repository.getAll();
      _state = LoadState.success;
    } catch (_) {
      _error = 'Impossible de charger les examens.';
      _state = LoadState.error;
    }
    notifyListeners();
  }

  Future<Exam> create(Exam exam) async {
    final created = await _repository.create(exam);
    _exams = [created, ..._exams];
    notifyListeners();
    return created;
  }

  Future<Exam> update(Exam exam) async {
    final updated = await _repository.update(exam);
    _exams = [
      for (final e in _exams)
        if (e.id == updated.id) updated else e,
    ];
    notifyListeners();
    return updated;
  }

  Future<void> delete(String id) async {
    await _repository.delete(id);
    _exams = _exams.where((e) => e.id != id).toList(growable: false);
    notifyListeners();
  }
}
