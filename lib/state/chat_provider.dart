import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/chat_message.dart';
import '../data/models/complaint.dart';
import '../data/models/complaint_draft.dart';
import '../data/services/assistant_prompt.dart';
import '../data/services/assistant_tools.dart';
import '../data/services/gemini_service.dart';

/// Textes du chat fournis par l'écran (traduits).
class ChatStrings {
  const ChatStrings({
    required this.offline,
    required this.unavailable,
    required this.quota,
    required this.draftIntro,
  });

  /// Pas d'internet.
  final String offline;

  /// Gemini indisponible ou réponse inutilisable.
  final String unavailable;

  /// Quota gratuit du jour atteint sur tous les modèles.
  final String quota;

  /// Texte de la carte si Gemini n'a rien écrit avec create_complaint.
  final String draftIntro;
}

/// Conversation avec l'« Assistant RentCar » (Gemini, multi-tour, avec
/// function calling).
///
/// - get_my_complaints / get_current_reservation : exécutées localement,
///   le résultat est renvoyé à Gemini (functionResponse) qui répond ;
/// - create_complaint : rien n'est créé, une carte récapitulative attend la
///   confirmation du client ([confirmDraft]).
///
/// Historique enregistré par utilisateur dans shared_preferences.
class ChatProvider extends ChangeNotifier {
  ChatProvider({GeminiService? gemini}) : _gemini = gemini ?? GeminiService();

  final GeminiService _gemini;

  /// Messages conservés (les plus anciens sont oubliés).
  static const maxStored = 60;

  /// Messages envoyés à Gemini (contexte de la conversation).
  static const maxSent = 10;

  /// Allers-retours fonction → Gemini au maximum pour un message.
  static const maxToolRounds = 4;

  List<ChatMessage> _messages = [];
  bool _typing = false;
  String? _userId;
  final Set<String> _confirming = {};

  List<ChatMessage> get messages => _messages;

  /// L'assistant « écrit… » (requête Gemini en cours).
  bool get isTyping => _typing;

  /// Création en cours depuis la carte [messageId] (bouton désactivé).
  bool isConfirming(String messageId) => _confirming.contains(messageId);

  static String _key(String userId) => 'assistant_chat_$userId';

  /// Les [maxSent] derniers messages, en commençant par un message du
  /// client (Gemini attend un premier tour « user »). Fonction pure.
  static List<Map<String, Object?>> recentHistory(
    List<Map<String, Object?>> history,
  ) {
    var start = history.length > maxSent ? history.length - maxSent : 0;
    while (start < history.length && history[start]['role'] != 'user') {
      start++;
    }
    return history.sublist(start);
  }

  // --- Avis 👍 / 👎 (soutenance : qualité des réponses) ---

  /// Journal global des avis, conservé même après « Nouvelle conversation ».
  static const _feedbackKey = 'assistant_feedback_log';
  static const _maxFeedback = 300;

  List<Map<String, Object?>> _feedbackLog = [];

  /// Nombre d'avis positifs / négatifs (tous utilisateurs de l'appareil).
  ({int up, int down}) get feedbackStats {
    final up = _feedbackLog.where((e) => e['liked'] == true).length;
    return (up: up, down: _feedbackLog.length - up);
  }

