import 'complaint_draft.dart';

/// Auteur d'un message de l'Assistant RentCar.
enum ChatRole { user, assistant }

/// Raccourci proposé sous une réponse (bouton qui ouvre un écran).
enum ChatAction {
  /// Formulaire de réclamation classique.
  newComplaint,

  /// Alerte « Panne urgente » en 2 clics.
  urgentBreakdown,

  /// Mes réservations.
  myReservations,

  /// Mes réclamations (suivi).
  myComplaints,

  /// Détail d'une réclamation ([ChatMessage.complaintId]).
  viewComplaint,

  /// Appeler l'agence.
  callAgency,
}

/// État de la carte « réclamation proposée » par l'assistant.
enum DraftState {
  /// En attente : boutons [Confirmer] et [Modifier].
  pending,

  /// Créée après confirmation du client.
  confirmed,

  /// Ouverte dans le formulaire classique (le client finit lui-même).
  edited,
}

/// Un message du chat (enregistré par utilisateur dans shared_preferences).
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.date,
    this.actions = const [],
    this.isError = false,
    this.draft,
    this.draftState = DraftState.pending,
    this.complaintId,
    this.liked,
  });

  final String id;
  final ChatRole role;
  final String text;
  final DateTime date;
  final List<ChatAction> actions;

  /// Message d'erreur local (pas d'internet, Gemini indisponible) :
  /// jamais renvoyé à Gemini dans l'historique.
  final bool isError;

  /// Réclamation proposée par create_complaint (jamais créée sans
  /// confirmation du client).
  final ComplaintDraft? draft;
  final DraftState draftState;

  /// Réclamation concernée (bouton « Voir le détail »).
  final String? complaintId;

  /// Avis du client sur une réponse : 👍 `true`, 👎 `false`, sinon `null`.
  final bool? liked;

  bool get isUser => role == ChatRole.user;

  /// [clearLiked] : retire l'avis (deuxième appui sur le même pouce).
  ChatMessage copyWith({
    DraftState? draftState,
    bool? liked,
    bool clearLiked = false,
  }) => ChatMessage(
    id: id,
    role: role,
    text: text,
    date: date,
    actions: actions,
    isError: isError,
    draft: draft,
    draftState: draftState ?? this.draftState,
    complaintId: complaintId,
    liked: clearLiked ? null : (liked ?? this.liked),
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'role': role.name,
    'text': text,
    'date': date.toIso8601String(),
    'actions': [for (final a in actions) a.name],
    'isError': isError,
    if (draft != null) 'draft': draft!.toJson(),
    'draftState': draftState.name,
    'complaintId': complaintId,
    'liked': liked,
  };

  /// `null` si l'entrée est illisible (données anciennes ou corrompues).
  static ChatMessage? tryFromJson(Map<String, Object?> json) {
    try {
      final draft = json['draft'];
      return ChatMessage(
        id: json['id']! as String,
        role: ChatRole.values.byName(json['role']! as String),
        text: json['text']! as String,
        date: DateTime.parse(json['date']! as String),
        actions: [
          for (final name in (json['actions'] as List?) ?? const [])
            ...ChatAction.values.where((a) => a.name == name),
        ],
        isError: json['isError'] == true,
        draft: draft is Map
            ? ComplaintDraft.tryFromJson(Map<String, Object?>.from(draft))
            : null,
        draftState:
            DraftState.values
                .where((s) => s.name == json['draftState'])
                .firstOrNull ??
            DraftState.pending,
        complaintId: json['complaintId'] as String?,
        liked: json['liked'] as bool?,
      );
    } catch (_) {
      return null;
    }
  }
}
