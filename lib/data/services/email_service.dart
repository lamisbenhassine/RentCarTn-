import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/emailjs_secrets.dart';

/// Échec d'envoi d'e-mail (réseau, délai dépassé, refus EmailJS).
class EmailSendException implements Exception {
  const EmailSendException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => statusCode == null
      ? 'EmailSendException: $message'
      : 'EmailSendException($statusCode): $message';
}

/// Envoi d'e-mails via l'API REST EmailJS.
///
/// - Modèle OTP : variables {{email}} (destinataire) et {{code}}.
/// - Modèle n° 2 « générique » (réclamations ET compte) : {{email}},
///   {{subject}}, {{name}}, {{intro}}, {{message}} ; {{reference}},
///   {{title}}, {{status}} restent envoyés (anciens modèles réclamation).
class EmailService {
  EmailService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static final Uri _endpoint = Uri.parse(
    'https://api.emailjs.com/api/v1.0/email/send',
  );
  static const Duration _timeout = Duration(seconds: 15);

  /// Le Template ID du modèle « réclamation » a été renseigné dans
  /// emailjs_secrets.dart (sinon : aucun envoi, sans erreur).
  static bool get complaintTemplateConfigured {
    final id = EmailJsSecrets.complaintTemplateId.trim();
    return id.isNotEmpty && !id.startsWith('COLLE_') && !id.contains('XXXX');
  }

  /// Envoie le code OTP à [email]. Lance [EmailSendException] si le
  /// serveur ne répond pas 200 ou si le délai de 15 s est dépassé.
  Future<void> sendOtp(String email, String code) => _send(
    templateId: EmailJsSecrets.templateId,
    params: {'email': email.trim(), 'code': code},
  );

  /// Suivi de réclamation (création, puis chaque action de l'admin).
  /// [message] : réponse de l'agence. Lance [EmailSendException] en cas
  /// d'échec.
  Future<void> sendComplaintConfirmation({
    required String email,
    required String name,
    required String reference,
    required String title,
    required String status,
    String message = '',
  }) async {
    await sendNotice(
      email: email,
      name: name,
      subject: 'Réclamation $reference : $status',
      intro:
          'Votre réclamation « $title » ($reference) est maintenant : $status.',
      message: message,
      reference: reference,
      title: title,
      status: status,
    );
  }

  /// Message générique sur le modèle n° 2 (bannissement, réactivation…).
  /// Lance [EmailSendException] en cas d'échec ou si le modèle manque.
  Future<void> sendNotice({
    required String email,
    required String name,
    required String subject,
    required String intro,
    String message = '',
    String reference = '',
    String title = '',
    String status = '',
  }) async {
    if (!complaintTemplateConfigured) {
      throw const EmailSendException(
        'Template ID n° 2 manquant dans emailjs_secrets.dart',
      );
    }
    await _send(
      templateId: EmailJsSecrets.complaintTemplateId,
      params: {
        'email': email.trim(),
        'name': name.trim(),
        'subject': subject,
        'intro': intro,
        'message': message,
        'reference': reference,
        'title': title.isEmpty ? subject : title,
        'status': status,
      },
    );
  }

  Future<void> _send({
    required String templateId,
    required Map<String, String> params,
  }) async {
    final body = jsonEncode({
      'service_id': EmailJsSecrets.serviceId,
      'template_id': templateId,
      'user_id': EmailJsSecrets.publicKey,
      'template_params': params,
    });

    final http.Response response;
    try {
      response = await _client
          .post(
            _endpoint,
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(_timeout);
    } on TimeoutException {
      throw const EmailSendException('Délai de 15 s dépassé.');
    } catch (e) {
      throw EmailSendException('Erreur réseau : $e');
    }

    if (response.statusCode != 200) {
      // EmailJS renvoie un texte explicatif (ex. clé invalide, quota).
      throw EmailSendException(
        response.body.isEmpty ? 'Réponse vide' : response.body,
        statusCode: response.statusCode,
      );
    }
  }
}
