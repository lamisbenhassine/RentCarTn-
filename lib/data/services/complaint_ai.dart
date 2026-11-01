import 'dart:convert';

import '../models/complaint.dart';

/// Résultat de l'analyse Gemini d'une réclamation.
class ComplaintAiAnalysis {
  const ComplaintAiAnalysis({
    required this.category,
    required this.priority,
    required this.tone,
    required this.summary,
  });

  final ComplaintCategory category;

  /// Priorité proposée par Gemini (avant ajustement selon le ton).
  final ComplaintPriority priority;
  final ComplaintTone tone;

  /// Résumé en une phrase.
  final String summary;

  /// Client très mécontent → la priorité monte d'un niveau.
  bool get priorityRaised =>
      tone == ComplaintTone.tresMecontent &&
      priority != ComplaintPriority.urgente;

  /// Priorité finale suggérée au client.
  ComplaintPriority get suggestedPriority =>
      tone == ComplaintTone.tresMecontent ? priority.raised : priority;
}

/// Prompt Gemini (en français) : réponse JSON stricte uniquement.
String buildComplaintAnalysisPrompt({
  required String title,
  required String description,
}) {
  return '''
Tu es l'assistant du service client de RentCar Tunisia (location de voitures et enchères de véhicules d'occasion).
Analyse la réclamation d'un client et réponds UNIQUEMENT avec un objet JSON valide, sans texte autour, sans markdown, avec exactement ces clés :

{
  "category": "panne" | "proprete" | "retardAgence" | "facturation" | "enchere" | "autre",
  "priority": "basse" | "moyenne" | "urgente",
  "tone": "calme" | "mecontent" | "tresMecontent",
  "summary": "résumé neutre en une seule phrase, en français, 25 mots maximum"
}

Règles :
- "panne" : véhicule en panne, accident, crevaison, voyant, ne démarre pas.
- "proprete" : véhicule sale, odeur, tâches. "retardAgence" : attente, agence fermée, retard de livraison.
- "facturation" : montant, caution, remboursement, double paiement. "enchere" : offres, enchères, adjudication.
- "urgente" : client bloqué ou en danger (panne sur la route, accident), ou véhicule inutilisable maintenant.
- "basse" : simple remarque ou suggestion sans gêne immédiate. Sinon "moyenne".
- Le ton se juge sur les mots du client (insultes, majuscules, menaces, « inadmissible » → "tresMecontent").

Titre : ${jsonEncode(title.trim())}
Description : ${jsonEncode(description.trim())}
''';
}

/// Lit la réponse de Gemini (tolère les fences ```json et le texte autour).
/// Retourne `null` si la réponse est inutilisable. Fonction pure (testée).
ComplaintAiAnalysis? parseComplaintAnalysis(String raw) {
  var text = raw.trim();
  if (text.startsWith('```')) {
    text = text
        .replaceFirst(RegExp(r'^```(?:json)?\s*'), '')
        .replaceFirst(RegExp(r'\s*```$'), '')
        .trim();
  }
  final start = text.indexOf('{');
  final end = text.lastIndexOf('}');
  if (start == -1 || end <= start) return null;

  try {
    final map = jsonDecode(text.substring(start, end + 1));
    if (map is! Map<String, dynamic>) return null;

    final category = parseComplaintCategory(map['category']);
    final priority = parseComplaintPriority(map['priority']);
    final tone = _tone(map['tone']);
    final summary = (map['summary'] as String?)?.trim() ?? '';
    if (category == null || priority == null || tone == null) return null;

    return ComplaintAiAnalysis(
      category: category,
      priority: priority,
      tone: tone,
      summary: summary,
    );
  } catch (_) {
    return null;
  }
}

/// Normalise : minuscules, sans accents ni espaces / tirets / underscores.
String _norm(Object? v) => '$v'
    .toLowerCase()
    .replaceAll(RegExp('[éèêë]'), 'e')
    .replaceAll(RegExp('[àâ]'), 'a')
    .replaceAll(RegExp(r'[\s_\-]'), '');

/// Catégorie depuis un texte libre (accents / casse tolérés), `null` sinon.
ComplaintCategory? parseComplaintCategory(Object? v) => switch (_norm(v)) {
  'panne' => ComplaintCategory.panne,
  'proprete' => ComplaintCategory.proprete,
  'retardagence' || 'retard' => ComplaintCategory.retardAgence,
  'facturation' => ComplaintCategory.facturation,
  'enchere' || 'encheres' => ComplaintCategory.enchere,
  'autre' => ComplaintCategory.autre,
  _ => null,
};

