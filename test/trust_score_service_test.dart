import 'package:flutter_test/flutter_test.dart';
import 'package:rentcar_tunisia/data/mock/mock_reservations.dart';
import 'package:rentcar_tunisia/data/models/reservation.dart';
import 'package:rentcar_tunisia/data/services/trust_score_service.dart';

void main() {
  const service = TrustScoreService();

  /// [count] locations terminées, à partir d'une réservation démo.
  List<Reservation> completed(
    int count, {
    bool late = false,
    int complaints = 0,
  }) {
    final base = MockReservations.build().first;
    return List.generate(
      count,
      (_) => base.copyWith(
        status: ReservationStatus.terminee,
        returnedLate: late,
        justifiedComplaints: complaints,
      ),
    );
  }

  group('Score', () {
    test('score initial = 50 sans location', () {
      expect(service.evaluate([]).score, 50);
    });

    test('+5 par location sans problème', () {
      expect(service.evaluate(completed(3)).score, 65);
    });

    test('-10 par retard, -15 par réclamation justifiée', () {
      expect(service.evaluate(completed(1, late: true)).score, 40);
      expect(service.evaluate(completed(1, complaints: 2)).score, 20);
      // Retard + réclamation sur la même location : -25, pas de bonus.
      expect(
        service.evaluate(completed(1, late: true, complaints: 1)).score,
        25,
      );
    });

    test('borné à 100 et à 0, à chaque étape', () {
      expect(service.evaluate(completed(20)).score, 100);
      expect(service.evaluate(completed(5, complaints: 1)).score, 0);
      // 100 puis un retard → 90 (et non 50 + 60 - 10 = 100).
      expect(
        service.scoreFromEvents([
          for (var i = 0; i < 12; i++) TrustEvent.cleanRental,
          TrustEvent.lateReturn,
        ]),
        90,
      );
    });

    test('annulées et à venir ne comptent pas', () {
      final base = MockReservations.build().first;
      final report = service.evaluate([
        base.copyWith(status: ReservationStatus.annulee, returnedLate: true),
        base.copyWith(status: ReservationStatus.aVenir),
      ]);
      expect(report.score, 50);
      expect(report.completedRentals, 0);
    });
  });

  group('Niveaux', () {
    test('Bronze < 3, Silver 3 à 9, Gold 10+', () {
      expect(service.tierFor(0), LoyaltyTier.bronze);
      expect(service.tierFor(2), LoyaltyTier.bronze);
      expect(service.tierFor(3), LoyaltyTier.silver);
      expect(service.tierFor(9), LoyaltyTier.silver);
      expect(service.tierFor(10), LoyaltyTier.gold);
    });

    test('les locations avec retard comptent pour le niveau', () {
      final report = service.evaluate(completed(3, late: true));
      expect(report.tier, LoyaltyTier.silver);
      expect(report.rentalsToNextTier, 7);
    });

    test('Gold = -10 %, les autres sans remise', () {
      expect(service.applyDiscount(200, LoyaltyTier.gold), 180);
      expect(service.applyDiscount(200, LoyaltyTier.silver), 200);
      expect(service.evaluate(completed(10)).rentalsToNextTier, isNull);
    });
  });

  test('données démo : 1 location propre + 1 retard → 45, Bronze', () {
    final report = service.evaluate(MockReservations.build());
    expect(report.completedRentals, 2);
    expect(report.lateReturns, 1);
    expect(report.score, 45);
    expect(report.tier, LoyaltyTier.bronze);
  });
}
