import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../data/models/complaint.dart';
import '../../data/models/user_profile.dart';
import '../../l10n/l10n.dart';
import '../../state/admin_complaint_provider.dart';
import '../../state/auth_provider.dart';
import '../../state/car_provider.dart';
import '../../state/load_state.dart';
import '../../widgets/common.dart';
import '../../widgets/status_badge.dart';
import '../complaints/complaint_actions.dart';
import '../complaints/complaint_details_screen.dart';
import '../complaints/complaint_l10n.dart';
import '../complaints/complaint_mail.dart';
import '../complaints/widgets/complaint_car.dart';
import '../complaints/widgets/complaint_photo.dart';
import '../complaints/widgets/rating_stars.dart';
import 'ban_sheet.dart';

/// Action de l'admin sur une réclamation.
enum _AdminAction { take, respond, resolve, reject, rejectAbusive }

/// Détail d'une réclamation côté admin : client (score de confiance,
/// réclamations rejetées), véhicule, photos, position, analyse IA,
/// historique, et actions selon le statut.
class AdminComplaintDetailsScreen extends StatefulWidget {
  const AdminComplaintDetailsScreen({super.key, required this.complaintId});

  final String complaintId;

  @override
  State<AdminComplaintDetailsScreen> createState() =>
      _AdminComplaintDetailsScreenState();
}

