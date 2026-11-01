import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show NumberFormat;
import 'package:provider/provider.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/relative_time.dart';
import '../../core/utils/responsive.dart';
import '../../data/models/complaint.dart';
import '../../l10n/l10n.dart';
import '../../state/auth_provider.dart';
import '../../state/complaint_provider.dart';
import '../../state/load_state.dart';
import '../../state/reminder_provider.dart';
import '../../widgets/common.dart';
import '../../widgets/status_badge.dart';
import '../assistant/assistant_screen.dart';
import 'complaint_l10n.dart';
import 'gemini_debug_sheet.dart';
import 'urgent_breakdown.dart';
import 'widgets/rating_stars.dart';

/// Liste « Mes réclamations » : compteurs, filtres, recherche, création.
class MyComplaintsScreen extends StatefulWidget {
  const MyComplaintsScreen({super.key});

  @override
  State<MyComplaintsScreen> createState() => _MyComplaintsScreenState();
}

class _MyComplaintsScreenState extends State<MyComplaintsScreen> {
  final _search = TextEditingController();

  /// `null` = « Toutes ».
  ComplaintStatus? _filter;
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final userId = context.read<AuthProvider>().user?.id;
    await context.read<ComplaintProvider>().loadFor(userId, force: true);
  }

  /// Filtre de statut + recherche (titre ou référence), plus récentes d'abord.
  List<Complaint> _visible(List<Complaint> all) {
    final q = _query.trim().toLowerCase();
    return all
        .where((c) => _filter == null || c.status == _filter)
        .where(
          (c) =>
              q.isEmpty ||
              c.title.toLowerCase().contains(q) ||
              c.reference.toLowerCase().contains(q),
        )
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  void _clearFilters() {
    _search.clear();
    setState(() {
      _filter = null;
      _query = '';
    });
  }

  void _open(Complaint c) => context.push(Routes.complaint(c.id));

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final provider = context.watch<ComplaintProvider>();
    final all = provider.complaints;
    final visible = _visible(all);

    final Widget body;
    if (provider.state == LoadState.loading && all.isEmpty) {
      body = const Center(child: CircularProgressIndicator());
    } else if (provider.state == LoadState.error && all.isEmpty) {
      body = _scrollable(
        EmptyState(
          icon: Icons.cloud_off_rounded,
          title: l.complaintsLoadError,
          message: '',
          actionLabel: l.complaintsRetry,
          onAction: _refresh,
        ),
      );
    } else if (all.isEmpty) {
      body = _scrollable(const _EmptyIllustration());
    } else {
      final pad = Responsive.value(context, mobile: 16.0, tablet: 24.0);
      body = ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(pad, 12, pad, 96),
        children: [
          // Toujours visible en haut : panne urgente en 2 clics.
          const UrgentBreakdownButton(),
          const SizedBox(height: 14),
          const _NotificationsOffNotice(),
          _Counters(
            complaints: all,
            selected: _filter,
            onTap: (s) => setState(() => _filter = _filter == s ? null : s),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _search,
            textInputAction: TextInputAction.search,
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: l.complaintsSearchHint,
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () {
                        _search.clear();
                        setState(() => _query = '');
                      },
                    ),
            ),
          ),
          const SizedBox(height: 12),
          _FilterChips(
            complaints: all,
            selected: _filter,
            onSelected: (s) => setState(() => _filter = s),
          ),
          const SizedBox(height: 14),
          if (visible.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Column(
                children: [
                  Icon(
                    Icons.search_off_rounded,
                    size: 44,
                    color: context.cs.outline,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l.complaintsNoMatch,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: context.cs.onSurfaceVariant),
                  ),
                  TextButton(
                    onPressed: _clearFilters,
                    child: Text(l.complaintsClearFilters),
                  ),
                ],
              ),
            )
          else
            for (final c in visible) ...[
              _ComplaintCard(complaint: c, onTap: () => _open(c)),
              const SizedBox(height: 10),
            ],
        ],
      );
    }

    return Scaffold(
      backgroundColor: context.cs.surfaceContainerLow,
      appBar: AppBar(
        backgroundColor: context.cs.surfaceContainerLow,
        // Mode debug : appui long sur le titre → test de la clé Gemini.
        title: GestureDetector(
          onLongPress: kDebugMode ? () => showGeminiDebugSheet(context) : null,
          child: Text(l.myComplaintsTitle),
        ),
        shape: Border(bottom: BorderSide(color: context.cs.outlineVariant)),
      ),
      // Bulle de l'assistant au-dessus du bouton « Nouvelle réclamation ».
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const AssistantFab(heroTag: 'assistant-fab-complaints'),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'complaint-new-fab',
            tooltip: l.complaintReport,
            onPressed: () => context.push(Routes.complaintNew),
            child: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ContentContainer(maxWidth: 760, child: body),
      ),
    );
  }

  /// Rend l'état vide « tirable » pour le pull-to-refresh.
  Widget _scrollable(Widget child) => LayoutBuilder(
    builder: (context, box) => SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: box.maxHeight),
        child: Center(child: child),
      ),
    ),
  );
}

// -----------------------------------------------------------------------------
// Compteurs
// -----------------------------------------------------------------------------

/// Une tuile par statut (« 2 En cours », « 5 Résolues ») ; un appui filtre.
class _Counters extends StatelessWidget {
  const _Counters({
    required this.complaints,
    required this.selected,
    required this.onTap,
  });

  final List<Complaint> complaints;
  final ComplaintStatus? selected;
  final ValueChanged<ComplaintStatus> onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final rated = complaints.where((c) => c.rating != null).toList();
    final average = rated.isEmpty
        ? null
        : rated.map((c) => c.rating!).reduce((a, b) => a + b) / rated.length;

