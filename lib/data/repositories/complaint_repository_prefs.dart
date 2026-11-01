import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/complaint.dart';
import 'complaint_repository.dart';

/// CRUD réclamations persisté dans le navigateur (shared_preferences).
class PrefsComplaintRepository implements ComplaintRepository {
  static const _storageKey = 'rentcar_complaints_v1';

  List<Complaint>? _cache;

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<List<Complaint>> _load() async {
    if (_cache != null) return _cache!;
    final raw = (await _prefs).getString(_storageKey);
    if (raw == null || raw.isEmpty) return _cache = [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return _cache = decoded
        .map((e) => Complaint.fromJson(Map<String, Object?>.from(e as Map)))
        .toList();
  }

  Future<void> _persist() async {
    await (await _prefs).setString(
      _storageKey,
      jsonEncode((_cache ?? []).map((c) => c.toJson()).toList()),
    );
  }

  @override
  Future<List<Complaint>> getByUser(String userId) async {
    final items = (await _load()).where((c) => c.userId == userId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(items);
  }

  @override
  Future<Complaint?> byId(String id) async {
    for (final c in await _load()) {
      if (c.id == id) return c;
    }
    return null;
  }

  @override
  Future<Complaint> create(Complaint complaint) async {
    final items = await _load();
    if (items.any(
      (c) => c.id == complaint.id || c.reference == complaint.reference,
    )) {
      throw StateError('Réclamation déjà existante : ${complaint.reference}');
    }
    items.add(complaint);
    await _persist();
    return complaint;
  }

  @override
  Future<Complaint> update(Complaint complaint) async {
    final items = await _load();
    final index = items.indexWhere((c) => c.id == complaint.id);
    if (index == -1) {
      throw StateError('Réclamation introuvable : ${complaint.id}');
    }
    items[index] = complaint;
    await _persist();
    return complaint;
  }

  @override
  Future<void> delete(String id) async {
    (await _load()).removeWhere((c) => c.id == id);
    await _persist();
  }

  @override
  Future<String> nextReference({DateTime? now}) async =>
      ComplaintReference.next(
        (await _load()).map((c) => c.reference),
        now ?? DateTime.now(),
      );
}
