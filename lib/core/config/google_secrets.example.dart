/// Modèle à copier → `google_secrets.dart`
///
/// 1. Copie ce fichier :
///    google_secrets.example.dart  →  google_secrets.dart
/// 2. Colle le Client ID du client OAuth **Web** (Google Cloud Console).
/// 3. Ne committe JAMAIS `google_secrets.dart` (déjà dans .gitignore).
class GoogleSecrets {
  GoogleSecrets._();

  static const String webClientId = 'COLLE_TON_WEB_CLIENT_ID';
}
