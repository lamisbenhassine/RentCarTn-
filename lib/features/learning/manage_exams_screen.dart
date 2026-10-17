import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../data/models/exam.dart';
import '../../state/exam_provider.dart';
import '../../state/load_state.dart';
import '../../widgets/common.dart';
import '../shell/main_shell.dart';

/// CRUD admin des examens (sans passage utilisateur pour l'instant).
class ManageExamsScreen extends StatefulWidget {
  const ManageExamsScreen({super.key});

  @override
  State<ManageExamsScreen> createState() => _ManageExamsScreenState();
}

class _ManageExamsScreenState extends State<ManageExamsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExamProvider>().load();
    });
  }

  Future<void> _confirmDelete(Exam exam) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer cet examen ?'),
        content: Text(
          '« ${exam.title} » et ses ${exam.questionCount} questions '
          'seront retirés.',
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
      await context.read<ExamProvider>().delete(exam.id);
      if (!mounted) return;
      AppSnack.success(context, 'Examen supprimé.');
    } catch (_) {
      if (!mounted) return;
      AppSnack.error(context, 'Suppression impossible.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExamProvider>();
    final exams = provider.exams;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: appScreenBar(
        context,
        title: 'Gérer les examens',
        subtitle: 'CRUD admin · ${exams.length} examen'
            '${exams.length > 1 ? 's' : ''}',
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(Routes.examForm()),
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nouvel examen'),
      ),
      body: ContentContainer(
        child: provider.state == LoadState.loading && exams.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : provider.state == LoadState.error
                ? ErrorState(
                    message: provider.error ?? 'Erreur',
                    onRetry: () => provider.load(force: true),
                  )
                : ListView(
                    padding: EdgeInsets.fromLTRB(
                      Responsive.value(
                        context,
                        mobile: 16.0,
                        tablet: 24.0,
                        desktop: 28.0,
                      ),
                      16,
                      Responsive.value(
                        context,
                        mobile: 16.0,
                        tablet: 24.0,
                        desktop: 28.0,
                      ),
                      100,
                    ),
                    children: [
                      const NoticeBox(
                        icon: Icons.admin_panel_settings_outlined,
                        title: 'Espace administrateur',
                        message:
                            'Créez et modifiez les examens (titre, questions, '
                            'seuil de réussite). Le passage du test par '
                            'l\'utilisateur sera branché ensuite.',
                      ),
                      const SizedBox(height: 16),
                      if (exams.isEmpty)
                        EmptyState(
                          icon: Icons.workspace_premium_outlined,
                          title: 'Aucun examen',
                          message:
                              'Ajoutez un examen final avec ses questions QCM.',
                          actionLabel: 'Créer un examen',
                          onAction: () => context.push(Routes.examForm()),
                        )
                      else
                        for (final exam in exams)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: AppCard(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: AppColors.accent
                                              .withValues(alpha: 0.12),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: const Icon(
                                          Icons.workspace_premium_rounded,
                                          color: AppColors.accent,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              exam.title,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              exam.description,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 12.5,
                                                color: AppColors.textMuted,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      _Chip(
                                        label:
                                            '${exam.questionCount} question'
                                            '${exam.questionCount > 1 ? 's' : ''}',
                                        color: AppColors.navy,
                                      ),
                                      _Chip(
                                        label:
                                            'Seuil ${exam.passingPercent} %',
                                        color: AppColors.warning,
                                      ),
                                      if (exam.isFinal)
                                        const _Chip(
                                          label: 'Examen final',
                                          color: AppColors.accent,
                                        ),
                                      _Chip(
                                        label: exam.isPublished
                                            ? 'Publié'
                                            : 'Brouillon',
                                        color: exam.isPublished
                                            ? AppColors.success
                                            : AppColors.textMuted,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      OutlinedButton.icon(
                                        onPressed: () => context.push(
                                          Routes.examForm(id: exam.id),
                                        ),
                                        icon: const Icon(
                                          Icons.edit_outlined,
                                          size: 16,
                                        ),
                                        label: const Text('Modifier'),
                                      ),
                                      const SizedBox(width: 8),
                                      OutlinedButton.icon(
                                        onPressed: () =>
                                            _confirmDelete(exam),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppColors.danger,
                                          side: const BorderSide(
                                            color: AppColors.danger,
                                          ),
                                        ),
                                        icon: const Icon(
                                          Icons.delete_outline_rounded,
                                          size: 16,
                                        ),
                                        label: const Text('Supprimer'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                    ],
                  ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
