import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/gemini_config.dart';
import '../models/auction.dart';
import '../models/car.dart';
import '../models/exam.dart';
import '../models/learning.dart';

/// Résultat texte simple (test de connexion).
class GeminiResult {
  const GeminiResult.ok(this.message) : ok = true;
  const GeminiResult.fail(this.message) : ok = false;

  final bool ok;
  final String message;
}

/// Estimation IA du prix de départ d'une enchère (marché Tunisie).
class GeminiPriceEstimate {
  const GeminiPriceEstimate.ok({
    required this.startingPrice,
    required this.rationale,
    this.minPrice,
    this.maxPrice,
  })  : ok = true,
        message = null;

  const GeminiPriceEstimate.fail(this.message)
      : ok = false,
        startingPrice = null,
        rationale = null,
        minPrice = null,
        maxPrice = null;

  final bool ok;
  final String? message;
  final double? startingPrice;
  final String? rationale;
  final double? minPrice;
  final double? maxPrice;
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

  /// Estime un prix de départ d'enchère (TND) pour un véhicule du parc.
  Future<GeminiPriceEstimate> estimateAuctionStartPrice({
    required Car car,
    required int mileage,
    required VehicleCondition condition,
    required bool hadAccident,
    String extraInfo = '',
    String description = '',
  }) async {
    if (!GeminiConfig.isConfigured) {
      return const GeminiPriceEstimate.fail(
        'Clé API manquante. Configure gemini_secrets.dart.',
      );
    }
    if (mileage < 0) {
      return const GeminiPriceEstimate.fail('Kilométrage invalide.');
    }

    final age = DateTime.now().year - car.year;
    final prompt = '''
Tu es un expert du marché automobile d'occasion en Tunisie (TND).
Estime un PRIX DE DÉPART réaliste pour une vente AUX ENCHÈRES
(prix d'ouverture, légèrement sous la valeur marché pour attirer des enchères).

Véhicule :
- Marque / modèle : ${car.brand} ${car.model}
- Année : ${car.year} (âge ≈ $age ans)
- Catégorie location : ${car.category.label}
- Carburant : ${car.fuel.label}
- Boîte : ${car.transmission.label}
- Places / portes : ${car.seats} / ${car.doors}
- Ville : ${car.city}
- Prix location / jour (indicatif flotte) : ${car.pricePerDay.toStringAsFixed(0)} TND
- Climatisation : ${car.airConditioning ? 'oui' : 'non'}

Fiche enchère :
- Kilométrage : $mileage km
- État déclaré : ${condition.label}
- Accident déclaré : ${hadAccident ? 'oui' : 'non'}
- Infos supplémentaires : ${extraInfo.isEmpty ? 'aucune' : extraInfo}
- Description : ${description.isEmpty ? car.description : description}

Règles :
- Devise : dinars tunisiens (TND), nombres entiers.
- startingPrice = prix d'ouverture recommandé (enchères).
- minPrice / maxPrice = fourchette de valeur marché estimée.
- rationale = 2–3 phrases courtes en français, concrètes (km, âge, état, marché TN).
- Pas de symbole monétaire dans les champs numériques.
- Réponds UNIQUEMENT en JSON valide, sans markdown.

FORMAT :
{
  "startingPrice": 18500,
  "minPrice": 17000,
  "maxPrice": 23000,
  "rationale": "..."
}
''';

    try {
      // Budget élevé + thinking désactivé : sinon les modèles « thinking »
      // consomment maxOutputTokens et renvoient un texte vide (illisible).
      var response = await _post(
        prompt: prompt,
        maxOutputTokens: 4096,
        temperature: 0.2,
        jsonMode: true,
        thinkingBudget: 0,
      );

      // Second essai sans JSON forcé si la 1ʳᵉ réponse est vide / illisible.
      if (response.ok && _parsePriceEstimate(response.text) == null) {
        response = await _post(
          prompt: '$prompt\n\nRéponds uniquement avec le JSON, rien d\'autre.',
          maxOutputTokens: 4096,
          temperature: 0.1,
          jsonMode: false,
          thinkingBudget: 0,
        );
      }

      if (!response.ok) {
        return GeminiPriceEstimate.fail(response.error!);
      }
      if (response.text.trim().isEmpty) {
        return const GeminiPriceEstimate.fail(
          'Gemini a renvoyé une réponse vide. Réessaie dans un instant.',
        );
      }
      final parsed = _parsePriceEstimate(response.text);
      if (parsed == null) {
        return const GeminiPriceEstimate.fail(
          'Réponse Gemini illisible. Réessaie l\'estimation.',
        );
      }
      return parsed;
    } on Exception catch (e) {
      return GeminiPriceEstimate.fail('Estimation impossible : $e');
    }
  }

