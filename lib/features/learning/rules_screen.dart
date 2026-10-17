import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
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

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: appScreenBar(
        context,
        title: 'Règles de circulation',
        subtitle: '${MockLearning.rules.length} thèmes à connaître',
      ),
      body: ContentContainer(
        maxWidth: 860,
        child: ListView(
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
            for (final section in MockLearning.rules)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _RuleCard(
                  section: section,
                  read: learning.isRead(section.id),
                  onExpanded: () => learning.markSectionRead(section.id),
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
    final verified = section.trust == ContentTrust.aVerifier;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          onExpansionChanged: (expanded) {
            if (expanded) onExpanded();
          },
          tilePadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(section.icon, size: 20, color: AppColors.accent),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  section.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (read)
                const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Icon(
                    Icons.check_circle_rounded,
                    size: 17,
                    color: AppColors.success,
                  ),
                ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(
              section.summary,
              style: const TextStyle(
                fontSize: 12,
                height: 1.4,
                color: AppColors.textMuted,
              ),
            ),
          ),
          children: [
            for (final point in section.points)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      height: 6,
                      width: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Text(
                        point,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.55,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: (verified ? AppColors.warning : AppColors.info)
                    .withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: Row(
                children: [
                  Icon(
                    verified
                        ? Icons.fact_check_outlined
                        : Icons.science_outlined,
                    size: 15,
                    color: verified ? AppColors.warning : AppColors.info,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      verified
                          ? "Règles générales : confirmez les valeurs exactes "
                                "auprès du Code de la route tunisien en vigueur."
                          : "Conseils pratiques illustratifs, sans portée "
                                "réglementaire.",
                      style: TextStyle(
                        fontSize: 11.5,
                        height: 1.45,
                        fontStyle: FontStyle.italic,
                        color: verified ? AppColors.warning : AppColors.info,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
