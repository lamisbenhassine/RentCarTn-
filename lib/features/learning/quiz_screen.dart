import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../data/mock/mock_learning.dart';
import '../../data/models/learning.dart';
import '../../state/exam_provider.dart';
import '../../state/learning_provider.dart';
import '../../widgets/common.dart';
import '../shell/main_shell.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key, required this.quizId});

  final String quizId;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  Quiz? _quiz;
  bool _loading = true;

  int _index = 0;
  int? _selected;
  bool _validated = false;
  bool _finished = false;
  late List<int> _answers;

  @override
  void initState() {
    super.initState();
    _answers = const [];
    WidgetsBinding.instance.addPostFrameCallback((_) => _resolveQuiz());
  }

  Future<void> _resolveQuiz() async {
    // 1) Quiz thématiques mock
    var quiz = MockLearning.quizById(widget.quizId);

    // 2) Examens admin (sqflite / prefs)
    if (quiz == null) {
      final exams = context.read<ExamProvider>();
      await exams.load();
      final exam = exams.byId(widget.quizId);
      if (exam != null && exam.isPublished) {
        quiz = exam.toQuiz();
      }
    }

    if (!mounted) return;
    setState(() {
      _quiz = quiz;
      _answers = List.filled(quiz?.questionCount ?? 0, -1);
      _loading = false;
    });
  }

  QuizQuestion get _question => _quiz!.questions[_index];

  int get _score {
    var score = 0;
    for (var i = 0; i < _answers.length; i++) {
      if (_answers[i] == _quiz!.questions[i].correctIndex) score++;
    }
    return score;
  }

  void _validate() {
    if (_selected == null) return;
    setState(() {
      _validated = true;
      _answers[_index] = _selected!;
    });
  }

  void _next() {
    if (_index == _quiz!.questionCount - 1) {
      _finish();
      return;
    }
    setState(() {
      _index++;
      _selected = _answers[_index] == -1 ? null : _answers[_index];
      _validated = false;
    });
  }

  void _finish() {
    final quiz = _quiz!;
    final result = QuizResult(
      quizId: quiz.id,
      score: _score,
      total: quiz.questionCount,
      date: DateTime.now(),
      answers: List<int>.from(_answers),
    );
    context.read<LearningProvider>().saveResult(result);
    setState(() => _finished = true);
  }

  void _restart() {
    setState(() {
      _index = 0;
      _selected = null;
      _validated = false;
      _finished = false;
      _answers = List.filled(_quiz!.questionCount, -1);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final quiz = _quiz;

    if (quiz == null) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        appBar: appScreenBar(context, title: 'Quiz'),
        body: EmptyState(
          icon: Icons.quiz_outlined,
          title: 'Quiz introuvable',
          message: "Ce quiz n'existe pas ou n'est plus disponible.",
          actionLabel: 'Retour au module',
          onAction: () => context.go(Routes.learning),
        ),
      );
    }

    if (_finished) {
      return _ResultView(
        quiz: quiz,
        score: _score,
        answers: _answers,
        onRestart: _restart,
      );
    }

    final progress = (_index + 1) / quiz.questionCount;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: appScreenBar(
        context,
        title: quiz.title,
        subtitle: 'Question ${_index + 1} sur ${quiz.questionCount}',
      ),
      body: ContentContainer(
        maxWidth: 760,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: AppColors.border,
                  valueColor: AlwaysStoppedAnimation(quiz.color),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  Responsive.value(context, mobile: 16.0, tablet: 24.0),
                  20,
                  Responsive.value(context, mobile: 16.0, tablet: 24.0),
                  24,
                ),
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: quiz.color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Text(
                                'Question ${_index + 1}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: quiz.color,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          _question.question,
                          style: const TextStyle(
                            fontSize: 17,
                            height: 1.4,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  for (var i = 0; i < _question.options.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _OptionTile(
                        label: _question.options[i],
                        index: i,
                        selected: _selected == i,
                        validated: _validated,
                        correctIndex: _question.correctIndex,
                        onTap: _validated
                            ? null
                            : () => setState(() => _selected = i),
                      ),
                    ),
                  if (_validated) ...[
                    const SizedBox(height: 6),
                    _FeedbackBox(
                      correct: _question.isCorrect(_selected ?? -1),
                      explanation: _question.explanation,
                      trust: _question.trust,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomActionBar(
        child: Row(
          children: [
            if (_index > 0 && !_validated)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: OutlinedButton(
                  onPressed: () => setState(() {
                    _index--;
                    _selected = _answers[_index] == -1
                        ? null
                        : _answers[_index];
                    _validated = _answers[_index] != -1;
                  }),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 52),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                  child: const Icon(Icons.arrow_back_rounded, size: 20),
                ),
              ),
            Expanded(
              child: ElevatedButton(
                onPressed: _validated
                    ? _next
                    : (_selected == null ? null : _validate),
                style: ElevatedButton.styleFrom(
                  backgroundColor: quiz.color,
                ),
                child: Text(
                  _validated
                      ? (_index == quiz.questionCount - 1
                            ? 'Voir mes résultats'
                            : 'Question suivante')
                      : 'Valider ma réponse',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.label,
    required this.index,
    required this.selected,
    required this.validated,
    required this.correctIndex,
    required this.onTap,
  });

  final String label;
  final int index;
  final bool selected;
  final bool validated;
  final int correctIndex;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isCorrect = index == correctIndex;
    final showCorrect = validated && isCorrect;
    final showWrong = validated && selected && !isCorrect;

    final borderColor = showCorrect
        ? AppColors.success
        : showWrong
        ? AppColors.danger
        : selected
        ? AppColors.accent
        : AppColors.border;

    final background = showCorrect
        ? AppColors.successSoft
        : showWrong
        ? AppColors.dangerSoft
        : selected
        ? AppColors.accent.withValues(alpha: 0.06)
        : AppColors.surfaceAlt;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(
            color: borderColor,
            width: selected || showCorrect ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              height: 26,
              width: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: showCorrect
                    ? AppColors.success
                    : showWrong
                    ? AppColors.danger
                    : selected
                    ? AppColors.accent
                    : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected || validated
                      ? Colors.transparent
                      : AppColors.border,
                  width: 1.5,
                ),
              ),
              child: validated && (showCorrect || showWrong)
                  ? Icon(
                      showCorrect ? Icons.check_rounded : Icons.close_rounded,
                      size: 16,
                      color: Colors.white,
                    )
                  : Text(
                      String.fromCharCode(65 + index),
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: selected
                            ? Colors.white
                            : AppColors.textSecondary,
                      ),
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedbackBox extends StatelessWidget {
  const _FeedbackBox({
    required this.correct,
    required this.explanation,
    required this.trust,
  });

  final bool correct;
  final String explanation;
  final ContentTrust trust;

  @override
  Widget build(BuildContext context) {
    final color = correct ? AppColors.success : AppColors.danger;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                correct
                    ? Icons.check_circle_rounded
                    : Icons.highlight_off_rounded,
                size: 19,
                color: color,
              ),
              const SizedBox(width: 9),
              Text(
                correct ? 'Bonne réponse !' : 'Réponse incorrecte',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            explanation,
            style: const TextStyle(
              fontSize: 13,
              height: 1.55,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            trust.label,
            style: const TextStyle(
              fontSize: 10.5,
              fontStyle: FontStyle.italic,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  const _ResultView({
    required this.quiz,
    required this.score,
    required this.answers,
    required this.onRestart,
  });

  final Quiz quiz;
  final int score;
  final List<int> answers;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    final total = quiz.questionCount;
    final percent = ((score / total) * 100).round();
    final passed = score >= quiz.passingScore;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: appScreenBar(
        context,
        title: 'Résultats',
        subtitle: quiz.title,
      ),
      body: ContentContainer(
        maxWidth: 760,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            Responsive.value(context, mobile: 16.0, tablet: 24.0),
            16,
            Responsive.value(context, mobile: 16.0, tablet: 24.0),
            28,
          ),
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: (passed ? AppColors.success : AppColors.warning)
                    .withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                border: Border.all(
                  color: (passed ? AppColors.success : AppColors.warning)
                      .withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    passed
                        ? Icons.emoji_events_rounded
                        : Icons.refresh_rounded,
                    size: 52,
                    color: passed ? AppColors.success : AppColors.warning,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    passed ? 'Quiz réussi !' : 'Encore un petit effort',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    passed
                        ? "Vous maîtrisez cette thématique. Pensez à réviser "
                              "régulièrement."
                        : "Il faut ${quiz.passingScore}/$total bonnes "
                              "réponses pour valider. Relisez les leçons puis "
                              "réessayez.",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13.5,
                      height: 1.55,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _ScoreStat(value: '$score/$total', label: 'Score'),
                      _ScoreStat(value: '$percent %', label: 'Réussite'),
                      _ScoreStat(
                        value: '${total - score}',
                        label: 'Erreurs',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Correction détaillée',
              style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < quiz.questions.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ReviewCard(
                  question: quiz.questions[i],
                  given: answers[i],
                  number: i + 1,
                ),
              ),
            const SizedBox(height: 10),
            const NoticeBox(
              icon: Icons.info_outline_rounded,
              message:
                  "Ce quiz est un entraînement. Il ne remplace pas l'examen "
                  "officiel et ne délivre aucun certificat.",
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onRestart,
                style: ElevatedButton.styleFrom(backgroundColor: quiz.color),
                icon: const Icon(Icons.replay_rounded, size: 18),
                label: const Text('Refaire le quiz'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => context.go(Routes.learning),
                child: const Text('Retour au module'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreStat extends StatelessWidget {
  const _ScoreStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.8,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
        ),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.question,
    required this.given,
    required this.number,
  });

  final QuizQuestion question;
  final int given;
  final int number;

  @override
  Widget build(BuildContext context) {
    final correct = given == question.correctIndex;

    return AppCard(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 24,
                width: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: correct ? AppColors.success : AppColors.danger,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  correct ? Icons.check_rounded : Icons.close_rounded,
                  size: 15,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  '$number. ${question.question}',
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          if (!correct)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                'Votre réponse : '
                '${given >= 0 ? question.options[given] : 'Aucune'}',
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.danger,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          Text(
            'Bonne réponse : ${question.options[question.correctIndex]}',
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.success,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            question.explanation,
            style: const TextStyle(
              fontSize: 12.5,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
