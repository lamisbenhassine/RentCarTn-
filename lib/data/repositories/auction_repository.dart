import '../mock/mock_auctions.dart';
import '../models/auction.dart';

/// Point d'intégration backend pour le module d'enchères.
/// En production, les enchères devraient transiter par un canal temps réel
/// (WebSocket) et l'heure de clôture être validée côté serveur.
class AuctionRepository {
  const AuctionRepository();

  Future<List<Auction>> fetchAuctions() async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    return MockAuctions.build();
  }

  Future<List<String>> fetchBidderPseudonyms() async => MockAuctions.pseudos;
}