/// Priorité depuis un texte libre, `null` sinon.
ComplaintPriority? parseComplaintPriority(Object? v) => switch (_norm(v)) {
  'basse' || 'faible' => ComplaintPriority.basse,
  'moyenne' || 'normale' => ComplaintPriority.moyenne,
  'urgente' || 'haute' => ComplaintPriority.urgente,
  _ => null,
};

ComplaintTone? _tone(Object? v) => switch (_norm(v)) {
  'calme' => ComplaintTone.calme,
  'mecontent' => ComplaintTone.mecontent,
  'tresmecontent' => ComplaintTone.tresMecontent,
  _ => null,
};

// -----------------------------------------------------------------------------
// « Améliorer mon message »
// -----------------------------------------------------------------------------

/// Longueur maximale de la description (identique au formulaire).
const complaintDescriptionMax = 1000;

/// Prompt de reformulation : français clair et poli, sans inventer de faits.
String buildComplaintRewritePrompt({
  required String title,
  required String description,
}) {
  return '''
Tu aides un client de RentCar Tunisia à rédiger sa réclamation.
Reformule la description en français clair, poli et factuel.

Règles strictes :
- N'invente AUCUN fait, date, montant, lieu ou nom absent du texte d'origine.
- Garde toutes les informations utiles (dates, montants, références, lieux).
- Retire les insultes, les majuscules excessives et les répétitions.
- Reste à la première personne, 900 caractères maximum, sans formule d'introduction.
- Réponds UNIQUEMENT avec ce JSON, sans markdown : {"text": "description reformulée"}

Titre : ${jsonEncode(title.trim())}
Description d'origine : ${jsonEncode(description.trim())}
''';
}

/// Texte reformulé, ou `null` si la réponse est inutilisable.
String? parseComplaintRewrite(String raw) {
  final map = _jsonObject(raw);
  final text = (map?['text'] as Object?)?.toString().trim() ?? '';
  if (text.length < 10) return null;
  return text.length > complaintDescriptionMax
      ? text.substring(0, complaintDescriptionMax).trim()
      : text;
}

// -----------------------------------------------------------------------------
// « Avant d'envoyer, avez-vous essayé ? »
// -----------------------------------------------------------------------------

/// Prompt des solutions rapides (1 à 3), selon la catégorie et le texte.
String buildQuickFixesPrompt({
  required ComplaintCategory category,
  required String title,
  required String description,
}) {
  return '''
Tu es l'assistant du service client de RentCar Tunisia (location de voitures et enchères).
Avant qu'un client envoie sa réclamation, propose de 1 à 3 solutions rapides qu'il peut essayer seul, tout de suite.

Règles :
- Chaque solution : une phrase courte, concrète, en français, 20 mots maximum.
- Uniquement des gestes simples et sans danger (vérifier, redémarrer, consulter l'application ou le contrat).
  Exemples : clé perdue → vérifier la boîte à gants / le double remis au contrat ;
  voyant allumé → consulter le manuel dans la boîte à gants, vérifier le bouchon du réservoir.
- Jamais de réparation mécanique, jamais d'action dangereuse sur la route.
- Si aucune solution rapide n'a de sens (litige de facturation, réclamation déjà détaillée…),
  renvoie une liste vide.
- Réponds UNIQUEMENT avec ce JSON, sans markdown : {"solutions": ["…", "…"]}

Catégorie : ${category.name}
Titre : ${jsonEncode(title.trim())}
Description : ${jsonEncode(description.trim())}
''';
}

/// 0 à 3 solutions (vide si la réponse est inutilisable).
List<String> parseQuickFixes(String raw) {
  final list = _jsonObject(raw)?['solutions'];
  if (list is! List) return const [];
  return list
      .map((e) => '$e'.trim())
      .where((s) => s.isNotEmpty)
      .take(3)
      .toList();
}

/// Premier objet JSON de la réponse (tolère les fences ```json).
Map<String, dynamic>? _jsonObject(String raw) {
  final text = raw.trim();
  final start = text.indexOf('{');
  final end = text.lastIndexOf('}');
  if (start == -1 || end <= start) return null;
  try {
    final map = jsonDecode(text.substring(start, end + 1));
    return map is Map<String, dynamic> ? map : null;
  } catch (_) {
    return null;
  }
}
