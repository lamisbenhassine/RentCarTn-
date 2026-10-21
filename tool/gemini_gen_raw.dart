import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:rentcar_tunisia/core/config/gemini_config.dart';

Future<void> main() async {
  final prompt = '''
Tu es un expert du Code de la route tunisien.
Génère EXACTEMENT 2 questions QCM en français.
Réponds UNIQUEMENT avec un JSON valide:
{"title":"...","description":"...","questions":[{"question":"...","options":["A","B","C","D"],"correctIndex":0,"explanation":"..."}]}

Contenu: panneau virage dangereux à droite; limitation 50 km/h en agglomération; priorité à droite.
''';
  final uri = Uri.parse('${GeminiConfig.endpoint}?key=${GeminiConfig.apiKey}');
  final res = await http.post(
    uri,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'contents': [{'parts': [{'text': prompt}]}],
      'generationConfig': {
        'temperature': 0.4,
        'maxOutputTokens': 2048,
        'responseMimeType': 'application/json',
      },
    }),
  ).timeout(GeminiConfig.timeout);
  print('status=${res.statusCode}');
  if (res.statusCode != 200) {
    print(res.body.substring(0, res.body.length.clamp(0, 500)));
    return;
  }
  final body = jsonDecode(res.body) as Map<String, dynamic>;
  final parts = body['candidates'][0]['content']['parts'] as List;
  final text = parts.map((p) => p['text'] ?? '').join();
  print(text.substring(0, text.length.clamp(0, 1000)));
  final map = jsonDecode(text) as Map<String, dynamic>;
  print('title=${map['title']} count=${(map['questions'] as List).length}');
}
