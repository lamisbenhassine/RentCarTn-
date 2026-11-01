import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/router/app_router.dart';
import '../../data/models/complaint.dart';
import '../../data/services/notification_service.dart';
import '../../l10n/app_localizations.dart';
import '../../state/complaint_provider.dart';
import 'complaint_l10n.dart';

/// Notifications locales du module Réclamations (canal dédié).
///
/// - changement de statut : « Votre réclamation REC-… est maintenant … » ;
/// - réclamation urgente créée : confirmation immédiate.
/// Clic → détail de la réclamation (payload = route `/reclamations/<id>`,
/// géré par [NotificationService.onOpenRoute] dans main.dart).
///
/// Permission refusée : rien n'est affiché, l'app fonctionne normalement
/// (badge dans le profil + bandeau dans « Mes réclamations »).
class ComplaintNotifications implements ComplaintAlerts {
  ComplaintNotifications({
    required this.l10n,
    this.onPermissionChanged,
    NotificationService? service,
  }) : _service = service ?? NotificationService.instance;

  /// Textes dans la langue courante de l'app.
  final AppLocalizations Function() l10n;

  /// Prévient l'interface (ReminderProvider.refreshPermission).
  final Future<void> Function()? onPermissionChanged;

  final NotificationService _service;

  static const channelId = 'rentcar_complaints';

  /// La demande Android 13+ n'est faite automatiquement qu'une fois
  /// (à la première réclamation) ; ensuite : bouton « Activer ».
  static const _kAsked = 'complaint_notif_permission_asked';

  /// Identifiant stable par réclamation (remplace la notification précédente
  /// de la même réclamation) : 500000 + 2 × hash (+1 pour l'alerte urgente).
  static int idFor(String complaintId, {bool urgent = false}) {
    var hash = 0x811c9dc5;
    for (final unit in complaintId.codeUnits) {
      hash = ((hash ^ unit) * 0x01000193) & 0xffffffff;
    }
    return 500000 + 2 * (hash % 100000) + (urgent ? 1 : 0);
  }

  @override
  Future<void> created(Complaint complaint) async {
    if (!_service.isSupported) return;
    if (!await _ensurePermission()) return;
    if (complaint.priority != ComplaintPriority.urgente) return;

    final l = l10n();
    await _service.show(
      id: idFor(complaint.id, urgent: true),
      title: l.complaintNotifUrgentTitle,
      body: l.complaintNotifUrgentBody(complaint.reference),
      route: Routes.complaint(complaint.id),
      channelId: channelId,
      channelName: l.complaintNotifChannel,
      channelDescription: l.complaintNotifChannelDesc,
    );
  }

  @override
  Future<void> statusChanged(Complaint complaint) async {
    if (!_service.isSupported) return;
    if (!await _service.areEnabled()) {
      debugPrint(
        '[Notif] ${complaint.reference} → ${complaint.status.name} : '
        'notifications refusées (badge seulement)',
      );
      return;
    }
    final l = l10n();
    await _service.show(
      id: idFor(complaint.id),
      title: l.complaintNotifStatusTitle(complaint.reference),
      body: l.complaintNotifStatusBody(
        complaint.reference,
        l.complaintStatus(complaint.status),
      ),
      route: Routes.complaint(complaint.id),
      channelId: channelId,
      channelName: l.complaintNotifChannel,
      channelDescription: l.complaintNotifChannelDesc,
    );
  }

  /// Android 13+ : POST_NOTIFICATIONS demandée une seule fois ici.
  Future<bool> _ensurePermission() async {
    if (await _service.areEnabled()) return true;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_kAsked) ?? false) {
        debugPrint('[Notif] Réclamations : notifications refusées');
        return false;
      }
      await prefs.setBool(_kAsked, true);
    } catch (_) {}
    final granted = await _service.requestPermission();
    await onPermissionChanged?.call();
    if (!granted) debugPrint('[Notif] Réclamations : permission refusée');
    return granted;
  }
}
