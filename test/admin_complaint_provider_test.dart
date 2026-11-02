import 'package:flutter_test/flutter_test.dart';
import 'package:rentcar_tunisia/data/models/complaint.dart';
import 'package:rentcar_tunisia/data/models/user_profile.dart';
import 'package:rentcar_tunisia/data/repositories/auth_repository.dart';
import 'package:rentcar_tunisia/data/repositories/complaint_repository.dart';
import 'package:rentcar_tunisia/state/admin_complaint_provider.dart';
import 'package:rentcar_tunisia/state/complaint_provider.dart';

class _MemoryRepo implements ComplaintRepository {
  _MemoryRepo(this.items);

  final List<Complaint> items;

  @override
  Future<List<Complaint>> getAll() async => [...items];
  @override
  Future<Complaint> update(Complaint c) async {
    items[items.indexWhere((x) => x.id == c.id)] = c;
    return c;
  }

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

/// Comptes clients (seuls byId / updateProfile servent au back office).
class _Users implements AuthRepository {
  final users = <String, UserProfile>{
    'u1': const UserProfile(
      id: 'u1',
      firstName: 'Sami',
      lastName: 'Trabelsi',
      email: 'sami@test.tn',
      phone: '22000000',
      trustScore: 55,
    ),
  };

  @override
  Future<UserProfile?> byId(String id) async => users[id];
  @override
  Future<UserProfile> updateProfile(UserProfile u) async => users[u.id] = u;

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _Alerts implements ComplaintAlerts {
  final status = <ComplaintStatus>[];
  int responses = 0;

  @override
  Future<void> created(Complaint c) async {}
  @override
  Future<void> statusChanged(Complaint c) async => status.add(c.status);
  @override
  Future<void> responded(Complaint c) async => responses++;
}

Complaint _complaint(
  String id,
  ComplaintPriority priority,
  DateTime at, {
  String userId = 'u1',
}) => Complaint(
  id: id,
  reference: 'REC-2026-$id',
  userId: userId,
  category: ComplaintCategory.panne,
  title: 'Batterie à plat',
  description: 'Impossible de démarrer le véhicule ce matin.',
  priority: priority,
  status: ComplaintStatus.enAttente,
  isUrgent: priority == ComplaintPriority.urgente,
  history: [
    ComplaintEvent(
      status: ComplaintStatus.enAttente,
      date: at,
      message: 'Réclamation envoyée',
    ),
  ],
  createdAt: at,
  updatedAt: at,
);

void main() {
  late _Users users;
  late _Alerts alerts;
  late List<(String, String)> unread;
  late AdminComplaintProvider admin;

  setUp(() async {
    users = _Users();
    alerts = _Alerts();
    unread = [];
    final now = DateTime.now();
    admin = AdminComplaintProvider(
      repository: _MemoryRepo([
        _complaint('0001', ComplaintPriority.basse, now),
        _complaint('0002', ComplaintPriority.urgente, now.subtract(_day)),
        _complaint('0003', ComplaintPriority.moyenne, now),
        _complaint('0004', ComplaintPriority.moyenne, now, userId: 'gone'),
      ]),
      users: users,
      markUnread: (u, c) async => unread.add((u, c)),
    )..alerts = alerts;
    await admin.loadAll();
  });

  test('toutes les réclamations, nom du client, tri priorité puis date', () {
    expect(admin.entries.map((e) => e.complaint.id), [
      '0002', // urgente (même plus ancienne)
      '0003',
      '0004',
      '0001', // basse
    ]);
    expect(admin.byId('0001')!.clientName, 'Sami Trabelsi');
    expect(admin.byId('0004')!.client, isNull); // compte supprimé
    expect(admin.pendingCount, 4);
  });

  test('prendre en charge → répondre → résoudre : historique signé', () async {
    expect(await admin.respond('0001', 'Bonjour', by: 'Admin'), isNull);
    final taken = await admin.takeCharge('0001', by: 'Admin RentCar');
    expect(taken!.status, ComplaintStatus.enCours);
    expect(taken.handledBy, 'Admin RentCar');
    expect(taken.history.last.by, 'Admin RentCar');

    final replied = await admin.respond(
      '0001',
      'Un dépanneur arrive.',
      by: 'A',
    );
    expect(replied!.status, ComplaintStatus.enCours);
    expect(replied.agencyResponse, 'Un dépanneur arrive.');

    final done = await admin.resolve('0001', 'Batterie changée.', by: 'A');
    expect(done!.status, ComplaintStatus.resolue);
    expect(done.closedAt, isNotNull);
    expect(done.processingTime, isNotNull);
    expect(await admin.takeCharge('0001', by: 'A'), isNull); // close

    // Badge client + notifications (2 statuts, 1 réponse).
    expect(unread.length, 3);
    expect(unread.first, ('u1', '0001'));
    expect(alerts.status, [ComplaintStatus.enCours, ComplaintStatus.resolue]);
    expect(alerts.responses, 1);
  });

  test('rejet abusif : -10 sur le score de confiance du client', () async {
    expect(await admin.reject('0003', '  ', by: 'A'), isNull); // message vide
    final r = await admin.reject(
      '0003',
      'Aucun incident constaté.',
      abusive: true,
      by: 'A',
    );
    expect(r!.status, ComplaintStatus.rejetee);
    expect(r.abusive, isTrue);
    expect(users.users['u1']!.trustScore, 45);
    expect(admin.byId('0001')!.client!.trustScore, 45);
    expect(admin.rejectedCountOf('u1'), 1);

    // Rejet simple : pas de pénalité.
    await admin.reject('0001', 'Hors de notre responsabilité.', by: 'A');
    expect(users.users['u1']!.trustScore, 45);
  });

  test('tableau de bord : compteurs, temps moyen, note moyenne', () {
    final now = DateTime(2026, 11, 1, 12);
    Complaint closed(String id, Duration took, int? rating) =>
        _complaint(id, ComplaintPriority.moyenne, now)
            .withEvent(ComplaintStatus.resolue, 'ok', at: now.add(took))
            .copyWith(closedAt: now.add(took), rating: rating);

    final stats = AdminComplaintStats.of([
      _complaint('a', ComplaintPriority.basse, now),
      closed('b', const Duration(hours: 2), 4),
      closed('c', const Duration(hours: 4), 2),
    ]);
    expect(stats.pending, 1);
    expect(stats.resolved, 2);
    expect(stats.rejected, 0);
    expect(stats.averageProcessing, const Duration(hours: 3));
    expect(stats.averageRating, 3);
    expect(stats.ratingCount, 2);
    expect(AdminComplaintStats.of([]).averageProcessing, isNull);
  });
}

const _day = Duration(days: 1);
