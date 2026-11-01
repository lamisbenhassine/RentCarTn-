import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

// -----------------------------------------------------------------------------
// Énumérations + libellés / couleurs / icônes
// -----------------------------------------------------------------------------

enum ComplaintCategory {
  panne,
  proprete,
  retardAgence,
  facturation,
  enchere,
  autre,
}

extension ComplaintCategoryX on ComplaintCategory {
  String get label => switch (this) {
    ComplaintCategory.panne => 'Panne du véhicule',
    ComplaintCategory.proprete => 'Propreté',
    ComplaintCategory.retardAgence => 'Retard de l\'agence',
    ComplaintCategory.facturation => 'Facturation',
    ComplaintCategory.enchere => 'Enchère',
    ComplaintCategory.autre => 'Autre',
  };

  IconData get icon => switch (this) {
    ComplaintCategory.panne => Icons.car_crash_rounded,
    ComplaintCategory.proprete => Icons.cleaning_services_rounded,
    ComplaintCategory.retardAgence => Icons.schedule_rounded,
    ComplaintCategory.facturation => Icons.receipt_long_rounded,
    ComplaintCategory.enchere => Icons.gavel_rounded,
    ComplaintCategory.autre => Icons.help_outline_rounded,
  };

  Color get color => switch (this) {
    ComplaintCategory.panne => AppColors.danger,
    ComplaintCategory.proprete => AppColors.info,
    ComplaintCategory.retardAgence => AppColors.warning,
    ComplaintCategory.facturation => AppColors.accent,
    ComplaintCategory.enchere => AppColors.gold,
    ComplaintCategory.autre => AppColors.textSecondary,
  };
}

enum ComplaintPriority { basse, moyenne, urgente }

extension ComplaintPriorityX on ComplaintPriority {
  String get label => switch (this) {
    ComplaintPriority.basse => 'Basse',
    ComplaintPriority.moyenne => 'Moyenne',
    ComplaintPriority.urgente => 'Urgente',
  };

  IconData get icon => switch (this) {
    ComplaintPriority.basse => Icons.arrow_downward_rounded,
    ComplaintPriority.moyenne => Icons.drag_handle_rounded,
    ComplaintPriority.urgente => Icons.priority_high_rounded,
  };

  Color get color => switch (this) {
    ComplaintPriority.basse => AppColors.success,
    ComplaintPriority.moyenne => AppColors.warning,
    ComplaintPriority.urgente => AppColors.danger,
  };
}

enum ComplaintStatus { enAttente, enCours, resolue, rejetee }

extension ComplaintStatusX on ComplaintStatus {
  String get label => switch (this) {
    ComplaintStatus.enAttente => 'En attente',
    ComplaintStatus.enCours => 'En cours',
    ComplaintStatus.resolue => 'Résolue',
    ComplaintStatus.rejetee => 'Rejetée',
  };

  IconData get icon => switch (this) {
    ComplaintStatus.enAttente => Icons.hourglass_top_rounded,
    ComplaintStatus.enCours => Icons.autorenew_rounded,
    ComplaintStatus.resolue => Icons.check_circle_rounded,
    ComplaintStatus.rejetee => Icons.cancel_rounded,
  };

  Color get color => switch (this) {
    ComplaintStatus.enAttente => AppColors.warning,
    ComplaintStatus.enCours => AppColors.info,
    ComplaintStatus.resolue => AppColors.success,
    ComplaintStatus.rejetee => AppColors.danger,
  };

  /// Dossier clos : plus de modification possible côté client.
  bool get isClosed =>
      this == ComplaintStatus.resolue || this == ComplaintStatus.rejetee;
}

/// Ton du client, estimé par l'IA (Gemini).
enum ComplaintTone { calme, mecontent, tresMecontent }

extension ComplaintToneX on ComplaintTone {
  IconData get icon => switch (this) {
    ComplaintTone.calme => Icons.sentiment_satisfied_rounded,
    ComplaintTone.mecontent => Icons.sentiment_dissatisfied_rounded,
    ComplaintTone.tresMecontent => Icons.sentiment_very_dissatisfied_rounded,
  };

  Color get color => switch (this) {
    ComplaintTone.calme => AppColors.success,
    ComplaintTone.mecontent => AppColors.warning,
    ComplaintTone.tresMecontent => AppColors.danger,
  };
}

extension ComplaintPriorityLevel on ComplaintPriority {
  /// Niveau suivant (urgente reste urgente).
  ComplaintPriority get raised => switch (this) {
    ComplaintPriority.basse => ComplaintPriority.moyenne,
    _ => ComplaintPriority.urgente,
  };
}

