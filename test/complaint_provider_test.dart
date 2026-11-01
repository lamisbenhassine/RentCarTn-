import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rentcar_tunisia/data/models/complaint.dart';
import 'package:rentcar_tunisia/data/repositories/complaint_repository.dart';
import 'package:rentcar_tunisia/state/complaint_provider.dart';

/// Dépôt en mémoire pour tester le provider sans BD.
class _MemoryRepo implements ComplaintRepository {
  final items = <Complaint>[];

  @override
  Future<Complaint> create(Complaint c) async {
    items.add(c);
    return c;
  }

  @override
  Future<void> delete(String id) async => items.removeWhere((c) => c.id == id);
  @override
  Future<Complaint?> byId(String id) async =>
      items.where((c) => c.id == id).firstOrNull;
  @override
  Future<List<Complaint>> getByUser(String userId) async =>
      items.where((c) => c.userId == userId).toList();
  @override
  Future<String> nextReference({DateTime? now}) async =>
      ComplaintReference.next(
        items.map((c) => c.reference),
        now ?? DateTime.now(),
      );
  @override
  Future<Complaint> update(Complaint c) async {
    items[items.indexWhere((x) => x.id == c.id)] = c;
    return c;
  }
}

void main() {
  late ComplaintProvider provider;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    provider = ComplaintProvider(repository: _MemoryRepo());
    await provider.loadFor('u1');
  });

  Future<Complaint> create() async => (await provider.create(
    category: ComplaintCategory.panne,
    title: 'Batterie à plat',
    description: 'Impossible de démarrer le véhicule ce matin.',
  ))!;

  test('création : référence, statut, historique', () async {
    final c = await create();
    expect(c.reference, startsWith('REC-'));
    expect(c.status, ComplaintStatus.enAttente);
    expect(c.history.single.message, 'Réclamation envoyée');
  });

  test('démo : en attente → en cours → résolue avec réponse', () async {
    final c = await create();
    expect(await provider.simulateAgencyStep(c.id), ComplaintStatus.enCours);
    expect(await provider.simulateAgencyStep(c.id), ComplaintStatus.resolue);
    final done = provider.byId(c.id)!;
    expect(done.history.map((e) => e.status), [
      ComplaintStatus.enAttente,
      ComplaintStatus.enCours,
      ComplaintStatus.resolue,
    ]);
    expect(done.agencyResponse, isNotEmpty);
    // Close : plus d'étape possible.
    expect(await provider.simulateAgencyStep(c.id), isNull);
  });

  test('démo : rejet', () async {
    final c = await create();
    await provider.simulateAgencyStep(c.id);
    expect(
      await provider.simulateAgencyStep(c.id, reject: true),
      ComplaintStatus.rejetee,
    );
  });

  test('annulation seulement en attente', () async {
    final a = await create();
    expect(await provider.cancel(a.id), isTrue);
    expect(provider.complaints, isEmpty);

    final b = await create();
    await provider.simulateAgencyStep(b.id);
    expect(await provider.cancel(b.id), isFalse);
    expect(provider.complaints.length, 1);
  });

  test(
    'statut changé : non lu (badge) + notification, lu à l\'ouverture',
    () async {
      final alerts = _FakeAlerts();
      provider.alerts = alerts;
      final c = await create();
      expect(alerts.createdLog.single.id, c.id);
      expect(provider.unreadCount, 0);

      await provider.simulateAgencyStep(c.id);
      await Future<void>.delayed(Duration.zero);
      expect(alerts.statusLog.single.status, ComplaintStatus.enCours);
      expect(provider.isUnread(c.id), isTrue);
      expect(provider.unreadCount, 1);

      // Conservé pour l'utilisateur (rechargement de l'app).
      final reloaded = ComplaintProvider(repository: _MemoryRepoOf(provider));
      await reloaded.loadFor('u1');
      expect(reloaded.unreadCount, 1);

      await provider.markRead(c.id);
      expect(provider.unreadCount, 0);
    },
  );

  test(
    'modification sans changement de statut : pas de notification',
    () async {
      final alerts = _FakeAlerts();
      provider.alerts = alerts;
      final c = await create();
      await provider.update(c.copyWith(title: 'Batterie HS'));
      expect(alerts.statusLog, isEmpty);
      expect(provider.unreadCount, 0);
    },
  );

  test('une notification qui échoue ne bloque pas le changement', () async {
    provider.alerts = _FakeAlerts(fail: true);
    final c = await create();
    expect(await provider.simulateAgencyStep(c.id), ComplaintStatus.enCours);
  });
  test('note : seulement une fois, après résolution', () async {
    final c = await create();
    expect(await provider.rate(c.id, 5), isFalse); // pas encore résolue
    await provider.simulateAgencyStep(c.id);
    await provider.simulateAgencyStep(c.id);
    expect(await provider.rate(c.id, 0), isFalse);
    expect(await provider.rate(c.id, 4, comment: '  Rapide  '), isTrue);
    final rated = provider.byId(c.id)!;
    expect(rated.rating, 4);
    expect(rated.ratingComment, 'Rapide');
    expect(rated.canReopen, isFalse);
    expect(await provider.rate(c.id, 1), isFalse); // déjà notée
  });

  test(
    'note 1-2 : réouverture → en attente, historique, note effacée',
    () async {
      final alerts = _FakeAlerts();
      provider.alerts = alerts;
      final c = await create();
      await provider.simulateAgencyStep(c.id);
      await provider.simulateAgencyStep(c.id);
      await provider.rate(c.id, 2, comment: '  ');
      expect(provider.byId(c.id)!.ratingComment, isNull);
      expect(provider.byId(c.id)!.canReopen, isTrue);
      final notified = alerts.statusLog.length;

      expect(await provider.reopen(c.id), isTrue);
      final r = provider.byId(c.id)!;
      expect(r.status, ComplaintStatus.enAttente);
      expect(r.history.last.message, contains('2/5'));
      expect(r.rating, isNull);
      expect(r.canEdit, isTrue);
      // Action du client lui-même : ni notification ni badge.
      expect(alerts.statusLog.length, notified);
      expect(await provider.reopen(c.id), isFalse);
    },
  );
  test('démo : rejet comme abusive', () async {
    final c = await create();
    await provider.simulateAgencyStep(c.id);
    await provider.simulateAgencyStep(c.id, reject: true, abusive: true);
    final r = provider.byId(c.id)!;
    expect(r.status, ComplaintStatus.rejetee);
    expect(r.abusive, isTrue);
    expect(r.history.last.message, contains('abusive'));
  });
}

class _FakeAlerts implements ComplaintAlerts {
  _FakeAlerts({this.fail = false});

  final bool fail;
  final createdLog = <Complaint>[];
  final statusLog = <Complaint>[];

  @override
  Future<void> created(Complaint c) async {
    if (fail) throw Exception('plugin');
    createdLog.add(c);
  }

  @override
  Future<void> statusChanged(Complaint c) async {
    if (fail) throw Exception('plugin');
    statusLog.add(c);
  }
}

/// Même contenu que le provider (simule un redémarrage de l'app).
class _MemoryRepoOf extends _MemoryRepo {
  _MemoryRepoOf(ComplaintProvider p) {
    items.addAll(p.complaints);
  }
}
