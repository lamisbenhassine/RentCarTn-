import 'package:sqflite/sqflite.dart';

import '../local/app_database.dart';
import '../local/database_constants.dart';
import '../models/exam.dart';
import 'exam_repository.dart';

class SqfliteExamRepository implements ExamRepository {
  Future<Database> get _db async =>
      await AppDatabase.instance.database as Database;

  Future<Exam> _hydrate(Map<String, Object?> row) async {
    final questions = await (await _db).query(
      DatabaseConstants.examQuestions,
      where: 'exam_id = ?',
      whereArgs: [row['id']],
      orderBy: 'sort_order ASC',
    );
    return Exam.fromRow(
      row,
      questions: questions.map(ExamQuestion.fromMap).toList(),
    );
  }

  @override
  Future<List<Exam>> getAll() async {
    final rows = await (await _db).query(
      DatabaseConstants.exams,
      orderBy: 'updated_at DESC',
    );
    final result = <Exam>[];
    for (final row in rows) {
      result.add(await _hydrate(row));
    }
    return result;
  }

  @override
  Future<Exam?> byId(String id) async {
    final rows = await (await _db).query(
      DatabaseConstants.exams,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _hydrate(rows.first);
  }

  Future<void> _replaceQuestions(Database db, Exam exam) async {
    await db.delete(
      DatabaseConstants.examQuestions,
      where: 'exam_id = ?',
      whereArgs: [exam.id],
    );
    final batch = db.batch();
    for (var i = 0; i < exam.questions.length; i++) {
      final q = exam.questions[i].copyWith(sortOrder: i);
      batch.insert(
        DatabaseConstants.examQuestions,
        q.toMap(examId: exam.id),
      );
    }
    await batch.commit(noResult: true);
  }

  @override
  Future<Exam> create(Exam exam) async {
    final db = await _db;
    final now = DateTime.now();
    final toSave = exam.copyWith(createdAt: now, updatedAt: now);
    await db.insert(DatabaseConstants.exams, toSave.toRow());
    await _replaceQuestions(db, toSave);
    return toSave;
  }

  @override
  Future<Exam> update(Exam exam) async {
    final db = await _db;
    final toSave = exam.copyWith(updatedAt: DateTime.now());
    final count = await db.update(
      DatabaseConstants.exams,
      toSave.toRow(),
      where: 'id = ?',
      whereArgs: [exam.id],
    );
    if (count == 0) {
      throw StateError('Examen introuvable : ${exam.id}');
    }
    await _replaceQuestions(db, toSave);
    return toSave;
  }

  @override
  Future<void> delete(String id) async {
    final db = await _db;
    await db.delete(
      DatabaseConstants.examQuestions,
      where: 'exam_id = ?',
      whereArgs: [id],
    );
    await db.delete(
      DatabaseConstants.exams,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> seedIfEmpty({List<Exam>? seed}) async {
    final db = await _db;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM ${DatabaseConstants.exams}'),
    );
    if ((count ?? 0) > 0) return;

    for (final exam in seed ?? defaultExamSeed()) {
      await create(exam);
    }
  }
}
