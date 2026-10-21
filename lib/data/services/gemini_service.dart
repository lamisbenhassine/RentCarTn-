import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/gemini_config.dart';
import '../models/exam.dart';
import '../models/learning.dart';

/// Résultat texte simple (test de connexion).
class GeminiResult {
  const GeminiResult.ok(this.message) : ok = true;
  const GeminiResult.fail(this.message) : ok = false;

  final bool ok;
  final String message;
}

/// Résultat de génération de questions d'examen.
class GeminiExamResult {
  const GeminiExamResult.ok({
    required this.title,
    required this.description,
    required this.questions,
  }) : ok = true,
       message = null;

  const GeminiExamResult.fail(this.message)
      : ok = false,
        title = null,
        description = null,
        questions = const [];

  final bool ok;
  final String? message;
  final String? title;
  final String? description;
  final List<ExamQuestion> questions;
}

/// Client Google Gemini — connexion + génération de quiz / examens.
class GeminiService {
  GeminiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// Vérifie que la clé API fonctionne.
  Future<GeminiResult> testConnection() async {
    if (!GeminiConfig.isConfigured) {
      return const GeminiResult.fail(
        'Clé API manquante. Colle ta clé dans '
        'lib/core/config/gemini_secrets.dart',
      );
    }

    try {
      final response = await _post(
        prompt:
            'Réponds uniquement par le mot OK. Ceci est un test de connexion.',
        maxOutputTokens: 32,
        temperature: 0,
        jsonMode: false,
      );

      if (!response.ok) return GeminiResult.fail(response.error!);

      final text = response.text.trim();
      return GeminiResult.ok(
        text.isEmpty
            ? 'Connexion Gemini réussie.'
            : 'Connexion Gemini réussie : $text',
      );
    } on Exception catch (e) {
      return GeminiResult.fail('Impossible de joindre Gemini : $e');
    }
  }

  /// Génère un examen QCM à partir des panneaux + règles pédagogiques.
  Future<GeminiExamResult> generateExam({
    required List<RoadSign> signs,
    required List<RuleSection> rules,
    int questionCount = 8,
  }) async {
    if (!GeminiConfig.isConfigured) {
      return const GeminiExamResult.fail(
        'Clé API manquante. Configure gemini_secrets.dart.',
      );
    }
    if (signs.isEmpty && rules.isEmpty) {
      return const GeminiExamResult.fail(
        'Aucun contenu pédagogique (panneaux / règles) pour générer.',
      );
    }

    final prompt = _buildExamPrompt(
      signs: signs,
      rules: rules,
      questionCount: questionCount,
    );

    try {
      final response = await _post(
        prompt: prompt,
        maxOutputTokens: 8192,
        temperature: 0.4,
        jsonMode: true,
      );

      if (!response.ok) {
        return GeminiExamResult.fail(response.error!);
      }

      final parsed = _parseExamJson(response.text);
      if (parsed == null || parsed.questions.isEmpty) {
        return const GeminiExamResult.fail(
          'Réponse Gemini illisible. Réessaie la génération.',
        );
      }
      return parsed;
    } on Exception catch (e) {
      return GeminiExamResult.fail('Génération impossible : $e');
    }
  }

  String _buildExamPrompt({
    required List<RoadSign> signs,
    required List<RuleSection> rules,
    required int questionCount,
  }) {
    final signsBlock = signs
        .take(25)
        .map(
          (s) =>
              '- [${s.category.shortLabel}] ${s.name} : ${s.meaning} '
              '(conseil : ${s.advice})',
        )
        .join('\n');

    final rulesBlock = rules
        .take(12)
        .map(
          (r) =>
              '- ${r.title} : ${r.summary}\n'
              '  Points : ${r.points.take(4).join(' | ')}',
        )
        .join('\n');

    return '''
Tu es un expert du Code de la route tunisien pour une application pédagogique.
Génère EXACTEMENT $questionCount questions QCM en français, basées UNIQUEMENT
sur le contenu fourni ci-dessous (panneaux et règles).

CONTRAINTES :
- Chaque question a exactement 4 options.
- Une seule bonne réponse (correctIndex de 0 à 3).
- Ajoute une courte explication pédagogique.
- Contenu réaliste pour la Tunisie, sans inventer de lois absurdes.
- Marque mentalement que c'est un contenu de démo à vérifier officiellement.
- Réponds UNIQUEMENT avec un JSON valide, sans markdown, sans texte autour.

FORMAT JSON STRICT :
{
  "title": "titre court de l'examen",
  "description": "description courte",
  "questions": [
    {
      "question": "énoncé",
      "options": ["A", "B", "C", "D"],
      "correctIndex": 0,
      "explanation": "pourquoi"
    }
  ]
}

=== PANNEAUX ===
$signsBlock

=== RÈGLES ===
$rulesBlock
''';
  }

