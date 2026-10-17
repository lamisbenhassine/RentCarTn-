import 'package:flutter/material.dart';

/// Fiabilité de l'information pédagogique affichée.
/// Le module sépare explicitement les règles à vérifier des exemples.
enum ContentTrust {
  /// Règle générale à confronter au Code de la route tunisien en vigueur.
  aVerifier,

  /// Contenu purement illustratif créé pour la démonstration.
  illustratif,
}

extension ContentTrustX on ContentTrust {
  String get label => switch (this) {
    ContentTrust.aVerifier => 'À vérifier auprès des textes officiels',
    ContentTrust.illustratif => 'Exemple illustratif (démo)',
  };
}

enum SignCategory { danger, interdiction, obligation, indication, priorite }

extension SignCategoryX on SignCategory {
  String get label => switch (this) {
    SignCategory.danger => 'Panneaux de danger',
    SignCategory.interdiction => 'Panneaux d’interdiction',
    SignCategory.obligation => 'Panneaux d’obligation',
    SignCategory.indication => 'Panneaux d’indication',
    SignCategory.priorite => 'Panneaux de priorité',
  };

  String get shortLabel => switch (this) {
    SignCategory.danger => 'Danger',
    SignCategory.interdiction => 'Interdiction',
    SignCategory.obligation => 'Obligation',
    SignCategory.indication => 'Indication',
    SignCategory.priorite => 'Priorité',
  };

  Color get color => switch (this) {
    SignCategory.danger => const Color(0xFFDC2626),
    SignCategory.interdiction => const Color(0xFFB91C1C),
    SignCategory.obligation => const Color(0xFF2563EB),
    SignCategory.indication => const Color(0xFF0F766E),
    SignCategory.priorite => const Color(0xFFD97706),
  };
}

/// Forme géométrique dessinée pour illustrer le panneau (aucun asset requis).
enum SignShape { triangle, cercle, carre, octogone, losange }

class RoadSign {
  const RoadSign({
    required this.id,
    required this.name,
    required this.category,
    required this.shape,
    required this.meaning,
    required this.advice,
    required this.glyph,
    this.trust = ContentTrust.aVerifier,
  });

  final String id;
  final String name;
  final SignCategory category;
  final SignShape shape;
  final String meaning;
  final String advice;

  /// Symbole textuel ou icône dessinée au centre du panneau.
  final String glyph;
  final ContentTrust trust;
}

class RuleSection {
  const RuleSection({
    required this.id,
    required this.title,
    required this.icon,
    required this.summary,
    required this.points,
    this.trust = ContentTrust.aVerifier,
  });

  final String id;
  final String title;
  final IconData icon;
  final String summary;
  final List<String> points;
  final ContentTrust trust;
}

class QuizQuestion {
  const QuizQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
    this.trust = ContentTrust.aVerifier,
  });

  final String id;
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;
  final ContentTrust trust;

  bool isCorrect(int index) => index == correctIndex;
}

class Quiz {
  const Quiz({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.questions,
    this.isFinalTest = false,
  });

  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final List<QuizQuestion> questions;
  final bool isFinalTest;

  int get questionCount => questions.length;

  /// Seuil de réussite affiché à l'utilisateur.
  int get passingScore => (questionCount * 0.7).ceil();
}

/// Résultat conservé localement pour le suivi de progression.
class QuizResult {
  const QuizResult({
    required this.quizId,
    required this.score,
    required this.total,
    required this.date,
    required this.answers,
  });

  final String quizId;
  final int score;
  final int total;
  final DateTime date;

  /// Index de la réponse choisie pour chaque question (-1 = non répondue).
  final List<int> answers;

  double get ratio => total == 0 ? 0 : score / total;
  int get percent => (ratio * 100).round();
  bool get passed => ratio >= 0.7;
}
