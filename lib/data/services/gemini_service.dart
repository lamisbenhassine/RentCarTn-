import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../core/config/gemini_config.dart';
import '../models/exam.dart';
import '../models/complaint.dart';
import '../models/learning.dart';
import 'complaint_ai.dart';
import 'gemini_quota.dart';

/// Résultat texte simple (test de connexion).
class GeminiResult {
  const GeminiResult.ok(this.message) : ok = true;
  const GeminiResult.fail(this.message) : ok = false;

  final bool ok;
  final String message;
}

/// Réponse de l'Assistant RentCar.
enum GeminiChatStatus {
  ok,
  offline,
  unavailable,

  /// Quota gratuit du jour atteint sur tous les modèles.
  quotaExceeded,
}

/// Appel de fonction demandé par Gemini (function calling).
class GeminiFunctionCall {
  const GeminiFunctionCall({required this.name, this.args = const {}, this.id});

  final String name;
  final Map<String, Object?> args;

  /// À renvoyer dans le functionResponse correspondant.
  final String? id;
}

/// Un tour de réponse du modèle : texte et/ou appels de fonctions.
class GeminiTurn {
  const GeminiTurn._({
    required this.status,
    this.text = '',
    this.calls = const [],
    this.modelContent,
  });

  const GeminiTurn.failed(this.status)
    : text = '',
      calls = const [],
      modelContent = null;

  final GeminiChatStatus status;
  final String text;
  final List<GeminiFunctionCall> calls;

  /// Contenu brut du modèle (avec les thoughtSignature des modèles
  /// Gemini 3) : à renvoyer TEL QUEL dans l'historique avant les
  /// functionResponse, sinon Gemini refuse la requête.
  final Map<String, Object?>? modelContent;

  /// `null` si la réponse ne contient ni texte ni appel de fonction.
  static GeminiTurn? parse(Map<String, dynamic> body) {
    try {
      final content = Map<String, Object?>.from(
        (body['candidates'] as List).first['content'] as Map,
      );
      final parts = (content['parts'] as List?) ?? const [];
      final text = StringBuffer();
      final calls = <GeminiFunctionCall>[];
      for (final p in parts.whereType<Map>()) {
        final call = p['functionCall'];
        if (call is Map) {
          final name = call['name'];
          if (name is! String || name.isEmpty) continue;
          final args = call['args'];
          calls.add(
            GeminiFunctionCall(
              name: name,
              args: args is Map ? Map<String, Object?>.from(args) : const {},
              id: call['id'] as String?,
            ),
          );
        } else if (p['text'] is String && p['thought'] != true) {
          text.write(p['text']);
        }
      }
      if (text.isEmpty && calls.isEmpty) return null;
      return GeminiTurn._(
        status: GeminiChatStatus.ok,
        text: text.toString().trim(),
        calls: calls,
        modelContent: content,
      );
    } catch (_) {
      return null;
    }
  }
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
        maxOutputTokens: 256,
        temperature: 0,
        jsonMode: false,
        timeout: GeminiConfig.quickTimeout,
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

