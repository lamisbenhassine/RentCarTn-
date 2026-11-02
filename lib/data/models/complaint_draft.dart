import 'complaint.dart';

/// Réclamation proposée par l'assistant, en attente de confirmation.
class ComplaintDraft {
  const ComplaintDraft({
    required this.category,
    required this.priority,
    required this.title,
    required this.description,
    this.isUrgent = false,
    this.reservationId,
    this.reservationLabel,
    this.carId,
    this.carLabel,
  });

  final ComplaintCategory category;
  final ComplaintPriority priority;
  final String title;
  final String description;
  final bool isUrgent;

  /// Réservation liée (en cours) et son libellé pour la carte.
  final String? reservationId;
  final String? reservationLabel;

  /// Véhicule du catalogue (réservation en cours ou choisi par le client
  /// parmi ses véhicules) et son libellé « Marque Modèle Année ».
  final String? carId;
  final String? carLabel;

  /// Urgente si Gemini le signale, quelle que soit la priorité proposée.
  ComplaintPriority get effectivePriority =>
      isUrgent ? ComplaintPriority.urgente : priority;

  Map<String, Object?> toJson() => {
    'category': category.name,
    'priority': priority.name,
    'title': title,
    'description': description,
    'isUrgent': isUrgent,
    'reservationId': reservationId,
    'reservationLabel': reservationLabel,
    'carId': carId,
    'carLabel': carLabel,
  };

  /// `null` si l'entrée enregistrée est illisible.
  static ComplaintDraft? tryFromJson(Map<String, Object?> json) {
    T? byName<T extends Enum>(List<T> values, Object? name) {
      for (final v in values) {
        if (v.name == name) return v;
      }
      return null;
    }

    final category = byName(ComplaintCategory.values, json['category']);
    final priority = byName(ComplaintPriority.values, json['priority']);
    if (category == null || priority == null) return null;
    return ComplaintDraft(
      category: category,
      priority: priority,
      title: '${json['title'] ?? ''}',
      description: '${json['description'] ?? ''}',
      isUrgent: json['isUrgent'] == true,
      reservationId: json['reservationId'] as String?,
      reservationLabel: json['reservationLabel'] as String?,
      carId: json['carId'] as String?,
      carLabel: json['carLabel'] as String?,
    );
  }
}
