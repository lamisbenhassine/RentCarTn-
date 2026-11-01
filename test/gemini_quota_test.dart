import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rentcar_tunisia/core/config/gemini_config.dart';
import 'package:rentcar_tunisia/data/services/gemini_quota.dart';
import 'package:rentcar_tunisia/data/services/gemini_service.dart';
import 'package:rentcar_tunisia/state/chat_provider.dart';
import 'package:rentcar_tunisia/data/services/assistant_prompt.dart';
import 'package:shared_preferences/shared_preferences.dart';

http.Response _ok(String text) => http.Response(
  jsonEncode({
    'candidates': [
      {
        'content': {
          'parts': [
            {'text': text},
          ],
        },
      },
    ],
  }),
  200,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

final _quota = http.Response(
  jsonEncode({
    'error': {
      'code': 429,
      'status': 'RESOURCE_EXHAUSTED',
      'message': 'free tier limit: 20 requests per day',
    },
  }),
  429,
);

/// Modèle appelé, lu dans l'URL (`…/models/MODELE:generateContent`).
String _model(http.Request r) => r.url.pathSegments.last.split(':').first;

const _analysis =
    '{"category":"panne","priority":"urgente","tone":"tresMecontent",'
    '"summary":"Voiture arrêtée sur l\'autoroute."}';

void main() {
  final skip = GeminiConfig.isConfigured ? null : 'clé Gemini absente';

  setUp(() {
    GeminiQuota.instance.reset();
    GeminiService.clearCache();
    SharedPreferences.setMockInitialValues({});
  });

  group('GeminiQuota', () {
    test('modèle épuisé ignoré jusqu\'au lendemain', () {
      var now = DateTime(2026, 11, 1, 10);
      final q = GeminiQuota(clock: () => now);
      q.markExhausted('a');
      expect(q.available(['a', 'b']), ['b']);
      expect(q.allExhausted(['a']), isTrue);

      now = DateTime(2026, 11, 1, 23, 59);
      expect(q.isExhausted('a'), isTrue);
      now = DateTime(2026, 11, 2, 0, 1); // nouvelle date
      expect(q.isExhausted('a'), isFalse);
      expect(q.available(['a', 'b']), ['a', 'b']);
    });
  });

  test('fallback : un flash-lite figure en fin de liste', () {
    expect(GeminiConfig.allModels.last, contains('flash-lite'));
    expect(GeminiConfig.allModels.first, GeminiConfig.model);
    expect(
      GeminiConfig.allModels.toSet().length,
      GeminiConfig.allModels.length,
    );
  });

  test(
    '429 → modèle suivant, puis le modèle épuisé n\'est plus appelé',
    () async {
      final called = <String>[];
      final gemini = GeminiService(
        client: MockClient((req) async {
          final model = _model(req);
          called.add(model);
          return model == GeminiConfig.model ? _quota : _ok(_analysis);
        }),
      );

      final a = await gemini.analyzeComplaint(
        title: 'Panne autoroute',
        description: 'La voiture s\'est arrêtée, je suis bloqué.',
      );
      expect(a, isNotNull);
      expect(called, [GeminiConfig.model, GeminiConfig.fallbackModels.first]);
      expect(GeminiQuota.instance.isExhausted(GeminiConfig.model), isTrue);

      called.clear();
      await gemini.improveComplaintText(
        title: 'Panne autoroute',
        description: 'La voiture s\'est arrêtée, je suis bloqué.',
      );
      expect(called, [GeminiConfig.fallbackModels.first]); // 1er modèle évité
    },
    skip: skip,
  );

  test('cache : même texte → aucun nouvel appel', () async {
    var calls = 0;
    final gemini = GeminiService(
      client: MockClient((_) async {
        calls++;
        return _ok(_analysis);
      }),
    );
    for (var i = 0; i < 3; i++) {
      await gemini.analyzeComplaint(
        title: ' Panne autoroute ',
        description: 'La voiture s\'est arrêtée, je suis bloqué.',
      );
    }
    expect(calls, 1);
    await gemini.analyzeComplaint(
      title: 'Panne autoroute',
      description: 'Autre texte assez long pour être analysé.',
    );
    expect(calls, 2);
  }, skip: skip);

  test(
    'tous les modèles épuisés : message clair, puis plus aucun appel',
    () async {
      var calls = 0;
      final gemini = GeminiService(
        client: MockClient((_) async {
          calls++;
          return _quota;
        }),
      );
      final r = await gemini.testConnection();
      expect(r.ok, isFalse);
      expect(r.message, GeminiService.quotaMessage);
      expect(calls, GeminiConfig.allModels.length);
      expect(GeminiService.quotaReached, isTrue);

      calls = 0;
      expect(
        await gemini.analyzeComplaint(
          title: 'Panne autoroute',
          description: 'La voiture s\'est arrêtée, je suis bloqué.',
        ),
        isNull,
      );
      expect(calls, 0); // l'app continue sans IA, sans appel inutile

      // Assistant : bulle « quota atteint » + bouton « Faire une réclamation ».
      final chat = ChatProvider(gemini: gemini);
      await chat.loadFor('u1');
      await chat.send(
        'Bonjour',
        context: const AssistantContext(),
        strings: const ChatStrings(
          offline: 'offline',
          unavailable: 'unavailable',
          quota: 'quota',
          draftIntro: 'intro',
        ),
      );
      expect(chat.messages.last.text, 'quota');
      expect(chat.messages.last.isError, isTrue);
      expect(calls, 0);
    },
    skip: skip,
  );
}