  /// Module Réclamations : catégorie, priorité, ton et résumé proposés par
  /// Gemini (JSON strict, voir complaint_ai.dart).
  /// Retourne `null` si Gemini est indisponible (pas de clé, pas d'internet,
  /// quota, réponse illisible) : le formulaire continue sans suggestion.
  Future<ComplaintAiAnalysis?> analyzeComplaint({
    required String title,
    required String description,
  }) async {
    if (!GeminiConfig.isConfigured) {
      debugPrint('[Gemini] analyzeComplaint ignorée : clé API manquante');
      return null;
    }
    final key = _cacheKey('analyze', [title, description]);
    final hit = _cache[key];
    if (hit is ComplaintAiAnalysis) {
      debugPrint('[Gemini] analyzeComplaint : résultat en cache (aucun appel)');
      return hit;
    }
    try {
      final response = await _post(
        prompt: buildComplaintAnalysisPrompt(
          title: title,
          description: description,
        ),
        maxOutputTokens: 1024,
        temperature: 0.1,
        jsonMode: true,
        timeout: GeminiConfig.quickTimeout,
      );
      if (!response.ok) {
        debugPrint('[Gemini] analyzeComplaint : ${response.error}');
        return null;
      }
      final analysis = parseComplaintAnalysis(response.text);
      if (analysis == null) {
        debugPrint(
          '[Gemini] analyzeComplaint : JSON illisible → ${response.text}',
        );
      } else {
        _remember(key, analysis);
      }
      return analysis;
    } catch (e) {
      // Pas d'internet, délai dépassé…
      debugPrint('[Gemini] analyzeComplaint impossible : $e');
      return null;
    }
  }

  /// « Améliorer mon message » : description reformulée (claire, polie, sans
  /// fait inventé). `null` si Gemini est indisponible.
  Future<String?> improveComplaintText({
    required String title,
    required String description,
  }) async {
    if (!GeminiConfig.isConfigured) {
      debugPrint('[Gemini] improveComplaintText ignorée : clé API manquante');
      return null;
    }
    final key = _cacheKey('improve', [title, description]);
    final hit = _cache[key];
    if (hit is String) {
      debugPrint('[Gemini] improveComplaintText : résultat en cache');
      return hit;
    }
    try {
      final response = await _post(
        prompt: buildComplaintRewritePrompt(
          title: title,
          description: description,
        ),
        maxOutputTokens: 1024,
        temperature: 0.3,
        jsonMode: true,
        timeout: GeminiConfig.quickTimeout,
      );
      if (!response.ok) {
        debugPrint('[Gemini] improveComplaintText : ${response.error}');
        return null;
      }
      final text = parseComplaintRewrite(response.text);
      if (text == null) {
        debugPrint('[Gemini] improveComplaintText : réponse illisible');
      } else {
        _remember(key, text);
      }
      return text;
    } catch (e) {
      debugPrint('[Gemini] improveComplaintText impossible : $e');
      return null;
    }
  }

  /// 1 à 3 solutions rapides avant l'envoi. Liste vide si Gemini est
  /// indisponible ou n'a rien d'utile à proposer.
  Future<List<String>> suggestQuickFixes({
    required ComplaintCategory category,
    required String title,
    required String description,
  }) async {
    if (!GeminiConfig.isConfigured) {
      debugPrint('[Gemini] suggestQuickFixes ignorée : clé API manquante');
      return const [];
    }
    final key = _cacheKey('fixes', [category.name, title, description]);
    final hit = _cache[key];
    if (hit is List<String>) {
      debugPrint('[Gemini] suggestQuickFixes : résultat en cache');
      return hit;
    }
    try {
      final response = await _post(
        prompt: buildQuickFixesPrompt(
          category: category,
          title: title,
          description: description,
        ),
        maxOutputTokens: 1024,
        temperature: 0.2,
        jsonMode: true,
        timeout: GeminiConfig.quickTimeout,
      );
      if (!response.ok) {
        debugPrint('[Gemini] suggestQuickFixes : ${response.error}');
        return const [];
      }
      final fixes = parseQuickFixes(response.text);
      _remember(key, fixes); // réponse valide, même vide
      return fixes;
    } catch (e) {
      debugPrint('[Gemini] suggestQuickFixes impossible : $e');
      return const [];
    }
  }

