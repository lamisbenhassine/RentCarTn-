import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Notifications locales (Android, sans serveur), fuseau Africa/Tunis.
///
/// Sur le web, toutes les méthodes sont sans effet : l'app fonctionne
/// simplement sans rappels.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _ready = false;

  /// Appelé au clic sur une notification (payload = route go_router).
  void Function(String route)? onOpenRoute;

  static const _channelId = 'rentcar_reminders';

  bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  /// À appeler avant runApp.
  Future<void> init() async {
    if (!isSupported || _ready) return;
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Africa/Tunis'));

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: (response) {
        final route = response.payload;
        if (route != null && route.isNotEmpty) onOpenRoute?.call(route);
      },
    );
    _ready = true;
  }

  /// Route de la notification qui a lancé l'app (app fermée), sinon `null`.
  Future<String?> launchRoute() async {
    if (!_ready) return null;
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp != true) return null;
    final route = details!.notificationResponse?.payload;
    return (route == null || route.isEmpty) ? null : route;
  }

  /// Android 13+ : affiche la demande POST_NOTIFICATIONS (une fois ou deux ;
  /// ensuite il faut passer par les paramètres). Avant Android 13 : `true`.
  Future<bool> requestPermission() async {
    if (!_ready) return false;
    final granted = await _android?.requestNotificationsPermission();
    return granted ?? await areEnabled();
  }

  Future<bool> areEnabled() async {
    if (!_ready) return false;
    return await _android?.areNotificationsEnabled() ?? false;
  }

  Future<void> openSettings() async {
    if (_ready) await _plugin.openAppNotificationSettings();
  }

  NotificationDetails _details(
    String channelName,
    String description, {
    String channelId = _channelId,
  }) => NotificationDetails(
    android: AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: description,
      importance: Importance.high,
      priority: Priority.high,
      styleInformation: const BigTextStyleInformation(''),
    ),
  );

  /// Alarme exacte si l'appareil l'autorise (SCHEDULE_EXACT_ALARM),
  /// sinon inexacte (peut arriver quelques minutes plus tard).
  Future<AndroidScheduleMode> _mode() async {
    final exact = await _android?.canScheduleExactNotifications() ?? false;
    return exact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
  }

  /// Programme une notification à l'heure [when] de Tunis.
  /// Retourne `false` si l'heure est passée ou si le service est inactif.
  Future<bool> schedule({
    required int id,
    required DateTime when,
    required String title,
    required String body,
    required String route,
    required String channelName,
    required String channelDescription,
  }) async {
    if (!_ready) return false;
    final at = tz.TZDateTime(
      tz.local,
      when.year,
      when.month,
      when.day,
      when.hour,
      when.minute,
      when.second,
    );
    if (!at.isAfter(tz.TZDateTime.now(tz.local))) return false;
    try {
      await _plugin.zonedSchedule(
        id: id,
        scheduledDate: at,
        title: title,
        body: body,
        payload: route,
        notificationDetails: _details(channelName, channelDescription),
        androidScheduleMode: await _mode(),
      );
      debugPrint('[Notif] #$id programmée pour $at → $route');
      return true;
    } catch (e) {
      debugPrint('[Notif] Échec programmation #$id : $e');
      return false;
    }
  }

  /// Démo : notification dans [delay] (10 s par défaut).
  /// Si l'alarme exacte n'est pas autorisée, l'app doit rester ouverte ou
  /// en arrière-plan (minuterie Dart).
  Future<void> showIn({
    required int id,
    required String title,
    required String body,
    required String route,
    required String channelName,
    required String channelDescription,
    Duration delay = const Duration(seconds: 10),
  }) async {
    if (!_ready) return;
    final exact = await _android?.canScheduleExactNotifications() ?? false;
    if (exact) {
      await schedule(
        id: id,
        when: tz.TZDateTime.now(tz.local).add(delay),
        title: title,
        body: body,
        route: route,
        channelName: channelName,
        channelDescription: channelDescription,
      );
      return;
    }
    debugPrint(
      '[Notif] Alarme exacte non autorisée : minuterie de ${delay.inSeconds} s',
    );
    Timer(delay, () {
      _plugin.show(
        id: id,
        title: title,
        body: body,
        payload: route,
        notificationDetails: _details(channelName, channelDescription),
      );
    });
  }

  /// Notification immédiate (ex. suivi de réclamation), sur son propre
  /// canal [channelId]. Sans effet si les notifications sont refusées.
  Future<void> show({
    required int id,
    required String title,
    required String body,
    required String route,
    required String channelId,
    required String channelName,
    required String channelDescription,
  }) async {
    if (!_ready) return;
    try {
      await _plugin.show(
        id: id,
        title: title,
        body: body,
        payload: route,
        notificationDetails: _details(
          channelName,
          channelDescription,
          channelId: channelId,
        ),
      );
      debugPrint('[Notif] #$id affichée → $route');
    } catch (e) {
      debugPrint('[Notif] Échec affichage #$id : $e');
    }
  }

  /// Annule seulement les rappels programmés : les notifications déjà
  /// affichées (suivi de réclamation) restent visibles.
  Future<void> cancelScheduled() async {
    if (!_ready) return;
    final pending = await _plugin.pendingNotificationRequests();
    for (final p in pending) {
      await _plugin.cancel(id: p.id);
    }
  }

  Future<void> cancel(int id) async {
    if (_ready) await _plugin.cancel(id: id);
  }

  /// Annule tout (déconnexion, suppression du compte, rappels désactivés).
  Future<void> cancelAll() async {
    if (!_ready) return;
    await _plugin.cancelAll();
    debugPrint('[Notif] Toutes les notifications annulées');
  }
}
