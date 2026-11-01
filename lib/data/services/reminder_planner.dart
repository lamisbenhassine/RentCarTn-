import '../../core/router/app_router.dart';
import '../models/profile_completion.dart';
import '../models/reservation.dart';
import '../models/user_profile.dart';

/// Types de rappels (chacun activable dans le profil).
enum ReminderKind {
  licence30,
  licence7,
  reservationStart,
  reservationReturn,
  profileIncomplete,
}

/// Rappel à programmer. [when] est une heure « murale » de Tunis
/// (convertie en Africa/Tunis par le service).
class PlannedReminder {
  const PlannedReminder({
    required this.id,
    required this.kind,
    required this.when,
    required this.route,
    this.reservation,
  });

  final int id;
  final ReminderKind kind;
  final DateTime when;

  /// Écran ouvert au clic (payload de la notification).
  final String route;
  final Reservation? reservation;
}

/// Quels types de rappels sont activés.
class ReminderSettings {
  const ReminderSettings({
    this.licence = true,
    this.reservation = true,
    this.profile = true,
  });

  final bool licence;
  final bool reservation;
  final bool profile;

  bool get anyEnabled => licence || reservation || profile;
}

/// Identifiants stables (un même rappel garde le même id d'un lancement
/// à l'autre, pour pouvoir l'annuler ou le remplacer).
abstract final class ReminderIds {
  static const licence30 = 1001;
  static const licence7 = 1002;
  static const profileIncomplete = 2001;
  static const test = 9001;

  /// Réservations : 300000 + 2 × (hash % 100000) (+1 pour le retour).
  static const reservationBase = 300000;

  static int reservationStart(String reservationId) =>
      reservationBase + 2 * (_fnv1a(reservationId) % 100000);
  static int reservationReturn(String reservationId) =>
      reservationStart(reservationId) + 1;

  /// Hash FNV-1a 32 bits : identique à chaque lancement (contrairement à
  /// String.hashCode, qui n'est pas garanti stable).
  static int _fnv1a(String s) {
    var hash = 0x811c9dc5;
    for (final unit in s.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return hash;
  }
}

/// Heures d'envoi.
abstract final class ReminderHours {
  static const licence = 9; // 9 h, 30 et 7 jours avant
  static const reservationEve = 18; // 18 h la veille du début
  static const reservationReturn = 8; // 8 h le jour du retour
}

/// Calcule les rappels à programmer (fonction pure, testée).
/// Seuls les rappels dans le futur (après [now]) sont retournés.
List<PlannedReminder> planReminders({
  required UserProfile user,
  required List<Reservation> reservations,
  required ReminderSettings settings,
  required DateTime now,
}) {
  final out = <PlannedReminder>[];
  void add(PlannedReminder r) {
    if (r.when.isAfter(now)) out.add(r);
  }

  DateTime at(DateTime day, int hour) =>
      DateTime(day.year, day.month, day.day, hour);

  // --- Permis : 30 et 7 jours avant l'expiration ---
  final expiry = user.licenceExpiry;
  if (settings.licence && expiry != null) {
    add(
      PlannedReminder(
        id: ReminderIds.licence30,
        kind: ReminderKind.licence30,
        when: at(
          expiry.subtract(const Duration(days: 30)),
          ReminderHours.licence,
        ),
        route: Routes.editProfile,
      ),
    );
    add(
      PlannedReminder(
        id: ReminderIds.licence7,
        kind: ReminderKind.licence7,
        when: at(
          expiry.subtract(const Duration(days: 7)),
          ReminderHours.licence,
        ),
        route: Routes.editProfile,
      ),
    );
  }

  // --- Réservations : veille du début, jour du retour ---
  if (settings.reservation) {
    for (final r in reservations) {
      final route = Routes.reservation(r.id);
      if (r.status == ReservationStatus.aVenir) {
        add(
          PlannedReminder(
            id: ReminderIds.reservationStart(r.id),
            kind: ReminderKind.reservationStart,
            when: at(
              r.range.start.subtract(const Duration(days: 1)),
              ReminderHours.reservationEve,
            ),
            route: route,
            reservation: r,
          ),
        );
      }
      if (r.status == ReservationStatus.aVenir ||
          r.status == ReservationStatus.enCours) {
        add(
          PlannedReminder(
            id: ReminderIds.reservationReturn(r.id),
            kind: ReminderKind.reservationReturn,
            when: at(r.range.end, ReminderHours.reservationReturn),
            route: route,
            reservation: r,
          ),
        );
      }
    }
  }

  // --- Profil incomplet : 2 jours après l'inscription ---
  final since = user.memberSince;
  if (settings.profile && since != null && !user.completion.isComplete) {
    add(
      PlannedReminder(
        id: ReminderIds.profileIncomplete,
        kind: ReminderKind.profileIncomplete,
        when: since.add(const Duration(days: 2)),
        route: Routes.profile,
      ),
    );
  }

  return out;
}