// -----------------------------------------------------------------------------
// Historique
// -----------------------------------------------------------------------------

/// Étape du suivi (« Réclamation envoyée », « Prise en charge »…).
class ComplaintEvent {
  const ComplaintEvent({
    required this.status,
    required this.date,
    required this.message,
  });

  final ComplaintStatus status;
  final DateTime date;
  final String message;

  Map<String, Object?> toJson() => {
    'status': status.name,
    'date': date.toIso8601String(),
    'message': message,
  };

  factory ComplaintEvent.fromJson(Map<String, Object?> json) => ComplaintEvent(
    status: _enumByName(
      ComplaintStatus.values,
      json['status'],
      ComplaintStatus.enAttente,
    ),
    date: DateTime.tryParse('${json['date']}') ?? DateTime.now(),
    message: (json['message'] as String?) ?? '',
  );
}

// -----------------------------------------------------------------------------
// Réclamation
// -----------------------------------------------------------------------------

class Complaint {
  const Complaint({
    required this.id,
    required this.reference,
    required this.userId,
    required this.category,
    required this.title,
    required this.description,
    required this.priority,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.reservationId,
    this.auctionId,
    this.carLabel,
    this.agency,
    this.photoPaths = const [],
    this.latitude,
    this.longitude,
    this.locationAddress,
    this.isUrgent = false,
    this.agencyResponse,
    this.history = const [],
    this.rating,
    this.ratingComment,
    this.abusive = false,
    this.aiSummary,
    this.aiTone,
  });

  final String id;

  /// Référence lisible : REC-AAAA-NNNN (voir [ComplaintReference]).
  final String reference;
  final String userId;
  final ComplaintCategory category;
  final String title;
  final String description;
  final ComplaintPriority priority;
  final ComplaintStatus status;

  /// Réservation ou enchère concernée (facultatif).
  final String? reservationId;
  final String? auctionId;

  /// « Peugeot 208 », copié à la création (la réservation peut disparaître).
  final String? carLabel;
  final String? agency;

  /// Photos jointes (chemins locaux ou data URL).
  final List<String> photoPaths;
  final double? latitude;
  final double? longitude;

  /// Adresse lisible de la position (Nominatim), si elle a pu être trouvée.
  final String? locationAddress;
  final bool isUrgent;

  /// Réponse de l'agence (back office).
  final String? agencyResponse;
  final List<ComplaintEvent> history;

  /// Note de satisfaction 1 à 5, une fois la réclamation close.
  final int? rating;
  final String? ratingComment;

  /// Rejetée par l'agence comme abusive : -10 sur le score de confiance
  /// du client (voir ComplaintTrustService).
  final bool abusive;

  /// Analyse IA (Gemini) au moment de l'envoi : résumé en une phrase et ton.
  final String? aiSummary;
  final ComplaintTone? aiTone;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get hasLocation => latitude != null && longitude != null;
  bool get canEdit => status == ComplaintStatus.enAttente;

  /// Note de satisfaction : seulement après une résolution, une fois.
  bool get canRate => status == ComplaintStatus.resolue && rating == null;

  /// Client insatisfait (1 ou 2 étoiles) : il peut rouvrir la réclamation.
  bool get canReopen =>
      status == ComplaintStatus.resolue && rating != null && rating! <= 2;

