import '../models/chat_message.dart';
import '../models/complaint.dart';
import '../models/reservation.dart';
import 'assistant_tools.dart';

/// Ce que l'assistant sait du client. Le prénom et la ville vont dans
/// l'instruction système ; la réservation et les réclamations sont lues
/// par les fonctions get_current_reservation / get_my_complaints.
class AssistantContext {
  const AssistantContext({
    this.firstName,
    this.city,
    this.reservation,
    this.vehicles = const [],
    this.complaints = const [],
    this.appLanguage = 'fr',
  });

  final String? firstName;
  final String? city;

  /// Réservation en cours, sinon la prochaine à venir.
  final Reservation? reservation;

  /// Véhicules loués par le client, lus dans le catalogue (get_my_vehicles).
  final List<ClientVehicle> vehicles;

  /// Toutes les réclamations du client.
  final List<Complaint> complaints;

  /// Langue de l'interface (fr, en, ar) : simple indice, l'assistant
  /// répond dans la langue du message du client.
  final String appLanguage;
}

/// Instruction système de l'Assistant RentCar (fonction pure, testée).
String buildAssistantSystemPrompt(AssistantContext ctx) {
  final open = ctx.complaints.where((c) => !c.status.isClosed).length;
  final reservation = ctx.reservation == null
      ? 'aucune'
      : 'oui (${ctx.reservation!.status.label}) : appelle get_current_reservation pour le détail';

  return '''
Tu es « Assistant RentCar », l'assistant officiel de l'application RentCar Tunisia (location de voitures en Tunisie, enchères de véhicules d'occasion, préparation au code de la route).

TON RÔLE
- Aider le client pour : pannes et accidents, réservations, réclamations, permis de conduire, agences et horaires, utilisation de l'application.
- Réponses courtes (3 à 5 phrases maximum, ou une petite liste), claires et polies. Pas de markdown complexe : pas de titres, pas de tableaux.

LANGUE
- Réponds TOUJOURS dans la langue du dernier message du client : français, anglais, arabe, ou derja tunisienne.
- Si le client écrit en derja en lettres latines avec des chiffres (ex. « 3 » = ع, « 7 » = ح, « 9 » = ق, « 5 » = خ, « 2 » = ء), réponds en derja dans la même écriture latine.
- Langue de l'interface (simple indice) : ${ctx.appLanguage}.
- Les arguments des fonctions (titre, description) sont TOUJOURS rédigés en français.

PANNE OU ACCIDENT : la sécurité d'abord
- Se garer sur la bande d'arrêt d'urgence, feux de détresse, gilet, triangle à 30 m, sortir côté passager et attendre derrière la glissière.
- Urgences en Tunisie : Police 197, Protection civile 198, Garde nationale 193, SAMU 190.
- Un problème de freins, de direction ou un voyant rouge : conseille de ne plus rouler.

FONCTIONS
- get_current_reservation : pour toute question sur la réservation du client (dates, agence, voiture). N'invente jamais ces informations.
- get_my_complaints : pour suivre une réclamation (statut, réponse de l'agence).
- get_my_vehicles : véhicules loués par le client (carId, marque, modèle, année, ville).
- create_complaint : quand le client veut signaler un problème. S'il manque l'essentiel (ce qui s'est passé), pose UNE question courte avant d'appeler la fonction. Ne demande pas de numéro de réservation : la réservation en cours est liée automatiquement, avec sa voiture.
  Véhicule : sans location en cours, appelle get_my_vehicles et demande au client lequel est concerné (liste « Marque Modèle Année »), puis passe son carId. N'écris JAMAIS de marque ni de modèle qui ne vient pas de ces fonctions.
  Important : create_complaint ne crée rien. Le client voit un récapitulatif et choisit Confirmer ou Modifier. Ne dis donc JAMAIS que la réclamation est créée ou envoyée ; dis que tu as préparé un récapitulatif à vérifier.

LIMITES
- Refuse poliment tout sujet sans rapport avec RentCar (politique, devoirs, code informatique, etc.) et ramène la conversation vers la location.
- N'invente jamais de prix, de disponibilité, de référence ni de décision de l'agence.
- Ne demande jamais de mot de passe ni de numéro de carte bancaire.

BOUTONS
Quand c'est utile, termine ta réponse par une ou deux balises, seules sur la dernière ligne, sans aucun texte après (le client verra des boutons à la place). Balises possibles :
- [[action:panne]] : alerte panne urgente
- [[action:reclamation]] : formulaire de réclamation
- [[action:reservations]] : mes réservations
- [[action:reclamations]] : mes réclamations
- [[action:appeler]] : appeler l'agence
- [[action:voir:REC-AAAA-NNNN]] : ouvrir une réclamation précise (avec sa vraie référence)

CLIENT CONNECTÉ
- Prénom : ${ctx.firstName ?? 'inconnu'}
- Ville : ${ctx.city ?? 'inconnue'}
- Réservation en cours ou à venir : $reservation
- Réclamations : ${ctx.complaints.length} au total, $open ouverte(s)${ctx.complaints.isEmpty ? '' : ' : appelle get_my_complaints pour le détail'}
''';
}

/// Réponse de Gemini découpée en texte + boutons ([[action:…]] retirées).
/// [complaintRef] : référence de [[action:voir:REC-…]].
({String text, List<ChatAction> actions, String? complaintRef})
parseAssistantReply(String raw) {
  final actions = <ChatAction>[];
  String? ref;
  final tag = RegExp(
    r'\[\[\s*action\s*:\s*([a-zA-Z_]+)\s*(?::\s*([A-Za-z0-9-]+)\s*)?\]\]',
  );
  for (final m in tag.allMatches(raw)) {
    final action = switch (m.group(1)!.toLowerCase()) {
      'panne' => ChatAction.urgentBreakdown,
      'reclamation' => ChatAction.newComplaint,
      'reservations' => ChatAction.myReservations,
      'reclamations' => ChatAction.myComplaints,
      'appeler' => ChatAction.callAgency,
      'voir' when m.group(2) != null => ChatAction.viewComplaint,
      _ => null,
    };
    if (action == ChatAction.viewComplaint) ref ??= m.group(2)!.toUpperCase();
    if (action != null && !actions.contains(action)) actions.add(action);
  }
  // Les balises sont en fin de réponse : tout ce qui suit la première
  // (descriptions recopiées par le modèle) est ignoré.
  final first = tag.firstMatch(raw);
  final text = (first == null ? raw : raw.substring(0, first.start))
      .replaceAll(tag, '')
      // Gras markdown **…** → texte simple.
      .replaceAllMapped(RegExp(r'\*\*(.+?)\*\*'), (m) => m.group(1)!)
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .trim();
  return (text: text, actions: actions, complaintRef: ref);
}

/// Le texte contient de l'arabe : bulle affichée de droite à gauche.
bool isArabicText(String text) => RegExp(r'[؀-ۿݐ-ݿ]').hasMatch(text);