    return Column(
      children: [
        Row(
          children: [
            for (final s in ComplaintStatus.values) ...[
              Expanded(
                child: _CounterTile(
                  count: complaints.where((c) => c.status == s).length,
                  label: l.complaintStatus(s),
                  color: s.color,
                  icon: s.icon,
                  selected: selected == s,
                  onTap: () => onTap(s),
                ),
              ),
              if (s != ComplaintStatus.values.last) const SizedBox(width: 8),
            ],
          ],
        ),
        // Note moyenne de satisfaction (dès le premier avis).
        if (average != null) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: ratingStarColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(
                color: ratingStarColor.withValues(alpha: 0.45),
              ),
            ),
            child: Row(
              children: [
                Text(
                  l.ratingAverage,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: context.cs.onSurface,
                  ),
                ),
                const Spacer(),
                RatingStars(value: average.round(), size: 16),
                const SizedBox(width: 8),
                Text(
                  '${NumberFormat('0.0', l.localeName).format(average)}/5',
                  textDirection: TextDirection.ltr,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: context.cs.onSurface,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '(${l.ratingCount(rated.length)})',
                  style: TextStyle(fontSize: 12, color: context.cs.outline),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _CounterTile extends StatelessWidget {
  const _CounterTile({
    required this.count,
    required this.label,
    required this.color,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final int count;
  final String label;
  final Color color;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? color.withValues(alpha: 0.14) : context.cs.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        side: BorderSide(
          color: selected ? color : context.cs.outlineVariant,
          width: selected ? 1.6 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          child: Column(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(height: 4),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: context.cs.onSurface,
                ),
              ),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: context.cs.outline),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Filtres
// -----------------------------------------------------------------------------

class _FilterChips extends StatelessWidget {
  const _FilterChips({
    required this.complaints,
    required this.selected,
    required this.onSelected,
  });

  final List<Complaint> complaints;
  final ComplaintStatus? selected;
  final ValueChanged<ComplaintStatus?> onSelected;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;

    Widget chip(String label, int count, ComplaintStatus? value) => Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: ChoiceChip(
        label: Text('$label ($count)'),
        selected: selected == value,
        onSelected: (_) => onSelected(value),
        showCheckmark: false,
      ),
    );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          chip(l.complaintsFilterAll, complaints.length, null),
          for (final s in ComplaintStatus.values)
            chip(
              l.complaintStatus(s),
              complaints.where((c) => c.status == s).length,
              s,
            ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Carte de réclamation
// -----------------------------------------------------------------------------

class _ComplaintCard extends StatelessWidget {
  const _ComplaintCard({required this.complaint, required this.onTap});

  final Complaint complaint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = complaint;
    final urgent = c.isUrgent || c.priority == ComplaintPriority.urgente;
    final unread = context.watch<ComplaintProvider>().isUnread(c.id);

    return Material(
      color: context.cs.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        side: BorderSide(color: context.cs.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icône de catégorie.
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: c.category.color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(c.category.icon, color: c.category.color),
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
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                            color: context.cs.outline,
                          ),
                        ),
                        if (unread) ...[
                          const SizedBox(width: 8),
                          Badge(
                            label: Text(l.complaintUnreadLabel),
                            backgroundColor: AppColors.danger,
                          ),
                        ],
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
                    const SizedBox(height: 2),
                    Text(
                      [
                        l.complaintCategory(c.category),
                        if (c.carLabel != null) c.carLabel!,
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: context.cs.onSurfaceVariant,
                      ),
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
                          ),
                        // Réclamation notée : étoiles du client.
                        if (c.rating != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: RatingStars(value: c.rating!, size: 16),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// État vide
// -----------------------------------------------------------------------------

/// Illustration dessinée en widgets (aucune image à embarquer).
class _EmptyIllustration extends StatelessWidget {
  const _EmptyIllustration();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final accent = context.cs.primary;

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 140,
            width: 160,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  height: 130,
                  width: 130,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                ),
                Icon(
                  Icons.support_agent_rounded,
                  size: 72,
                  color: accent.withValues(alpha: 0.85),
                ),
                PositionedDirectional(
                  top: 12,
                  end: 8,
                  child: _Bubble(
                    icon: Icons.chat_bubble_rounded,
                    color: AppColors.success,
                  ),
                ),
                PositionedDirectional(
                  bottom: 14,
                  start: 6,
                  child: _Bubble(
                    icon: Icons.build_rounded,
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            l.complaintsEmptyTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            l.complaintsEmptyMessage,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.5,
              color: context.cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => context.push(Routes.complaintNew),
            icon: const Icon(Icons.report_problem_outlined),
            label: Text(l.complaintReport),
          ),
          const SizedBox(height: 16),
          const UrgentBreakdownButton(),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: context.cs.surface,
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Icon(icon, size: 18, color: color),
    );
  }
}

/// Android 13+ : notifications refusées → bandeau + bouton « Activer »
/// (demande système, sinon paramètres Android). Les mises à jour restent
/// visibles dans la liste (pastille « Nouveau » et badge du profil).
class _NotificationsOffNotice extends StatelessWidget {
  const _NotificationsOffNotice();

  @override
  Widget build(BuildContext context) {
    final reminders = context.watch<ReminderProvider>();
    if (!reminders.supported || reminders.permissionGranted != false) {
      return const SizedBox.shrink();
    }
    final l = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          NoticeBox(
            icon: Icons.notifications_off_outlined,
            color: AppColors.warning,
            message: l.complaintNotifOff,
          ),
          TextButton.icon(
            onPressed: reminders.requestPermission,
            icon: const Icon(Icons.notifications_active_outlined, size: 18),
            label: Text(l.complaintNotifEnable),
          ),
        ],
      ),
    );
  }
}
