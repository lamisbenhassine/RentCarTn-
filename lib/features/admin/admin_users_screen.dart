import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../data/models/user_profile.dart';
import '../../data/models/user_role.dart';
import '../../l10n/l10n.dart';
import '../../state/admin_complaint_provider.dart';
import '../../state/admin_user_provider.dart';
import '../../state/load_state.dart';
import '../../widgets/common.dart';
import '../../widgets/status_badge.dart';
import 'ban_sheet.dart';

enum _UserFilter { all, banned, active }

/// Libellé du rôle (Admin / Utilisateur / Entreprise).
String roleLabel(AppLocalizations l, UserRole role) => switch (role) {
  UserRole.admin => l.adminRoleAdmin,
  UserRole.company => l.registerRoleCompany,
  _ => l.registerRoleUser,
};

/// Couleur du score de confiance (vert ≥ 70, orange ≥ 40, rouge sinon).
Color trustColor(int score) => score >= 70
    ? AppColors.success
    : (score >= 40 ? AppColors.warning : AppColors.danger);

/// Back office « Utilisateurs » : recherche, filtre Bannis / Actifs,
/// badge de bannissement, score de confiance, réclamations abusives.
class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final _search = TextEditingController();
  String _query = '';
  _UserFilter _filter = _UserFilter.all;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AdminUserProvider>().load(force: true);
      context.read<AdminComplaintProvider>().loadAll(); // réclamations abusives
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<UserProfile> _visible(List<UserProfile> all) {
    final q = _query.trim().toLowerCase();
    return all.where((u) {
      if (_filter == _UserFilter.banned && !u.isBanned) return false;
      if (_filter == _UserFilter.active && u.isBanned) return false;
      if (q.isEmpty) return true;
      return '${u.fullName} ${u.email} ${u.phone}'.toLowerCase().contains(q);
    }).toList()..sort((a, b) {
      // Bannis d'abord, puis ordre alphabétique.
      if (a.isBanned != b.isBanned) return a.isBanned ? -1 : 1;
      return a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase());
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final provider = context.watch<AdminUserProvider>();
    final pad = Responsive.value(context, mobile: 16.0, tablet: 24.0);

    final Widget body;
    if (provider.users.isEmpty &&
        (provider.state == LoadState.initial || provider.state.isLoading)) {
      body = const Center(child: CircularProgressIndicator());
    } else if (provider.users.isEmpty && provider.state.isError) {
      body = EmptyState(
        icon: Icons.cloud_off_rounded,
        title: l.adminUsersTitle,
        message: provider.errorMessage ?? '',
        actionLabel: l.adminRetry,
        onAction: () => provider.load(force: true),
      );
    } else {
      final visible = _visible(provider.users);
      body = RefreshIndicator(
        onRefresh: () => provider.load(force: true),
        child: ContentContainer(
          maxWidth: 820,
          child: ListView(
            padding: EdgeInsets.fromLTRB(pad, 16, pad, 32),
            children: [
              TextField(
                controller: _search,
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: l.adminUsersSearch,
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            _search.clear();
                            setState(() => _query = '');
                          },
                        ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  for (final f in _UserFilter.values)
                    ChoiceChip(
                      label: Text(switch (f) {
                        _UserFilter.all =>
                          '${l.adminUsersFilterAll} (${provider.users.length})',
                        _UserFilter.banned =>
                          '${l.adminUsersFilterBanned} (${provider.bannedCount})',
                        _UserFilter.active => l.adminUsersFilterActive,
                      }),
                      selected: _filter == f,
                      onSelected: (_) => setState(() => _filter = f),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              if (visible.isEmpty)
                EmptyState(
                  compact: true,
                  icon: Icons.person_search_outlined,
                  title: l.adminUsersEmpty,
                  message: '',
                )
              else
                for (final u in visible)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _UserTile(
                      user: u,
                      onTap: () => context.push(Routes.adminUser(u.id)),
                    ),
                  ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: context.cs.surfaceContainerLow,
      appBar: AppBar(
        backgroundColor: context.cs.surfaceContainerLow,
        title: Text(l.adminUsersTitle),
        shape: Border(bottom: BorderSide(color: context.cs.outlineVariant)),
      ),
      body: SafeArea(child: body),
    );
  }
}

class _UserTile extends StatelessWidget {
  const _UserTile({required this.user, required this.onTap});

  final UserProfile user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final abusive = context.watch<AdminComplaintProvider>().abusiveCountOf(
      user.id,
    );
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      color: context.cs.surface,
      borderColor: user.isBanned
          ? AppColors.danger.withValues(alpha: 0.6)
          : context.cs.outlineVariant,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor:
                (user.isBanned ? AppColors.danger : context.cs.primary)
                    .withValues(alpha: 0.14),
            child: Text(
              user.initials,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: user.isBanned ? AppColors.danger : context.cs.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: context.cs.onSurface,
                  ),
                ),
                Text(
                  user.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
                    if (user.isBanned) BanBadge(user: user),
                    StatusBadge(
                      label: roleLabel(l, user.role),
                      color: user.isAdmin
                          ? AppColors.accent
                          : context.cs.outline,
                      dense: true,
                    ),
                    if (!user.isAdmin) ...[
                      StatusBadge(
                        label: l.adminClientTrust(user.trustScore),
                        color: trustColor(user.trustScore),
                        icon: Icons.verified_user_outlined,
                        dense: true,
                      ),
                      StatusBadge(
                        label: l.adminUserAbusive(abusive),
                        color: abusive > 0
                            ? AppColors.danger
                            : context.cs.outline,
                        icon: Icons.gpp_bad_outlined,
                        dense: true,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: context.cs.outline),
        ],
      ),
    );
  }
}
