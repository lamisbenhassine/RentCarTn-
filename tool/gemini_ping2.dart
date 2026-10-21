import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:rentcar_tunisia/core/config/gemini_config.dart';

Future<void> main() async {
  print('model=${GeminiConfig.model}');
  print('configured=${GeminiConfig.isConfigured}');
  final uri = Uri.parse('${GeminiConfig.endpoint}?key=${GeminiConfig.apiKey}');
  print('url=${uri.toString().replaceAll(GeminiConfig.apiKey, "***")}');
  final res = await http.post(
    uri,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'contents': [
        {'parts': [{'text': 'Reply with only the word OK'}]}
      ],
      'generationConfig': {'temperature': 0, 'maxOutputTokens': 64},
    }),
  );
  print('status=${res.statusCode}');
  print(res.body);
}
