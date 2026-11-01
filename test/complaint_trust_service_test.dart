import 'package:flutter_test/flutter_test.dart';
import 'package:rentcar_tunisia/data/models/complaint.dart';
import 'package:rentcar_tunisia/data/services/complaint_trust_service.dart';
import 'package:rentcar_tunisia/data/services/trust_score_service.dart';

final _now = DateTime(2026, 10, 31, 12);

/// Réclamation passée au statut [status] il y a [daysAgo] jours.
Complaint _complaint(
  String id,
  ComplaintStatus status, {
  int daysAgo = 1,
  bool abusive = false,
  int? rating,
}) {
  final created = _now.subtract(Duration(days: daysAgo + 2));
  final at = _now.subtract(Duration(days: daysAgo));
  return Complaint(
    id: id,
    reference: 'REC-2026-$id',
    userId: 'u1',
    category: ComplaintCategory.autre,
    title: 'Titre',
    description: 'Description suffisamment longue.',
    priority: ComplaintPriority.moyenne,
    status: status,
    abusive: abusive,
    rating: rating,
    history: [
      ComplaintEvent(
        status: ComplaintStatus.enAttente,
        date: created,
        message: 'Réclamation envoyée',
      ),
      if (status != ComplaintStatus.enAttente)
        ComplaintEvent(status: status, date: at, message: status.name),
    ],
    createdAt: created,
    updatedAt: at,
  );
}

void main() {
  const service = ComplaintTrustService();
  const trust = TrustScoreService();

  group('score de confiance', () {
    test('rejetée comme abusive : -10', () {
      final report = trust.evaluate(
        const [],
        extraEvents: service.trustEvents([
          _complaint('1', ComplaintStatus.rejetee, abusive: true),
        ]),
      );
      expect(report.score, 40);
      expect(report.abusiveComplaints, 1);
    });

    test('résolue (justifiée) ou rejetée sans abus : pas de pénalité', () {
      final events = service.trustEvents([
        _complaint('1', ComplaintStatus.resolue),
        _complaint('2', ComplaintStatus.rejetee),
        _complaint('3', ComplaintStatus.enCours),
      ]);
      expect(events, isEmpty);
      expect(trust.evaluate(const [], extraEvents: events).score, 50);
    });

    test('borné à 0 et appliqué à la date du rejet', () {
      final events = service.trustEvents([
        for (var i = 0; i < 7; i++)
          _complaint('$i', ComplaintStatus.rejetee, abusive: true),
      ]);
      expect(trust.evaluate(const [], extraEvents: events).score, 0);
      expect(events.first.$1, _now.subtract(const Duration(days: 1)));
    });
  });

  group('avertissement avant création', () {
    test('3 rejets en 30 jours : pas encore', () {
      final list = [
        for (var i = 0; i < 3; i++) _complaint('$i', ComplaintStatus.rejetee),
      ];
      expect(service.recentRejections(list, now: _now), 3);
      expect(service.shouldWarnBeforeCreate(list, now: _now), isFalse);
    });

    test('plus de 3 rejets en 30 jours : avertissement', () {
      final list = [
        for (var i = 0; i < 4; i++)
          _complaint('$i', ComplaintStatus.rejetee, daysAgo: 5 + i),
      ];
      expect(service.shouldWarnBeforeCreate(list, now: _now), isTrue);
    });

    test('les rejets de plus de 30 jours ne comptent pas', () {
      final list = [
        for (var i = 0; i < 3; i++) _complaint('$i', ComplaintStatus.rejetee),
        _complaint('old', ComplaintStatus.rejetee, daysAgo: 31),
        _complaint('ok', ComplaintStatus.resolue),
      ];
      expect(service.recentRejections(list, now: _now), 3);
      expect(service.shouldWarnBeforeCreate(list, now: _now), isFalse);
    });
  });

  test('statistiques du profil', () {
    final stats = service.stats([
      _complaint('1', ComplaintStatus.resolue, rating: 5),
      _complaint('2', ComplaintStatus.resolue, rating: 2),
      _complaint('3', ComplaintStatus.rejetee, abusive: true),
      _complaint('4', ComplaintStatus.enAttente),
    ]);
    expect(stats.total, 4);
    expect(stats.resolved, 2);
    expect(stats.rejected, 1);
    expect(stats.abusive, 1);
    expect(stats.ratingsGiven, 2);
    expect(stats.averageRatingGiven, 3.5);
    expect(service.stats(const []).averageRatingGiven, isNull);
  });

  test('le champ abusive survit au JSON (payload sqflite)', () {
    final c = _complaint('1', ComplaintStatus.rejetee, abusive: true);
    expect(Complaint.fromJson(c.toJson()).abusive, isTrue);
    // Anciennes réclamations sans le champ.
    final legacy = c.toJson()..remove('abusive');
    expect(Complaint.fromJson(legacy).abusive, isFalse);
  });
}
