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

  RoadSign copyWith({
    String? id,
    String? name,
    SignCategory? category,
    SignShape? shape,
    String? meaning,
    String? advice,
    String? glyph,
    ContentTrust? trust,
  }) {
    return RoadSign(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      shape: shape ?? this.shape,
      meaning: meaning ?? this.meaning,
      advice: advice ?? this.advice,
      glyph: glyph ?? this.glyph,
      trust: trust ?? this.trust,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'category': category.name,
        'shape': shape.name,
        'meaning': meaning,
        'advice': advice,
        'glyph': glyph,
        'trust': trust.name,
      };

  factory RoadSign.fromMap(Map<String, Object?> map) {
    return RoadSign(
      id: map['id']! as String,
      name: map['name']! as String,
      category: SignCategory.values.byName(map['category']! as String),
      shape: SignShape.values.byName(map['shape']! as String),
      meaning: map['meaning']! as String,
      advice: map['advice']! as String,
      glyph: map['glyph']! as String,
      trust: ContentTrust.values.byName(
        (map['trust'] as String?) ?? ContentTrust.aVerifier.name,
      ),
    );
  }
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
    this.passingPercent = 70,
  });

  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final List<QuizQuestion> questions;
  final bool isFinalTest;

  /// Seuil de réussite en pourcentage (ex. 70).
  final int passingPercent;

  int get questionCount => questions.length;

  /// Nombre minimum de bonnes réponses pour réussir.
  int get passingScore =>
      (questionCount * (passingPercent.clamp(1, 100) / 100)).ceil();
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
