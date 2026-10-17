import 'package:flutter_test/flutter_test.dart';

import 'package:rentcar_tunisia/data/mock/mock_auctions.dart';
import 'package:rentcar_tunisia/data/mock/mock_cars.dart';
import 'package:rentcar_tunisia/data/models/auction.dart';
import 'package:rentcar_tunisia/data/models/car.dart';
import 'package:rentcar_tunisia/data/models/date_range.dart';
import 'package:rentcar_tunisia/data/repositories/auction_repository.dart';
import 'package:rentcar_tunisia/state/auction_provider.dart';
import 'package:rentcar_tunisia/state/cart_provider.dart';

DateRange _range(int startInDays, int days) {
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, now.day + startInDays);
  return DateRange(start, start.add(Duration(days: days)));
}

Car _firstAvailableCar() =>
    MockCars.cars.firstWhere((c) => c.available && c.bookedRanges.isEmpty);

void main() {
  group('Panier — règles de disponibilité', () {
    test('refuse un véhicule marqué indisponible', () {
      final cart = CartProvider();
      final car = MockCars.cars.firstWhere((c) => !c.available);

      final result = cart.add(
        car: car,
        range: _range(2, 3),
        pickupCity: 'Tunis',
        returnCity: 'Tunis',
      );

      expect(result.ok, isFalse);
      expect(cart.items, isEmpty);
    });

    test('refuse des dates qui chevauchent une réservation existante', () {
      final cart = CartProvider();
      final car = MockCars.cars.firstWhere(
        (c) => c.available && c.bookedRanges.isNotEmpty,
      );
      final booked = car.bookedRanges.first;

      final result = cart.add(
        car: car,
        range: DateRange(booked.start, booked.start.add(const Duration(days: 2))),
        pickupCity: 'Sousse',
        returnCity: 'Sousse',
      );

      expect(result.ok, isFalse);
    });

    test('refuse deux lignes du même véhicule sur des dates qui se recoupent', () {
      final cart = CartProvider();
      final car = _firstAvailableCar();

      expect(
        cart
            .add(
              car: car,
              range: _range(5, 4),
              pickupCity: 'Tunis',
              returnCity: 'Sfax',
            )
            .ok,
        isTrue,
      );

      final second = cart.add(
        car: car,
        range: _range(6, 3),
        pickupCity: 'Tunis',
        returnCity: 'Sfax',
      );

      expect(second.ok, isFalse);
      expect(cart.items.length, 1);
    });

    test('bloque la validation quand le panier est vide', () {
      expect(CartProvider().validateForCheckout().ok, isFalse);
    });
  });

  group('Enchères — règles de mise', () {
    late AuctionProvider provider;

    setUp(() async {
      provider = AuctionProvider(repository: const AuctionRepository());
      await provider.load();
    });

    tearDown(() => provider.dispose());

    test("refuse une offre inférieure à l'incrément minimal", () {
      final auction = provider.liveAuctions.first;

      final result = provider.placeBid(
        auction.id,
        auction.minimumNextBid - auction.minIncrement / 2,
      );

      expect(result.ok, isFalse);
    });

    test('accepte une offre valide et place le compte en tête', () {
      final auction = provider.liveAuctions.first;

      final result = provider.placeBid(auction.id, auction.minimumNextBid);

      expect(result.ok, isTrue);
      final updated = provider.byId(auction.id)!;
      expect(updated.currentUserIsLeading, isTrue);
      expect(updated.currentPrice, auction.minimumNextBid);
    });

    test('une offre concurrente simulée reprend la tête', () {
      final auction = provider.liveAuctions.first;
      provider.placeBid(auction.id, auction.minimumNextBid);

      final result = provider.simulateCompetingBid(auction.id);

      expect(result.ok, isTrue);
      final updated = provider.byId(auction.id)!;
      expect(updated.currentUserIsLeading, isFalse);
      expect(updated.highestBid!.isSimulated, isTrue);
    });

    test('aucune offre acceptée après la clôture', () {
      final auction = provider.liveAuctions.first;
      provider.simulateClose(auction.id);

      final result = provider.placeBid(auction.id, 999999);

      expect(result.ok, isFalse);
      expect(provider.byId(auction.id)!.isOpen, isFalse);
    });

    test('une vente terminée sans offre n\'a pas de gagnant', () {
      final ended = MockAuctions.build().firstWhere(
        (a) => a.computedStatus == AuctionStatus.terminee && !a.hasBids,
      );

      expect(ended.winner, isNull);
    });
  });
}
