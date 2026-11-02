import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/relative_time.dart';
import '../../core/utils/responsive.dart';
import '../../data/models/complaint.dart';
import '../../l10n/l10n.dart';
import '../../state/admin_complaint_provider.dart';
import '../../state/car_provider.dart';
import '../../state/load_state.dart';
import '../../widgets/common.dart';
import '../../widgets/status_badge.dart';
import '../complaints/complaint_l10n.dart';

/// « 2 j 4 h », « 3 h 15 min », « 12 min ».
String formatProcessingTime(AppLocalizations l, Duration d) {
  if (d.inDays > 0) return l.adminDurationDays(d.inDays, d.inHours % 24);
  if (d.inHours > 0) return l.adminDurationHours(d.inHours, d.inMinutes % 60);
  return l.adminDurationMinutes(d.inMinutes < 1 ? 1 : d.inMinutes);
}

/// Véhicule d'une réclamation : nom du catalogue, sinon libellé enregistré.
String? adminCarName(BuildContext context, Complaint c) {
  final id = c.carId;
  final car = id == null ? null : context.watch<CarProvider>().carById(id);
  return car?.fullName ?? c.carLabel;
}

/// Back office : toutes les réclamations des clients (admin uniquement).
/// Tableau de bord, filtres (statut, priorité, catégorie) et recherche
/// (référence, nom du client, véhicule). Tri : priorité puis date.
class AdminComplaintsScreen extends StatefulWidget {
  const AdminComplaintsScreen({super.key});

  @override
  State<AdminComplaintsScreen> createState() => _AdminComplaintsScreenState();
}

class _AdminComplaintsScreenState extends State<AdminComplaintsScreen> {
  final _search = TextEditingController();
  String _query = '';
  ComplaintStatus? _status;
  ComplaintPriority? _priority;
  ComplaintCategory? _category;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Toujours à jour : de nouvelles réclamations ont pu arriver.
      context.read<AdminComplaintProvider>().loadAll(force: true);
      context.read<CarProvider>().load(); // noms des véhicules
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool get _hasFilters =>
      _status != null ||
      _priority != null ||
      _category != null ||
      _query.trim().isNotEmpty;

  void _clearFilters() {
    _search.clear();
    setState(() {
      _query = '';
      _status = null;
      _priority = null;
      _category = null;
    });
  }

  List<AdminComplaintEntry> _visible(List<AdminComplaintEntry> all) {
    final q = _query.trim().toLowerCase();
    return all.where((e) {
      final c = e.complaint;
      if (_status != null && c.status != _status) return false;
      if (_priority != null && c.priority != _priority) return false;
      if (_category != null && c.category != _category) return false;
      if (q.isEmpty) return true;
      final haystack = [
        c.reference,
        e.clientName,
        e.client?.email ?? '',
        adminCarName(context, c) ?? '',
      ].join(' ').toLowerCase();
      return haystack.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final provider = context.watch<AdminComplaintProvider>();
    final pad = Responsive.value(context, mobile: 16.0, tablet: 24.0);

    /// Tirer vers le bas recharge TOUT (repository.getAll()), même quand la
    /// liste est vide ou en erreur.
    Future<void> refresh() => provider.loadAll(force: true);
    Widget scrollable(Widget child) => RefreshIndicator(
      onRefresh: refresh,
      child: LayoutBuilder(
        builder: (context, box) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(minHeight: box.maxHeight),
              child: Center(child: child),
            ),
          ],
        ),
      ),
    );

