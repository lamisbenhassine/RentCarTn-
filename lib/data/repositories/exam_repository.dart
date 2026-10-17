import '../local/app_database.dart';
import '../mock/mock_learning.dart';
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

/// Seed : examen blanc final du mock pédagogique.
List<Exam> defaultExamSeed() {
  final quiz = MockLearning.quizzes.firstWhere((q) => q.isFinalTest);
  var order = 0;
  return [
    Exam(
      id: quiz.id,
      title: quiz.title,
      description: quiz.description,
      passingPercent: 70,
      isPublished: true,
      isFinal: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      questions: [
        for (final q in quiz.questions)
          ExamQuestion(
            id: q.id,
            question: q.question,
            options: q.options,
            correctIndex: q.correctIndex,
            explanation: q.explanation,
            sortOrder: order++,
          ),
      ],
    ),
  ];
}