class _AdminComplaintDetailsScreenState
    extends State<AdminComplaintDetailsScreen> {
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    // Ouverture directe (notification) : la liste n'est pas encore chargée.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AdminComplaintProvider>().loadAll();
      context.read<CarProvider>().load();
    });
  }

  String _dateTime(BuildContext context, DateTime d) =>
      DateFormat.yMMMMd(Localizations.localeOf(context).toLanguageTag())
          .add_Hm()
          .format(d);

  /// Demande confirmation (et le message au client), exécute l'action,
  /// puis e-mail au client et, pour un rejet abusif, « Bannir ce client ? ».
  Future<void> _run(AdminComplaintEntry entry, _AdminAction action) async {
    final l = context.l10n;
    final c = entry.complaint;

    String? message;
    if (action == _AdminAction.take) {
      final ok = await _confirm(l.adminTake, l.adminTakeConfirm(c.reference));
      if (ok != true) return;
    } else {
      if (!mounted) return;
      message = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => _MessageSheet(action: action),
      );
      if (message == null) return;
    }
    if (!mounted) return;

    final provider = context.read<AdminComplaintProvider>();
    final by = context.read<AuthProvider>().user?.fullName.trim();
    final admin = (by == null || by.isEmpty) ? 'Admin RentCar' : by;

    setState(() => _busy = true);
    final saved = switch (action) {
      _AdminAction.take => await provider.takeCharge(c.id, by: admin),
      _AdminAction.respond => await provider.respond(c.id, message!, by: admin),
      _AdminAction.resolve => await provider.resolve(c.id, message!, by: admin),
      _AdminAction.reject => await provider.reject(c.id, message!, by: admin),
      _AdminAction.rejectAbusive => await provider.reject(
        c.id,
        message!,
        abusive: true,
        by: admin,
      ),
    };
    if (!mounted) return;
    setState(() => _busy = false);
    if (saved == null) {
      AppSnack.error(context, l.adminActionFailed);
      return;
    }
    AppSnack.success(
      context,
      action == _AdminAction.respond
          ? l.adminResponseSent
          : l.adminActionDone(saved.reference, l.complaintStatus(saved.status)),
    );

    // E-mail au client (modèle EmailJS n° 2), sans bloquer l'écran.
    final client = provider.byId(c.id)?.client ?? entry.client;
    sendComplaintMail(saved, client, message: message).then((result) {
      if (!mounted) return;
      switch (result) {
        case ComplaintMailResult.sent:
          AppSnack.info(
            context,
            l.complaintMailStatusSent(maskedComplaintEmail(client)),
          );
        case ComplaintMailResult.failed:
          AppSnack.info(context, l.complaintMailFailed);
        case ComplaintMailResult.skipped:
          break;
      }
    });

    if (action == _AdminAction.rejectAbusive && client != null) {
      await _proposeBan(client, saved);
    }
  }

  Future<bool?> _confirm(String title, String message) => showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text(context.l10n.commonCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(context.l10n.adminConfirm),
        ),
      ],
    ),
  );

  /// Après un rejet abusif : dialogue « Bannir » directement, motif
  /// pré-rempli « Fausse réclamation REC-… » (« Annuler » = pas de ban).
  /// Un admin ne peut pas être banni : rien n'est proposé.
  Future<void> _proposeBan(UserProfile client, Complaint complaint) async {
    if (!mounted || client.isAdmin || client.isBanned) return;
    await showBanSheet(context, user: client, complaint: complaint);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final provider = context.watch<AdminComplaintProvider>();
    final entry = provider.byId(widget.complaintId);
    final pad = Responsive.value(context, mobile: 16.0, tablet: 24.0);

    final Widget body;
    if (entry == null) {
      body = provider.state == LoadState.initial || provider.state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : EmptyState(
              icon: Icons.search_off_rounded,
              title: l.adminDetailsTitle,
              message: l.complaintNotFound,
            );
    } else {
      final c = entry.complaint;
      body = ContentContainer(
        maxWidth: 760,
        child: ListView(
          padding: EdgeInsets.fromLTRB(pad, 16, pad, 32),
          children: [
            ComplaintHeader(complaint: c),
            const SizedBox(height: 14),
            _ClientCard(
              entry: entry,
              rejected: provider.rejectedCountOf(c.userId),
              total: provider.complaintsOf(c.userId).length,
            ),
            const SizedBox(height: 14),
            ComplaintInfoCard(complaint: c, dateTime: _dateTime),
            if (c.handledBy != null) ...[
              const SizedBox(height: 8),
              Text(
                l.adminHandledBy(c.handledBy!),
                style: TextStyle(fontSize: 12.5, color: context.cs.outline),
              ),
            ],
            if (c.carId != null || c.carLabel != null) ...[
              const SizedBox(height: 14),
              ComplaintCarCard(carId: c.carId, label: c.carLabel),
            ],
            const SizedBox(height: 14),
            ComplaintLinkedItem(complaint: c),
            const SizedBox(height: 14),
            ComplaintSection(
              icon: Icons.notes_rounded,
              title: l.complaintDescLabel,
              child: SelectableText(
                c.description,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.55,
                  color: context.cs.onSurface,
                ),
              ),
            ),
            if (c.aiSummary != null || c.aiTone != null) ...[
              const SizedBox(height: 14),
              ComplaintAiCard(complaint: c),
            ],
            if (c.photoPaths.isNotEmpty) ...[
              const SizedBox(height: 14),
              ComplaintSection(
                icon: Icons.photo_library_outlined,
                title: '${l.complaintPhotos} (${c.photoPaths.length})',
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var i = 0; i < c.photoPaths.length; i++)
                      ComplaintPhotoThumb(
                        path: c.photoPaths[i],
                        onTap: () => openComplaintGallery(
                          context,
                          c.photoPaths,
                          initialIndex: i,
                        ),
                      ),
                  ],
                ),
              ),
            ],
            if (c.hasLocation) ...[
              const SizedBox(height: 14),
              ComplaintSection(
                icon: Icons.place_outlined,
                title: l.complaintLocation,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (c.locationAddress != null)
                      Text(
                        c.locationAddress!,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: context.cs.onSurface,
                        ),
                      ),
                    Text(
                      '${c.latitude!.toStringAsFixed(5)}, '
                      '${c.longitude!.toStringAsFixed(5)}',
                      textDirection: TextDirection.ltr,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: context.cs.outline,
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () =>
                          openInMaps(context, c.latitude!, c.longitude!),
                      icon: const Icon(Icons.map_outlined, size: 18),
                      label: Text(l.complaintOpenMaps),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            ComplaintAgencyResponse(complaint: c),
            if (c.rating != null) ...[
              const SizedBox(height: 14),
              ComplaintSection(
                icon: Icons.star_rounded,
                title: l.adminStatAvgRating,
                color: AppColors.gold,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RatingStars(value: c.rating!),
                    if (c.ratingComment != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        c.ratingComment!,
                        style: TextStyle(color: context.cs.onSurface),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            ComplaintSection(
              icon: Icons.timeline_rounded,
              title: l.complaintHistory,
              child: ComplaintTimeline(events: c.history, dateTime: _dateTime),
            ),
            const SizedBox(height: 18),
            _Actions(
              complaint: c,
              busy: _busy,
              onAction: (a) => _run(entry, a),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: context.cs.surfaceContainerLow,
      appBar: AppBar(
        backgroundColor: context.cs.surfaceContainerLow,
        title: Text(entry?.complaint.reference ?? l.adminDetailsTitle),
        shape: Border(bottom: BorderSide(color: context.cs.outlineVariant)),
      ),
      body: SafeArea(child: body),
    );
  }
}

/// Client : nom, contact, score de confiance, réclamations rejetées.
class _ClientCard extends StatelessWidget {
  const _ClientCard({
    required this.entry,
    required this.rejected,
    required this.total,
  });

  final AdminComplaintEntry entry;
  final int rejected;
  final int total;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final client = entry.client;
    final score = client?.trustScore;
    final scoreColor = score == null
        ? context.cs.outline
        : (score >= 70
              ? AppColors.success
              : (score >= 40 ? AppColors.warning : AppColors.danger));

    return ComplaintSection(
      icon: Icons.person_outline_rounded,
      title: l.adminClientSection,
      child: client == null
          ? Text(
              l.adminClientDeleted,
              style: TextStyle(color: context.cs.outline),
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: context.cs.primary.withValues(alpha: 0.14),
                  child: Text(
                    client.initials,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: context.cs.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.clientName,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: context.cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      SelectableText(
                        [
                          client.email,
                          if (client.phone.isNotEmpty) client.phone,
                        ].join(' · '),
                        style: TextStyle(
                          fontSize: 12.5,
                          color: context.cs.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          StatusBadge(
                            label: l.adminClientTrust(score!),
                            color: scoreColor,
                            icon: Icons.verified_user_outlined,
                            dense: true,
                          ),
                          StatusBadge(
                            label: l.adminClientRejected(rejected, total),
                            color: rejected > 0
                                ? AppColors.danger
                                : context.cs.outline,
                            icon: Icons.cancel_outlined,
                            dense: true,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

/// Boutons selon le statut :
/// - En attente : Prendre en charge, Rejeter, Rejeter comme abusive ;
/// - En cours : Répondre, Résoudre, Rejeter, Rejeter comme abusive ;
/// - Résolue / Rejetée : aucune action.
class _Actions extends StatelessWidget {
  const _Actions({
    required this.complaint,
    required this.busy,
    required this.onAction,
  });

  final Complaint complaint;
  final bool busy;
  final ValueChanged<_AdminAction> onAction;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final status = complaint.status;
    if (status.isClosed) {
      return NoticeBox(
        icon: Icons.lock_outline_rounded,
        message: l.adminClosedNotice,
      );
    }
    VoidCallback? tap(_AdminAction a) => busy ? null : () => onAction(a);

    return ComplaintSection(
      icon: Icons.admin_panel_settings_outlined,
      title: l.adminActionsTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (busy) ...[
            const LinearProgressIndicator(),
            const SizedBox(height: 12),
          ],
          if (status == ComplaintStatus.enAttente)
            FilledButton.icon(
              onPressed: tap(_AdminAction.take),
              icon: const Icon(Icons.assignment_ind_outlined),
              label: Text(l.adminTake),
            )
          else ...[
            FilledButton.icon(
              onPressed: tap(_AdminAction.respond),
              icon: const Icon(Icons.reply_rounded),
              label: Text(l.adminRespond),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: AppColors.success),
              onPressed: tap(_AdminAction.resolve),
              icon: const Icon(Icons.check_circle_rounded),
              label: Text(l.adminResolve),
            ),
          ],
          const SizedBox(height: 10),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.danger,
              side: const BorderSide(color: AppColors.danger),
            ),
            onPressed: tap(_AdminAction.reject),
            icon: const Icon(Icons.cancel_rounded),
            label: Text(l.adminReject),
          ),
          const SizedBox(height: 4),
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            onPressed: tap(_AdminAction.rejectAbusive),
            icon: const Icon(Icons.gpp_bad_outlined),
            label: Text(l.adminRejectAbusive),
          ),
        ],
      ),
    );
  }
}

/// Message au client (Répondre / Résoudre / Rejeter). Rejet abusif :
/// avertissement + case de confirmation obligatoire. Retourne le texte.
class _MessageSheet extends StatefulWidget {
  const _MessageSheet({required this.action});

  final _AdminAction action;

  @override
  State<_MessageSheet> createState() => _MessageSheetState();
}

class _MessageSheetState extends State<_MessageSheet> {
  static const _minLength = 10;
  final _text = TextEditingController();
  bool _confirmed = false;
  bool _showError = false;

  bool get _abusive => widget.action == _AdminAction.rejectAbusive;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _send() {
    final ok =
        _text.text.trim().length >= _minLength && (!_abusive || _confirmed);
    if (!ok) {
      setState(() => _showError = true);
      return;
    }
    Navigator.pop(context, _text.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final (title, color) = switch (widget.action) {
      _AdminAction.respond => (l.adminRespondTitle, context.cs.primary),
      _AdminAction.resolve => (l.adminResolveTitle, AppColors.success),
      _AdminAction.rejectAbusive => (l.adminRejectAbusive, AppColors.danger),
      _ => (l.adminRejectTitle, AppColors.danger),
    };
    final tooShort = _text.text.trim().length < _minLength;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(color: color),
              ),
              const SizedBox(height: 12),
              if (_abusive) ...[
                NoticeBox(
                  icon: Icons.warning_amber_rounded,
                  color: AppColors.danger,
                  message: l.adminAbusiveWarning,
                ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: _confirmed,
                  onChanged: (v) => setState(() => _confirmed = v ?? false),
                  title: Text(l.adminAbusiveCheck),
                ),
              ],
              TextField(
                controller: _text,
                autofocus: !_abusive,
                minLines: 4,
                maxLines: 8,
                maxLength: 1000,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: l.adminMessageHint,
                  alignLabelWithHint: true,
                  errorText: _showError && tooShort
                      ? l.adminMessageRequired
                      : null,
                ),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: color),
                onPressed: _abusive && !_confirmed ? null : _send,
                icon: const Icon(Icons.send_rounded, size: 18),
                label: Text(l.adminSend),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l.commonCancel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
