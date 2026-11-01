import 'package:flutter_test/flutter_test.dart';
import 'package:rentcar_tunisia/data/models/complaint.dart';

void main() {
  group('Référence REC-AAAA-NNNN', () {
    final now = DateTime(2026, 10, 30);

    test('première réclamation de l’année', () {
      expect(ComplaintReference.next([], now), 'REC-2026-0001');
    });

    test('suit le plus grand numéro de l’année', () {
      expect(
        ComplaintReference.next([
          'REC-2026-0001',
          'REC-2026-0007',
          'REC-2026-0003',
        ], now),
        'REC-2026-0008',
      );
    });

    test('le compteur repart à 0001 chaque année', () {
      expect(ComplaintReference.next(['REC-2025-0042'], now), 'REC-2026-0001');
    });

    test('références invalides ignorées, au-delà de 9999', () {
      expect(
        ComplaintReference.next(['n/a', 'REC-2026-9999'], now),
        'REC-2026-10000',
      );
    });
  });

  test('toJson / fromJson aller-retour', () {
    final created = DateTime(2026, 10, 30, 14, 5);
    final c =
        Complaint(
          id: 'cmp-1',
          reference: 'REC-2026-0001',
          userId: 'usr-001',
          category: ComplaintCategory.panne,
          title: 'Batterie à plat',
          description: 'Impossible de démarrer à Sousse.',
          priority: ComplaintPriority.urgente,
          status: ComplaintStatus.enAttente,
          reservationId: 'res-002',
          carLabel: 'Peugeot 208',
          agency: 'Agence Sousse',
          photoPaths: const ['/data/photo1.jpg'],
          latitude: 35.82,
          longitude: 10.63,
          isUrgent: true,
          history: [
            ComplaintEvent(
              status: ComplaintStatus.enAttente,
              date: created,
              message: 'Réclamation envoyée',
            ),
          ],
          createdAt: created,
          updatedAt: created,
        ).withEvent(
          ComplaintStatus.enCours,
          'Prise en charge',
          at: created.add(const Duration(hours: 1)),
        );

    final back = Complaint.fromJson(c.toJson());
    expect(back.reference, 'REC-2026-0001');
    expect(back.category, ComplaintCategory.panne);
    expect(back.priority, ComplaintPriority.urgente);
    expect(back.status, ComplaintStatus.enCours);
    expect(back.photoPaths, ['/data/photo1.jpg']);
    expect(back.hasLocation, isTrue);
    expect(back.history.length, 2);
    expect(back.history.last.message, 'Prise en charge');
    expect(back.updatedAt, created.add(const Duration(hours: 1)));
    expect(back.canEdit, isFalse);
  });

  test('valeurs inconnues → valeurs de secours', () {
    final c = Complaint.fromJson({
      'id': 'x',
      'category': 'inconnue',
      'priority': '???',
      'status': 'zzz',
      'createdAt': '2026-10-30T10:00:00.000',
    });
    expect(c.category, ComplaintCategory.autre);
    expect(c.priority, ComplaintPriority.moyenne);
    expect(c.status, ComplaintStatus.enAttente);
  });

  test('statut clos : notation possible, plus de modification', () {
    final now = DateTime(2026);
    final c = Complaint(
      id: 'a',
      reference: 'REC-2026-0002',
      userId: 'u',
      category: ComplaintCategory.autre,
      title: 't',
      description: 'd',
      priority: ComplaintPriority.basse,
      status: ComplaintStatus.resolue,
      createdAt: now,
      updatedAt: now,
    );
    expect(c.canEdit, isFalse);
    expect(c.canRate, isTrue);
    expect(c.copyWith(rating: 4).canRate, isFalse);
  });
}
