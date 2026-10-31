import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/config/groq_config.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../data/models/car.dart';
import '../../data/models/recommend_quiz.dart';
import '../../data/services/groq_service.dart';
import '../../state/auth_provider.dart';
import '../../state/car_provider.dart';
import '../../widgets/car_card.dart';
import '../../widgets/common.dart';
import '../shell/main_shell.dart';

/// Mini questionnaire → recommandation IA (Groq) parmi le parc local.
class RecommendQuizScreen extends StatefulWidget {
  const RecommendQuizScreen({super.key});

  @override
  State<RecommendQuizScreen> createState() => _RecommendQuizScreenState();
}

class _RecommendQuizScreenState extends State<RecommendQuizScreen> {
  final _groq = GroqService();
  final Map<String, String> _answers = {};
  int _step = 0;
  bool _loading = false;
  String? _rationale;
  List<Car> _recommended = [];
  Map<String, String> _whyByCarId = {};

  List<RecommendQuestion> get _questions => RecommendQuizCatalog.questions;

  bool get _done => !_loading && _rationale != null;

  Future<void> _submit() async {
    if (_answers.length < _questions.length) {
      AppSnack.info(context, 'Répondez à toutes les questions.');
      return;
    }
    setState(() {
      _loading = true;
      _recommended = [];
      _rationale = null;
      _whyByCarId = {};
    });

    final role = context.read<AuthProvider>().role;
    final fleet = context
        .read<CarProvider>()
        .allCars
        .where((c) => c.isVisibleFor(role))
        .toList();
    final result = await _groq.recommendCars(
      answers: Map<String, String>.from(_answers),
      fleet: fleet,
    );

    if (!mounted) return;
    final byId = {for (final c in fleet) c.id: c};
    final cars = [
      for (final id in result.carIds)
        if (byId[id] != null) byId[id]!,
    ];
    final whyByCarId = {
      for (final pick in result.picks)
        if (pick.why.trim().isNotEmpty) pick.id: pick.why.trim(),
    };

    if (!result.ok) {
      setState(() {
        _loading = false;
        _recommended = [];
        _rationale = null;
        _whyByCarId = {};
      });
      AppSnack.error(
        context,
        result.message ?? 'Recommandation Groq impossible.',
      );
      return;
    }

    setState(() {
      _loading = false;
      _recommended = cars;
      _whyByCarId = whyByCarId;
      _rationale = result.rationale ?? 'Voici les véhicules adaptés.';
    });
  }

  void _reset() {
    setState(() {
      _answers.clear();
      _step = 0;
      _recommended = [];
      _rationale = null;
      _whyByCarId = {};
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pad = Responsive.pagePadding(context);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: appScreenBar(
        context,
        title: 'Trouver ma voiture',
        subtitle: GroqConfig.isConfigured
            ? 'Questions rapides · IA Groq'
            : 'Questions rapides · clé Groq requise',
      ),
      body: ContentContainer(
        child: ListView(
          padding: EdgeInsets.fromLTRB(pad.left, 16, pad.right, 120),
          children: [
            if (!_done && !_loading) ...[
              LinearProgressIndicator(
                value: (_step + 1) / _questions.length,
                minHeight: 6,
                borderRadius: BorderRadius.circular(100),
                backgroundColor: AppColors.border,
                color: AppColors.accent,
              ),
              const SizedBox(height: 8),
              Text(
                'Question ${_step + 1} / ${_questions.length}',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 18),
              _QuestionCard(
                question: _questions[_step],
                selectedId: _answers[_questions[_step].id],
                onSelect: (optId) {
                  setState(() {
                    _answers[_questions[_step].id] = optId;
                  });
                },
              ),
            ],
            if (_loading) ...[
              const SizedBox(height: 48),
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  'L\'IA analyse vos réponses…',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ],
            if (_done && !_loading) ...[
              NoticeBox(
                icon: Icons.auto_awesome_rounded,
                color: AppColors.accent,
                title: 'Réponse IA Groq',
                message: _rationale ?? '',
              ),
              const SizedBox(height: 16),
              Text(
                _recommended.isEmpty
                    ? 'Aucune suggestion'
                    : '${_recommended.length} véhicule'
                        '${_recommended.length > 1 ? 's' : ''} recommandé'
                        '${_recommended.length > 1 ? 's' : ''}',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              if (_recommended.isEmpty)
                const EmptyState(
                  icon: Icons.search_off_rounded,
                  title: 'Pas de match',
                  message:
                      'Ajoutez des voitures disponibles ou reformulez '
                      'vos réponses.',
                )
              else
                for (final car in _recommended)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        CarCard(
                          car: car,
                          onTap: () => context.push(Routes.car(car.id)),
                        ),
                        if ((_whyByCarId[car.id] ?? '').isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusMd,
                              ),
                              border: Border.all(
                                color: AppColors.accent.withValues(alpha: 0.25),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.auto_awesome_rounded,
                                  size: 18,
                                  color: AppColors.accent,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _whyByCarId[car.id]!,
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      height: 1.35,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
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
            ],
          ],
        ),
      ),
      bottomNavigationBar: BottomActionBar(
        child: Row(
          children: [
            if (_done && !_loading)
              Expanded(
                child: OutlinedButton(
                  onPressed: _reset,
                  child: const Text('Recommencer'),
                ),
              )
            else ...[
              if (_step > 0)
                OutlinedButton(
                  onPressed: _loading
                      ? null
                      : () => setState(() => _step--),
                  child: const Text('Retour'),
                ),
              if (_step > 0) const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: _loading
                      ? null
                      : () {
                          final q = _questions[_step];
                          if (!_answers.containsKey(q.id)) {
                            AppSnack.info(
                              context,
                              'Choisissez une réponse.',
                            );
                            return;
                          }
                          if (_step < _questions.length - 1) {
                            setState(() => _step++);
                          } else {
                            _submit();
                          }
                        },
                  child: Text(
                    _step < _questions.length - 1
                        ? 'Suivant'
                        : 'Voir mes voitures',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.question,
    required this.selectedId,
    required this.onSelect,
  });

  final RecommendQuestion question;
  final String? selectedId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Cochez une seule réponse',
            style: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
          ),
          const SizedBox(height: 14),
          for (final opt in question.options) ...[
            Material(
              color: selectedId == opt.id
                  ? AppColors.accent.withValues(alpha: 0.1)
                  : AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              child: InkWell(
                onTap: () => onSelect(opt.id),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(
                      color: selectedId == opt.id
                          ? AppColors.accent
                          : AppColors.border,
                      width: selectedId == opt.id ? 1.6 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        selectedId == opt.id
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_off_rounded,
                        color: selectedId == opt.id
                            ? AppColors.accent
                            : AppColors.textMuted,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          opt.label,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: selectedId == opt.id
                                ? FontWeight.w700
                                : FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
