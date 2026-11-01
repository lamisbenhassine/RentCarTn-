/// Modèle à copier → `emailjs_secrets.dart`
///
/// 1. Copie ce fichier :
///    emailjs_secrets.example.dart  →  emailjs_secrets.dart
/// 2. Colle tes identifiants EmailJS (https://dashboard.emailjs.com).
/// 3. Ne committe JAMAIS `emailjs_secrets.dart` (déjà dans .gitignore).
class EmailJsSecrets {
  EmailJsSecrets._();

  static const String serviceId = 'service_XXXXXXX';
  static const String templateId = 'template_XXXXXXX';

  /// 2e modèle : confirmation / suivi de réclamation.
  /// Variables : {{email}}, {{name}}, {{reference}}, {{title}}, {{status}}.
  static const String complaintTemplateId = 'COLLE_TON_TEMPLATE_ID';
  static const String publicKey = 'COLLE_TA_CLE_ICI';
}
