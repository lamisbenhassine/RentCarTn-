import '../models/complaint.dart';
import 'trust_score_service.dart';

/// Bilan des réclamations d'un client (profil).
class ComplaintStats {
  const ComplaintStats({
    required this.total,
    required this.resolved,
    required this.rejected,
    required this.abusive,
    required this.ratingsGiven,
    required this.averageRatingGiven,
  });

  final int total;
  final int resolved;
  final int rejected;
  final int abusive;

  /// Nombre de notes de satisfaction données.
  final int ratingsGiven;

  /// Note moyenne donnée par le client (sur 5), `null` sans note.
  final double? averageRatingGiven;
}

/// Lien entre les réclamations et le score de confiance du module User.
///
/// - Rejetée comme abusive → -10 (évènement [TrustEvent.abusiveComplaint],
///   appliqué à la date du rejet par [TrustScoreService.evaluate]) ;
/// - Résolue (justifiée) → aucune pénalité ;
/// - plus de 3 rejets en 30 jours → avertissement avant une nouvelle
///   réclamation.
///
/// Logique pure (aucun accès BD ni UI) : testée unitairement.
class ComplaintTrustService {
  const ComplaintTrustService();

  /// Au-delà de ce nombre de rejets sur [rejectionWindow] : avertissement.
  static const int rejectionWarningThreshold = 3;
  static const Duration rejectionWindow = Duration(days: 30);

  /// Date du rejet : dernier évènement « Rejetée » de l'historique, sinon la
  /// dernière mise à jour.
  DateTime? rejectedAt(Complaint c) {
    if (c.status != ComplaintStatus.rejetee) return null;
    for (final e in c.history.reversed) {
      if (e.status == ComplaintStatus.rejetee) return e.date;
    }
    return c.updatedAt;
  }

  /// Évènements datés pour le score (seules les réclamations abusives
  /// comptent ; les résolues ne pénalisent pas).
  List<(DateTime, TrustEvent)> trustEvents(Iterable<Complaint> complaints) => [
    for (final c in complaints)
      if (c.status == ComplaintStatus.rejetee && c.abusive)
        (rejectedAt(c)!, TrustEvent.abusiveComplaint),
  ];

  /// Réclamations rejetées dans les 30 jours précédant [now].
  int recentRejections(Iterable<Complaint> complaints, {DateTime? now}) {
    final since = (now ?? DateTime.now()).subtract(rejectionWindow);
    return complaints.where((c) {
      final at = rejectedAt(c);
      return at != null && at.isAfter(since);
    }).length;
  }

  /// Plus de 3 rejets en 30 jours → avertir avant la création.
  bool shouldWarnBeforeCreate(
    Iterable<Complaint> complaints, {
    DateTime? now,
  }) => recentRejections(complaints, now: now) > rejectionWarningThreshold;

  ComplaintStats stats(Iterable<Complaint> complaints) {
    final list = complaints.toList();
    final ratings = [
      for (final c in list)
        if (c.rating != null) c.rating!,
    ];
    return ComplaintStats(
      total: list.length,
      resolved: list.where((c) => c.status == ComplaintStatus.resolue).length,
      rejected: list.where((c) => c.status == ComplaintStatus.rejetee).length,
      abusive: list
          .where((c) => c.status == ComplaintStatus.rejetee && c.abusive)
          .length,
      ratingsGiven: ratings.length,
      averageRatingGiven: ratings.isEmpty
          ? null
          : ratings.reduce((a, b) => a + b) / ratings.length,
    );
  }
}
