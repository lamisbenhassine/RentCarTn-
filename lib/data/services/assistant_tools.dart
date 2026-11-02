import '../models/car.dart';
import '../models/complaint.dart';
import '../models/complaint_draft.dart';
import '../models/reservation.dart';
import 'complaint_ai.dart';

/// Noms des fonctions exposées à Gemini (function calling).
abstract final class AssistantTools {
  static const createComplaint = 'create_complaint';
  static const getMyComplaints = 'get_my_complaints';
  static const getCurrentReservation = 'get_current_reservation';
  static const getMyVehicles = 'get_my_vehicles';

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
              'carId': {
                'type': 'STRING',
                'description':
                    'Véhicule concerné : carId EXACT renvoyé par '
                    'get_my_vehicles, choisi par le client. Ne jamais '
                    'inventer. À omettre si la location en cours est '
                    'concernée (liée automatiquement).',
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
        {
          'name': getMyVehicles,
          'description':
              'Véhicules loués par le client (lus dans le catalogue) : carId, '
              'marque, modèle, année, ville, réservation. Pour lui faire '
              'choisir le véhicule concerné par une réclamation.',
        },
      ],
    },
  ];
}

/// Véhicule loué par le client, tel qu'il existe dans le catalogue.
class ClientVehicle {
  const ClientVehicle({required this.car, required this.reservation});

  final Car car;
  final Reservation reservation;
}

/// Véhicules des réservations du client (sauf annulées), lus dans le
/// catalogue via [carById] : une voiture retirée n'apparaît pas. Location
/// en cours d'abord, puis les plus récentes ; une ligne par voiture.
List<ClientVehicle> clientVehicles(
  Iterable<Reservation> reservations,
  Car? Function(String id) carById,
) {
  int rank(Reservation r) => switch (r.status) {
    ReservationStatus.enCours => 0,
    ReservationStatus.aVenir => 1,
    _ => 2,
  };
  final sorted =
      reservations.where((r) => r.status != ReservationStatus.annulee).toList()
        ..sort((a, b) {
          final byRank = rank(a).compareTo(rank(b));
          return byRank != 0 ? byRank : b.range.start.compareTo(a.range.start);
        });
  final seen = <String>{};
  return [
    for (final r in sorted)
      if (carById(r.car.id) case final car? when seen.add(car.id))
        ClientVehicle(car: car, reservation: r),
  ];
}

/// Arguments de create_complaint validés : brouillon OU message d'erreur
/// renvoyé à Gemini (qui redemande les détails au client).
///
/// Véhicule : celui de la location en cours, sinon [carId] choisi parmi
/// [vehicles]. Jamais de nom libre : panne / propreté sans véhicule alors
/// que le client en a → Gemini doit lui faire choisir (get_my_vehicles).
({ComplaintDraft? draft, String? error}) parseComplaintDraft(
  Map<String, Object?> args, {
  Reservation? reservation,
  List<ClientVehicle> vehicles = const [],
}) {
  final category = parseComplaintCategory(args['category']);
  final priority = parseComplaintPriority(args['priority']);
  final title = '${args['title'] ?? ''}'.trim();
  final description = '${args['description'] ?? ''}'.trim();
  final isUrgent = args['isUrgent'] == true || args['isUrgent'] == 'true';
  final carArg = '${args['carId'] ?? ''}'.trim();

  // Seule une location en cours est liée automatiquement.
  final current = reservation?.status == ReservationStatus.enCours
      ? reservation
      : null;
  ClientVehicle? vehicle;
  if (carArg.isNotEmpty) {
    vehicle = vehicles.where((v) => v.car.id == carArg).firstOrNull;
  } else if (current != null) {
    vehicle = vehicles.where((v) => v.reservation.id == current.id).firstOrNull;
  }

  final problems = [
    if (carArg.isNotEmpty && vehicle == null)
      'carId inconnu : utilise uniquement un carId renvoyé par '
          'get_my_vehicles, ou demande au client de choisir',
    if (carArg.isEmpty &&
        vehicle == null &&
        (category?.requiresCar ?? false) &&
        vehicles.isNotEmpty)
      'véhicule requis pour ${category!.name} : appelle get_my_vehicles et '
          'demande au client lequel est concerné (ne devine pas)',
    if (category == null)
      'category invalide (valeurs : ${ComplaintCategory.values.map((c) => c.name).join(', ')})',
    if (priority == null) 'priority invalide (basse, moyenne ou urgente)',
    if (title.length < 5) 'title trop court (5 caractères minimum)',
    if (description.length < 20)
      'description trop courte (20 caractères minimum) : demande plus de '
          'détails au client',
  ];
  if (problems.isNotEmpty) return (draft: null, error: problems.join(' ; '));

  // Véhicule choisi : sa réservation ; sinon la location en cours.
  final linked = vehicle?.reservation ?? current;
  final car = vehicle?.car;
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
      reservationLabel: linked?.reference,
      carId: car?.id,
      carLabel: car?.title,
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

/// Résultat de get_my_vehicles (renvoyé à Gemini).
Map<String, Object?> myVehiclesResult(List<ClientVehicle> vehicles) => {
  'count': vehicles.length,
  if (vehicles.isEmpty)
    'message':
        'Aucun véhicule du catalogue lié aux réservations du client. '
        'Prépare la réclamation sans carId : il choisira le véhicule dans '
        'le formulaire.',
  'vehicles': [
    for (final v in vehicles)
      {
        'carId': v.car.id,
        'label': v.car.title,
        'city': v.car.city,
        'reservation': v.reservation.reference,
        'reservationStatus': v.reservation.status.label,
      },
  ],
};

/// Résultat de get_current_reservation (renvoyé à Gemini). Voiture lue
/// dans le catalogue ([vehicles]) : `null` si elle en a été retirée.
Map<String, Object?> currentReservationResult(
  Reservation? r, {
  List<ClientVehicle> vehicles = const [],
}) => r == null
    ? {
        'reservation': null,
        'message': 'Aucune réservation en cours ni à venir.',
      }
    : {
        'reservation': {
          'reference': r.reference,
          'status': r.status.label,
          'car': vehicles
              .where((v) => v.reservation.id == r.id)
              .firstOrNull
              ?.car
              .title,
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
