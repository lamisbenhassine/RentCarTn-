import 'groq_secrets.dart';

/// Configuration Groq (recommandation de véhicules).
abstract final class GroqConfig {
  static const String endpoint =
      'https://api.groq.com/openai/v1/chat/completions';

  /// Modèles actuels (Llama 3.x retiré du free tier Groq depuis août 2026).
  /// Docs : https://console.groq.com/docs/models
  static const String model = 'openai/gpt-oss-20b';

  static const List<String> fallbackModels = [
    'openai/gpt-oss-20b',
    'openai/gpt-oss-120b',
  ];

  static String get apiKey => GroqSecrets.apiKey.trim();

  static bool get isConfigured {
    final key = apiKey;
    if (key.isEmpty) return false;
    if (key == 'COLLE_TA_CLE_GROQ_ICI') return false;
    if (key.startsWith('YOUR_')) return false;
    return key.length > 20;
  }

  static const Duration timeout = Duration(seconds: 45);
}
