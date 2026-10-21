import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:rentcar_tunisia/core/config/gemini_secrets.dart';

Future<void> main() async {
  final key = GeminiSecrets.apiKey;
  print('Key prefix: ${key.substring(0, 6)}... len=${key.length}');

  // List models
  final listUri = Uri.parse(
    'https://generativelanguage.googleapis.com/v1beta/models?key=$key',
  );
  final listRes = await http.get(listUri);
  print('LIST ${listRes.statusCode}');
  print(listRes.body.substring(0, listRes.body.length.clamp(0, 800)));

  final models = ['gemini-2.0-flash', 'gemini-2.0-flash-001', 'gemini-1.5-flash', 'gemini-1.5-flash-latest', 'gemini-flash-latest'];
  for (final m in models) {
    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$m:generateContent?key=$key',
    );
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {'parts': [{'text': 'Say OK'}]}
        ],
      }),
    );
    print('$m -> ${res.statusCode} ${res.body.substring(0, res.body.length.clamp(0, 200))}');
  }
}
