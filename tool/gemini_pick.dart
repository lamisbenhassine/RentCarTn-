import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:rentcar_tunisia/core/config/gemini_secrets.dart';

Future<void> main() async {
  final key = GeminiSecrets.apiKey;
  for (final m in ['gemini-3.5-flash', 'gemini-3.6-flash', 'gemini-3.7-flash', 'gemini-3.1-flash-lite', 'gemini-3-flash-preview']) {
    final res = await http.post(
      Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/$m:generateContent?key=$key'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [{'parts': [{'text': 'Reply OK only'}]}],
        'generationConfig': {'maxOutputTokens': 32},
      }),
    );
    print('$m -> ${res.statusCode}');
  }
}
