import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/config/gemini_config.dart';
import '../../core/theme/app_colors.dart';
import '../../data/services/complaint_ai.dart';
import '../../data/services/gemini_service.dart';
import '../../l10n/l10n.dart';
import 'complaint_l10n.dart';

/// Outil développeur (mode debug uniquement) : appui long sur le titre de
/// « Mes réclamations ». Teste la clé Gemini puis l'analyse d'une phrase.
/// Textes non traduits volontairement : jamais visible en release.
Future<void> showGeminiDebugSheet(BuildContext context) async {
  if (!kDebugMode) return;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const _GeminiDebugSheet(),
  );
}

class _GeminiDebugSheet extends StatefulWidget {
  const _GeminiDebugSheet();

  @override
  State<_GeminiDebugSheet> createState() => _GeminiDebugSheetState();
}

class _GeminiDebugSheetState extends State<_GeminiDebugSheet> {
  static const _sample =
      "La voiture s'est arrêtée sur l'autoroute, je suis bloqué, "
      "c'est inadmissible !";

  final _gemini = GeminiService();
  bool _running = false;
  GeminiResult? _connection;
  ComplaintAiAnalysis? _analysis;
  bool _analysisDone = false;
  Duration? _elapsed;

  @override
  void initState() {
    super.initState();
    _run();
  }

  @override
  void dispose() {
    _gemini.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    setState(() {
      _running = true;
      _connection = null;
      _analysis = null;
      _analysisDone = false;
      _elapsed = null;
    });
    final watch = Stopwatch()..start();
    final connection = await _gemini.testConnection();
    if (!mounted) return;
    setState(() => _connection = connection);
    debugPrint('[Gemini] Test connexion : ${connection.message}');

    if (connection.ok) {
      final analysis = await _gemini.analyzeComplaint(
        title: 'Panne sur l\'autoroute',
        description: _sample,
      );
      if (!mounted) return;
      debugPrint(
        '[Gemini] Test analyse : ${analysis == null ? 'échec' : '${analysis.category.name} / ${analysis.suggestedPriority.name} / ${analysis.tone.name}'}',
      );
      setState(() {
        _analysis = analysis;
        _analysisDone = true;
      });
    }
    watch.stop();
    if (mounted) {
      setState(() {
        _running = false;
        _elapsed = watch.elapsed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final key = GeminiConfig.apiKey;
    final maskedKey = key.length > 8
        ? '${key.substring(0, 5)}…${key.substring(key.length - 4)}'
        : '(vide)';

    Widget line(IconData icon, Color color, String text) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );

    final connection = _connection;
    final analysis = _analysis;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Test Gemini (debug)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            line(
              Icons.key_rounded,
              GeminiConfig.isConfigured ? AppColors.success : AppColors.danger,
              'Clé : $maskedKey '
              '(${GeminiConfig.isConfigured ? 'configurée' : 'manquante'})',
            ),
            line(
              Icons.memory_rounded,
              AppColors.info,
              'Modèle : ${GeminiConfig.model} '
              '(secours : ${GeminiConfig.fallbackModels.join(', ')})',
            ),
            if (connection == null)
              line(Icons.sync_rounded, AppColors.info, 'Connexion en cours…')
            else
              line(
                connection.ok
                    ? Icons.check_circle_rounded
                    : Icons.error_rounded,
                connection.ok ? AppColors.success : AppColors.danger,
                connection.message,
              ),
            if (connection?.ok == true) ...[
              if (!_analysisDone)
                line(
                  Icons.sync_rounded,
                  AppColors.info,
                  'Analyse de : « $_sample »…',
                )
              else if (analysis == null)
                line(
                  Icons.error_rounded,
                  AppColors.danger,
                  'Analyse impossible : voir les logs [Gemini].',
                )
              else
                line(
                  Icons.auto_awesome_rounded,
                  AppColors.success,
                  'Catégorie : ${l.complaintCategory(analysis.category)}\n'
                  'Priorité : ${l.complaintPriority(analysis.suggestedPriority)}'
                  '${analysis.priorityRaised ? ' (relevée : très mécontent)' : ''}\n'
                  'Ton : ${l.complaintTone(analysis.tone)}\n'
                  'Résumé : ${analysis.summary}',
                ),
            ],
            if (_elapsed != null)
              Text(
                'Durée : ${(_elapsed!.inMilliseconds / 1000).toStringAsFixed(1)} s',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _running ? null : _run,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Relancer le test'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
