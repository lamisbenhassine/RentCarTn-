import '../local/app_database.dart';
import '../models/auction.dart';
import 'auction_repository_prefs.dart';
import 'auction_repository_sqflite.dart';

/// Contrat CRUD des ventes aux enchères (+ offres).
abstract class AuctionRepository {
  Future<List<Auction>> getAll();

  Future<Auction?> byId(String id);

  Future<Auction> create(Auction auction);

  Future<Auction> update(Auction auction);

  Future<void> delete(String id);

  Future<void> seedIfEmpty({List<Auction>? seed});
}

class AuctionRepositoryFactory {
  static AuctionRepository create() {
    if (AppDatabase.instance.isSupported) {
      return SqfliteAuctionRepository();
    }
    return PrefsAuctionRepository();
  }
}

/// Aucun seed démo.
List<Auction> defaultAuctionSeed() => const [];
