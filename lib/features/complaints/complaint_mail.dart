import 'package:flutter/foundation.dart';

import '../../data/models/complaint.dart';
import '../../data/models/user_profile.dart';
import '../../data/services/email_service.dart';
import '../../data/services/otp_service.dart';

/// Résultat d'un e-mail de suivi de réclamation.
enum ComplaintMailResult { sent, failed, skipped }

final _emailService = EmailService();

/// E-mail de suivi (création, puis Résolue / Rejetée), modèle EmailJS n° 2.
///
/// Ne lance jamais d'exception : un échec n'annule rien (la réclamation
/// reste enregistrée), il est seulement signalé par un debugPrint.
/// `skipped` : modèle non configuré ou utilisateur sans e-mail.
Future<ComplaintMailResult> sendComplaintMail(
  Complaint complaint,
  UserProfile? user,
) async {
  final email = user?.email.trim() ?? '';
  if (email.isEmpty || !EmailService.complaintTemplateConfigured) {
    debugPrint(
      '[ComplaintMail] Non envoyé ${complaint.reference} : '
      '${email.isEmpty ? 'e-mail inconnu' : 'Template ID manquant'}',
    );
    return ComplaintMailResult.skipped;
  }
  try {
    await _emailService.sendComplaintConfirmation(
      email: email,
      name: user!.fullName,
      reference: complaint.reference,
      title: complaint.title,
      status: complaint.status.label, // libellé français (comme l'historique)
    );
    debugPrint(
      '[ComplaintMail] ${complaint.reference} (${complaint.status.name}) '
      '→ ${OtpService.maskEmail(email)}',
    );
    return ComplaintMailResult.sent;
  } catch (e) {
    debugPrint('[ComplaintMail] Échec ${complaint.reference} : $e');
    return ComplaintMailResult.failed;
  }
}

/// t***@gmail.com
String maskedComplaintEmail(UserProfile? user) =>
    OtpService.maskEmail(user?.email ?? '');
