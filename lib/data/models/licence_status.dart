import 'user_profile.dart';

/// État du permis de conduire selon sa date d'expiration.
enum LicenceStatus {
  /// Date d'expiration non renseignée.
  unknown,
  valid,

  /// Expire dans [LicenceRules.warningDays] jours ou moins.
  expiringSoon,
  expired,
}

abstract final class LicenceRules {
  /// Alerte affichée à partir de 30 jours avant l'expiration.
  static const int warningDays = 30;
}

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

extension UserLicence on UserProfile {
  /// Jours restants avant expiration (négatif si expiré, `null` si inconnu).
  /// Le permis est valable jusqu'au jour d'expiration inclus.
  int? daysUntilLicenceExpiry({DateTime? now}) {
    final expiry = licenceExpiry;
    if (expiry == null) return null;
    return _day(expiry).difference(_day(now ?? DateTime.now())).inDays;
  }

  LicenceStatus licenceStatus({DateTime? now}) {
    final days = daysUntilLicenceExpiry(now: now);
    if (days == null) return LicenceStatus.unknown;
    if (days < 0) return LicenceStatus.expired;
    if (days <= LicenceRules.warningDays) return LicenceStatus.expiringSoon;
    return LicenceStatus.valid;
  }

  /// `true` si le permis est valable jusqu'au [lastDay] inclus
  /// (dernier jour de location). Date inconnue → pas de blocage.
  bool licenceValidUntil(DateTime lastDay) {
    final expiry = licenceExpiry;
    if (expiry == null) return true;
    return !_day(expiry).isBefore(_day(lastDay));
  }
}
