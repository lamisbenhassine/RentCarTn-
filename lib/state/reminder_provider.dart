import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/router/app_router.dart';
import '../data/models/profile_completion.dart';
import '../data/models/reservation.dart';
import '../data/models/user_profile.dart';
import '../data/services/notification_service.dart';
import '../data/services/reminder_planner.dart';
import '../l10n/app_localizations.dart';

/// Réglages des rappels (interrupteurs du profil) + programmation.
class ReminderProvider extends ChangeNotifier {
  ReminderProvider({NotificationService? service})
    : _service = service ?? NotificationService.instance;

  final NotificationService _service;

  static const _kLicence = 'reminder_licence';
  static const _kReservation = 'reminder_reservation';
  static const _kProfile = 'reminder_profile';

  /// La demande système n'est faite automatiquement qu'une fois.
  static const _kAsked = 'reminder_permission_asked';

  ReminderSettings _settings = const ReminderSettings();
  bool? _permissionGranted;

  ReminderSettings get settings => _settings;
  bool get supported => _service.isSupported;

  /// `false` si l'utilisateur a refusé les notifications (rappels inactifs).
  bool? get permissionGranted => _permissionGranted;

  /// Change quand un réglage change (pour savoir s'il faut reprogrammer).
  String get signature =>
      '${_settings.licence}${_settings.reservation}${_settings.profile}'
      '$_permissionGranted';

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _settings = ReminderSettings(
        licence: prefs.getBool(_kLicence) ?? true,
        reservation: prefs.getBool(_kReservation) ?? true,
        profile: prefs.getBool(_kProfile) ?? true,
      );
    } catch (_) {
      _settings = const ReminderSettings();
    }
    if (supported) _permissionGranted = await _service.areEnabled();
  }

  Future<void> setLicence(bool v) => _save(_kLicence, v);
  Future<void> setReservation(bool v) => _save(_kReservation, v);
  Future<void> setProfile(bool v) => _save(_kProfile, v);

  Future<void> _save(String key, bool value) async {
    _settings = ReminderSettings(
      licence: key == _kLicence ? value : _settings.licence,
      reservation: key == _kReservation ? value : _settings.reservation,
      profile: key == _kProfile ? value : _settings.profile,
    );
    notifyListeners(); // → reprogrammation par le coordinateur (main.dart)
    try {
      await (await SharedPreferences.getInstance()).setBool(key, value);
    } catch (_) {}
  }

  /// Bouton « Autoriser » : demande système, sinon paramètres Android.
  Future<void> requestPermission() async {
    var granted = await _service.requestPermission();
    if (!granted) {
      await _service.openSettings();
      granted = await _service.areEnabled();
    }
    _setPermission(granted);
  }

  /// Au retour dans l'app (l'utilisateur a pu changer le réglage Android).
  Future<void> refreshPermission() async {
    if (supported) _setPermission(await _service.areEnabled());
  }

  void _setPermission(bool granted) {
    if (granted == _permissionGranted) return;
    _permissionGranted = granted;
    notifyListeners();
  }

  /// (Re)programme tous les rappels de [user]. `null` (déconnexion,
  /// compte supprimé) → tout est annulé.
  Future<void> sync({
    required UserProfile? user,
    required List<Reservation> reservations,
    required AppLocalizations l,
  }) async {
    if (!supported) return;
    if (user == null || !_settings.anyEnabled) {
      await _service.cancelAll();
      return;
    }

    var granted = await _service.areEnabled();
    if (!granted) {
      // Première fois : demande système (Android 13+ : POST_NOTIFICATIONS).
      final prefs = await SharedPreferences.getInstance();
      if (!(prefs.getBool(_kAsked) ?? false)) {
        await prefs.setBool(_kAsked, true);
        granted = await _service.requestPermission();
      }
    }
    _setPermission(granted);
    if (!granted) {
      // Permission refusée : l'app fonctionne, simplement sans rappels.
      await _service.cancelScheduled();
      return;
    }

    // On repart de zéro : les dates ont pu changer.
    await _service.cancelScheduled();
    final plan = planReminders(
      user: user,
      reservations: reservations,
      settings: _settings,
      now: DateTime.now(),
    );
    final date = DateFormat.yMMMMd(l.localeName);
    for (final r in plan) {
      final (title, body) = _texts(r, user, l, date);
      await _service.schedule(
        id: r.id,
        when: r.when,
        title: title,
        body: body,
        route: r.route,
        channelName: l.notifChannelName,
        channelDescription: l.notifChannelDesc,
      );
    }
    debugPrint('[Notif] ${plan.length} rappel(s) programmé(s)');
  }

  (String, String) _texts(
    PlannedReminder r,
    UserProfile user,
    AppLocalizations l,
    DateFormat date,
  ) {
    final resa = r.reservation;
    return switch (r.kind) {
      ReminderKind.licence30 => (
        l.notifLicenceTitle,
        l.notifLicence30Body(date.format(user.licenceExpiry!)),
      ),
      ReminderKind.licence7 => (
        l.notifLicenceTitle,
        l.notifLicence7Body(date.format(user.licenceExpiry!)),
      ),
      ReminderKind.reservationStart => (
        l.notifResaStartTitle,
        l.notifResaStartBody(
          resa!.car.fullName,
          resa.pickupTime,
          resa.pickupCity,
        ),
      ),
      ReminderKind.reservationReturn => (
        l.notifResaReturnTitle,
        l.notifResaReturnBody(
          resa!.car.fullName,
          resa.returnTime,
          resa.returnCity,
        ),
      ),
      ReminderKind.profileIncomplete => (
        l.notifProfileTitle,
        l.notifProfileBody(user.completion.percent),
      ),
    };
  }

  /// Démo : notification dans 10 s, qui ouvre le profil.
  Future<void> sendTest(AppLocalizations l) async {
    if (!supported) return;
    var granted = await _service.areEnabled();
    if (!granted) granted = await _service.requestPermission();
    _setPermission(granted);
    if (!granted) return;
    await _service.showIn(
      id: ReminderIds.test,
      title: l.notifTestTitle,
      body: l.notifTestBody,
      route: Routes.profile,
      channelName: l.notifChannelName,
      channelDescription: l.notifChannelDesc,
    );
  }
}
