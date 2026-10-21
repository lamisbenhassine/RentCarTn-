import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../local/app_database.dart';
import '../local/database_constants.dart';
import '../mock/mock_cars.dart';
import '../models/car.dart';
import '../models/reservation.dart';
import 'car_repository.dart';

/// CRUD véhicules via **sqflite** (Android / iOS / desktop).
///
/// La colonne [payload_json] contient le véhicule complet ; les colonnes
/// indexées (marque, modèle, prix…) restent synchronisées pour les listes.
class SqfliteCarRepository implements CarRepository {
  Future<Database> get _db async =>
      await AppDatabase.instance.database as Database;

  Car _fromRow(Map<String, Object?> row) {
    final raw = row['payload_json'] as String?;
    if (raw != null && raw.isNotEmpty) {
      final map = Map<String, Object?>.from(jsonDecode(raw) as Map);
      return Car.fromJson(map);
    }
    // Fallback si ancienne ligne sans payload.
    return Car(
      id: row['id']! as String,
      brand: row['brand']! as String,
      model: row['model']! as String,
      year: (row['year'] as num).toInt(),
      category: CarCategory.values.byName(row['category']! as String),
      pricePerDay: (row['price_per_day'] as num).toDouble(),
      transmission: Transmission.values.byName(row['transmission']! as String),
      fuel: FuelType.values.byName(row['fuel']! as String),
      seats: (row['seats'] as num).toInt(),
      doors: 4,
      luggage: 2,
      city: row['city']! as String,
      rating: 4.5,
      reviewCount: 0,
      images: _splitImages(row['image_urls'] as String?),
      description: '',
      features: const [],
      available: (row['available'] as num?)?.toInt() == 1,
    );
  }

  List<String> _splitImages(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    return raw.split('|').where((e) => e.isNotEmpty).toList();
  }

  Map<String, Object?> _toRow(Car car, {required String now}) => {
        'id': car.id,
        'brand': car.brand,
        'model': car.model,
        'year': car.year,
        'category': car.category.name,
        'price_per_day': car.pricePerDay,
        'transmission': car.transmission.name,
        'fuel': car.fuel.name,
        'seats': car.seats,
        'city': car.city,
        'available': car.available ? 1 : 0,
        'image_urls': car.images.join('|'),
        'payload_json': jsonEncode(car.toJson()),
        'updated_at': now,
      };

  @override
  Future<List<Car>> getAll() async {
    final rows = await (await _db).query(
      DatabaseConstants.cars,
      orderBy: 'brand ASC, model ASC',
    );
    return rows.map(_fromRow).toList(growable: false);
  }

  @override
  Future<Car?> byId(String id) async {
    final rows = await (await _db).query(
      DatabaseConstants.cars,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _fromRow(rows.first);
  }

  @override
  Future<Car> create(Car car) async {
    final now = DateTime.now().toIso8601String();
    await (await _db).insert(
      DatabaseConstants.cars,
      {
        ..._toRow(car, now: now),
        'created_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
    return car;
  }

  @override
  Future<Car> update(Car car) async {
    final now = DateTime.now().toIso8601String();
    final count = await (await _db).update(
      DatabaseConstants.cars,
      _toRow(car, now: now),
      where: 'id = ?',
      whereArgs: [car.id],
    );
    if (count == 0) {
      throw StateError('Véhicule introuvable : ${car.id}');
    }
    return car;
  }

  @override
  Future<void> delete(String id) async {
    await (await _db).delete(
      DatabaseConstants.cars,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> seedIfEmpty({List<Car>? seed}) async {
    final db = await _db;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM ${DatabaseConstants.cars}'),
    );
    if ((count ?? 0) > 0) return;

    final batch = db.batch();
    final now = DateTime.now().toIso8601String();
    for (final car in seed ?? defaultCarSeed()) {
      batch.insert(DatabaseConstants.cars, {
        ..._toRow(car, now: now),
        'created_at': now,
      });
    }
    await batch.commit(noResult: true);
  }

  @override
  Future<List<RentalExtra>> fetchExtras() async => MockCars.extras;

  @override
  Future<List<String>> fetchCities() async => MockCars.villes;

  @override
  Future<List<String>> fetchAgencies() async => MockCars.agences;
}
