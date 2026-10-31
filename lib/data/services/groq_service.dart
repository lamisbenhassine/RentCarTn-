import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/groq_config.dart';
import '../models/car.dart';
import '../models/recommend_quiz.dart';

class GroqRecommendPick {
  const GroqRecommendPick({required this.id, required this.why});

  final String id;
  final String why;
}

class GroqRecommendResult {
  const GroqRecommendResult({
    required this.ok,
    this.picks = const [],
    this.message,
    this.rationale,
    this.usedAi = false,
  });

  final bool ok;
  final List<GroqRecommendPick> picks;
  final String? message;
  final String? rationale;

  /// Toujours `true` quand `ok` — recommandation 100 % Groq (pas de fallback local).
  final bool usedAi;

  List<String> get carIds => [for (final p in picks) p.id];

  String? whyFor(String carId) {
    for (final p in picks) {
      if (p.id == carId) return p.why;
    }
    return null;
  }
}

/// Recommandation de véhicules via Groq uniquement (pas de scoring local).
class GroqService {
  GroqService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<GroqRecommendResult> recommendCars({
    required Map<String, String> answers,
    required List<Car> fleet,
  }) async {
    final candidates = fleet.where((c) => c.available).toList();
    if (candidates.isEmpty) {
      return const GroqRecommendResult(
        ok: false,
        message: 'Aucun véhicule disponible à recommander pour le moment.',
      );
    }

    if (!GroqConfig.isConfigured) {
      return const GroqRecommendResult(
        ok: false,
        usedAi: false,
        message:
            'Clé Groq manquante. Colle ta clé dans groq_secrets.dart '
            '(https://console.groq.com/keys).',
      );
    }

    final answersLabel = <String, String>{};
    for (final q in RecommendQuizCatalog.questions) {
      final optId = answers[q.id];
      if (optId == null) continue;
      String label = optId;
      for (final o in q.options) {
        if (o.id == optId) {
          label = o.label;
          break;
        }
      }
      answersLabel[q.title] = label;
    }

    final carsJson = [
      for (final c in candidates)
        {
          'id': c.id,
          'name': c.fullName,
          'category': c.category.label,
          'seats': c.seats,
          'doors': c.doors,
          'luggage': c.luggage,
          'pricePerDay': c.pricePerDay,
          'city': c.city,
          'fuel': c.fuel.label,
          'transmission': c.transmission.label,
        },
    ];

    final prompt = '''
Tu es un conseiller location de voitures en Tunisie (RentCar Tunisia).
Choisis les MEILLEURES voitures pour ce client — PAS toute la liste.

Règles STRICTES:
- Recommande exactement 1 ou 2 voitures maximum (jamais 3+).
- Ignore les voitures mal adaptées (ex. utilitaire pour famille, luxe si budget éco).
- Classe du meilleur match au second.
- Utilise UNIQUEMENT les id de la liste fournie.
- Pour CHAQUE voiture, écris une courte raison "why" (1 phrase, français, max ~20 mots)
  qui explique pourquoi elle convient aux réponses du client (usage, budget, passagers…).

Réponses client:
${const JsonEncoder.withIndent('  ').convert(answersLabel)}

Véhicules disponibles:
${const JsonEncoder.withIndent('  ').convert(carsJson)}

Réponds UNIQUEMENT en JSON valide, sans markdown:
{"cars":[{"id":"meilleur_id","why":"Courte raison personnalisée."}],"rationale":"Phrase globale (optionnelle)"}
''';

    try {
      final raw = await _chat(prompt);
      final parsed = _parseRecommend(raw, candidates.map((c) => c.id).toSet());
      if (parsed.picks.isEmpty) {
        return GroqRecommendResult(
          ok: false,
          usedAi: false,
          message:
              'Groq n\'a renvoyé aucun véhicule valide. Réessaie.',
          rationale: parsed.rationale,
        );
      }
      final picks = parsed.picks.take(2).toList();
      return GroqRecommendResult(
        ok: true,
        picks: picks,
        usedAi: true,
        rationale: parsed.rationale == null || parsed.rationale!.isEmpty
            ? 'Voici pourquoi ces véhicules vous correspondent.'
            : parsed.rationale,
      );
    } catch (e) {
      return GroqRecommendResult(
        ok: false,
        usedAi: false,
        message: 'Erreur Groq : $e',
      );
    }
  }

  Future<String> _chat(String userPrompt) async {
    final models = <String>{
      GroqConfig.model,
      ...GroqConfig.fallbackModels,
    }.toList();

    String? lastError;
    for (final model in models) {
      final response = await _client
          .post(
            Uri.parse(GroqConfig.endpoint),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${GroqConfig.apiKey}',
            },
            body: jsonEncode({
              'model': model,
              'temperature': 0.2,
              'max_tokens': 700,
              'response_format': {'type': 'json_object'},
              'messages': [
                {
                  'role': 'system',
                  'content':
                      'Tu réponds uniquement en JSON. '
                      'Maximum 2 voitures. Chaque voiture a id + why (1 phrase FR).',
                },
                {'role': 'user', 'content': userPrompt},
              ],
            }),
          )
          .timeout(GroqConfig.timeout);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final choices = body['choices'] as List<dynamic>? ?? const [];
        if (choices.isEmpty) {
          lastError = 'Réponse vide ($model)';
          continue;
        }
        final message =
            (choices.first as Map<String, dynamic>)['message']
                as Map<String, dynamic>?;
        final content = (message?['content'] as String?)?.trim() ?? '';
        if (content.isEmpty) {
          lastError = 'Contenu vide ($model)';
          continue;
        }
        return content;
      }

      lastError = 'HTTP ${response.statusCode} ($model): ${response.body}';
      if (response.statusCode == 401 || response.statusCode == 403) {
        throw StateError(
          'Clé Groq invalide. Vérifie groq_secrets.dart.',
        );
      }
    }

    throw StateError(lastError ?? 'Appel Groq impossible.');
  }

  GroqRecommendResult _parseRecommend(String raw, Set<String> validIds) {
    var text = raw.trim();
    if (text.startsWith('```')) {
      text = text.replaceAll(RegExp(r'^```(?:json)?\s*'), '');
      text = text.replaceAll(RegExp(r'\s*```$'), '');
    }
    final map = jsonDecode(text) as Map<String, dynamic>;
    final picks = <GroqRecommendPick>[];

    final cars = map['cars'] as List<dynamic>?;
    if (cars != null) {
      for (final item in cars) {
        if (item is! Map) continue;
        final id = item['id']?.toString();
        if (id == null || !validIds.contains(id)) continue;
        if (picks.any((p) => p.id == id)) continue;
        final why = (item['why'] as String?)?.trim() ?? '';
        picks.add(GroqRecommendPick(
          id: id,
          why: why.isEmpty ? 'Bon match selon vos réponses.' : why,
        ));
      }
    }

    // Ancien format {ids, rationale} si le modèle ne suit pas cars[].
    if (picks.isEmpty) {
      final ids = (map['ids'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .where(validIds.contains);
      for (final id in ids) {
        picks.add(GroqRecommendPick(
          id: id,
          why: 'Bon match selon vos réponses.',
        ));
      }
    }

    return GroqRecommendResult(
      ok: true,
      picks: picks,
      rationale: map['rationale'] as String?,
      usedAi: true,
    );
  }
}