    final Widget body;
    if (provider.entries.isEmpty &&
        (provider.state == LoadState.initial || provider.state.isLoading)) {
      body = const Center(child: CircularProgressIndicator());
    } else if (provider.entries.isEmpty && provider.state.isError) {
      body = scrollable(
        EmptyState(
          icon: Icons.cloud_off_rounded,
          title: l.adminComplaintsTitle,
          message: provider.errorMessage ?? l.adminActionFailed,
          actionLabel: l.adminRetry,
          onAction: refresh,
        ),
      );
    } else if (provider.entries.isEmpty) {
      body = scrollable(
        EmptyState(
          icon: Icons.inbox_outlined,
          title: l.adminEmptyTitle,
          message: l.adminEmptyMessage,
          actionLabel: l.adminRetry,
          onAction: refresh,
        ),
      );
    } else {
      final visible = _visible(provider.entries);
      body = RefreshIndicator(
        onRefresh: refresh,
        child: ContentContainer(
          maxWidth: 900,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(pad, 16, pad, 32),
            children: [
              _Dashboard(
                stats: provider.stats,
                selected: _status,
                onStatus: (s) =>
                    setState(() => _status = _status == s ? null : s),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _search,
                onChanged: (v) => setState(() => _query = v),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: l.adminSearchHint,
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
              _filters(l),
              const SizedBox(height: 14),
              if (visible.isEmpty)
                EmptyState(
                  compact: true,
                  icon: Icons.filter_alt_off_outlined,
                  title: l.adminNoMatch,
                  message: '',
                  actionLabel: l.adminClearFilters,
                  onAction: _clearFilters,
                )
              else
                for (final e in visible)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _AdminComplaintCard(
                      entry: e,
                      onTap: () =>
                          context.push(Routes.adminComplaint(e.complaint.id)),
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
        title: Text(l.adminComplaintsTitle),
        shape: Border(bottom: BorderSide(color: context.cs.outlineVariant)),
        actions: [
          if (_hasFilters)
            IconButton(
              tooltip: l.adminClearFilters,
              onPressed: _clearFilters,
              icon: const Icon(Icons.filter_alt_off_outlined),
            ),
        ],
      ),
      body: SafeArea(child: body),
    );
  }

  /// Statut (puces) + priorité et catégorie (listes déroulantes).
  Widget _filters(AppLocalizations l) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ChoiceChip(
                label: Text(l.adminFilterAll),
                selected: _status == null,
                onSelected: (_) => setState(() => _status = null),
              ),
              for (final s in ComplaintStatus.values) ...[
                const SizedBox(width: 8),
                ChoiceChip(
                  avatar: Icon(s.icon, size: 16, color: s.color),
                  label: Text(l.complaintStatus(s)),
                  selected: _status == s,
                  onSelected: (on) => setState(() => _status = on ? s : null),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<ComplaintPriority?>(
                key: ValueKey(
                  _priority,
                ), // « Effacer les filtres » la réinitialise
                initialValue: _priority,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: l.complaintPriorityLabel,
                  isDense: true,
                ),
                items: [
                  DropdownMenuItem(
                    value: null,
                    child: Text(l.adminFilterAllPriorities),
                  ),
                  for (final p in ComplaintPriority.values)
                    DropdownMenuItem(
                      value: p,
                      child: Text(l.complaintPriority(p)),
                    ),
                ],
                onChanged: (v) => setState(() => _priority = v),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButtonFormField<ComplaintCategory?>(
                key: ValueKey(_category),
                initialValue: _category,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: l.complaintCategoryLabel,
                  isDense: true,
                ),
                items: [
                  DropdownMenuItem(
                    value: null,
                    child: Text(l.adminFilterAllCategories),
                  ),
                  for (final c in ComplaintCategory.values)
                    DropdownMenuItem(
                      value: c,
                      child: Text(
                        l.complaintCategory(c),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (v) => setState(() => _category = v),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Compteurs par statut (cliquables = filtre), temps moyen, satisfaction.
class _Dashboard extends StatelessWidget {
  const _Dashboard({
    required this.stats,
    required this.selected,
    required this.onStatus,
  });

  final AdminComplaintStats stats;
  final ComplaintStatus? selected;
  final ValueChanged<ComplaintStatus> onStatus;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final counts = {
      ComplaintStatus.enAttente: stats.pending,
      ComplaintStatus.enCours: stats.inProgress,
      ComplaintStatus.resolue: stats.resolved,
      ComplaintStatus.rejetee: stats.rejected,
    };
    final columns = MediaQuery.sizeOf(context).width >= 700 ? 4 : 2;

    return Column(
      children: [
        GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.1,
          children: [
            for (final s in ComplaintStatus.values)
              _StatTile(
                icon: s.icon,
                color: s.color,
                value: '${counts[s]}',
                label: l.complaintStatus(s),
                selected: selected == s,
                onTap: () => onStatus(s),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                icon: Icons.timer_outlined,
                color: AppColors.accent,
                value: stats.averageProcessing == null
                    ? '—'
                    : formatProcessingTime(l, stats.averageProcessing!),
                label: l.adminStatAvgTime,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatTile(
                icon: Icons.star_rounded,
                color: AppColors.gold,
                value: stats.averageRating == null
                    ? '—'
                    : l.adminStatRating(
                        stats.averageRating!.toStringAsFixed(1),
                        stats.ratingCount,
                      ),
                label: l.adminStatAvgRating,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
    this.selected = false,
    this.onTap,
  });

  final IconData icon;
  final Color color;
  final String value;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      color: selected ? color.withValues(alpha: 0.12) : context.cs.surface,
      borderColor: selected ? color : context.cs.outlineVariant,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: context.cs.onSurface,
                    ),
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: context.cs.outline),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Ligne de la liste : référence, client, véhicule, statut, urgence.
class _AdminComplaintCard extends StatelessWidget {
  const _AdminComplaintCard({required this.entry, required this.onTap});

  final AdminComplaintEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = entry.complaint;
    final urgent = c.isUrgent || c.priority == ComplaintPriority.urgente;
    final car = adminCarName(context, c);

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      color: context.cs.surface,
      borderColor: urgent && !c.status.isClosed
          ? AppColors.danger.withValues(alpha: 0.6)
          : context.cs.outlineVariant,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: c.category.color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Icon(c.category.icon, color: c.category.color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      c.reference,
                      textDirection: TextDirection.ltr,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: context.cs.outline,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      relativeTime(l, c.createdAt),
                      style: TextStyle(
                        fontSize: 11.5,
                        color: context.cs.outline,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  c.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: context.cs.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.person_outline_rounded,
                      size: 15,
                      color: context.cs.outline,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        [entry.clientName, ?car].join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: context.cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
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
                      dense: true,
                    ),
                    if (urgent)
                      StatusBadge(
                        label: l.complaintPriorityUrgente,
                        color: AppColors.danger,
                        icon: Icons.priority_high_rounded,
                        dense: true,
                        filled: true,
                      )
                    else
                      StatusBadge(
                        label: l.complaintPriority(c.priority),
                        color: c.priority.color,
                        icon: c.priority.icon,
                        dense: true,
                      ),
                    StatusBadge(
                      label: l.complaintCategory(c.category),
                      color: c.category.color,
                      dense: true,
                    ),
                    if (c.abusive)
                      StatusBadge(
                        label: l.complaintAbusiveBadge,
                        color: AppColors.danger,
                        icon: Icons.gpp_bad_outlined,
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
