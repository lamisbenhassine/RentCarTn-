import '../models/reservation.dart';

/// Niveau de fidélité, selon le nombre de locations terminées.
enum LoyaltyTier { bronze, silver, gold }

extension LoyaltyTierX on LoyaltyTier {
  String get label => switch (this) {
    LoyaltyTier.bronze => 'Bronze',
    LoyaltyTier.silver => 'Silver',
    LoyaltyTier.gold => 'Gold',
  };

  /// Remise appliquée aux réservations (0.10 = -10 %).
  double get discountRate => this == LoyaltyTier.gold ? 0.10 : 0;

  /// Niveau suivant, `null` pour Gold.
  LoyaltyTier? get next => switch (this) {
    LoyaltyTier.bronze => LoyaltyTier.silver,
    LoyaltyTier.silver => LoyaltyTier.gold,
    LoyaltyTier.gold => null,
  };

  /// Nombre de locations terminées pour atteindre ce niveau.
  int get minRentals => switch (this) {
    LoyaltyTier.bronze => 0,
    LoyaltyTier.silver => TrustScoreService.silverFrom,
    LoyaltyTier.gold => TrustScoreService.goldFrom,
  };
}

/// Un évènement qui fait bouger le score.
enum TrustEvent {
  cleanRental,
  lateReturn,
  justifiedComplaint,

  /// Réclamation du client rejetée comme abusive (module Réclamations).
  abusiveComplaint,
}

/// Bilan complet : score, niveau et détail des évènements.
class TrustReport {
  const TrustReport({
    required this.score,
    required this.tier,
    required this.completedRentals,
    required this.cleanRentals,
    required this.lateReturns,
    required this.justifiedComplaints,
    this.abusiveComplaints = 0,
  });

  final int score;
  final LoyaltyTier tier;
  final int completedRentals;
  final int cleanRentals;
  final int lateReturns;
  final int justifiedComplaints;

  /// Réclamations du client rejetées comme abusives (-10 chacune).
  final int abusiveComplaints;

  double get discountRate => tier.discountRate;

  /// Locations restantes avant le niveau suivant (`null` si Gold).
  int? get rentalsToNextTier {
    final next = tier.next;
    return next == null ? null : next.minRentals - completedRentals;
  }
}

/// Calcul du score de confiance et du niveau de fidélité.
///
/// Logique pure (aucun accès BD ni UI) : facile à tester unitairement.
class TrustScoreService {
  const TrustScoreService();

  static const int initialScore = 50;
  static const int cleanRentalBonus = 5;
  static const int lateReturnPenalty = 10;
  static const int complaintPenalty = 15;
  static const int abusiveComplaintPenalty = 10;
  static const int minScore = 0;
  static const int maxScore = 100;

  /// Seuils des niveaux (locations terminées).
  static const int silverFrom = 3;
  static const int goldFrom = 10;

  static int _delta(TrustEvent event) => switch (event) {
    TrustEvent.cleanRental => cleanRentalBonus,
    TrustEvent.lateReturn => -lateReturnPenalty,
    TrustEvent.justifiedComplaint => -complaintPenalty,
    TrustEvent.abusiveComplaint => -abusiveComplaintPenalty,
  };

  /// Applique les évènements dans l'ordre, en restant entre 0 et 100 à
  /// chaque étape (un client à 100 qui a un retard redescend à 90).
  int scoreFromEvents(Iterable<TrustEvent> events) {
    var score = initialScore;
    for (final event in events) {
      score = (score + _delta(event)).clamp(minScore, maxScore);
    }
    return score;
  }

  LoyaltyTier tierFor(int completedRentals) {
    if (completedRentals >= goldFrom) return LoyaltyTier.gold;
    if (completedRentals >= silverFrom) return LoyaltyTier.silver;
    return LoyaltyTier.bronze;
  }

  /// Évènements d'une liste de réservations, dans l'ordre chronologique
  /// des retours. Seules les locations terminées comptent.
  List<TrustEvent> eventsFrom(Iterable<Reservation> reservations) => [
    for (final e in _datedEventsFrom(reservations)) e.$2,
  ];

  /// Évènements des réservations, datés au retour du véhicule.
  List<(DateTime, TrustEvent)> _datedEventsFrom(
    Iterable<Reservation> reservations,
  ) {
    final done =
        reservations
            .where((r) => r.status == ReservationStatus.terminee)
            .toList()
          ..sort((a, b) => a.range.end.compareTo(b.range.end));

    return [
      for (final r in done)
        if (r.completedWithoutIssue)
          (r.range.end, TrustEvent.cleanRental)
        else ...[
          if (r.returnedLate) (r.range.end, TrustEvent.lateReturn),
          for (var i = 0; i < r.justifiedComplaints; i++)
            (r.range.end, TrustEvent.justifiedComplaint),
        ],
    ];
  }

  /// [extraEvents] : évènements datés venant d'autres modules (ex.
  /// réclamations abusives, voir ComplaintTrustService). Tout est appliqué
  /// dans l'ordre chronologique (à date égale : réservations d'abord).
  TrustReport evaluate(
    Iterable<Reservation> reservations, {
    Iterable<(DateTime, TrustEvent)> extraEvents = const [],
  }) {
    final dated = [..._datedEventsFrom(reservations), ...extraEvents];
    final order = List.generate(dated.length, (i) => i)
      ..sort((a, b) {
        final byDate = dated[a].$1.compareTo(dated[b].$1);
        return byDate != 0 ? byDate : a.compareTo(b); // tri stable
      });
    final events = [for (final i in order) dated[i].$2];
    final completed = reservations
        .where((r) => r.status == ReservationStatus.terminee)
        .length;
    return TrustReport(
      score: scoreFromEvents(events),
      tier: tierFor(completed),
      completedRentals: completed,
      cleanRentals: events.where((e) => e == TrustEvent.cleanRental).length,
      lateReturns: events.where((e) => e == TrustEvent.lateReturn).length,
      justifiedComplaints: events
          .where((e) => e == TrustEvent.justifiedComplaint)
          .length,
      abusiveComplaints: events
          .where((e) => e == TrustEvent.abusiveComplaint)
          .length,
    );
  }

  /// Montant après la remise du niveau (Gold : -10 %).
  double applyDiscount(double amount, LoyaltyTier tier) =>
      amount * (1 - tier.discountRate);
}
