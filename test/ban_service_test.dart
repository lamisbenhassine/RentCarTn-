import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rentcar_tunisia/data/models/ban_record.dart';
import 'package:rentcar_tunisia/data/models/user_profile.dart';
import 'package:rentcar_tunisia/data/models/user_role.dart';
import 'package:rentcar_tunisia/data/repositories/auth_repository.dart';
import 'package:rentcar_tunisia/data/services/ban_service.dart';
import 'package:rentcar_tunisia/state/auth_provider.dart';

/// Comptes + historique en mémoire (mêmes règles que sqflite / prefs).
class _Repo implements AuthRepository {
  final users = <String, UserProfile>{
    'admin': const UserProfile(
      id: 'admin',
      firstName: 'Admin',
      lastName: 'RentCar',
      email: 'admin@rentcar.tn',
      phone: '',
      role: UserRole.admin,
    ),
    'u1': const UserProfile(
      id: 'u1',
      firstName: 'Sami',
      lastName: 'Trabelsi',
      email: 'sami@test.tn',
      phone: '22000000',
    ),
  };
  final bans = <BanRecord>[];
  bool sessionCleared = false;

  @override
  Future<UserProfile?> byId(String id) async => users[id];

  @override
  Future<UserProfile> login(String email, String password) async =>
      users.values.firstWhere((u) => u.email == email);

  @override
  Future<void> clearSession() async => sessionCleared = true;

  @override
  Future<UserProfile> banUser(BanRecord r) async {
    bans.add(r);
    return users[r.userId] = users[r.userId]!.copyWith(
      bannedUntil: r.end,
      banPermanent: r.permanent,
      banReason: r.reason,
      bannedBy: r.adminName,
    );
  }

  @override
  Future<UserProfile> unbanUser(
    String userId, {
    required String liftedBy,
    DateTime? at,
  }) async {
    for (var i = 0; i < bans.length; i++) {
      if (bans[i].userId == userId && bans[i].liftedAt == null) {
        bans[i] = bans[i].copyWith(
          liftedAt: at ?? DateTime.now(),
          liftedBy: liftedBy,
        );
      }
    }
    return users[userId] = users[userId]!.copyWith(clearBan: true);
  }

  @override
  Future<List<BanRecord>> getBanHistory(String userId) async =>
      bans.where((b) => b.userId == userId).toList();

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

void main() {
  late _Repo repo;
  late DateTime now;
  late BanService service;

  setUp(() {
    repo = _Repo();
    now = DateTime(2026, 11, 1, 10);
    service = BanService(repository: repo, clock: () => now);
  });

  UserProfile admin() => repo.users['admin']!;

  test('règles : ni admin, ni soi-même, motif et date future obligatoires', () {
    expect(
      () => service.banUser(
        userId: 'admin',
        admin: admin(),
        reason: 'x',
        permanent: true,
      ),
      throwsA(
        isA<BanException>().having(
          (e) => e.code,
          'code',
          BanErrorCode.selfTarget,
        ),
      ),
    );
    repo.users['admin2'] = UserProfile(
      id: 'admin2',
      firstName: 'B',
      lastName: 'C',
      email: 'b@c.tn',
      phone: '',
      role: UserRole.admin, // autre admin
    );
    expect(
      () => service.banUser(
        userId: 'admin2',
        admin: admin(),
        reason: 'x',
        permanent: true,
      ),
      throwsA(
        isA<BanException>().having(
          (e) => e.code,
          'code',
          BanErrorCode.adminTarget,
        ),
      ),
    );
    expect(
      () => service.banUser(
        userId: 'u1',
        admin: admin(),
        reason: '  ',
        permanent: true,
      ),
      throwsA(isA<BanException>()),
    );
    expect(
      () => service.banUser(
        userId: 'u1',
        admin: admin(),
        reason: 'Spam',
        until: now.subtract(const Duration(minutes: 1)),
      ),
      throwsA(
        isA<BanException>().having(
          (e) => e.code,
          'code',
          BanErrorCode.endInPast,
        ),
      ),
    );
  });

  test('bannissement temporaire puis réactivation automatique', () async {
    final banned = await service.banUser(
      userId: 'u1',
      admin: admin(),
      reason: 'Fausse réclamation REC-2026-0001',
      duration: const Duration(minutes: 2),
      complaintId: 'cmp-1',
    );
    expect(banned.isBannedAt(now), isTrue);
    expect(banned.bannedUntil, now.add(const Duration(minutes: 2)));
    expect(repo.bans.single.complaintId, 'cmp-1');
    expect(repo.bans.single.adminName, 'Admin RentCar');

    // Encore actif : refresh ne change rien.
    expect((await service.refresh(banned)).banReason, isNotNull);

    // 3 minutes plus tard : levé automatiquement, daté de la fin prévue.
    now = now.add(const Duration(minutes: 3));
    final back = await service.refresh(repo.users['u1']!);
    expect(back.isBannedAt(now), isFalse);
    expect(back.bannedUntil, isNull);
    final record = (await service.getBanHistory('u1')).single;
    expect(record.liftedBy, BanService.autoLiftedBy);
    expect(record.liftedAt, banned.bannedUntil);
  });

  test('définitif, puis débannissement par l\'admin', () async {
    final banned = await service.banUser(
      userId: 'u1',
      admin: admin(),
      reason: 'Fraude',
      permanent: true,
    );
    now = now.add(const Duration(days: 9999));
    expect((await service.refresh(banned)).isBanned, isTrue);
    final back = await service.unbanUser('u1', admin: admin());
    expect(back.isBanned, isFalse);
    expect(repo.bans.single.liftedBy, 'Admin RentCar');
  });

  test('libellés des e-mails', () {
    expect(BanService.formatDuration(const Duration(minutes: 2)), '2 min');
    expect(BanService.formatDuration(const Duration(hours: 24)), '1 jour');
    expect(BanService.formatDuration(const Duration(days: 7)), '7 jours');
    expect(
      BanService.formatDate(DateTime(2026, 11, 3, 14, 5)),
      '03/11/2026 à 14:05',
    );
  });

  test('connexion d\'un compte banni : refusée, écran suspendu', () async {
    SharedPreferences.setMockInitialValues({});
    await service.banUser(
      userId: 'u1',
      admin: admin(),
      reason: 'Spam',
      duration: const Duration(days: 1),
    );
    final auth = AuthProvider(
      repository: repo,
      bans: BanService(repository: repo), // horloge réelle
    );
    // Fin du ban dans le futur réel.
    repo.users['u1'] = repo.users['u1']!.copyWith(
      bannedUntil: DateTime.now().add(const Duration(days: 1)),
    );
    expect(await auth.login('sami@test.tn', 'secret'), isFalse);
    expect(auth.errorCode, AuthErrorCode.banned);
    expect(auth.user, isNull);
    expect(auth.suspended?.id, 'u1');
    expect(repo.sessionCleared, isTrue);
    expect(auth.attemptsLeft, AuthProvider.maxAttempts); // pas un échec

    auth.clearSuspended();
    expect(auth.suspended, isNull);
  });
}
