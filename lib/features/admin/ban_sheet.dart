import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/ban_format.dart';
import '../../data/models/complaint.dart';
import '../../data/models/user_profile.dart';
import '../../data/services/ban_service.dart';
import '../../l10n/l10n.dart';
import '../../state/admin_user_provider.dart';
import '../../state/auth_provider.dart';
import '../../widgets/common.dart';

/// Durées proposées.
enum BanChoice { h24, d3, d7, d30, custom, permanent }

extension BanChoiceX on BanChoice {
  Duration? get duration => switch (this) {
    BanChoice.h24 => const Duration(hours: 24),
    BanChoice.d3 => const Duration(days: 3),
    BanChoice.d7 => const Duration(days: 7),
    BanChoice.d30 => const Duration(days: 30),
    _ => null,
  };

  String label(AppLocalizations l) => switch (this) {
    BanChoice.h24 => l.ban24h,
    BanChoice.d3 => l.ban3d,
    BanChoice.d7 => l.ban7d,
    BanChoice.d30 => l.ban30d,
    BanChoice.custom => l.banCustom,
    BanChoice.permanent => l.banPermanent,
  };
}

/// Message d'un refus de [BanService].
String banErrorText(AppLocalizations l, BanErrorCode code) => switch (code) {
  BanErrorCode.adminTarget => l.adminUserIsAdmin,
  BanErrorCode.selfTarget => l.adminUserIsSelf,
  BanErrorCode.endInPast => l.banEndRequired,
  BanErrorCode.noReason => l.banReasonRequired,
  BanErrorCode.notFound => l.banFailed,
};

/// Dialogue « Bannir » : durée, motif (pré-rempli « Fausse réclamation
/// REC-… » depuis une réclamation), récapitulatif puis confirmation.
/// Retourne `true` si le compte a été banni (e-mail envoyé ensuite).
Future<bool> showBanSheet(
  BuildContext context, {
  required UserProfile user,
  Complaint? complaint,
}) async {
  final banned = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _BanSheet(user: user, complaint: complaint),
  );
  return banned ?? false;
}

class _BanSheet extends StatefulWidget {
  const _BanSheet({required this.user, this.complaint});

  final UserProfile user;
  final Complaint? complaint;

  @override
  State<_BanSheet> createState() => _BanSheetState();
}

