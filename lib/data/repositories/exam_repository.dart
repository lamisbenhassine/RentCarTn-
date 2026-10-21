import '../local/app_database.dart';
import '../models/exam.dart';
import 'exam_repository_prefs.dart';
import 'exam_repository_sqflite.dart';

/// Contrat CRUD des examens (admin).
abstract class ExamRepository {
  Future<List<Exam>> getAll();

  Future<Exam?> byId(String id);

  Future<Exam> create(Exam exam);

  Future<Exam> update(Exam exam);

  Future<void> delete(String id);

  Future<void> seedIfEmpty({List<Exam>? seed});
}

class ExamRepositoryFactory {
  static ExamRepository create() {
    if (AppDatabase.instance.isSupported) {
      return SqfliteExamRepository();
    }
    return PrefsExamRepository();
  }
}

/// Aucun seed démo : les examens démarrent vides (CRUD uniquement).
List<Exam> defaultExamSeed() => const [];
