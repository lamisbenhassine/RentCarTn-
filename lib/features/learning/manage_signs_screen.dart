import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../data/models/learning.dart';
import '../../state/learning_provider.dart';
import '../../widgets/common.dart';
import '../shell/main_shell.dart';
import 'sign_widget.dart';

/// Liste CRUD de tous les panneaux (Create / Read / Update / Delete).
class ManageSignsScreen extends StatefulWidget {
  const ManageSignsScreen({super.key});

  @override
  State<ManageSignsScreen> createState() => _ManageSignsScreenState();
}

class _ManageSignsScreenState extends State<ManageSignsScreen> {
  SignCategory? _filter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LearningProvider>().loadSigns();
    });
  }

  Future<void> _confirmDelete(RoadSign sign) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ce panneau ?'),
        content: Text(
          '« ${sign.name} » sera retiré définitivement '
          '(base locale / session).',
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
    if (ok != true || !mounted) return;

    try {
      await context.read<LearningProvider>().deleteSign(sign.id);
      if (!mounted) return;
      AppSnack.success(context, 'Panneau supprimé.');
    } catch (_) {
      if (!mounted) return;
      AppSnack.error(context, 'Suppression impossible.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final learning = context.watch<LearningProvider>();
    final signs = _filter == null
        ? learning.signs
        : learning.signsByCategory(_filter!);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: appScreenBar(
        context,
        title: 'Gérer les panneaux',
        subtitle: 'CRUD · ${learning.signs.length} entrées',
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(Routes.signForm(category: _filter)),
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nouveau panneau'),
      ),
      body: ContentContainer(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                Responsive.value(
                  context,
                  mobile: 16.0,
                  tablet: 24.0,
                  desktop: 28.0,
                ),
                12,
                Responsive.value(
                  context,
                  mobile: 16.0,
                  tablet: 24.0,
                  desktop: 28.0,
                ),
                8,
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('Tous'),
                      selected: _filter == null,
                      onSelected: (_) => setState(() => _filter = null),
                    ),
                    const SizedBox(width: 8),
                    for (final cat in SignCategory.values) ...[
                      FilterChip(
                        label: Text(cat.shortLabel),
                        selected: _filter == cat,
                        selectedColor: cat.color.withValues(alpha: 0.18),
                        onSelected: (_) =>
                            setState(() => _filter = cat),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.value(
                  context,
                  mobile: 16.0,
                  tablet: 24.0,
                  desktop: 28.0,
                ),
              ),
              child: const NoticeBox(
                icon: Icons.storage_outlined,
                title: 'Persistance locale',
                message:
                    'APK / téléphone : sqflite. Navigateur (Chrome) : '
                    'shared_preferences (localStorage) — tes CRUD survivent '
                    'au refresh (F5).',
              ),
            ),
            Expanded(
              child: signs.isEmpty
                  ? EmptyState(
                      icon: Icons.traffic_rounded,
                      title: 'Aucun panneau',
                      message: 'Créez votre premier panneau pour commencer.',
                      actionLabel: 'Ajouter',
                      onAction: () => context.push(
                        Routes.signForm(category: _filter),
                      ),
                    )
                  : ListView.separated(
                      padding: EdgeInsets.fromLTRB(
                        Responsive.value(
                          context,
                          mobile: 16.0,
                          tablet: 24.0,
                          desktop: 28.0,
                        ),
                        12,
                        Responsive.value(
                          context,
                          mobile: 16.0,
                          tablet: 24.0,
                          desktop: 28.0,
                        ),
                        100,
                      ),
                      itemCount: signs.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final sign = signs[i];
                        return AppCard(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              RoadSignWidget(sign: sign, size: 52),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      sign.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14.5,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      sign.category.shortLabel,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: sign.category.color,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: 'Modifier',
                                onPressed: () => context.push(
                                  Routes.signForm(id: sign.id),
                                ),
                                icon: const Icon(Icons.edit_outlined),
                              ),
                              IconButton(
                                tooltip: 'Supprimer',
                                onPressed: () => _confirmDelete(sign),
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: AppColors.danger,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
