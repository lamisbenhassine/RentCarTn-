import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../data/mock/mock_learning.dart';
import '../../data/models/learning.dart';
import '../../state/learning_provider.dart';
import '../../widgets/common.dart';
import '../shell/main_shell.dart';

class RulesScreen extends StatelessWidget {
  const RulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final learning = context.watch<LearningProvider>();
    final rules = learning.rules;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: appScreenBar(
        context,
        title: 'Règles de circulation',
        subtitle: rules.isEmpty
            ? 'Aucun thème pour le moment'
            : '${rules.length} thèmes à connaître',
      ),
      body: ContentContainer(
        maxWidth: 860,
        child: rules.isEmpty
            ? const EmptyState(
                icon: Icons.rule_rounded,
                title: 'Pas encore de règles',
                message:
                    'Les thèmes de circulation ne sont plus préremplis. '
                    'Concentrez-vous sur les panneaux et examens (CRUD).',
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
                  28,
                ),
                children: [
                  const NoticeBox(
                    icon: Icons.warning_amber_rounded,
                    color: AppColors.warning,
                    title: 'À vérifier auprès des textes officiels',
                    message: MockLearning.disclaimer,
                  ),
                  const SizedBox(height: 16),
                  for (final section in rules)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _RuleCard(
                        section: section,
                        read: learning.isRead(section.id),
                        onExpanded: () =>
                            learning.markSectionRead(section.id),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

class _RuleCard extends StatelessWidget {
  const _RuleCard({
    required this.section,
    required this.read,
    required this.onExpanded,
  });

  final RuleSection section;
  final bool read;
  final VoidCallback onExpanded;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          onExpansionChanged: (open) {
            if (open) onExpanded();
          },
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(section.icon, color: AppColors.accent, size: 20),
          ),
          title: Text(
            section.title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          subtitle: read
              ? const Text(
                  'Lu',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                )
              : Text(
                  section.summary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textMuted,
                  ),
                ),
          children: [
            Text(
              section.summary,
              style: const TextStyle(
                fontSize: 13.5,
                height: 1.55,
                color: AppColors.textSecondary,
              ),
            ),
            if (section.points.isNotEmpty) ...[
              const SizedBox(height: 12),
              for (final point in section.points)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.check_rounded,
                        size: 16,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          point,
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.45,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
