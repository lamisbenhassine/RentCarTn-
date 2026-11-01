import 'gemini_secrets.dart';

/// Configuration Google Gemini (quiz / examens, module Réclamations).
abstract final class GeminiConfig {
  /// Modèle principal (vérifié le 01/11/2026 : disponible, JSON en ~4 s).
  static const String model = 'gemini-3.6-flash';

  /// Secours si 429 (quota du jour : chaque modèle a le sien), 404 (modèle
  /// retiré), 503 (surcharge) ou délai dépassé. Vérifié le 01/11/2026 :
  /// `gemini-2.5-flash` et `gemini-2.5-flash-lite` renvoient désormais 404.
  /// Les « flash-lite » répondent en ~1 s avec le même JSON.
  static const List<String> fallbackModels = [
    'gemini-3.5-flash',
    'gemini-3.5-flash-lite',
    'gemini-3.1-flash-lite',
  ];

  /// Ordre d'essai complet (sans doublon).
  static List<String> get allModels => {model, ...fallbackModels}.toList();

  /// API REST v1beta. La clé est envoyée dans le header `x-goog-api-key`
  /// (voir GeminiService._post), pas dans l'URL.
  static String endpointFor(String modelName) =>
      'https://generativelanguage.googleapis.com/v1beta/models/'
      '$modelName:generateContent';

  /// Équipe (scripts tool/) : endpoint du modèle principal.
  static String get endpoint => endpointFor(model);

  /// Clé lue depuis [GeminiSecrets] (fichier local non versionné).
  static String get apiKey => GeminiSecrets.apiKey.trim();

  /// `true` si une vraie clé a été collée. Aucun préfixe n'est imposé :
  /// les clés AI Studio peuvent commencer par « AIza » (anciennes) ou
  /// « AQ. » (nouvelles) ; seul le placeholder est refusé.
  static bool get isConfigured {
    final key = apiKey;
    if (key.isEmpty) return false;
    if (key == 'COLLE_TA_CLE_ICI') return false;
    if (key.startsWith('YOUR_')) return false;
    return key.length > 20;
  }

  /// Génération d'examens (réponse longue) : délai par modèle.
  static const Duration timeout = Duration(seconds: 60);

  /// Réclamations et test de connexion : délai court par modèle, le
  /// formulaire ne doit jamais attendre longtemps.
  static const Duration quickTimeout = Duration(seconds: 15);
}
