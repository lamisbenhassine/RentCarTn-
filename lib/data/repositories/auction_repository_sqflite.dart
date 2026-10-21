import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../local/app_database.dart';
import '../local/database_constants.dart';
import '../models/auction.dart';
import '../models/car.dart';
import 'auction_repository.dart';

/// CRUD enchères via sqflite — payload JSON complet + colonnes indexées.
class SqfliteAuctionRepository implements AuctionRepository {
  Future<Database> get _db async =>
      await AppDatabase.instance.database as Database;

  Auction _fromRow(Map<String, Object?> row) {
    final raw = row['payload_json'] as String?;
    if (raw != null && raw.isNotEmpty) {
      return Auction.fromJson(
        Map<String, Object?>.from(jsonDecode(raw) as Map),
      );
    }
    return Auction(
      id: row['id']! as String,
      brand: row['brand']! as String,
      model: row['model']! as String,
      year: (row['year'] as num).toInt(),
      mileage: 0,
      condition: VehicleCondition.bon,
      description: '',
      images: const [],
      startingPrice: (row['starting_price'] as num).toDouble(),
      minIncrement: (row['min_increment'] as num).toDouble(),
      startAt: DateTime.tryParse((row['start_at'] as String?) ?? '') ??
          DateTime.now(),
      endAt: DateTime.tryParse((row['end_at'] as String?) ?? '') ??
          DateTime.now(),
      city: 'Tunis',
      fuel: FuelType.essence,
      transmission: Transmission.manuelle,
      bids: const [],
      cancelled: (row['cancelled'] as num?)?.toInt() == 1,
    );
  }

  Map<String, Object?> _toRow(Auction auction, {required String now}) => {
        'id': auction.id,
        'brand': auction.brand,
        'model': auction.model,
        'year': auction.year,
        'starting_price': auction.startingPrice,
        'min_increment': auction.minIncrement,
        'start_at': auction.startAt.toIso8601String(),
        'end_at': auction.endAt.toIso8601String(),
        'status': auction.status?.name ?? auction.computedStatus.name,
        'cancelled': auction.cancelled ? 1 : 0,
        'payload_json': jsonEncode(auction.toJson()),
        'updated_at': now,
      };

  @override
  Future<List<Auction>> getAll() async {
    final rows = await (await _db).query(
      DatabaseConstants.auctions,
      orderBy: 'start_at DESC',
    );
    return rows.map(_fromRow).toList(growable: false);
  }

  @override
  Future<Auction?> byId(String id) async {
    final rows = await (await _db).query(
      DatabaseConstants.auctions,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _fromRow(rows.first);
  }

  @override
  Future<Auction> create(Auction auction) async {
    final now = DateTime.now().toIso8601String();
    await (await _db).insert(
      DatabaseConstants.auctions,
      {
        ..._toRow(auction, now: now),
        'created_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
    return auction;
  }

  @override
  Future<Auction> update(Auction auction) async {
    final now = DateTime.now().toIso8601String();
    final count = await (await _db).update(
      DatabaseConstants.auctions,
      _toRow(auction, now: now),
      where: 'id = ?',
      whereArgs: [auction.id],
    );
    if (count == 0) {
      throw StateError('Enchère introuvable : ${auction.id}');
    }
    return auction;
  }

  @override
  Future<void> delete(String id) async {
    final db = await _db;
    await db.delete(
      DatabaseConstants.bids,
      where: 'auction_id = ?',
      whereArgs: [id],
    );
    await db.delete(
      DatabaseConstants.auctions,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> seedIfEmpty({List<Auction>? seed}) async {
    final db = await _db;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM ${DatabaseConstants.auctions}'),
    );
    if ((count ?? 0) > 0) return;
    for (final auction in seed ?? defaultAuctionSeed()) {
      await create(auction);
    }
  }
}