  /// 👍 / 👎 sur une réponse ; même pouce une 2e fois → avis retiré.
  Future<void> setFeedback(String messageId, bool liked) async {
    final index = _messages.indexWhere((m) => m.id == messageId);
    if (index == -1) return;
    final m = _messages[index];
    if (m.isUser || m.isError) return;
    final removing = m.liked == liked;
    _replace(
      messageId,
      (x) => removing ? x.copyWith(clearLiked: true) : x.copyWith(liked: liked),
    );

    // Question du client juste avant la réponse (contexte de l'avis).
    String? question;
    for (var i = index - 1; i >= 0; i--) {
      if (_messages[i].isUser) {
        question = _messages[i].text;
        break;
      }
    }
    String cut(String s, int max) =>
        s.length > max ? '${s.substring(0, max)}…' : s;

    _feedbackLog = [
      for (final e in _feedbackLog)
        if (e['messageId'] != messageId) e,
      if (!removing)
        {
          'messageId': messageId,
          'userId': _userId,
          'liked': liked,
          'date': DateTime.now().toIso8601String(),
          'question': question == null ? null : cut(question, 200),
          'answer': cut(m.text, 300),
        },
    ];
    if (_feedbackLog.length > _maxFeedback) {
      _feedbackLog = _feedbackLog.sublist(_feedbackLog.length - _maxFeedback);
    }
    debugPrint(
      '[Assistant] Avis ${removing ? 'retiré' : (liked ? '👍' : '👎')} '
      '— total 👍 ${feedbackStats.up} / 👎 ${feedbackStats.down}',
    );
    notifyListeners();
    await _save();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_feedbackKey, jsonEncode(_feedbackLog));
    } catch (e) {
      debugPrint('[Assistant] Avis non enregistré : $e');
    }
  }

  Future<void> _loadFeedback(SharedPreferences prefs) async {
    try {
      final raw = prefs.getString(_feedbackKey);
      _feedbackLog = raw == null
          ? []
          : [
              for (final e in jsonDecode(raw) as List)
                Map<String, Object?>.from(e as Map),
            ];
    } catch (e) {
      debugPrint('[Assistant] Journal des avis illisible : $e');
      _feedbackLog = [];
    }
  }

  /// Charge l'historique de [userId] ; `null` → conversation vidée.
  Future<void> loadFor(String? userId) async {
    if (userId == _userId) return;
    _userId = userId;
    _messages = [];
    _typing = false;
    if (userId != null) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await _loadFeedback(prefs);
        final raw = prefs.getString(_key(userId));
        if (raw != null && userId == _userId) {
          _messages = [
            for (final e in jsonDecode(raw) as List)
              ?ChatMessage.tryFromJson(Map<String, Object?>.from(e as Map)),
          ];
        }
      } catch (e) {
        debugPrint('[Assistant] Historique illisible : $e');
      }
    }
    notifyListeners();
  }

  /// Envoie [text] avec l'historique, le [context] du client et les
  /// fonctions. Erreur → message clair + bouton « Faire une réclamation ».
  Future<void> send(
    String text, {
    required AssistantContext context,
    required ChatStrings strings,
  }) async {
    final message = text.trim();
    if (message.isEmpty || _typing) return;

    _add(ChatRole.user, message);
    _typing = true;
    notifyListeners();

    final history = <Map<String, Object?>>[
      for (final m in _messages)
        if (!m.isError)
          {
            'role': m.isUser ? 'user' : 'model',
            'parts': [
              {'text': _historyText(m)},
            ],
          },
    ];
    final contents = recentHistory(history);
    final system = buildAssistantSystemPrompt(context);

    var answered = false;
    for (var round = 0; round < maxToolRounds && !answered; round++) {
      final turn = await _gemini.converse(
        systemInstruction: system,
        contents: contents,
        tools: AssistantTools.declarations,
      );

      if (turn.status != GeminiChatStatus.ok) {
        _addError(switch (turn.status) {
          GeminiChatStatus.offline => strings.offline,
          GeminiChatStatus.quotaExceeded => strings.quota,
          _ => strings.unavailable,
        });
        answered = true;
        break;
      }

      // Réponse finale (texte seul).
      if (turn.calls.isEmpty) {
        final reply = parseAssistantReply(turn.text);
        _add(
          ChatRole.assistant,
          reply.text,
          actions: reply.actions,
          complaintId: _complaintIdFor(reply.complaintRef, context),
        );
        answered = true;
        break;
      }

      // create_complaint valide : carte à confirmer, on s'arrête là.
      final draftCall = turn.calls
          .where((c) => c.name == AssistantTools.createComplaint)
          .firstOrNull;
      if (draftCall != null) {
        final parsed = parseComplaintDraft(
          draftCall.args,
          reservation: context.reservation,
        );
        if (parsed.draft != null) {
          final intro = parseAssistantReply(turn.text).text;
          _add(
            ChatRole.assistant,
            intro.isEmpty ? strings.draftIntro : intro,
            draft: parsed.draft,
          );
          debugPrint(
            '[Assistant] Réclamation proposée (non créée) : '
            '${parsed.draft!.category.name} / '
            '${parsed.draft!.effectivePriority.name}',
          );
          answered = true;
          break;
        }
        debugPrint('[Assistant] create_complaint refusée : ${parsed.error}');
      }

      // Fonctions de lecture (ou create_complaint invalide) : exécution
      // locale, résultat renvoyé à Gemini qui formulera la réponse.
      contents
        ..add(turn.modelContent!)
        ..add({
          'role': 'user',
          'parts': [
            for (final call in turn.calls)
              {
                'functionResponse': {
                  'name': call.name,
                  'id': ?call.id,
                  'response': _execute(call, context),
                },
              },
          ],
        });
    }

    if (!answered) {
      debugPrint('[Assistant] Trop d\'appels de fonctions sans réponse');
      _addError(strings.unavailable);
    }
    _typing = false;
    notifyListeners();
    await _save();
  }

  /// Exécute une fonction de lecture (jamais d'écriture ici).
  Map<String, Object?> _execute(
    GeminiFunctionCall call,
    AssistantContext context,
  ) {
    debugPrint('[Assistant] Fonction ${call.name}(${jsonEncode(call.args)})');
    switch (call.name) {
      case AssistantTools.getMyComplaints:
        return myComplaintsResult(context.complaints);
      case AssistantTools.getCurrentReservation:
        return currentReservationResult(context.reservation);
      case AssistantTools.createComplaint:
        final parsed = parseComplaintDraft(
          call.args,
          reservation: context.reservation,
        );
        return {
          'error': parsed.error ?? 'Arguments invalides',
          'hint': 'Demande les informations manquantes au client.',
        };
      default:
        return {'error': 'Fonction inconnue : ${call.name}'};
    }
  }

  /// Texte d'un message pour l'historique Gemini : la carte est résumée
  /// pour que l'assistant sache si elle a été confirmée.
  String _historyText(ChatMessage m) {
    final d = m.draft;
    if (d == null) return m.text;
    final state = switch (m.draftState) {
      DraftState.pending => 'en attente de confirmation du client',
      DraftState.confirmed => 'confirmée et créée par le client',
      DraftState.edited => 'ouverte dans le formulaire par le client',
    };
    return '${m.text}\n[Récapitulatif proposé : ${d.category.name}, '
        '${d.effectivePriority.name}, « ${d.title} » — $state]';
  }

  String? _complaintIdFor(String? reference, AssistantContext context) {
    if (reference == null) return null;
    for (final c in context.complaints) {
      if (c.reference.toUpperCase() == reference) return c.id;
    }
    return null;
  }

  /// [Confirmer] sur la carte [messageId] : [create] crée la réclamation
  /// (ComplaintProvider), puis « Réclamation REC-… créée ✓ » + « Voir le
  /// détail ». Une seule création par carte, même en double-tapant.
  Future<Complaint?> confirmDraft(
    String messageId, {
    required Future<Complaint?> Function(ComplaintDraft draft) create,
    required String Function(Complaint created) createdText,
  }) async {
    final index = _messages.indexWhere((m) => m.id == messageId);
    if (index == -1) return null;
    final message = _messages[index];
    final draft = message.draft;
    if (draft == null ||
        message.draftState != DraftState.pending ||
        !_confirming.add(messageId)) {
      return null;
    }
    notifyListeners();

    Complaint? created;
    try {
      created = await create(draft);
    } catch (e) {
      debugPrint('[Assistant] Création impossible : $e');
    }
    _confirming.remove(messageId);
    if (created != null) {
      _replace(messageId, (m) => m.copyWith(draftState: DraftState.confirmed));
      _add(
        ChatRole.assistant,
        createdText(created),
        actions: const [ChatAction.viewComplaint],
        complaintId: created.id,
      );
      await _save();
    }
    notifyListeners();
    return created;
  }

  /// [Modifier] : la carte passe « ouverte dans le formulaire ».
  Future<void> markDraftEdited(String messageId) async {
    _replace(messageId, (m) => m.copyWith(draftState: DraftState.edited));
    notifyListeners();
    await _save();
  }

  /// « Nouvelle conversation » : efface l'historique de l'utilisateur.
  Future<void> newConversation() async {
    if (_typing || _confirming.isNotEmpty) return;
    _messages = [];
    notifyListeners();
    await _save();
  }

  void _replace(String id, ChatMessage Function(ChatMessage) update) {
    _messages = [
      for (final m in _messages)
        if (m.id == id) update(m) else m,
    ];
  }

  void _addError(String text) => _add(
    ChatRole.assistant,
    text,
    actions: const [ChatAction.newComplaint],
    isError: true,
  );

  void _add(
    ChatRole role,
    String text, {
    List<ChatAction> actions = const [],
    bool isError = false,
    ComplaintDraft? draft,
    String? complaintId,
  }) {
    final now = DateTime.now();
    _messages = [
      ..._messages,
      ChatMessage(
        id: 'msg-${now.microsecondsSinceEpoch}',
        role: role,
        text: text,
        date: now,
        actions: actions,
        isError: isError,
        draft: draft,
        complaintId: complaintId,
      ),
    ];
    if (_messages.length > maxStored) {
      _messages = _messages.sublist(_messages.length - maxStored);
    }
  }

  Future<void> _save() async {
    final userId = _userId;
    if (userId == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_messages.isEmpty) {
        await prefs.remove(_key(userId));
      } else {
        await prefs.setString(
          _key(userId),
          jsonEncode([for (final m in _messages) m.toJson()]),
        );
      }
    } catch (e) {
      debugPrint('[Assistant] Historique non enregistré : $e');
    }
  }

  @override
  void dispose() {
    _gemini.dispose();
    super.dispose();
  }
}
