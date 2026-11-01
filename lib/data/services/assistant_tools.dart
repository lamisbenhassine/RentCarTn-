import '../models/complaint.dart';
import '../models/complaint_draft.dart';
import '../models/reservation.dart';
import 'complaint_ai.dart';

/// Noms des fonctions exposées à Gemini (function calling).
abstract final class AssistantTools {
  static const createComplaint = 'create_complaint';
  static const getMyComplaints = 'get_my_complaints';
  static const getCurrentReservation = 'get_current_reservation';

  /// `tools` de la requête generateContent. Catégories et priorités =
  /// noms exacts des enums de complaint.dart.
  static List<Map<String, Object?>> get declarations => [
    {
      'functionDeclarations': [
        {
          'name': createComplaint,
          'description':
              'Prépare une réclamation pour le client. Elle n\'est PAS créée '
              'tout de suite : le client voit un récapitulatif et doit la '
              'confirmer dans l\'application. À appeler quand le client veut '
              'signaler un problème et que tu sais ce qui s\'est passé.',
          'parameters': {
            'type': 'OBJECT',
            'properties': {
              'category': {
                'type': 'STRING',
                'enum': [for (final c in ComplaintCategory.values) c.name],
                'description':
                    'panne (véhicule, bruit, voyant, accident), proprete, '
                    'retardAgence, facturation, enchere, autre',
              },
              'priority': {
                'type': 'STRING',
                'enum': [for (final p in ComplaintPriority.values) p.name],
                'description':
                    'urgente si le client est bloqué, en danger ou si le '
                    'véhicule est dangereux à conduire ; basse pour une simple '
                    'remarque ; sinon moyenne',
              },
              'title': {
                'type': 'STRING',
                'description': 'Titre court, 5 à 80 caractères, en français',
              },
              'description': {
                'type': 'STRING',
                'description':
                    'Faits rapportés par le client, 20 à 1000 caractères, à la '
                    'première personne, sans rien inventer',
              },
              'isUrgent': {
                'type': 'BOOLEAN',
                'description': 'Vrai si le client est bloqué ou en danger',
              },
            },
            'required': [
              'category',
              'priority',
              'title',
              'description',
              'isUrgent',
            ],
          },
        },
        {
          'name': getMyComplaints,
          'description':
              'Liste des réclamations du client connecté (référence, titre, '
              'statut, catégorie, date).',
        },
        {
          'name': getCurrentReservation,
          'description':
              'Réservation en cours du client (sinon la prochaine à venir) : '
              'référence, voiture, agence, dates.',
        },
      ],
    },
  ];
}

/// Arguments de create_complaint validés : brouillon OU message d'erreur
/// renvoyé à Gemini (qui redemande les détails au client).
({ComplaintDraft? draft, String? error}) parseComplaintDraft(
  Map<String, Object?> args, {
  Reservation? reservation,
}) {
  final category = parseComplaintCategory(args['category']);
  final priority = parseComplaintPriority(args['priority']);
  final title = '${args['title'] ?? ''}'.trim();
  final description = '${args['description'] ?? ''}'.trim();
  final isUrgent = args['isUrgent'] == true || args['isUrgent'] == 'true';

  final problems = [
    if (category == null)
      'category invalide (valeurs : ${ComplaintCategory.values.map((c) => c.name).join(', ')})',
    if (priority == null) 'priority invalide (basse, moyenne ou urgente)',
    if (title.length < 5) 'title trop court (5 caractères minimum)',
    if (description.length < 20)
      'description trop courte (20 caractères minimum) : demande plus de '
          'détails au client',
  ];
  if (problems.isNotEmpty) return (draft: null, error: problems.join(' ; '));

  // Seule une location en cours est liée automatiquement.
  final linked = reservation?.status == ReservationStatus.enCours
      ? reservation
      : null;
  return (
    draft: ComplaintDraft(
      category: category!,
      priority: priority!,
      title: title.length > 80 ? title.substring(0, 80).trim() : title,
      description: description.length > 1000
          ? description.substring(0, 1000).trim()
          : description,
      isUrgent: isUrgent,
      reservationId: linked?.id,
      reservationLabel: linked == null
          ? null
          : '${linked.car.fullName} · ${linked.reference}',
    ),
    error: null,
  );
}

String _date(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

/// Résultat de get_my_complaints (renvoyé à Gemini).
Map<String, Object?> myComplaintsResult(Iterable<Complaint> complaints) {
  final list = complaints.toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return {
    'count': list.length,
    'complaints': [
      for (final c in list.take(15))
        {
          'reference': c.reference,
          'title': c.title,
          'status': c.status.label,
          'category': c.category.name,
          'priority': c.priority.name,
          'createdAt': _date(c.createdAt),
          if (c.agencyResponse != null) 'agencyResponse': c.agencyResponse,
        },
    ],
  };
}

/// Résultat de get_current_reservation (renvoyé à Gemini).
Map<String, Object?> currentReservationResult(Reservation? r) => r == null
    ? {
        'reservation': null,
        'message': 'Aucune réservation en cours ni à venir.',
      }
    : {
        'reservation': {
          'reference': r.reference,
          'status': r.status.label,
          'car': r.car.fullName,
          'pickupAgency': r.pickupCity,
          'returnAgency': r.returnCity,
          'start': '${_date(r.range.start)} ${r.pickupTime}',
          'end': '${_date(r.range.end)} ${r.returnTime}',
        },
      };

/// Réservation en cours, sinon la prochaine à venir.
Reservation? currentOrNextReservation(Iterable<Reservation> reservations) {
  for (final r in reservations) {
    if (r.status == ReservationStatus.enCours) return r;
  }
  final next =
      reservations.where((r) => r.status == ReservationStatus.aVenir).toList()
        ..sort((a, b) => a.range.start.compareTo(b.range.start));
  return next.isEmpty ? null : next.first;
}
