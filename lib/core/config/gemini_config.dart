import 'gemini_secrets.dart';

/// Configuration Google Gemini (génération de quiz / examens).
abstract final class GeminiConfig {
  /// Modèle principal.
  static const String model = 'gemini-3.6-flash';

  /// Modèles de secours si 503 / 404 (surcharge ou modèle indisponible).
  static const List<String> fallbackModels = [
    'gemini-3.6-flash',
    'gemini-3.5-flash',
    'gemini-3-flash-preview',
    'gemini-flash-latest',
  ];

  static String endpointFor(String modelName) =>
      'https://generativelanguage.googleapis.com/v1beta/models/'
      '$modelName:generateContent';

  /// Clé lue depuis [GeminiSecrets] (fichier local non versionné).
  static String get apiKey => GeminiSecrets.apiKey.trim();

  /// `true` si une clé non vide a été collée (pas le placeholder).
  static bool get isConfigured {
    final key = apiKey;
    if (key.isEmpty) return false;
    if (key == 'COLLE_TA_CLE_ICI') return false;
    if (key.startsWith('YOUR_')) return false;
    return key.length > 20;
  }

  /// Timeout réseau pour les appels IA (génération peut être longue).
  static const Duration timeout = Duration(seconds: 90);
}
