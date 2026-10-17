import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/exam.dart';
import 'exam_repository.dart';

/// Persistance web (localStorage) pour le CRUD examens.
class PrefsExamRepository implements ExamRepository {
  static const _storageKey = 'rentcar_exams_v1';

  List<Exam>? _cache;

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<List<Exam>> _load() async {
    if (_cache != null) return _cache!;
    final prefs = await _prefs;
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      _cache = [];
      return _cache!;
    }
    final decoded = jsonDecode(raw) as List<dynamic>;
    _cache = decoded
        .map((e) => Exam.fromJson(Map<String, Object?>.from(e as Map)))
        .toList();
    return _cache!;
  }

  Future<void> _persist() async {
    final prefs = await _prefs;
    await prefs.setString(
      _storageKey,
      jsonEncode((_cache ?? []).map((e) => e.toJson()).toList()),
    );
  }

  @override
  Future<List<Exam>> getAll() async {
    final items = await _load();
    final sorted = List<Exam>.from(items)
      ..sort((a, b) {
        final aAt = a.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bAt = b.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bAt.compareTo(aAt);
      });
    return List.unmodifiable(sorted);
  }

  @override
  Future<Exam?> byId(String id) async {
    final items = await _load();
    for (final exam in items) {
      if (exam.id == id) return exam;
    }
    return null;
  }

  @override
  Future<Exam> create(Exam exam) async {
    final items = await _load();
    if (items.any((e) => e.id == exam.id)) {
      throw StateError('Un examen avec l\'id ${exam.id} existe déjà.');
    }
    final now = DateTime.now();
    final saved = exam.copyWith(createdAt: now, updatedAt: now);
    items.add(saved);
    _cache = items;
    await _persist();
    return saved;
  }

  @override
  Future<Exam> update(Exam exam) async {
    final items = await _load();
    final index = items.indexWhere((e) => e.id == exam.id);
    if (index == -1) {
      throw StateError('Examen introuvable : ${exam.id}');
    }
    final saved = exam.copyWith(updatedAt: DateTime.now());
    items[index] = saved;
    _cache = items;
    await _persist();
    return saved;
  }

  @override
  Future<void> delete(String id) async {
    final items = await _load();
    items.removeWhere((e) => e.id == id);
    _cache = items;
    await _persist();
  }

  @override
  Future<void> seedIfEmpty({List<Exam>? seed}) async {
    final items = await _load();
    if (items.isNotEmpty) return;
    _cache = List<Exam>.from(seed ?? defaultExamSeed());
    await _persist();
  }
}
