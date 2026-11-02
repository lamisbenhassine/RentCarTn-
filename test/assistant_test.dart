import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rentcar_tunisia/core/config/gemini_config.dart';
import 'package:rentcar_tunisia/core/services/voice_input_service.dart';
import 'package:rentcar_tunisia/data/mock/mock_reservations.dart';
import 'package:rentcar_tunisia/data/models/chat_message.dart';
import 'package:rentcar_tunisia/data/models/complaint.dart';
import 'package:rentcar_tunisia/data/models/complaint_draft.dart';
import 'package:rentcar_tunisia/data/models/reservation.dart';
import 'package:rentcar_tunisia/data/services/assistant_prompt.dart';
import 'package:rentcar_tunisia/data/services/assistant_tools.dart';
import 'package:rentcar_tunisia/data/services/gemini_service.dart';
import 'package:rentcar_tunisia/state/chat_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _strings = ChatStrings(
  offline: 'offline',
  unavailable: 'unavailable',
  quota: 'quota',
  draftIntro: 'intro',
);

http.Response _reply(List<Map<String, Object?>> parts) => http.Response(
  jsonEncode({
    'candidates': [
      {
        'content': {'role': 'model', 'parts': parts},
      },
    ],
  }),
  200,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

http.Response _text(String text) => _reply([
  {'text': text},
]);

http.Response _call(String name, [Map<String, Object?> args = const {}]) =>
    _reply([
      {
        'functionCall': {'name': name, 'args': args, 'id': 'call_1'},
        'thoughtSignature': 'SIG',
      },
    ]);

Complaint _complaint(String ref, ComplaintStatus status) {
  final now = DateTime(2026, 10, 30);
  return Complaint(
    id: 'id-$ref',
    reference: ref,
    userId: 'u1',
    category: ComplaintCategory.panne,
    title: 'Clim en panne',
    description: 'La climatisation ne fonctionne plus du tout.',
    priority: ComplaintPriority.moyenne,
    status: status,
    createdAt: now,
    updatedAt: now,
  );
}

final _reservations = MockReservations.build();
final _enCours = _reservations.firstWhere(
  (r) => r.status == ReservationStatus.enCours,
);

const _brakeArgs = {
  'category': 'panne',
  'priority': 'urgente',
  'title': 'Bruit au freinage',
  'description': 'La voiture fait un bruit bizarre quand je freine.',
  'isUrgent': false,
};

void main() {
  group('réponse et instruction système', () {
    test('balises → boutons, référence de « voir »', () {
      final r = parseAssistantReply(
        'Votre dossier est en cours, appelez le **198** si besoin.\n'
        '[[action:voir:rec-2026-0003]] [[action:appeler]] [[action:inconnue]]',
      );
      expect(r.text, 'Votre dossier est en cours, appelez le 198 si besoin.');
      expect(r.actions, [ChatAction.viewComplaint, ChatAction.callAgency]);
      expect(r.complaintRef, 'REC-2026-0003');
    });

    test('texte recopié après les balises : ignoré', () {
      final r = parseAssistantReply(
        'Retour le 4 novembre à Sousse.\n\n'
        '[[action:reservations]] mes réservations · [[action:appeler]] '
        "appeler l'agence",
      );
      expect(r.text, 'Retour le 4 novembre à Sousse.');
      expect(r.actions, [ChatAction.myReservations, ChatAction.callAgency]);
    });

    test('texte arabe → bulle RTL ; derja latine → LTR', () {
      expect(isArabicText('سيارتي معطلة'), isTrue);
      expect(isArabicText('karhba ta3i 7arqet'), isFalse);
    });

    test('instruction : fonctions, jamais « créée », contexte résumé', () {
      final p = buildAssistantSystemPrompt(
        AssistantContext(
          firstName: 'Hamza',
          city: 'Sousse',
          reservation: _enCours,
          complaints: [_complaint('REC-2026-0003', ComplaintStatus.enCours)],
        ),
      );
      expect(p, contains('create_complaint ne crée rien'));
      expect(p, contains('get_current_reservation'));
      expect(p, contains('« 3 »'));
      expect(p, contains('Prénom : Hamza'));
      expect(p, contains('1 au total, 1 ouverte(s)'));
      // Le détail passe par les fonctions, pas par l'instruction.
      expect(p, isNot(contains(_enCours.reference)));
    });
  });

  group('fonctions', () {
    test('déclarations = enums de complaint.dart', () {
      final decl =
          (AssistantTools.declarations.single['functionDeclarations']! as List)
              .cast<Map>();
      expect(decl.map((d) => d['name']), [
        'create_complaint',
        'get_my_complaints',
        'get_current_reservation',
        'get_my_vehicles',
      ]);
      final props = (decl.first['parameters'] as Map)['properties'] as Map;
      expect((props['category'] as Map)['enum'], [
        for (final c in ComplaintCategory.values) c.name,
      ]);
      expect((props['priority'] as Map)['enum'], [
        'basse',
        'moyenne',
        'urgente',
      ]);
    });

    test('create_complaint valide : brouillon lié à la location en cours', () {
      final r = parseComplaintDraft(_brakeArgs, reservation: _enCours);
      expect(r.error, isNull);
      expect(r.draft!.category, ComplaintCategory.panne);
      expect(r.draft!.reservationId, _enCours.id);
      expect(r.draft!.reservationLabel, contains(_enCours.reference));
      // Réservation à venir : pas de lien automatique.
      final upcoming = _reservations.firstWhere(
        (x) => x.status == ReservationStatus.aVenir,
      );
      expect(
        parseComplaintDraft(
          _brakeArgs,
          reservation: upcoming,
        ).draft!.reservationId,
        isNull,
      );
    });

    test('véhicule : catalogue seulement, jamais de nom inventé', () {
      final catalogue = {for (final r in _reservations) r.car.id: r.car};
      final vehicles = clientVehicles(_reservations, (id) => catalogue[id]);
      // Location en cours d'abord, réservations annulées exclues.
      expect(vehicles.first.reservation.id, _enCours.id);
      expect(
        vehicles.any((v) => v.reservation.status == ReservationStatus.annulee),
        isFalse,
      );
      // Voiture retirée du catalogue : absente de la liste.
      expect(clientVehicles(_reservations, (_) => null), isEmpty);

      // Location en cours → sa voiture.
      final linked = parseComplaintDraft(
        _brakeArgs,
        reservation: _enCours,
        vehicles: vehicles,
      ).draft!;
      expect(linked.carId, _enCours.car.id);
      expect(linked.carLabel, _enCours.car.title);

      // Panne sans location en cours : le client doit choisir.
      final ask = parseComplaintDraft(_brakeArgs, vehicles: vehicles);
      expect(ask.draft, isNull);
      expect(ask.error, contains('get_my_vehicles'));

      // carId inventé → refusé ; carId de la liste → accepté.
      expect(
        parseComplaintDraft({
          ..._brakeArgs,
          'carId': 'voiture-inventee',
        }, vehicles: vehicles).error,
        contains('carId inconnu'),
      );
      final other = vehicles.last;
      final chosen = parseComplaintDraft({
        ..._brakeArgs,
        'carId': other.car.id,
      }, vehicles: vehicles).draft!;
      expect(chosen.carId, other.car.id);
      expect(chosen.reservationId, other.reservation.id);
      expect(myVehiclesResult(vehicles)['count'], vehicles.length);
    });

    test('isUrgent → priorité urgente ; arguments invalides → erreur', () {
      final urgent = parseComplaintDraft({
        ..._brakeArgs,
        'priority': 'moyenne',
        'isUrgent': true,
      }).draft!;
      expect(urgent.effectivePriority, ComplaintPriority.urgente);

      final bad = parseComplaintDraft({
        'category': 'moteur',
        'priority': 'haute',
        'title': 'Bruit',
        'description': 'Bruit.',
      });
      expect(bad.draft, isNull);
      expect(bad.error, contains('category invalide'));
      expect(bad.error, contains('description trop courte'));
    });

    test('résultats get_my_complaints / get_current_reservation', () {
      final list = myComplaintsResult([
        _complaint('REC-2026-0001', ComplaintStatus.resolue),
      ]);
      expect(list['count'], 1);
      expect(((list['complaints'] as List).single as Map)['status'], 'Résolue');

      // Voiture lue dans le catalogue : absente du catalogue → null.
      final vehicles = [
        ClientVehicle(car: _enCours.car, reservation: _enCours),
      ];
      final res =
          currentReservationResult(_enCours, vehicles: vehicles)['reservation']
              as Map;
      expect(res['reference'], _enCours.reference);
      expect(res['car'], _enCours.car.title);
      expect(
        (currentReservationResult(_enCours)['reservation'] as Map)['car'],
        isNull,
      );
      expect(currentReservationResult(null)['reservation'], isNull);
      expect(currentOrNextReservation(_reservations)!.id, _enCours.id);
    });

    test('brouillon et message : aller-retour JSON', () {
      final m = ChatMessage(
        id: '1',
        role: ChatRole.assistant,
        text: 'intro',
        date: DateTime(2026, 11, 1),
        draft: parseComplaintDraft(_brakeArgs).draft,
        draftState: DraftState.edited,
      );
      final back = ChatMessage.tryFromJson(
        jsonDecode(jsonEncode(m.toJson())) as Map<String, Object?>,
      )!;
      expect(back.draft!.title, 'Bruit au freinage');
      expect(back.draftState, DraftState.edited);
      expect(ComplaintDraft.tryFromJson({'category': 'x'}), isNull);
    });
  });

  group('ChatProvider (function calling)', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    final skip = GeminiConfig.isConfigured
        ? null
        : 'gemini_secrets.dart sans clé : assistant désactivé';

    ChatProvider providerWith(
      List<http.Response> responses,
      List<Map<String, dynamic>> bodies,
    ) {
      var i = 0;
      return ChatProvider(
        gemini: GeminiService(
          client: MockClient((req) async {
            bodies.add(jsonDecode(req.body) as Map<String, dynamic>);
            return responses[i < responses.length ? i++ : responses.length - 1];
          }),
        ),
      );
    }

    final context = AssistantContext(
      firstName: 'Hamza',
      reservation: _enCours,
      complaints: [_complaint('REC-2026-0003', ComplaintStatus.enCours)],
    );

    test('get_my_complaints : exécutée localement puis réponse', () async {
      final bodies = <Map<String, dynamic>>[];
      final p = providerWith([
        _call('get_my_complaints'),
        _text('REC-2026-0003 est en cours. [[action:voir:REC-2026-0003]]'),
      ], bodies);
      await p.loadFor('u1');
      await p.send('Mes réclamations ?', context: context, strings: _strings);

      expect(bodies, hasLength(2));
      expect(bodies.first['tools'], isNotNull);
      final contents = bodies.last['contents'] as List;
      // Tour du modèle renvoyé tel quel (thoughtSignature), puis réponse.
      expect(
        contents[contents.length - 2]['parts'][0]['thoughtSignature'],
        'SIG',
      );
      final response = contents.last['parts'][0]['functionResponse'] as Map;
      expect(response['id'], 'call_1');
      expect(response['response']['count'], 1);

      final last = p.messages.last;
      expect(last.text, 'REC-2026-0003 est en cours.');
      expect(last.actions, [ChatAction.viewComplaint]);
      expect(last.complaintId, 'id-REC-2026-0003');
    }, skip: skip);

    test(
      'create_complaint : carte, rien de créé, puis Confirmer une fois',
      () async {
        final bodies = <Map<String, dynamic>>[];
        final p = providerWith([_call('create_complaint', _brakeArgs)], bodies);
        await p.loadFor('u1');
        await p.send(
          'Ma voiture fait un bruit bizarre quand je freine',
          context: context,
          strings: _strings,
        );

        expect(bodies, hasLength(1)); // pas de functionResponse : on attend
        final card = p.messages.last;
        expect(card.text, 'intro');
        expect(card.draft!.reservationId, _enCours.id);
        expect(card.draftState, DraftState.pending);

        var created = 0;
        Future<Complaint?> create(ComplaintDraft d) async {
          created++;
          await Future<void>.delayed(const Duration(milliseconds: 10));
          return _complaint('REC-2026-0009', ComplaintStatus.enAttente);
        }

        // Double appui : une seule réclamation.
        final results = await Future.wait([
          p.confirmDraft(
            card.id,
            create: create,
            createdText: (c) => c.reference,
          ),
          p.confirmDraft(
            card.id,
            create: create,
            createdText: (c) => c.reference,
          ),
        ]);
        expect(created, 1);
        expect(results.whereType<Complaint>(), hasLength(1));
        expect(
          p.messages.firstWhere((m) => m.id == card.id).draftState,
          DraftState.confirmed,
        );
        expect(p.messages.last.text, 'REC-2026-0009');
        expect(p.messages.last.actions, [ChatAction.viewComplaint]);
        expect(p.messages.last.complaintId, 'id-REC-2026-0009');
      },
      skip: skip,
    );

    test('create_complaint invalide : erreur renvoyée à Gemini', () async {
      final bodies = <Map<String, dynamic>>[];
      final p = providerWith([
        _call('create_complaint', {
          'category': 'panne',
          'description': 'Bruit',
        }),
        _text('Pouvez-vous décrire le bruit ?'),
      ], bodies);
      await p.loadFor('u1');
      await p.send('Bruit', context: context, strings: _strings);

      final response =
          (bodies.last['contents'] as List).last['parts'][0]['functionResponse']
              as Map;
      expect(
        response['response']['error'],
        contains('description trop courte'),
      );
      expect(p.messages.last.draft, isNull);
      expect(p.messages.last.text, 'Pouvez-vous décrire le bruit ?');
    }, skip: skip);

    test('boucle de fonctions sans fin → message d\'erreur', () async {
      final p = providerWith([_call('get_current_reservation')], []);
      await p.loadFor('u1');
      await p.send('?', context: context, strings: _strings);
      expect(p.messages.last.text, 'unavailable');
      expect(p.messages.last.actions, [ChatAction.newComplaint]);
      expect(p.isTyping, isFalse);
    }, skip: skip);

    test('pas d\'internet → « offline » + bouton réclamation', () async {
      final p = ChatProvider(
        gemini: GeminiService(
          client: MockClient(
            (_) async => throw http.ClientException('Failed host lookup'),
          ),
        ),
      );
      await p.loadFor('u1');
      await p.send('Panne', context: context, strings: _strings);
      expect(p.messages.last.text, 'offline');
      expect(p.messages.last.actions, [ChatAction.newComplaint]);
    }, skip: skip);

    test('historique par utilisateur + nouvelle conversation', () async {
      final p = providerWith([_text('OK')], []);
      await p.loadFor('u1');
      await p.send('Salut', context: context, strings: _strings);

      final other = providerWith([_text('OK')], []);
      await other.loadFor('u1');
      expect(other.messages.map((m) => m.text), ['Salut', 'OK']);
      await other.loadFor('u2');
      expect(other.messages, isEmpty);

      await p.newConversation();
      final reloaded = providerWith([_text('OK')], []);
      await reloaded.loadFor('u1');
      expect(reloaded.messages, isEmpty);
    }, skip: skip);

    test('👍 / 👎 : enregistré, 2e appui = retiré, conservé après nouvelle conversation', () async {
      final p = providerWith([_text('Réponse A')], []);
      await p.loadFor('u1');
      await p.send('Question A', context: context, strings: _strings);
      final answer = p.messages.last;

      await p.setFeedback(answer.id, true);
      expect(p.messages.last.liked, isTrue);
      expect(p.feedbackStats, (up: 1, down: 0));

      await p.setFeedback(answer.id, false); // change d'avis
      expect(p.feedbackStats, (up: 0, down: 1));
      await p.setFeedback(answer.id, false); // même pouce : retiré
      expect(p.messages.last.liked, isNull);
      expect(p.feedbackStats, (up: 0, down: 0));

      await p.setFeedback(answer.id, true);
      await p.setFeedback(p.messages.first.id, true); // message client : ignoré
      await p.newConversation();
      final other = providerWith([_text('OK')], []);
      await other.loadFor('u2');
      expect(other.feedbackStats, (up: 1, down: 0));

      final log = jsonDecode(
        (await SharedPreferences.getInstance()).getString(
          'assistant_feedback_log',
        )!,
      ) as List;
      expect(log.single['question'], 'Question A');
      expect(log.single['answer'], 'Réponse A');
    }, skip: skip);

    test(
      '10 derniers messages au maximum, en commençant par le client',
      () async {
        final bodies = <Map<String, dynamic>>[];
        final p = providerWith([_text('OK')], bodies);
        await p.loadFor('u1');
        for (var i = 0; i < 15; i++) {
          await p.send('Message $i', context: context, strings: _strings);
        }
        final contents = bodies.last['contents'] as List;
        expect(contents.length, lessThanOrEqualTo(ChatProvider.maxSent));
        expect(contents.first['role'], 'user');
        expect(contents.last['parts'][0]['text'], 'Message 14');

        final trimmed = ChatProvider.recentHistory([
          for (var i = 0; i < 26; i++) {'role': i.isEven ? 'model' : 'user'},
        ]);
        expect(trimmed.length, 9); // 10 derniers, 1er « model » retiré
        expect(trimmed.first['role'], 'user');
      },
      skip: skip,
    );
  });

  group('saisie vocale', () {
    test('langue : fr_FR / ar_TN, sinon variante, sinon système', () {
      const ids = ['en_US', 'fr_CA', 'fr_FR', 'ar_EG', 'ar-TN'];
      expect(VoiceInputService.pickLocale(ids, VoiceLanguage.fr), 'fr_FR');
      expect(VoiceInputService.pickLocale(ids, VoiceLanguage.ar), 'ar-TN');
      expect(
        VoiceInputService.pickLocale(['ar_SA', 'fr_BE'], VoiceLanguage.ar),
        'ar_SA',
      );
      expect(VoiceInputService.pickLocale(['en_US'], VoiceLanguage.ar), isNull);
    });
  });
}
