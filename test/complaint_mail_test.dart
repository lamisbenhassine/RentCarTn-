import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rentcar_tunisia/data/services/email_service.dart';

void main() {
  test('sendComplaintConfirmation : variables du 2e modèle', () async {
    Map<String, dynamic>? sent;
    final service = EmailService(
      client: MockClient((req) async {
        sent = jsonDecode(req.body) as Map<String, dynamic>;
        return http.Response('OK', 200);
      }),
    );
    if (!EmailService.complaintTemplateConfigured) {
      await expectLater(
        service.sendComplaintConfirmation(
          email: 'a@b.tn',
          name: 'A',
          reference: 'REC-2026-0001',
          title: 'T',
          status: 'En attente',
        ),
        throwsA(isA<EmailSendException>()),
      );
      expect(sent, isNull); // rien n'est envoyé sans Template ID
      return;
    }
    await service.sendComplaintConfirmation(
      email: ' test@gmail.com ',
      name: 'Hamza T',
      reference: 'REC-2026-0001',
      title: 'Clim en panne',
      status: 'Résolue',
    );
    expect(sent!['template_params'], {
      'email': 'test@gmail.com',
      'name': 'Hamza T',
      'reference': 'REC-2026-0001',
      'title': 'Clim en panne',
      'status': 'Résolue',
    });
  });

  test('échec EmailJS → EmailSendException', () async {
    final service = EmailService(
      client: MockClient((_) async => http.Response('Bad key', 400)),
    );
    await expectLater(
      service.sendOtp('a@b.tn', '123456'),
      throwsA(isA<EmailSendException>()),
    );
  });
}