  Future<({bool ok, String text, String? error})> _post({
    required String prompt,
    required int maxOutputTokens,
    required double temperature,
    bool jsonMode = false,
  }) async {
    // Essaye plusieurs modèles : 503 = serveur saturé, 404 = modèle retiré.
    final models = <String>{
      GeminiConfig.model,
      ...GeminiConfig.fallbackModels,
    }.toList();

    String? lastError;

    for (final modelName in models) {
      final uri = Uri.parse(
        '${GeminiConfig.endpointFor(modelName)}?key=${GeminiConfig.apiKey}',
      );

      final generationConfig = <String, Object?>{
        'temperature': temperature,
        'maxOutputTokens': maxOutputTokens,
      };
      if (jsonMode) {
        generationConfig['responseMimeType'] = 'application/json';
      }

      final response = await _client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'contents': [
                {
                  'parts': [
                    {'text': prompt},
                  ],
                },
              ],
              'generationConfig': generationConfig,
            }),
          )
          .timeout(GeminiConfig.timeout);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        return (ok: true, text: _extractText(body), error: null);
      }

      if (response.statusCode == 503 || response.statusCode == 404) {
        lastError =
            'Modèle $modelName indisponible (${response.statusCode}), '
            'essai du suivant…';
        continue;
      }

      if (response.statusCode == 400) {
        return (
          ok: false,
          text: '',
          error: 'Requête invalide — vérifie le modèle ou la clé API.',
        );
      }
      if (response.statusCode == 403) {
        return (
          ok: false,
          text: '',
          error: 'Clé API refusée (403). Vérifie la clé sur AI Studio.',
        );
      }
      if (response.statusCode == 429) {
        return (
          ok: false,
          text: '',
          error: 'Quota Gemini dépassé (429). Réessaie plus tard.',
        );
      }

      return (
        ok: false,
        text: '',
        error: 'Erreur Gemini HTTP ${response.statusCode}.',
      );
    }

    return (
      ok: false,
      text: '',
      error: lastError ??
          'Gemini surchargé (503). Tous les modèles sont indisponibles — '
              'réessaie dans 1–2 minutes.',
    );
  }

  GeminiExamResult? _parseExamJson(String raw) {
    var text = raw.trim();
    if (text.isEmpty) return null;

    // Au cas où le modèle renvoie encore des fences markdown.
    if (text.startsWith('```')) {
      text = text
          .replaceFirst(RegExp(r'^```(?:json)?\s*', multiLine: true), '')
          .replaceFirst(RegExp(r'\s*```$'), '')
          .trim();
    }

    // Extraire le premier objet JSON si du texte parasite est présent.
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start == -1 || end == -1 || end <= start) return null;
    text = text.substring(start, end + 1);

    try {
      final map = jsonDecode(text) as Map<String, dynamic>;
      final title = (map['title'] as String?)?.trim() ?? 'Examen généré (IA)';
      final description =
          (map['description'] as String?)?.trim() ??
          'Questions générées automatiquement à partir des panneaux et règles.';

      final rawQuestions = map['questions'] as List<dynamic>? ?? [];
      final questions = <ExamQuestion>[];
      for (var i = 0; i < rawQuestions.length; i++) {
        final q = Map<String, dynamic>.from(rawQuestions[i] as Map);
        final options = (q['options'] as List<dynamic>? ?? [])
            .map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList();
        if (options.length < 2) continue;

        var correct = (q['correctIndex'] as num?)?.toInt() ?? 0;
        if (correct < 0 || correct >= options.length) correct = 0;

        final questionText = (q['question'] as String?)?.trim() ?? '';
        if (questionText.isEmpty) continue;

        questions.add(
          ExamQuestion(
            id: 'ai-${DateTime.now().microsecondsSinceEpoch}-$i',
            question: questionText,
            options: options.take(4).toList(),
            correctIndex: correct,
            explanation: (q['explanation'] as String?)?.trim() ?? '',
            sortOrder: i,
          ),
        );
      }

      if (questions.isEmpty) return null;
      return GeminiExamResult.ok(
        title: title,
        description: description,
        questions: questions,
      );
    } catch (_) {
      return null;
    }
  }

  static String _extractText(Map<String, dynamic> body) {
    try {
      final candidates = body['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) return '';
      final content = candidates.first['content'] as Map<String, dynamic>?;
      final parts = content?['parts'] as List<dynamic>?;
      if (parts == null || parts.isEmpty) return '';

      // Certains modèles renvoient plusieurs parts (thinking + texte).
      final buffer = StringBuffer();
      for (final part in parts) {
        final text = (part as Map<String, dynamic>)['text'] as String?;
        if (text != null && text.trim().isNotEmpty) {
          buffer.write(text);
        }
      }
      return buffer.toString().trim();
    } catch (_) {
      return '';
    }
  }

  void dispose() => _client.close();
}