class _BanSheetState extends State<_BanSheet> {
  BanChoice _choice = BanChoice.d7;
  DateTime? _customEnd;
  late final TextEditingController _reason;
  bool _summary = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final c = widget.complaint;
    _reason = TextEditingController();
    // Texte traduit : disponible après le premier frame (context.l10n).
    if (c != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _reason.text.isEmpty) {
          _reason.text = context.l10n.banFalseComplaint(c.reference);
        }
      });
    }
  }

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  /// Fin prévue (indicative : la durée exacte part de la confirmation).
  DateTime? get _end => switch (_choice) {
    BanChoice.permanent => null,
    BanChoice.custom => _customEnd,
    _ => DateTime.now().add(_choice.duration!),
  };

  Future<void> _pickCustom() async {
    final now = DateTime.now();
    final initial = _customEnd ?? now.add(const Duration(hours: 1));
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365 * 5)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !mounted) return;
    setState(() {
      _customEnd = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
      _error = null;
    });
  }

  /// Formulaire valide → récapitulatif.
  void _next() {
    final l = context.l10n;
    String? error;
    if (_reason.text.trim().isEmpty) error = l.banReasonRequired;
    if (_choice == BanChoice.custom &&
        (_customEnd == null || !_customEnd!.isAfter(DateTime.now()))) {
      error = l.banEndRequired;
    }
    setState(() {
      _error = error;
      _summary = error == null;
    });
  }

  Future<void> _confirm() async {
    final l = context.l10n;
    final admin = context.read<AuthProvider>().user;
    if (admin == null) return;
    setState(() => _saving = true);
    try {
      final outcome = await context.read<AdminUserProvider>().ban(
        userId: widget.user.id,
        admin: admin,
        reason: _reason.text,
        duration: _choice.duration,
        until: _choice == BanChoice.custom ? _customEnd : null,
        permanent: _choice == BanChoice.permanent,
        complaintId: widget.complaint?.id,
      );
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context, true);
      // Feuille fermée : messages via le ScaffoldMessenger de l'écran.
      messenger.showSnackBar(
        SnackBar(content: Text(l.banDone(widget.user.fullName))),
      );
      outcome.mail.then((sent) {
        messenger.showSnackBar(
          SnackBar(content: Text(sent ? l.banMailSent : l.banMailFailed)),
        );
      });
    } on BanException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _summary = false;
        _error = banErrorText(l, e.code);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = l.banFailed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final name = widget.user.fullName;
    final end = _end;

    final Widget content;
    if (_summary) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.banSummaryTitle,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 10),
          NoticeBox(
            icon: Icons.block_rounded,
            color: AppColors.danger,
            title: end == null
                ? l.banSummaryPermanent(name)
                : l.banSummaryUntil(
                    name,
                    banDateTime(context, end),
                    banRemaining(l, end.difference(DateTime.now())),
                  ),
            message:
                '${l.banSummaryReason(_reason.text.trim())}\n\n'
                '${l.banSummaryEffects}',
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: _saving ? null : _confirm,
            icon: _saving
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.gavel_rounded),
            label: Text(l.banConfirm),
          ),
          TextButton(
            onPressed: _saving ? null : () => setState(() => _summary = false),
            child: Text(l.banEdit),
          ),
        ],
      );
    } else {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.banDuration, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in BanChoice.values)
                ChoiceChip(
                  label: Text(c.label(l)),
                  selected: _choice == c,
                  selectedColor: c == BanChoice.permanent
                      ? AppColors.danger.withValues(alpha: 0.18)
                      : null,
                  onSelected: (_) {
                    setState(() {
                      _choice = c;
                      _error = null;
                    });
                    if (c == BanChoice.custom && _customEnd == null) {
                      _pickCustom();
                    }
                  },
                ),
            ],
          ),
          if (_choice == BanChoice.custom) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _pickCustom,
              icon: const Icon(Icons.event_rounded, size: 18),
              label: Text(
                _customEnd == null
                    ? l.banPickDate
                    : l.banEnd(banDateTime(context, _customEnd!)),
              ),
            ),
          ] else if (end != null) ...[
            const SizedBox(height: 8),
            Text(
              l.banEnd(banDateTime(context, end)),
              style: TextStyle(fontSize: 12.5, color: context.cs.outline),
            ),
          ],
          const SizedBox(height: 18),
          TextField(
            controller: _reason,
            minLines: 2,
            maxLines: 4,
            maxLength: 300,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
            decoration: InputDecoration(
              labelText: l.banReasonLabel,
              hintText: l.banReasonHint,
              alignLabelWithHint: true,
            ),
          ),
          FilledButton(onPressed: _next, child: Text(l.banNext)),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.commonCancel),
          ),
        ],
      );
    }

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
              Row(
                children: [
                  const Icon(Icons.gavel_rounded, color: AppColors.danger),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l.banDialogTitle(name),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (_error != null) ...[
                NoticeBox(
                  icon: Icons.error_outline_rounded,
                  color: AppColors.danger,
                  message: _error!,
                ),
                const SizedBox(height: 12),
              ],
              content,
            ],
          ),
        ),
      ),
    );
  }
}

/// Badge « Banni jusqu'au … » / « Banni définitivement ».
class BanBadge extends StatelessWidget {
  const BanBadge({super.key, required this.user, this.dense = true});

  final UserProfile user;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final until = user.bannedUntil;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: dense ? 3 : 6),
      decoration: BoxDecoration(
        color: AppColors.danger,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.block_rounded, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              user.banPermanent || until == null
                  ? l.banBadgePermanent
                  : l.banBadgeUntil(banDateTime(context, until)),
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
