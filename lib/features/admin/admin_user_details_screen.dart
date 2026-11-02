import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/ban_format.dart';
import '../../core/utils/responsive.dart';
import '../../data/models/ban_record.dart';
import '../../data/models/complaint.dart';
import '../../data/models/user_profile.dart';
import '../../data/services/ban_service.dart';
import '../../l10n/l10n.dart';
import '../../state/admin_complaint_provider.dart';
import '../../state/admin_user_provider.dart';
import '../../state/auth_provider.dart';
import '../../state/load_state.dart';
import '../../widgets/common.dart';
import '../../widgets/status_badge.dart';
import '../complaints/complaint_details_screen.dart' show ComplaintSection;
import 'admin_users_screen.dart';
import 'ban_sheet.dart';

/// Détail d'un compte (admin) : profil, score de confiance, réclamations
/// abusives, suspension en cours, Bannir / Débannir et historique.
class AdminUserDetailsScreen extends StatefulWidget {
  const AdminUserDetailsScreen({super.key, required this.userId});

  final String userId;

  @override
  State<AdminUserDetailsScreen> createState() => _AdminUserDetailsScreenState();
}

class _AdminUserDetailsScreenState extends State<AdminUserDetailsScreen> {
  late Future<List<BanRecord>> _history;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _history = context.read<AdminUserProvider>().history(widget.userId);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AdminUserProvider>().load();
      context.read<AdminComplaintProvider>().loadAll();
    });
  }

  void _reloadHistory() => setState(() {
    _history = context.read<AdminUserProvider>().history(widget.userId);
  });

  Future<void> _ban(UserProfile user) async {
    if (await showBanSheet(context, user: user) && mounted) _reloadHistory();
  }

  Future<void> _unban(UserProfile user) async {
    final l = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.lock_open_rounded, color: AppColors.success),
        title: Text(l.adminUserUnban),
        content: Text(l.adminUserUnbanConfirm(user.fullName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l.adminConfirm),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final admin = context.read<AuthProvider>().user;
    if (admin == null) return;
    setState(() => _busy = true);
    try {
      final outcome = await context.read<AdminUserProvider>().unban(
        user.id,
        admin: admin,
      );
      if (!mounted) return;
      AppSnack.success(context, l.unbanDone(user.fullName));
      _reloadHistory();
      outcome.mail.then((sent) {
        if (mounted) {
          AppSnack.info(context, sent ? l.banMailSent : l.banMailFailed);
        }
      });
    } catch (_) {
      if (mounted) AppSnack.error(context, l.adminActionFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final users = context.watch<AdminUserProvider>();
    final complaints = context.watch<AdminComplaintProvider>();
    final me = context.watch<AuthProvider>().user;
    final user = users.byId(widget.userId);
    final pad = Responsive.value(context, mobile: 16.0, tablet: 24.0);

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l.adminUsersTitle)),
        body: users.state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : EmptyState(
                icon: Icons.person_off_outlined,
                title: l.adminUsersTitle,
                message: l.adminClientDeleted,
              ),
      );
    }

    final own = complaints.complaintsOf(user.id);
    // Règles du back office : ni un admin, ni soi-même.
    final blocked = user.isAdmin
        ? l.adminUserIsAdmin
        : (user.id == me?.id ? l.adminUserIsSelf : null);

    return Scaffold(
      backgroundColor: context.cs.surfaceContainerLow,
      appBar: AppBar(
        backgroundColor: context.cs.surfaceContainerLow,
        title: Text(user.fullName),
        shape: Border(bottom: BorderSide(color: context.cs.outlineVariant)),
      ),
      body: SafeArea(
        child: ContentContainer(
          maxWidth: 760,
          child: ListView(
            padding: EdgeInsets.fromLTRB(pad, 16, pad, 32),
            children: [
              _ProfileCard(user: user),
              const SizedBox(height: 14),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  StatusBadge(
                    label: l.adminClientTrust(user.trustScore),
                    color: trustColor(user.trustScore),
                    icon: Icons.verified_user_outlined,
                  ),
                  StatusBadge(
                    label: l.adminUserAbusive(
                      complaints.abusiveCountOf(user.id),
                    ),
                    color: complaints.abusiveCountOf(user.id) > 0
                        ? AppColors.danger
                        : context.cs.outline,
                    icon: Icons.gpp_bad_outlined,
                  ),
                  StatusBadge(
                    label: l.adminClientRejected(
                      complaints.rejectedCountOf(user.id),
                      own.length,
                    ),
                    color: context.cs.outline,
                    icon: Icons.cancel_outlined,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (user.isBanned) ...[
                ComplaintSection(
                  icon: Icons.block_rounded,
                  title: l.banCurrentTitle,
                  color: AppColors.danger,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BanBadge(user: user, dense: false),
                      const SizedBox(height: 10),
                      Text(
                        l.banSummaryReason(user.banReason ?? '—'),
                        style: TextStyle(color: context.cs.onSurface),
                      ),
                      if (user.bannedBy != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          l.banCurrentBy(user.bannedBy!),
                          style: TextStyle(
                            fontSize: 12.5,
                            color: context.cs.outline,
                          ),
                        ),
                      ],
                      if (!user.banPermanent && user.bannedUntil != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${l.suspendedRemaining} : '
                          '${banRemaining(l, user.bannedUntil!.difference(DateTime.now()))}',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: context.cs.outline,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.success,
                          ),
                          onPressed: _busy ? null : () => _unban(user),
                          icon: const Icon(Icons.lock_open_rounded),
                          label: Text(l.adminUserUnban),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (blocked != null)
                NoticeBox(icon: Icons.shield_outlined, message: blocked)
              else
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: const BorderSide(color: AppColors.danger),
                    ),
                    onPressed: _busy ? null : () => _ban(user),
                    icon: const Icon(Icons.gavel_rounded),
                    label: Text(l.adminUserBan),
                  ),
                ),
              const SizedBox(height: 14),
              ComplaintSection(
                icon: Icons.history_rounded,
                title: l.banHistoryTitle,
                child: FutureBuilder<List<BanRecord>>(
                  future: _history,
                  builder: (context, snap) {
                    if (snap.connectionState != ConnectionState.done) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    final list = snap.data ?? const [];
                    if (list.isEmpty) {
                      return Text(
                        l.banHistoryEmpty,
                        style: TextStyle(color: context.cs.outline),
                      );
                    }
                    return Column(
                      children: [
                        for (final b in list)
                          _BanHistoryTile(
                            record: b,
                            complaint: b.complaintId == null
                                ? null
                                : complaints.byId(b.complaintId!)?.complaint,
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.user});

  final UserProfile user;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final since = user.memberSince;
    return AppCard(
      color: context.cs.surface,
      borderColor: context.cs.outlineVariant,
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: context.cs.primary.withValues(alpha: 0.14),
            child: Text(
              user.initials,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: context.cs.primary,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: context.cs.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                SelectableText(
                  [
                    user.email,
                    if (user.phone.isNotEmpty) user.phone,
                  ].join(' · '),
                  style: TextStyle(
                    fontSize: 12.5,
                    color: context.cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    StatusBadge(
                      label: roleLabel(l, user.role),
                      color: user.isAdmin
                          ? AppColors.accent
                          : context.cs.outline,
                      dense: true,
                    ),
                    if (since != null)
                      Text(
                        l.adminUserMemberSince(
                          MaterialLocalizations.of(context)
                              .formatMediumDate(since),
                        ),
                        style: TextStyle(
                          fontSize: 12,
                          color: context.cs.outline,
                        ),
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

/// Une ligne de l'historique : période, motif, réclamation, levée.
class _BanHistoryTile extends StatelessWidget {
  const _BanHistoryTile({required this.record, this.complaint});

  final BanRecord record;
  final Complaint? complaint;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final b = record;
    final active = b.isActive();
    final start = banDateTime(context, b.start);
    final period = b.permanent || b.end == null
        ? l.banHistorySince(start)
        : l.banHistoryPeriod(start, banDateTime(context, b.end!));
    final lifter = b.liftedBy == BanService.autoLiftedBy
        ? l.banHistoryAuto
        : (b.liftedBy ?? '—');

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: active
            ? AppColors.danger.withValues(alpha: 0.06)
            : context.cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(
          color: active
              ? AppColors.danger.withValues(alpha: 0.4)
              : context.cs.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              if (active)
                StatusBadge(
                  label: l.banHistoryActive,
                  color: AppColors.danger,
                  dense: true,
                  filled: true,
                ),
              if (b.permanent)
                StatusBadge(
                  label: l.banHistoryPermanent,
                  color: AppColors.danger,
                  dense: true,
                ),
            ],
          ),
          if (active || b.permanent) const SizedBox(height: 6),
          Text(
            period,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: context.cs.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            l.banSummaryReason(b.reason),
            style: TextStyle(fontSize: 13, color: context.cs.onSurface),
          ),
          if (b.adminName != null)
            Text(
              l.banCurrentBy(b.adminName!),
              style: TextStyle(fontSize: 12, color: context.cs.outline),
            ),
          if (complaint != null)
            InkWell(
              onTap: () => context.push(Routes.adminComplaint(complaint!.id)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  l.banHistoryComplaint(complaint!.reference),
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: context.cs.primary,
                  ),
                ),
              ),
            ),
          if (b.liftedAt != null)
            Text(
              l.banHistoryLifted(banDateTime(context, b.liftedAt!), lifter),
              style: const TextStyle(fontSize: 12, color: AppColors.success),
            ),
        ],
      ),
    );
  }
}