  Complaint copyWith({
    ComplaintCategory? category,
    String? title,
    String? description,
    ComplaintPriority? priority,
    ComplaintStatus? status,
    String? reservationId,
    String? auctionId,
    String? carLabel,
    String? agency,
    List<String>? photoPaths,
    double? latitude,
    double? longitude,
    String? locationAddress,
    bool? isUrgent,
    String? agencyResponse,
    List<ComplaintEvent>? history,
    int? rating,
    String? ratingComment,
    bool? abusive,
    String? aiSummary,
    ComplaintTone? aiTone,
    DateTime? updatedAt,

    /// Efface la note (réclamation rouverte : nouvelle note après la
    /// prochaine résolution).
    bool clearRating = false,
  }) {
    return Complaint(
      id: id,
      reference: reference,
      userId: userId,
      category: category ?? this.category,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      reservationId: reservationId ?? this.reservationId,
      auctionId: auctionId ?? this.auctionId,
      carLabel: carLabel ?? this.carLabel,
      agency: agency ?? this.agency,
      photoPaths: photoPaths ?? this.photoPaths,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationAddress: locationAddress ?? this.locationAddress,
      isUrgent: isUrgent ?? this.isUrgent,
      agencyResponse: agencyResponse ?? this.agencyResponse,
      history: history ?? this.history,
      rating: clearRating ? null : (rating ?? this.rating),
      ratingComment: clearRating ? null : (ratingComment ?? this.ratingComment),
      abusive: abusive ?? this.abusive,
      aiSummary: aiSummary ?? this.aiSummary,
      aiTone: aiTone ?? this.aiTone,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Ajoute une étape au suivi et passe au [status] donné.
  Complaint withEvent(ComplaintStatus status, String message, {DateTime? at}) {
    final when = at ?? DateTime.now();
    return copyWith(
      status: status,
      history: [
        ...history,
        ComplaintEvent(status: status, date: when, message: message),
      ],
      updatedAt: when,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'reference': reference,
    'userId': userId,
    'category': category.name,
    'title': title,
    'description': description,
    'priority': priority.name,
    'status': status.name,
    'reservationId': reservationId,
    'auctionId': auctionId,
    'carLabel': carLabel,
    'agency': agency,
    'photoPaths': photoPaths,
    'latitude': latitude,
    'longitude': longitude,
    'locationAddress': locationAddress,
    'isUrgent': isUrgent,
    'agencyResponse': agencyResponse,
    'history': history.map((e) => e.toJson()).toList(),
    'rating': rating,
    'ratingComment': ratingComment,
    'abusive': abusive,
    'aiSummary': aiSummary,
    'aiTone': aiTone?.name,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory Complaint.fromJson(Map<String, Object?> json) {
    final created = DateTime.tryParse('${json['createdAt']}') ?? DateTime.now();
    return Complaint(
      id: json['id']! as String,
      reference: (json['reference'] as String?) ?? '',
      userId: (json['userId'] as String?) ?? '',
      category: _enumByName(
        ComplaintCategory.values,
        json['category'],
        ComplaintCategory.autre,
      ),
      title: (json['title'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      priority: _enumByName(
        ComplaintPriority.values,
        json['priority'],
        ComplaintPriority.moyenne,
      ),
      status: _enumByName(
        ComplaintStatus.values,
        json['status'],
        ComplaintStatus.enAttente,
      ),
      reservationId: json['reservationId'] as String?,
      auctionId: json['auctionId'] as String?,
      carLabel: json['carLabel'] as String?,
      agency: json['agency'] as String?,
      photoPaths: [
        for (final p in (json['photoPaths'] as List?) ?? const []) '$p',
      ],
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      locationAddress: json['locationAddress'] as String?,
      isUrgent: json['isUrgent'] == true,
      agencyResponse: json['agencyResponse'] as String?,
      history: [
        for (final e in (json['history'] as List?) ?? const [])
          ComplaintEvent.fromJson(Map<String, Object?>.from(e as Map)),
      ],
      rating: (json['rating'] as num?)?.toInt(),
      ratingComment: json['ratingComment'] as String?,
      abusive: json['abusive'] == true,
      aiSummary: json['aiSummary'] as String?,
      aiTone: json['aiTone'] == null
          ? null
          : _enumByName(
              ComplaintTone.values,
              json['aiTone'],
              ComplaintTone.calme,
            ),
      createdAt: created,
      updatedAt: DateTime.tryParse('${json['updatedAt']}') ?? created,
    );
  }
}

/// Valeur d'énumération depuis son nom, avec valeur de secours (données
/// anciennes ou corrompues).
T _enumByName<T extends Enum>(List<T> values, Object? name, T fallback) {
  for (final v in values) {
    if (v.name == name) return v;
  }
  return fallback;
}

// -----------------------------------------------------------------------------
// Référence REC-AAAA-NNNN
// -----------------------------------------------------------------------------

/// Génère les références lisibles : REC-2026-0001, REC-2026-0002…
/// Le compteur repart à 0001 chaque année. Fonction pure (testée).
abstract final class ComplaintReference {
  static final RegExp _pattern = RegExp(r'^REC-(\d{4})-(\d{4,})$');

  /// Prochaine référence pour l'année de [now], d'après les références
  /// déjà utilisées ([existing], toutes années confondues).
  static String next(Iterable<String> existing, DateTime now) {
    final year = now.year;
    var max = 0;
    for (final ref in existing) {
      final m = _pattern.firstMatch(ref);
      if (m == null || int.parse(m.group(1)!) != year) continue;
      final n = int.parse(m.group(2)!);
      if (n > max) max = n;
    }
    return format(year, max + 1);
  }

  static String format(int year, int number) =>
      'REC-$year-${number.toString().padLeft(4, '0')}';

  /// Préfixe de l'année (pour une recherche SQL `LIKE 'REC-2026-%'`).
  static String yearPrefix(int year) => 'REC-$year-';
}
