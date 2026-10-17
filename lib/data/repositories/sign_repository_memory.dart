import '../models/learning.dart';
import 'sign_repository.dart';

/// CRUD en mémoire — utilisé sur le web (sqflite indisponible).
class MemorySignRepository implements SignRepository {
  final List<RoadSign> _items = [];

  @override
  Future<List<RoadSign>> getAll() async => List.unmodifiable(_items);

  @override
  Future<List<RoadSign>> byCategory(SignCategory category) async =>
      _items.where((s) => s.category == category).toList(growable: false);

  @override
  Future<RoadSign?> byId(String id) async {
    for (final sign in _items) {
      if (sign.id == id) return sign;
    }
    return null;
  }

  @override
  Future<RoadSign> create(RoadSign sign) async {
    if (_items.any((s) => s.id == sign.id)) {
      throw StateError('Un panneau avec l\'id ${sign.id} existe déjà.');
    }
    _items.add(sign);
    return sign;
  }

  @override
  Future<RoadSign> update(RoadSign sign) async {
    final index = _items.indexWhere((s) => s.id == sign.id);
    if (index == -1) {
      throw StateError('Panneau introuvable : ${sign.id}');
    }
    _items[index] = sign;
    return sign;
  }

  @override
  Future<void> delete(String id) async {
    _items.removeWhere((s) => s.id == id);
  }

  @override
  Future<void> seedIfEmpty({List<RoadSign>? seed}) async {
    if (_items.isNotEmpty) return;
    _items.addAll(seed ?? defaultRoadSignSeed());
  }
}