  GeminiPriceEstimate? _parsePriceEstimate(String raw) {
    var text = raw.trim();
    if (text.isEmpty) return null;
    if (text.startsWith('```')) {
      text = text
          .replaceFirst(RegExp(r'^```(?:json)?\s*', multiLine: true), '')
          .replaceFirst(RegExp(r'\s*```$'), '')
          .trim();
    }
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start != -1 && end != -1 && end > start) {
      final jsonSlice = text.substring(start, end + 1);
      try {
        final map = jsonDecode(jsonSlice) as Map<String, dynamic>;
        final starting = _asDouble(
          map['startingPrice'] ??
              map['starting_price'] ??
              map['prixDepart'] ??
              map['prix'],
        );
        if (starting != null && starting > 0) {
          return _okEstimate(
            starting: starting,
            minPrice: _asDouble(map['minPrice'] ?? map['min_price']),
            maxPrice: _asDouble(map['maxPrice'] ?? map['max_price']),
            rationale: ((map['rationale'] ?? map['explication'] ?? '') as Object?)
                .toString()
                .trim(),
          );
        }
      } catch (_) {
        // tombe sur le fallback texte
      }
    }

    // Fallback : premier nombre plausible dans le texte (TND).
    final match = RegExp(r'(\d[\d\s]{2,})\s*(?:TND|DT)?', caseSensitive: false)
        .firstMatch(text);
    if (match == null) return null;
    final starting = _asDouble(match.group(1));
    if (starting == null || starting < 500) return null;
    return _okEstimate(
      starting: starting,
      rationale: 'Estimation extraite de la réponse Gemini.',
    );
  }

  static double? _asDouble(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    final cleaned = value
        .toString()
        .replaceAll(RegExp(r'[^\d.,]'), '')
        .replaceAll(' ', '')
        .replaceAll(',', '.');
    return double.tryParse(cleaned);
  }

  static GeminiPriceEstimate _okEstimate({
    required double starting,
    double? minPrice,
    double? maxPrice,
    String rationale = '',
  }) {
    final rounded = (starting / 100).round() * 100.0;
    return GeminiPriceEstimate.ok(
      startingPrice: rounded < 500 ? 500 : rounded,
      minPrice: minPrice,
      maxPrice: maxPrice,
      rationale: rationale,
    );
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
    int? thinkingBudget,
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
      // 0 = pas de « thinking » (évite réponses vides sur Flash/Pro récents).
      if (thinkingBudget != null) {
        generationConfig['thinkingConfig'] = {
          'thinkingBudget': thinkingBudget,
        };
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
        final text = _extractText(body);
        // Réponse vide (souvent MAX_TOKENS à cause du thinking) → modèle suivant.
        if (text.trim().isEmpty) {
          lastError =
              'Modèle $modelName : réponse vide, essai du suivant…';
          continue;
        }
        return (ok: true, text: text, error: null);
      }

      if (response.statusCode == 503 || response.statusCode == 404) {
        lastError =
            'Modèle $modelName indisponible (${response.statusCode}), '
            'essai du suivant…';
        continue;
      }

      if (response.statusCode == 400) {
        // Certains modèles refusent thinkingBudget — 1 nouvel essai sans.
        if (thinkingBudget != null) {
          final configNoThink = Map<String, Object?>.from(generationConfig)
            ..remove('thinkingConfig');
          final retry = await _client
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
                  'generationConfig': configNoThink,
                }),
              )
              .timeout(GeminiConfig.timeout);
          if (retry.statusCode == 200) {
            final body = jsonDecode(retry.body) as Map<String, dynamic>;
            final text = _extractText(body);
            if (text.trim().isNotEmpty) {
              return (ok: true, text: text, error: null);
            }
          }
          lastError =
              'Modèle $modelName : 400 avec thinking, essai du suivant…';
          continue;
        }
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
