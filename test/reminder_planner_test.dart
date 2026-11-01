import 'package:flutter_test/flutter_test.dart';
import 'package:rentcar_tunisia/core/router/app_router.dart';
import 'package:rentcar_tunisia/data/mock/mock_reservations.dart';
import 'package:rentcar_tunisia/data/models/date_range.dart';
import 'package:rentcar_tunisia/data/models/reservation.dart';
import 'package:rentcar_tunisia/data/models/user_profile.dart';
import 'package:rentcar_tunisia/data/services/reminder_planner.dart';

void main() {
  final now = DateTime(2026, 10, 30, 12);

  UserProfile user({
    DateTime? expiry,
    DateTime? since,
    bool complete = false,
  }) => UserProfile(
    id: 'u1',
    firstName: 'A',
    lastName: 'B',
    email: 'a@b.tn',
    phone: complete ? '22345678' : '',
    licenceExpiry: expiry ?? (complete ? DateTime(2030) : null),
    memberSince: since,
    avatarUrl: complete ? 'x' : null,
    cin: complete ? '12345678' : '',
    licenceNumber: complete ? 'TN-1' : '',
    address: complete ? 'Rue' : '',
    latitude: complete ? 36.8 : null,
    longitude: complete ? 10.1 : null,
    emailVerified: complete,
  );

  Reservation resa(ReservationStatus status, DateTime start, DateTime end) =>
      MockReservations.build().first.copyWith(
        status: status,
        range: DateRange(start, end),
      );

  List<PlannedReminder> plan({
    UserProfile? u,
    List<Reservation> r = const [],
    ReminderSettings s = const ReminderSettings(),
  }) =>
      planReminders(user: u ?? user(), reservations: r, settings: s, now: now);

  test('permis : 30 et 7 jours avant, à 9 h', () {
    final list = plan(u: user(expiry: DateTime(2027, 1, 15)));
    final byKind = {for (final p in list) p.kind: p};
    expect(byKind[ReminderKind.licence30]!.when, DateTime(2026, 12, 16, 9));
    expect(byKind[ReminderKind.licence7]!.when, DateTime(2027, 1, 8, 9));
    expect(byKind[ReminderKind.licence7]!.route, Routes.editProfile);
  });

  test('permis : rappels passés ignorés', () {
    // J-30 (21/10) passé, J-7 (13/11) à venir.
    final list = plan(u: user(expiry: DateTime(2026, 11, 20)));
    expect(list.single.kind, ReminderKind.licence7);
    // Les deux passés.
    expect(plan(u: user(expiry: DateTime(2026, 11, 3))), isEmpty);
  });

  test('profil complet : les rappels permis existent mais pas le profil', () {
    final list = plan(u: user(since: DateTime(2026, 10, 29), complete: true));
    expect(
      list.where((p) => p.kind == ReminderKind.profileIncomplete),
      isEmpty,
    );
  });

  test('réservation à venir : veille 18 h + retour 8 h', () {
    final r = resa(
      ReservationStatus.aVenir,
      DateTime(2026, 11, 10),
      DateTime(2026, 11, 14),
    );
    final list = plan(r: [r]);
    expect(list.length, 2);
    expect(list[0].when, DateTime(2026, 11, 9, 18));
    expect(list[1].when, DateTime(2026, 11, 14, 8));
    expect(list[0].route, Routes.reservation(r.id));
    expect(list[1].id, list[0].id + 1);
  });

  test('réservation en cours : seulement le retour ; terminée : rien', () {
    final enCours = resa(
      ReservationStatus.enCours,
      DateTime(2026, 10, 28),
      DateTime(2026, 11, 2),
    );
    final finie = resa(
      ReservationStatus.terminee,
      DateTime(2026, 9, 1),
      DateTime(2026, 9, 5),
    );
    final list = plan(r: [enCours, finie]);
    expect(list.single.kind, ReminderKind.reservationReturn);
  });

  test('profil incomplet : 2 jours après l’inscription, pas si complet', () {
    final since = DateTime(2026, 10, 29, 15);
    expect(plan(u: user(since: since)).single.when, DateTime(2026, 10, 31, 15));
    expect(
      plan(u: user(since: since, complete: true))
          .where((p) => p.kind == ReminderKind.profileIncomplete),
      isEmpty,
    );
  });

  test('types désactivés → aucun rappel', () {
    final list = plan(
      u: user(expiry: DateTime(2027, 6, 1), since: DateTime(2026, 10, 29)),
      s: const ReminderSettings(
        licence: false,
        reservation: false,
        profile: false,
      ),
    );
    expect(list, isEmpty);
  });

  test('ids de réservation stables', () {
    expect(
      ReminderIds.reservationStart('res-001'),
      ReminderIds.reservationStart('res-001'),
    );
    expect(
      ReminderIds.reservationStart('res-001'),
      isNot(ReminderIds.reservationStart('res-002')),
    );
  });
}
