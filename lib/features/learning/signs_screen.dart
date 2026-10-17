import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../data/models/learning.dart';
import '../../state/learning_provider.dart';
import '../../state/load_state.dart';
import '../../widgets/common.dart';
import '../shell/main_shell.dart';
import 'sign_widget.dart';

class SignsScreen extends StatefulWidget {
  const SignsScreen({super.key});

  @override
  State<SignsScreen> createState() => _SignsScreenState();
}

class _SignsScreenState extends State<SignsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(
    length: SignCategory.values.length,
    vsync: this,
  );

  @override
  void initState() {
    super.initState();
    _tabs.addListener(_markStudied);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LearningProvider>().loadSigns();
      _markStudied();
    });
  }

  void _markStudied() {
    if (_tabs.indexIsChanging) return;
    context.read<LearningProvider>().markCategoryStudied(
      SignCategory.values[_tabs.index],
    );
  }

  @override
  void dispose() {
    _tabs.removeListener(_markStudied);
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final learning = context.watch<LearningProvider>();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: appScreenBar(
        context,
        title: 'Panneaux de signalisation',
        subtitle: learning.signs.isEmpty
            ? 'Chargement…'
            : '${learning.signs.length} panneaux expliqués',
        actions: [
          IconButton(
            tooltip: 'Gérer les panneaux',
            onPressed: () => context.push(Routes.manageSigns),
            icon: const Icon(Icons.edit_note_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(Routes.signForm()),
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Ajouter'),
      ),
      body: ContentContainer(
        child: Column(
          children: [
            TabBar(
              controller: _tabs,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: [
                for (final category in SignCategory.values)
                  Tab(
                    text:
                        '${category.shortLabel} '
                        '(${learning.signsByCategory(category).length})',
                  ),
              ],
            ),
            Expanded(
              child: learning.signsState == LoadState.loading &&
                      learning.signs.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : learning.signsState == LoadState.error
                      ? ErrorState(
                          message: learning.signsError ??
                              'Erreur de chargement',
                          onRetry: () =>
                              learning.loadSigns(force: true),
                        )
                      : TabBarView(
                          controller: _tabs,
                          children: [
                            for (final category in SignCategory.values)
                              _SignList(category: category),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SignList extends StatelessWidget {
  const _SignList({required this.category});

  final SignCategory category;

  @override
  Widget build(BuildContext context) {
    final signs = context.watch<LearningProvider>().signsByCategory(category);

    if (signs.isEmpty) {
      return EmptyState(
        icon: Icons.traffic_rounded,
        title: 'Aucun panneau « ${category.shortLabel} »',
        message:
            'Ajoutez votre propre contenu pour cette catégorie '
            '(Create / Update / Delete).',
        actionLabel: 'Ajouter un panneau',
        onAction: () => context.push(
          Routes.signForm(category: category),
        ),
      );
    }

    return ListView(
      padding: EdgeInsets.fromLTRB(
        Responsive.value(context, mobile: 16.0, tablet: 24.0, desktop: 28.0),
        18,
        Responsive.value(context, mobile: 16.0, tablet: 24.0, desktop: 28.0),
        100,
      ),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: category.color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(
              color: category.color.withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 19, color: category.color),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  _intro,
                  style: const TextStyle(
                    fontSize: 12.5,
                    height: 1.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (Responsive.isWide(context))
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: signs.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: Responsive.value(context, mobile: 1, tablet: 2),
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              mainAxisExtent: 240,
            ),
            itemBuilder: (_, i) => _SignCard(sign: signs[i]),
          )
        else
          for (final sign in signs)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _SignCard(sign: sign),
            ),
      ],
    );
  }

  String get _intro => switch (category) {
        SignCategory.danger =>
          "Les panneaux triangulaires à bordure rouge annoncent un danger. "
              "Ils sont implantés en amont pour vous laisser le temps de ralentir.",
        SignCategory.interdiction =>
          "Les panneaux ronds à bordure rouge interdisent une manœuvre ou "
              "limitent la vitesse. Leur non-respect constitue une infraction.",
        SignCategory.obligation =>
          "Les panneaux ronds à fond bleu imposent un comportement : direction, "
              "vitesse minimale ou voie réservée.",
        SignCategory.indication =>
          "Les panneaux carrés informent sans imposer : services, équipements et "
              "points d'intérêt sur l'itinéraire.",
        SignCategory.priorite =>
          "Ces panneaux définissent l'ordre de passage aux intersections. "
              "Ils priment sur la règle de la priorité à droite.",
      };
}

class _SignCard extends StatelessWidget {
  const _SignCard({required this.sign});

  final RoadSign sign;

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ce panneau ?'),
        content: Text(
          '« ${sign.name} » sera retiré définitivement.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;

    try {
      await context.read<LearningProvider>().deleteSign(sign.id);
      if (!context.mounted) return;
      AppSnack.success(context, 'Panneau supprimé.');
    } catch (_) {
      if (!context.mounted) return;
      AppSnack.error(context, 'Suppression impossible.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RoadSignWidget(sign: sign, size: 72),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sign.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      sign.meaning,
                      style: const TextStyle(
                        fontSize: 12.5,
                        height: 1.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Modifier',
                onPressed: () =>
                    context.push(Routes.signForm(id: sign.id)),
                icon: const Icon(Icons.edit_outlined, size: 20),
              ),
              IconButton(
                tooltip: 'Supprimer',
                onPressed: () => _confirmDelete(context),
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  size: 20,
                  color: AppColors.danger,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.lightbulb_outline_rounded,
                  size: 16,
                  color: AppColors.warning,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    sign.advice,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.45,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _TrustTag(trust: sign.trust),
        ],
      ),
    );
  }
}

class _TrustTag extends StatelessWidget {
  const _TrustTag({required this.trust});

  final ContentTrust trust;

  @override
  Widget build(BuildContext context) {
    final color = trust == ContentTrust.aVerifier
        ? AppColors.warning
        : AppColors.info;
    return Row(
      children: [
        Icon(
          trust == ContentTrust.aVerifier
              ? Icons.fact_check_outlined
              : Icons.science_outlined,
          size: 13,
          color: color,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            trust.label,
            style: TextStyle(
              fontSize: 10.5,
              fontStyle: FontStyle.italic,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}
