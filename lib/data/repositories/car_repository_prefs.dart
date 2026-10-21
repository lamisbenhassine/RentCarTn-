import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../mock/mock_cars.dart';
import '../models/car.dart';
import '../models/reservation.dart';
import 'car_repository.dart';

/// CRUD véhicules persisté dans le navigateur (shared_preferences).
class PrefsCarRepository implements CarRepository {
  /// v2 : plus de seed démo (catalogue vide au premier lancement).
  static const _storageKey = 'rentcar_cars_v2';

  List<Car>? _cache;

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<List<Car>> _load() async {
    if (_cache != null) return _cache!;
    final prefs = await _prefs;
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      _cache = [];
      return _cache!;
    }
    final decoded = jsonDecode(raw) as List<dynamic>;
    _cache = decoded
        .map((e) => Car.fromJson(Map<String, Object?>.from(e as Map)))
        .toList();
    return _cache!;
  }

  Future<void> _persist() async {
    final prefs = await _prefs;
    await prefs.setString(
      _storageKey,
      jsonEncode((_cache ?? []).map((c) => c.toJson()).toList()),
    );
  }

  @override
  Future<List<Car>> getAll() async {
    final items = await _load();
    final sorted = List<Car>.from(items)
      ..sort((a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()));
    return List.unmodifiable(sorted);
  }

  @override
  Future<Car?> byId(String id) async {
    final items = await _load();
    for (final car in items) {
      if (car.id == id) return car;
    }
    return null;
  }

  @override
  Future<Car> create(Car car) async {
    final items = await _load();
    if (items.any((c) => c.id == car.id)) {
      throw StateError('Un véhicule avec l\'id ${car.id} existe déjà.');
    }
    items.add(car);
    _cache = items;
    await _persist();
    return car;
  }

  @override
  Future<Car> update(Car car) async {
    final items = await _load();
    final index = items.indexWhere((c) => c.id == car.id);
    if (index == -1) {
      throw StateError('Véhicule introuvable : ${car.id}');
    }
    items[index] = car;
    _cache = items;
    await _persist();
    return car;
  }

  @override
  Future<void> delete(String id) async {
    final items = await _load();
    items.removeWhere((c) => c.id == id);
    _cache = items;
    await _persist();
  }

  @override
  Future<void> seedIfEmpty({List<Car>? seed}) async {
    final items = await _load();
    if (items.isNotEmpty) return;
    _cache = List<Car>.from(seed ?? defaultCarSeed());
    await _persist();
  }

  @override
  Future<List<RentalExtra>> fetchExtras() async => MockCars.extras;

  @override
  Future<List<String>> fetchCities() async => MockCars.villes;

  @override
  Future<List<String>> fetchAgencies() async => MockCars.agences;
}
