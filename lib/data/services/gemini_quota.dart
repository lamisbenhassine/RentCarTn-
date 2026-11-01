import 'package:flutter/foundation.dart';

/// Modèles Gemini dont le quota du jour est épuisé (HTTP 429), mémorisés
/// en mémoire pour ne plus les appeler inutilement.
///
/// Remis à zéro au redémarrage de l'app ou au changement de date. (Google
/// remet les quotas gratuits à zéro vers minuit heure du Pacifique : si un
/// modèle répond encore 429 après minuit en Tunisie, il est simplement
/// re-marqué après un seul appel.)
class GeminiQuota {
  GeminiQuota({DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  /// Partagé par toutes les instances de GeminiService.
  static final GeminiQuota instance = GeminiQuota();

  final DateTime Function() _clock;
  final Set<String> _exhausted = {};
  String _day = '';

  String _today() {
    final d = _clock();
    return '${d.year}-${d.month}-${d.day}';
  }

  /// Nouvelle journée : tous les modèles redeviennent disponibles.
  void _rollDay() {
    final today = _today();
    if (today != _day) {
      if (_exhausted.isNotEmpty) {
        debugPrint('[Gemini] Nouvelle journée : quotas réinitialisés');
      }
      _exhausted.clear();
      _day = today;
    }
  }

  void markExhausted(String model) {
    _rollDay();
    if (_exhausted.add(model)) {
      debugPrint(
        '[Gemini] Quota du jour atteint pour $model : ignoré '
        "jusqu'à demain",
      );
    }
  }

  bool isExhausted(String model) {
    _rollDay();
    return _exhausted.contains(model);
  }

  /// [models] sans ceux épuisés aujourd'hui (ordre conservé).
  List<String> available(List<String> models) => [
    for (final m in models)
      if (!isExhausted(m)) m,
  ];

  /// Tous les modèles ont atteint leur quota : l'app continue sans IA.
  bool allExhausted(List<String> models) =>
      models.isNotEmpty && available(models).isEmpty;

  @visibleForTesting
  void reset() => _exhausted.clear();
}
