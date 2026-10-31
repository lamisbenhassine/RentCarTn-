/// Petite question à choix unique pour la recommandation IA.
class RecommendQuestion {
  const RecommendQuestion({
    required this.id,
    required this.title,
    required this.options,
  });

  final String id;
  final String title;
  final List<RecommendOption> options;
}

class RecommendOption {
  const RecommendOption({
    required this.id,
    required this.label,
  });

  final String id;
  final String label;
}

/// Questionnaire fixe (réponses déjà prêtes — l'utilisateur coche seulement).
abstract final class RecommendQuizCatalog {
  static const List<RecommendQuestion> questions = [
    RecommendQuestion(
      id: 'usage',
      title: 'À quoi servira la voiture ?',
      options: [
        RecommendOption(id: 'ville', label: 'Déplacements en ville'),
        RecommendOption(id: 'voyage', label: 'Voyage / week-end'),
        RecommendOption(id: 'travail', label: 'Travail / pro'),
        RecommendOption(id: 'famille', label: 'Sortie en famille'),
      ],
    ),
    RecommendQuestion(
      id: 'route',
      title: 'Quel type de route ?',
      options: [
        RecommendOption(id: 'urbaine', label: 'Urbaine (ville)'),
        RecommendOption(id: 'autoroute', label: 'Autoroute'),
        RecommendOption(id: 'mixte', label: 'Mixte'),
        RecommendOption(id: 'montagne', label: 'Montagne / routes difficiles'),
      ],
    ),
    RecommendQuestion(
      id: 'duree',
      title: 'Pour combien de temps ?',
      options: [
        RecommendOption(id: 'weekend', label: '1–3 jours'),
        RecommendOption(id: 'semaine', label: 'Une semaine'),
        RecommendOption(id: 'long', label: 'Plus d\'une semaine'),
      ],
    ),
    RecommendQuestion(
      id: 'passagers',
      title: 'Combien de passagers ?',
      options: [
        RecommendOption(id: 'solo', label: '1–2 personnes'),
        RecommendOption(id: 'moyen', label: '3–4 personnes'),
        RecommendOption(id: 'groupe', label: '5 personnes ou plus'),
      ],
    ),
    RecommendQuestion(
      id: 'budget',
      title: 'Quel budget par jour ?',
      options: [
        RecommendOption(id: 'eco', label: 'Économique'),
        RecommendOption(id: 'moyen', label: 'Moyen'),
        RecommendOption(id: 'premium', label: 'Confort / premium'),
      ],
    ),
  ];
}
