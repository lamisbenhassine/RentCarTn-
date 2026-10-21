import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/auction.dart';
import 'auction_repository.dart';

class PrefsAuctionRepository implements AuctionRepository {
  static const _storageKey = 'rentcar_auctions_v1';

  List<Auction>? _cache;

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<List<Auction>> _load() async {
    if (_cache != null) return _cache!;
    final prefs = await _prefs;
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      _cache = [];
      return _cache!;
    }
    final decoded = jsonDecode(raw) as List<dynamic>;
    _cache = decoded
        .map((e) => Auction.fromJson(Map<String, Object?>.from(e as Map)))
        .toList();
    return _cache!;
  }

  Future<void> _persist() async {
    final prefs = await _prefs;
    await prefs.setString(
      _storageKey,
      jsonEncode((_cache ?? []).map((a) => a.toJson()).toList()),
    );
  }

  @override
  Future<List<Auction>> getAll() async {
    final items = await _load();
    final sorted = List<Auction>.from(items)
      ..sort((a, b) => b.startAt.compareTo(a.startAt));
    return List.unmodifiable(sorted);
  }

  @override
  Future<Auction?> byId(String id) async {
    final items = await _load();
    for (final a in items) {
      if (a.id == id) return a;
    }
    return null;
  }

  @override
  Future<Auction> create(Auction auction) async {
    final items = await _load();
    if (items.any((a) => a.id == auction.id)) {
      throw StateError('Une enchère avec l\'id ${auction.id} existe déjà.');
    }
    items.insert(0, auction);
    _cache = items;
    await _persist();
    return auction;
  }

  @override
  Future<Auction> update(Auction auction) async {
    final items = await _load();
    final index = items.indexWhere((a) => a.id == auction.id);
    if (index == -1) {
      throw StateError('Enchère introuvable : ${auction.id}');
    }
    items[index] = auction;
    _cache = items;
    await _persist();
    return auction;
  }

  @override
  Future<void> delete(String id) async {
    final items = await _load();
    items.removeWhere((a) => a.id == id);
    _cache = items;
    await _persist();
  }

  @override
  Future<void> seedIfEmpty({List<Auction>? seed}) async {
    final items = await _load();
    if (items.isNotEmpty) return;
    _cache = List<Auction>.from(seed ?? defaultAuctionSeed());
    await _persist();
  }
}
