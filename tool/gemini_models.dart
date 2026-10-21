import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:rentcar_tunisia/core/config/gemini_secrets.dart';

Future<void> main() async {
  final key = GeminiSecrets.apiKey;
  final listRes = await http.get(Uri.parse(
    'https://generativelanguage.googleapis.com/v1beta/models?key=$key',
  ));
  final models = (jsonDecode(listRes.body)['models'] as List)
      .map((m) => m['name'] as String)
      .where((n) => n.contains('flash') || n.contains('pro'))
      .toList();
  print('Available flash/pro models:');
  for (final m in models) print(' - $m');

  final tryModels = [
    'gemini-3.8-flash',
    'gemini-3-flash-preview',
    'gemini-2.5-flash',
    'gemini-flash-latest',
  ];
  for (final m in tryModels) {
    final res = await http.post(
      Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/$m:generateContent?key=$key'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [{'parts': [{'text': 'Reply OK only'}]}],
        'generationConfig': {'maxOutputTokens': 32},
      }),
    );
    final short = res.body.length > 180 ? res.body.substring(0, 180) : res.body;
    print('$m -> ${res.statusCode} $short');
  }
}
