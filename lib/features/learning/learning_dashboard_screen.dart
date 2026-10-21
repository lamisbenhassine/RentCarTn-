import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../data/mock/mock_learning.dart';
import '../../data/models/exam.dart';
import '../../data/models/learning.dart';
import '../../state/exam_provider.dart';
import '../../state/learning_provider.dart';
import '../../widgets/common.dart';
import '../shell/main_shell.dart';

class LearningDashboardScreen extends StatefulWidget {
  const LearningDashboardScreen({super.key});

  @override
  State<LearningDashboardScreen> createState() =>
      _LearningDashboardScreenState();
}

class _LearningDashboardScreenState extends State<LearningDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LearningProvider>().loadSigns();
      context.read<ExamProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final learning = context.watch<LearningProvider>();
    final exams = context.watch<ExamProvider>();
    final publishedExams = exams.publishedExams;
    final wide = Responsive.isWide(context);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: wide
          ? null
          : AppBar(
              backgroundColor: AppColors.surface,
              automaticallyImplyLeading: false,
              toolbarHeight: 64,
              title: const Text('Code de la route'),
            ),
      body: ContentContainer(
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            Responsive.value(
              context,
              mobile: 16.0,
              tablet: 24.0,
              desktop: 32.0,
            ),
            wide ? 28 : 4,
            Responsive.value(
              context,
              mobile: 16.0,
              tablet: 24.0,
              desktop: 32.0,
            ),
            28,
          ),
          children: [
            if (wide) ...[
              Text(
                'Code de la route tunisien',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
            ],
            _ProgressCard(learning: learning),
            const SizedBox(height: 20),
            const NoticeBox(
              icon: Icons.warning_amber_rounded,
              color: AppColors.warning,
              title: 'Avertissement pédagogique',
              message: MockLearning.disclaimer,
            ),
            const SizedBox(height: 24),
            SectionHeader(
              title: 'Apprendre',
              subtitle: 'Panneaux, règles et conseils de conduite',
            ),
            _LessonsGrid(learning: learning),
            const SizedBox(height: 26),
            if (learning.quizzes.isNotEmpty) ...[
              SectionHeader(
                title: 'Quiz thématiques',
                subtitle:
                    'Testez vos connaissances et suivez votre progression',
              ),
              for (final quiz in learning.quizzes)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _QuizTile(
                    quiz: quiz,
                    result: learning.resultFor(quiz.id),
                  ),
                ),
              const SizedBox(height: 18),
            ],
            SectionHeader(
              title: 'Examens publiés',
              subtitle: publishedExams.isEmpty
                  ? 'Aucun examen publié pour le moment'
                  : '${publishedExams.length} examen'
                      '${publishedExams.length > 1 ? 's' : ''} disponible'
                      '${publishedExams.length > 1 ? 's' : ''}',
            ),
            if (publishedExams.isEmpty)
              AppCard(
                child: EmptyState(
                  compact: true,
                  icon: Icons.workspace_premium_outlined,
                  title: 'Pas encore d\'examen publié',
                  message:
                      'Créez un examen dans l\'espace admin et activez '
                      '« Publié » pour qu\'il apparaisse ici.',
                  actionLabel: 'Gérer les examens',
                  onAction: () => context.push(Routes.manageExams),
                ),
              )
            else
              for (final exam in publishedExams)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _PublishedExamCard(
                    exam: exam,
                    learning: learning,
                  ),
                ),
            const SizedBox(height: 12),
            AppCard(
              onTap: () => context.push(Routes.manageExams),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.admin_panel_settings_outlined,
                      color: AppColors.accent,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Gérer les examens (admin)',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14.5,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Créer, modifier ou supprimer un examen final',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            if (learning.results.isNotEmpty) ...[
              SectionHeader(
                title: 'Mes résultats',
                actionLabel: 'Réinitialiser',
                onAction: () {
                  learning.resetProgress();
                  AppSnack.info(context, 'Progression réinitialisée.');
                },
              ),
              _ResultsCard(learning: learning),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.learning});

  final LearningProvider learning;

  @override
  Widget build(BuildContext context) {
    final percent = (learning.overallProgress * 100).round();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: navyBlock(radius: AppTheme.radiusXl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.school_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Votre progression',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${learning.completedQuizzes} quiz réalisé'
                      '${learning.completedQuizzes > 1 ? 's' : ''} · '
                      'score moyen ${learning.globalScore} %',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$percent %',
                style: const TextStyle(
                  color: AppColors.accentLight,
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: learning.overallProgress,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.15),
              valueColor: const AlwaysStoppedAnimation(AppColors.accentLight),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            learning.finalTestPassed
                ? "Examen blanc réussi. Continuez à réviser régulièrement."
                : "Ajoutez panneaux et examens via le CRUD, puis passez "
                    "les examens publiés pour suivre votre progression.",
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              fontSize: 12.5,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _LessonsGrid extends StatelessWidget {
  const _LessonsGrid({required this.learning});

  final LearningProvider learning;

  @override
  Widget build(BuildContext context) {
    final lessons = <(IconData, String, String, Color, String)>[
      (
        Icons.signpost_rounded,
        'Panneaux de signalisation',
        '${learning.signs.isEmpty ? '…' : learning.signs.length} panneaux illustrés',
        AppColors.danger,
        Routes.signs,
      ),
      (
        Icons.rule_rounded,
        'Règles de circulation',
        learning.rules.isEmpty
            ? 'Contenu à compléter'
            : '${learning.rules.length} thèmes détaillés',
        AppColors.accent,
        Routes.rules,
      ),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: Responsive.value(context, mobile: 1, tablet: 2),
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      childAspectRatio: Responsive.value(
        context,
        mobile: 3.3,
        tablet: 2.6,
        desktop: 3.0,
      ),
      children: [
        for (final (icon, title, subtitle, color, path) in lessons)
          AppCard(
            onTap: () => context.push(path),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.11),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(icon, size: 22, color: color),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _QuizTile extends StatelessWidget {
  const _QuizTile({required this.quiz, required this.result});

  final Quiz quiz;
  final QuizResult? result;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      onTap: () => context.push(Routes.quiz(quiz.id)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: quiz.color.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(quiz.icon, size: 21, color: quiz.color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  quiz.title,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${quiz.questionCount} questions · ${quiz.description}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (result == null)
            const Icon(
              Icons.play_circle_fill_rounded,
              size: 30,
              color: AppColors.accent,
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${result!.score}/${result!.total}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: result!.passed
                        ? AppColors.success
                        : AppColors.warning,
                  ),
                ),
                Text(
                  result!.passed ? 'Réussi' : 'À revoir',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _PublishedExamCard extends StatelessWidget {
  const _PublishedExamCard({
    required this.exam,
    required this.learning,
  });

  final Exam exam;
  final LearningProvider learning;

  @override
  Widget build(BuildContext context) {
    final quiz = exam.toQuiz();
    final result = learning.resultFor(exam.id);
    const color = Color(0xFF7C3AED);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withValues(alpha: 0.75)],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.workspace_premium_rounded,
                color: Colors.white,
                size: 26,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exam.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.4,
                      ),
                    ),
                    Text(
                      '${exam.questionCount} questions · seuil '
                      '${exam.passingPercent} % '
                      '(${quiz.passingScore}/${exam.questionCount})',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (result != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    '${result.percent} %',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            exam.description,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: exam.questionCount == 0
                  ? null
                  : () => context.push(Routes.quiz(exam.id)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: color,
                minimumSize: const Size(0, 46),
              ),
              child: Text(
                result == null ? 'Passer l\'examen' : 'Repasser l\'examen',
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Entraînement pédagogique : aucun permis ni certificat officiel.",
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultsCard extends StatelessWidget {
  const _ResultsCard({required this.learning});

  final LearningProvider learning;

  @override
  Widget build(BuildContext context) {
    final entries = learning.results.entries.toList();

    return AppCard(
      child: Column(
        children: [
          for (var i = 0; i < entries.length; i++) ...[
            Builder(
              builder: (_) {
                final quiz = MockLearning.quizById(entries[i].key);
                final result = entries[i].value;
                return Row(
                  children: [
                    Icon(
                      result.passed
                          ? Icons.check_circle_rounded
                          : Icons.cancel_rounded,
                      size: 19,
                      color: result.passed
                          ? AppColors.success
                          : AppColors.danger,
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Text(
                        quiz?.title ?? entries[i].key,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      '${result.score}/${result.total} · ${result.percent} %',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                );
              },
            ),
            if (i != entries.length - 1) const Divider(height: 20),
          ],
        ],
      ),
    );
  }
}
