import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../local/app_database.dart';
import '../local/database_constants.dart';
import '../models/complaint.dart';
import 'complaint_repository.dart';

/// CRUD réclamations via **sqflite** (Android / iOS / desktop).
///
/// [payload_json] contient la réclamation complète ; les colonnes indexées
/// (utilisateur, statut, catégorie…) servent aux listes et aux filtres.
class SqfliteComplaintRepository implements ComplaintRepository {
  Future<Database> get _db async =>
      await AppDatabase.instance.database as Database;

  static const _table = DatabaseConstants.complaints;

  Complaint _fromRow(Map<String, Object?> row) => Complaint.fromJson(
    Map<String, Object?>.from(
      jsonDecode(row['payload_json']! as String) as Map,
    ),
  );

  Map<String, Object?> _toRow(Complaint c) => {
    'id': c.id,
    'reference': c.reference,
    'user_id': c.userId,
    'category': c.category.name,
    'priority': c.priority.name,
    'status': c.status.name,
    'is_urgent': c.isUrgent ? 1 : 0,
    'reservation_id': c.reservationId,
    'auction_id': c.auctionId,
    'title': c.title,
    'payload_json': jsonEncode(c.toJson()),
    'created_at': c.createdAt.toIso8601String(),
    'updated_at': c.updatedAt.toIso8601String(),
  };

  @override
  Future<List<Complaint>> getByUser(String userId) async {
    final rows = await (await _db).query(
      _table,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
    return rows.map(_fromRow).toList(growable: false);
  }

  @override
  Future<Complaint?> byId(String id) async {
    final rows = await (await _db).query(
      _table,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : _fromRow(rows.first);
  }

  @override
  Future<Complaint> create(Complaint complaint) async {
    await (await _db).insert(
      _table,
      _toRow(complaint),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
    return complaint;
  }

  @override
  Future<Complaint> update(Complaint complaint) async {
    final count = await (await _db).update(
      _table,
      _toRow(complaint),
      where: 'id = ?',
      whereArgs: [complaint.id],
    );
    if (count == 0) {
      throw StateError('Réclamation introuvable : ${complaint.id}');
    }
    return complaint;
  }

  @override
  Future<void> delete(String id) async {
    await (await _db).delete(_table, where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<String> nextReference({DateTime? now}) async {
    final date = now ?? DateTime.now();
    // Références de l'année seulement (le compteur repart chaque année).
    final rows = await (await _db).query(
      _table,
      columns: ['reference'],
      where: 'reference LIKE ?',
      whereArgs: ['${ComplaintReference.yearPrefix(date.year)}%'],
    );
    return ComplaintReference.next(
      rows.map((r) => r['reference']! as String),
      date,
    );
  }
}
