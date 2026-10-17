import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/learning.dart';
import 'sign_repository.dart';

/// CRUD panneaux persisté dans le navigateur (localStorage via shared_preferences).
///
/// Utilisé uniquement sur le **web**, où sqflite n'est pas disponible.
/// Les ajouts / modifications / suppressions survivent au refresh (F5).
class PrefsSignRepository implements SignRepository {
  static const _storageKey = 'rentcar_road_signs_v1';

  List<RoadSign>? _cache;

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<List<RoadSign>> _load() async {
    if (_cache != null) return _cache!;

    final prefs = await _prefs;
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      _cache = [];
      return _cache!;
    }

    final decoded = jsonDecode(raw) as List<dynamic>;
    _cache = decoded
        .map((e) => RoadSign.fromMap(Map<String, Object?>.from(e as Map)))
        .toList();
    return _cache!;
  }

  Future<void> _persist() async {
    final prefs = await _prefs;
    final encoded = jsonEncode(
      (_cache ?? []).map((s) => s.toMap()).toList(),
    );
    await prefs.setString(_storageKey, encoded);
  }

  @override
  Future<List<RoadSign>> getAll() async {
    final items = await _load();
    final sorted = List<RoadSign>.from(items)
      ..sort((a, b) {
        final byCat = a.category.name.compareTo(b.category.name);
        if (byCat != 0) return byCat;
        return a.name.compareTo(b.name);
      });
    return List.unmodifiable(sorted);
  }

  @override
  Future<List<RoadSign>> byCategory(SignCategory category) async {
    final items = await _load();
    return items
        .where((s) => s.category == category)
        .toList(growable: false);
  }

  @override
  Future<RoadSign?> byId(String id) async {
    final items = await _load();
    for (final sign in items) {
      if (sign.id == id) return sign;
    }
    return null;
  }

  @override
  Future<RoadSign> create(RoadSign sign) async {
    final items = await _load();
    if (items.any((s) => s.id == sign.id)) {
      throw StateError('Un panneau avec l\'id ${sign.id} existe déjà.');
    }
    items.add(sign);
    _cache = items;
    await _persist();
    return sign;
  }

  @override
  Future<RoadSign> update(RoadSign sign) async {
    final items = await _load();
    final index = items.indexWhere((s) => s.id == sign.id);
    if (index == -1) {
      throw StateError('Panneau introuvable : ${sign.id}');
    }
    items[index] = sign;
    _cache = items;
    await _persist();
    return sign;
  }

  @override
  Future<void> delete(String id) async {
    final items = await _load();
    items.removeWhere((s) => s.id == id);
    _cache = items;
    await _persist();
  }

  @override
  Future<void> seedIfEmpty({List<RoadSign>? seed}) async {
    final items = await _load();
    if (items.isNotEmpty) return;
    _cache = List<RoadSign>.from(seed ?? defaultRoadSignSeed());
    await _persist();
  }
}