  /// Assistant RentCar : un tour de conversation multi-tour avec function
  /// calling. [contents] = historique brut Gemini (rôles user / model,
  /// parts text / functionCall / functionResponse).
  /// Ne lance jamais d'exception : [GeminiChatStatus.offline] sans internet,
  /// [GeminiChatStatus.unavailable] si Gemini échoue ou répond mal.
  Future<GeminiTurn> converse({
    required String systemInstruction,
    required List<Map<String, Object?>> contents,
    List<Map<String, Object?>>? tools,
  }) async {
    if (!GeminiConfig.isConfigured) {
      debugPrint('[Gemini] assistant ignoré : clé API manquante');
      return const GeminiTurn.failed(GeminiChatStatus.unavailable);
    }
    try {
      final response = await _post(
        systemInstruction: systemInstruction,
        contents: contents,
        tools: tools,
        maxOutputTokens: 1024,
        temperature: 0.4,
        timeout: GeminiConfig.quickTimeout,
      );
      final raw = response.raw;
      if (!response.ok || raw == null) {
        debugPrint('[Gemini] assistant : ${response.error}');
        return GeminiTurn.failed(
          quotaReached
              ? GeminiChatStatus.quotaExceeded
              : GeminiChatStatus.unavailable,
        );
      }
      final turn = GeminiTurn.parse(raw);
      if (turn == null) {
        debugPrint(
          '[Gemini] assistant : réponse illisible '
          '(finishReason=${_finishReason(raw)})',
        );
        return const GeminiTurn.failed(GeminiChatStatus.unavailable);
      }
      return turn;
    } on http.ClientException catch (e) {
      debugPrint("[Gemini] assistant : pas d'internet ($e)");
      return const GeminiTurn.failed(GeminiChatStatus.offline);
    } catch (e) {
      debugPrint('[Gemini] assistant impossible : $e');
      return const GeminiTurn.failed(GeminiChatStatus.unavailable);
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

  /// Appel generateContent. La clé part dans le header `x-goog-api-key`
  /// (jamais dans l'URL : pas de fuite dans les logs), ce qui accepte les
  /// clés AI Studio « AIza… » comme les nouvelles « AQ.… ».
  ///
  /// Modèles essayés dans l'ordre : on passe au suivant sur 404 (modèle
  /// retiré), 503 (surcharge) ou délai dépassé. Les autres erreurs (clé,
  /// permission, quota) arrêtent tout : un autre modèle n'y changerait rien.
  Future<({bool ok, String text, String? error, Map<String, dynamic>? raw})>
  _post({
    String prompt = '',

    /// Conversation multi-tour (remplace [prompt]) : [{role, parts}].
    List<Map<String, Object?>>? contents,
    String? systemInstruction,

    /// Function calling : `tools: [{functionDeclarations: [...]}]`.
    List<Map<String, Object?>>? tools,
    required int maxOutputTokens,
    required double temperature,
    bool jsonMode = false,
    Duration timeout = GeminiConfig.timeout,
  }) async {
    // Modèles épuisés aujourd'hui (429) : on ne les rappelle pas.
    final models = GeminiQuota.instance.available(GeminiConfig.allModels);
    if (models.isEmpty) {
      debugPrint(
        '[Gemini] Quota du jour atteint sur tous les modèles : appel évité',
      );
      return (ok: false, text: '', error: quotaMessage, raw: null);
    }

    final generationConfig = <String, Object?>{
      'temperature': temperature,
      'maxOutputTokens': maxOutputTokens,
      if (jsonMode) 'responseMimeType': 'application/json',
    };
    final body = jsonEncode({
      if (systemInstruction != null)
        'systemInstruction': {
          'parts': [
            {'text': systemInstruction},
          ],
        },
      'contents':
          contents ??
          [
            {
              'parts': [
                {'text': prompt},
              ],
            },
          ],
      'tools': ?tools,
      'generationConfig': generationConfig,
    });

    String? lastError;

    for (final modelName in models) {
      final http.Response response;
      try {
        response = await _client
            .post(
              Uri.parse(GeminiConfig.endpointFor(modelName)),
              headers: {
                'Content-Type': 'application/json',
                'x-goog-api-key': GeminiConfig.apiKey,
              },
              body: body,
            )
            .timeout(timeout);
      } on TimeoutException {
        debugPrint(
          '[Gemini] $modelName : pas de réponse en ${timeout.inSeconds} s, '
          'modèle suivant…',
        );
        lastError = 'Gemini ne répond pas (délai de ${timeout.inSeconds} s).';
        continue;
      }
      // Pas d'internet (SocketException…) : remonte à l'appelant, qui
      // continue sans IA.

      final code = response.statusCode;
      if (code == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final text = _extractText(json);
        // Réponse sans texte normale si Gemini appelle une fonction.
        if (text.isEmpty && !response.body.contains('"functionCall"')) {
          debugPrint(
            '[Gemini] $modelName : réponse vide '
            '(finishReason=${_finishReason(json)})',
          );
        }
        return (ok: true, text: text, error: null, raw: json);
      }

      final google = _googleError(response.body);
      final hint = switch (code) {
        400 => 'requête invalide ou clé API invalide',
        401 => 'clé API non reconnue',
        403 => 'permission refusée (clé restreinte ou API non activée)',
        404 => 'modèle introuvable',
        429 => 'quota dépassé',
        503 => 'serveur surchargé',
        _ => 'erreur inattendue',
      };
      debugPrint('[Gemini] HTTP $code ($modelName) — $hint : $google');

      // 429 : chaque modèle a son propre quota → on mémorise et on passe
      // au suivant (comme pour 404 / 503).
      if (code == 429) {
        GeminiQuota.instance.markExhausted(modelName);
        lastError = quotaMessage;
        continue;
      }
      if (code == 404 || code == 503) {
        lastError = 'Modèle $modelName indisponible ($code).';
        continue;
      }
      return (
        ok: false,
        text: '',
        raw: null,
        error: switch (code) {
          400 => 'Requête invalide (400) — vérifie la clé API : $google',
          401 => 'Clé API non reconnue (401) : $google',
          403 => 'Clé API refusée (403). Vérifie la clé sur AI Studio.',
          _ => 'Erreur Gemini HTTP $code : $google',
        },
      );
    }

    return (
      ok: false,
      text: '',
      raw: null,
      error:
          (quotaReached ? quotaMessage : null) ??
          lastError ??
          'Gemini surchargé (503). Tous les modèles sont indisponibles — '
              'réessaie dans 1–2 minutes.',
    );
  }

  /// Cache mémoire des aides « réclamations » : même texte → même
  /// résultat, sans nouvel appel (partagé, 50 entrées, vidé au redémarrage).
  static final Map<String, Object> _cache = {};

  static String _cacheKey(String kind, List<String> parts) =>
      '$kind|${parts.map((p) => p.trim().toLowerCase()).join('|')}';

  static void _remember(String key, Object value) {
    if (_cache.length >= 50) _cache.remove(_cache.keys.first);
    _cache[key] = value;
  }

  static void clearCache() => _cache.clear();

  /// Tous les modèles ont atteint leur quota gratuit du jour.
  static const quotaMessage =
      'Assistant IA temporairement indisponible (quota atteint), '
      'réessayez plus tard.';

  /// `true` si plus aucun modèle n'est utilisable aujourd'hui.
  static bool get quotaReached =>
      GeminiQuota.instance.allExhausted(GeminiConfig.allModels);

  /// Message d'erreur de Google : {"error": {"message": "…", "status": "…"}}.
  static String _googleError(String body) {
    try {
      final error = (jsonDecode(body) as Map<String, dynamic>)['error'] as Map;
      return '${error['status'] ?? ''} ${error['message'] ?? ''}'.trim();
    } catch (_) {
      return body.length > 200 ? '${body.substring(0, 200)}…' : body;
    }
  }

  static String? _finishReason(Map<String, dynamic> body) {
    try {
      return (body['candidates'] as List).first['finishReason'] as String?;
    } catch (_) {
      return null;
    }
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
