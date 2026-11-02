import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:provider/provider.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/relative_time.dart';
import '../../core/utils/responsive.dart';
import '../../data/models/complaint.dart';
import '../../l10n/l10n.dart';
import '../../state/auction_provider.dart';
import '../../state/car_provider.dart';
import '../../state/complaint_provider.dart';
import '../../state/reservation_provider.dart';
import '../../widgets/common.dart';
import '../../widgets/status_badge.dart';
import 'complaint_actions.dart';
import 'complaint_l10n.dart';
import 'widgets/complaint_car.dart';
import 'widgets/complaint_photo.dart';
import 'widgets/rating_stars.dart';

/// Détail d'une réclamation : infos, élément lié, photos, position,
/// réponse de l'agence, frise du suivi, actions (modifier / annuler) et
/// simulation de l'agence (démo, sans back office).
class ComplaintDetailsScreen extends StatelessWidget {
  const ComplaintDetailsScreen({super.key, required this.complaintId});

  final String complaintId;

  String _dateTime(BuildContext context, DateTime d) =>
      DateFormat.yMMMMd(Localizations.localeOf(context).toLanguageTag())
          .add_Hm()
          .format(d);

  Future<void> _cancel(BuildContext context, Complaint c) async {
    final l = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
        title: Text(l.complaintCancelTitle),
        content: Text(l.complaintCancelMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l.complaintKeep),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l.complaintCancelConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final provider = context.read<ComplaintProvider>();
    final ok = await provider.cancel(c.id);
    if (!context.mounted) return;
    if (ok) {
      AppSnack.success(context, l.complaintCancelled);
      context.canPop() ? context.pop() : context.go(Routes.complaints);
    } else {
      AppSnack.error(
        context,
        c.canEdit ? l.complaintSaveFailed : l.complaintNotEditable,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final complaints = context.watch<ComplaintProvider>();
    final c = complaints.byId(complaintId);
    // Détail ouvert (et visible) : la mise à jour est lue, le badge disparaît.
    if (c != null &&
        complaints.isUnread(c.id) &&
        (ModalRoute.of(context)?.isCurrent ?? true)) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => complaints.markRead(c.id),
      );
    }
    final pad = Responsive.value(context, mobile: 16.0, tablet: 24.0);

    return Scaffold(
      backgroundColor: context.cs.surfaceContainerLow,
      appBar: AppBar(
        backgroundColor: context.cs.surfaceContainerLow,
        title: Text(l.complaintDetailsTitle),
        shape: Border(bottom: BorderSide(color: context.cs.outlineVariant)),
      ),
      body: c == null
          ? EmptyState(
              icon: Icons.search_off_rounded,
              title: l.complaintDetailsTitle,
              message: l.complaintNotFound,
              actionLabel: l.myComplaintsTitle,
              onAction: () => context.go(Routes.complaints),
            )
          : ContentContainer(
              maxWidth: 760,
              child: ListView(
                padding: EdgeInsets.fromLTRB(pad, 16, pad, 32),
                children: [
                  ComplaintHeader(complaint: c),
                  const SizedBox(height: 14),
                  ComplaintInfoCard(complaint: c, dateTime: _dateTime),
                  const SizedBox(height: 14),
                  if (c.carId != null || c.carLabel != null) ...[
                    ComplaintCarCard(carId: c.carId, label: c.carLabel),
                    const SizedBox(height: 14),
                  ],
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
                          // Plein écran : zoom + balayage entre les photos.
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
                    // Pas de carte intégrée (flutter_map non installé) :
                    // adresse + coordonnées + ouverture dans Maps.
                    ComplaintSection(
                      icon: Icons.place_outlined,
                      title: l.complaintLocation,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (c.locationAddress != null) ...[
                            Text(
                              c.locationAddress!,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: context.cs.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                          ],
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
                  // Résolue : note de satisfaction (ou « Merci pour votre avis »).
                  _RatingSection(complaint: c),
                  const SizedBox(height: 14),
                  ComplaintSection(
                    icon: Icons.timeline_rounded,
                    title: l.complaintHistory,
                    child: ComplaintTimeline(
                      events: c.history,
                      dateTime: _dateTime,
                    ),
                  ),
                  if (c.canEdit) ...[
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                context.push(Routes.complaintEdit(c.id)),
                            icon: const Icon(Icons.edit_rounded, size: 18),
                            label: Text(l.complaintEdit),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _cancel(context, c),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.danger,
                              side: const BorderSide(color: AppColors.danger),
                            ),
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              size: 18,
                            ),
                            label: Text(l.complaintCancel),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

// -----------------------------------------------------------------------------
// Blocs
// -----------------------------------------------------------------------------

class ComplaintSection extends StatelessWidget {
  const ComplaintSection({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
    this.color,
  });

  final IconData icon;
  final String title;
  final Widget child;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: color?.withValues(alpha: 0.08) ?? context.cs.surface,
      borderColor: color?.withValues(alpha: 0.4) ?? context.cs.outlineVariant,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 19, color: color ?? AppColors.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: context.cs.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

/// Résumé en une phrase + ton détecté par Gemini à l'envoi.
class ComplaintAiCard extends StatelessWidget {
  const ComplaintAiCard({super.key, required this.complaint});

  final Complaint complaint;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final tone = complaint.aiTone;
    final summary = complaint.aiSummary?.trim() ?? '';

    return ComplaintSection(
      icon: Icons.auto_awesome_rounded,
      title: l.aiAnalysisTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (summary.isNotEmpty) ...[
            Text(
              l.aiSummaryLabel,
              style: TextStyle(fontSize: 12.5, color: context.cs.outline),
            ),
            const SizedBox(height: 4),
            Text(
              summary,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                fontStyle: FontStyle.italic,
                color: context.cs.onSurface,
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (tone != null)
            Row(
              children: [
                Text(
                  '${l.aiToneLabel} : ',
                  style: TextStyle(fontSize: 12.5, color: context.cs.outline),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: tone.color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(tone.icon, size: 16, color: tone.color),
                      const SizedBox(width: 6),
                      Text(
                        l.complaintTone(tone),
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: tone.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Catégorie, référence (copiable), titre, badges.
class ComplaintHeader extends StatelessWidget {
  const ComplaintHeader({super.key, required this.complaint});

  final Complaint complaint;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = complaint;
    return AppCard(
      color: context.cs.surface,
      borderColor: context.cs.outlineVariant,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: c.category.color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(c.category.icon, color: c.category.color, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: c.reference));
                    AppSnack.info(context, l.complaintCopied);
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        c.reference,
                        textDirection: TextDirection.ltr,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: context.cs.outline,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.copy_rounded,
                        size: 14,
                        color: context.cs.outline,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  c.title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: context.cs.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  relativeTime(l, c.createdAt),
                  style: TextStyle(fontSize: 12, color: context.cs.outline),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    StatusBadge(
                      label: l.complaintStatus(c.status),
                      color: c.status.color,
                      icon: c.status.icon,
                    ),
                    if (c.isUrgent || c.priority == ComplaintPriority.urgente)
                      StatusBadge(
                        label: l.complaintPriorityUrgente,
                        color: AppColors.danger,
                        icon: Icons.priority_high_rounded,
                        filled: true,
                      ),
                    if (c.abusive)
                      StatusBadge(
                        label: l.complaintAbusiveBadge,
                        color: AppColors.danger,
                        icon: Icons.gpp_bad_outlined,
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

/// Lignes « libellé / valeur ».
class ComplaintInfoCard extends StatelessWidget {
  const ComplaintInfoCard({
    super.key,
    required this.complaint,
    required this.dateTime,
  });

  final Complaint complaint;
  final String Function(BuildContext, DateTime) dateTime;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = complaint;
    Widget row(String label, Widget value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: context.cs.outline),
            ),
          ),
          Expanded(child: value),
        ],
      ),
    );
    Text value(String s) => Text(
      s,
      style: TextStyle(
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
        color: context.cs.onSurface,
      ),
    );

    return ComplaintSection(
      icon: Icons.info_outline_rounded,
      title: l.complaintDetailsTitle,
      child: Column(
        children: [
          row(l.complaintFieldCategory, value(l.complaintCategory(c.category))),
          row(
            l.complaintFieldPriority,
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: StatusBadge(
                label: l.complaintPriority(c.priority),
                color: c.priority.color,
                icon: c.priority.icon,
                dense: true,
              ),
            ),
          ),
          row(l.complaintFieldStatus, value(l.complaintStatus(c.status))),
          if (c.agency != null) row(l.complaintFieldAgency, value(c.agency!)),
          row(l.complaintFieldSent, value(dateTime(context, c.createdAt))),
          if (c.updatedAt != c.createdAt)
            row(l.complaintFieldUpdated, value(dateTime(context, c.updatedAt))),
        ],
      ),
    );
  }
}

/// Réservation ou enchère liée (cliquable si elle existe encore).
class ComplaintLinkedItem extends StatelessWidget {
  const ComplaintLinkedItem({super.key, required this.complaint});

  final Complaint complaint;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = complaint;

    if (c.reservationId != null) {
      final r = context.watch<ReservationProvider>().byId(c.reservationId!);
      return ComplaintSection(
        icon: Icons.event_note_rounded,
        title: l.complaintLinkedReservation,
        child: r == null
            ? Text(
                l.complaintLinkedMissing,
                style: TextStyle(color: context.cs.outline),
              )
            : _LinkTile(
                icon: Icons.directions_car_rounded,
                // Nom lu dans le catalogue ; voiture retirée → référence.
                title:
                    context.watch<CarProvider>().carById(r.car.id)?.fullName ??
                    r.reference,
                subtitle:
                    '${r.reference} · ${context.dateLong(r.range.start)} · '
                    '${r.pickupCity}',
                onTap: () => context.push(Routes.reservation(r.id)),
              ),
      );
    }
    if (c.auctionId != null) {
      final a = context.watch<AuctionProvider>().byId(c.auctionId!);
      return ComplaintSection(
        icon: Icons.gavel_rounded,
        title: l.complaintLinkedAuction,
        child: a == null
            ? Text(
                l.complaintLinkedMissing,
                style: TextStyle(color: context.cs.outline),
              )
            : _LinkTile(
                icon: Icons.gavel_rounded,
                title: a.title,
                subtitle: a.city,
                onTap: () => context.push(Routes.auction(a.id)),
              ),
      );
    }
    return const SizedBox.shrink();
  }
}

class _LinkTile extends StatelessWidget {
  const _LinkTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Dans une carte colorée (AppCard) : Material transparent pour que
    // l'effet d'appui du ListTile soit visible.
    return Material(
      type: MaterialType.transparency,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        onTap: onTap,
        leading: Icon(icon, color: context.cs.primary),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: context.cs.onSurface,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: context.cs.outline),
        ),
        trailing: Icon(Icons.chevron_right_rounded, color: context.cs.outline),
      ),
    );
  }
}

/// « Réponse de l'agence », ou message d'attente si elle n'a pas répondu.
class ComplaintAgencyResponse extends StatelessWidget {
  const ComplaintAgencyResponse({super.key, required this.complaint});

  final Complaint complaint;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final response = complaint.agencyResponse;
    if (response == null || response.isEmpty) {
      return complaint.status.isClosed
          ? const SizedBox.shrink()
          : NoticeBox(
              icon: Icons.hourglass_top_rounded,
              message: l.complaintWaitingResponse,
            );
    }
    final color = complaint.status == ComplaintStatus.rejetee
        ? AppColors.danger
        : AppColors.success;
    return ComplaintSection(
      icon: Icons.support_agent_rounded,
      title: l.complaintAgencyResponse,
      color: color,
      child: Text(
        response,
        style: TextStyle(
          fontSize: 14,
          height: 1.5,
          color: context.cs.onSurface,
        ),
      ),
    );
  }
}

/// Frise verticale : pastille colorée par statut + trait + texte.
class ComplaintTimeline extends StatelessWidget {
  const ComplaintTimeline({
    super.key,
    required this.events,
    required this.dateTime,
  });

  final List<ComplaintEvent> events;
  final String Function(BuildContext, DateTime) dateTime;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final sorted = [...events]..sort((a, b) => a.date.compareTo(b.date));

    return Column(
      children: [
        for (var i = 0; i < sorted.length; i++)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 34,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: sorted[i].status.color.withValues(
                            alpha: i == sorted.length - 1 ? 1 : 0.16,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          sorted[i].status.icon,
                          size: 16,
                          color: i == sorted.length - 1
                              ? Colors.white
                              : sorted[i].status.color,
                        ),
                      ),
                      if (i < sorted.length - 1)
                        Expanded(
                          child: Container(
                            width: 2,
                            margin: const EdgeInsets.symmetric(vertical: 2),
                            color: context.cs.outlineVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: i < sorted.length - 1 ? 18 : 0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.complaintStatus(sorted[i].status),
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: sorted[i].status.color,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          sorted[i].message,
                          style: TextStyle(
                            fontSize: 13.5,
                            color: context.cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          [
                            dateTime(context, sorted[i].date),
                            if (sorted[i].by case final by?)
                              l.complaintEventBy(by),
                          ].join(' · '),
                          style: TextStyle(
                            fontSize: 12,
                            color: context.cs.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// « Êtes-vous satisfait de la résolution ? » : étoiles animées +
/// commentaire facultatif, puis « Merci pour votre avis ».
/// Note de 1 ou 2 : proposition de rouvrir la réclamation.
class _RatingSection extends StatefulWidget {
  const _RatingSection({required this.complaint});

  final Complaint complaint;

  @override
  State<_RatingSection> createState() => _RatingSectionState();
}

class _RatingSectionState extends State<_RatingSection> {
  static const _commentMax = 300;

  final _comment = TextEditingController();
  int _value = 0;
  bool _saving = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  String _label(AppLocalizations l, int v) => switch (v) {
    1 => l.ratingLabel1,
    2 => l.ratingLabel2,
    3 => l.ratingLabel3,
    4 => l.ratingLabel4,
    _ => l.ratingLabel5,
  };

  Future<void> _submit() async {
    final l = context.l10n;
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    final ok = await context.read<ComplaintProvider>().rate(
      widget.complaint.id,
      _value,
      comment: _comment.text,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      AppSnack.success(context, l.ratingThanks);
    } else {
      AppSnack.error(context, l.complaintSaveFailed);
    }
  }

  Future<void> _reopen() async {
    final l = context.l10n;
    final c = widget.complaint;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.replay_rounded, color: AppColors.warning),
        title: Text(l.ratingReopenTitle),
        content: Text(l.ratingReopenMessage(c.reference)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l.complaintKeep),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l.ratingReopen),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final ok = await context.read<ComplaintProvider>().reopen(c.id);
    if (!mounted) return;
    if (ok) {
      AppSnack.success(context, l.ratingReopened);
    } else {
      AppSnack.error(context, l.complaintSaveFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.complaint;
    final Widget child;
    if (c.rating != null) {
      child = _thanks(context, c);
    } else if (c.canRate) {
      child = _form(context);
    } else {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SizeTransition(sizeFactor: animation, child: child),
        ),
        child: KeyedSubtree(key: ValueKey(c.rating != null), child: child),
      ),
    );
  }

  Widget _form(BuildContext context) {
    final l = context.l10n;
    return ComplaintSection(
      icon: Icons.sentiment_satisfied_alt_rounded,
      title: l.ratingTitle,
      color: ratingStarColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.ratingSubtitle,
            style: TextStyle(fontSize: 12.5, color: context.cs.outline),
          ),
          const SizedBox(height: 10),
          Center(
            child: RatingStars(
              value: _value,
              size: 38,
              onChanged: _saving ? null : (v) => setState(() => _value = v),
            ),
          ),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: _value == 0 ? 0 : 1,
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _value == 0 ? ' ' : _label(l, _value),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: context.cs.onSurface,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _comment,
            enabled: !_saving,
            maxLength: _commentMax,
            minLines: 2,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: l.ratingCommentHint,
              filled: true,
              fillColor: context.cs.surface,
            ),
          ),
          const SizedBox(height: 6),
          FilledButton.icon(
            onPressed: _value == 0 || _saving ? null : _submit,
            icon: _saving
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.send_rounded, size: 18),
            label: Text(l.ratingSubmit),
          ),
        ],
      ),
    );
  }

  Widget _thanks(BuildContext context, Complaint c) {
    final l = context.l10n;
    final rating = c.rating!;
    return ComplaintSection(
      icon: Icons.favorite_rounded,
      title: l.ratingThanks,
      color: AppColors.success,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              RatingStars(value: rating, size: 22),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  _label(l, rating),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: context.cs.onSurface,
                  ),
                ),
              ),
            ],
          ),
          if (c.ratingComment != null) ...[
            const SizedBox(height: 10),
            Text(
              l.ratingYourComment,
              style: TextStyle(fontSize: 12, color: context.cs.outline),
            ),
            const SizedBox(height: 2),
            Text(
              '« ${c.ratingComment} »',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                height: 1.45,
                color: context.cs.onSurface,
              ),
            ),
          ],
          if (c.canReopen) ...[
            const SizedBox(height: 14),
            NoticeBox(
              icon: Icons.sentiment_dissatisfied_rounded,
              color: AppColors.warning,
              message: l.ratingReopenPrompt,
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _reopen,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.warning,
                  side: const BorderSide(color: AppColors.warning),
                ),
                icon: const Icon(Icons.replay_rounded, size: 18),
                label: Text(l.ratingReopen),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
