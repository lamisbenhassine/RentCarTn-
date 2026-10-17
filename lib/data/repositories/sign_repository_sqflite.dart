import 'package:sqflite/sqflite.dart';

import '../local/app_database.dart';
import '../local/database_constants.dart';
import '../models/learning.dart';
import 'sign_repository.dart';

/// CRUD panneaux via **sqflite** (Android / iOS / desktop).
class SqfliteSignRepository implements SignRepository {
  Future<Database> get _db async {
    final database = await AppDatabase.instance.database;
    return database as Database;
  }

  @override
  Future<List<RoadSign>> getAll() async {
    final rows = await (await _db).query(
      DatabaseConstants.roadSigns,
      orderBy: 'category ASC, name ASC',
    );
    return rows.map(RoadSign.fromMap).toList(growable: false);
  }

  @override
  Future<List<RoadSign>> byCategory(SignCategory category) async {
    final rows = await (await _db).query(
      DatabaseConstants.roadSigns,
      where: 'category = ?',
      whereArgs: [category.name],
      orderBy: 'name ASC',
    );
    return rows.map(RoadSign.fromMap).toList(growable: false);
  }

  @override
  Future<RoadSign?> byId(String id) async {
    final rows = await (await _db).query(
      DatabaseConstants.roadSigns,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return RoadSign.fromMap(rows.first);
  }

  @override
  Future<RoadSign> create(RoadSign sign) async {
    final now = DateTime.now().toIso8601String();
    await (await _db).insert(
      DatabaseConstants.roadSigns,
      {
        ...sign.toMap(),
        'created_at': now,
        'updated_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
    return sign;
  }

  @override
  Future<RoadSign> update(RoadSign sign) async {
    final now = DateTime.now().toIso8601String();
    final count = await (await _db).update(
      DatabaseConstants.roadSigns,
      {
        ...sign.toMap()..remove('id'),
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [sign.id],
    );
    if (count == 0) {
      throw StateError('Panneau introuvable : ${sign.id}');
    }
    return sign;
  }

  @override
  Future<void> delete(String id) async {
    await (await _db).delete(
      DatabaseConstants.roadSigns,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> seedIfEmpty({List<RoadSign>? seed}) async {
    final db = await _db;
    final count = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM ${DatabaseConstants.roadSigns}',
      ),
    );
    if ((count ?? 0) > 0) return;

    final batch = db.batch();
    final now = DateTime.now().toIso8601String();
    for (final sign in seed ?? defaultRoadSignSeed()) {
      batch.insert(DatabaseConstants.roadSigns, {
        ...sign.toMap(),
        'created_at': now,
        'updated_at': now,
      });
    }
    await batch.commit(noResult: true);
  }
}
