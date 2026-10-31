/// Modèle à copier → `groq_secrets.dart`
///
/// 1. Copie ce fichier :
///    groq_secrets.example.dart  →  groq_secrets.dart
/// 2. Colle ta clé API Groq entre les guillemets (commence souvent par gsk_).
/// 3. Ne committe JAMAIS `groq_secrets.dart` (déjà dans .gitignore).
///
/// Clé : https://console.groq.com/keys
class GroqSecrets {
  GroqSecrets._();

  /// Clé obtenue sur https://console.groq.com/keys
  static const String apiKey = 'COLLE_TA_CLE_GROQ_ICI';
}
