import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive.dart';
import '../../data/models/car.dart';
import '../../data/models/payment.dart';
import '../../data/models/reservation.dart';
import '../../state/reservation_provider.dart';
import '../../widgets/common.dart';
import '../shell/main_shell.dart';

/// Contrat de location présenté sous forme de document.
/// Document de démonstration — sans aucune valeur juridique.
class ContractScreen extends StatelessWidget {
  const ContractScreen({super.key, required this.reservationId});

  final String reservationId;

  Future<void> _simulateExport(BuildContext context, String action) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(
          Icons.download_rounded,
          size: 30,
          color: AppColors.accent,
        ),
        title: Text('$action simulé'),
        content: Text(
          "Dans une version connectée à un backend, le contrat serait généré "
          "au format PDF puis ${action.toLowerCase() == 'téléchargement' ? 'téléchargé' : 'envoyé à l\'imprimante'}. "
          "Cette démonstration n'écrit aucun fichier.",
          style: const TextStyle(fontSize: 13.5, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Compris'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reservation = context.watch<ReservationProvider>().byId(
      reservationId,
    );

    if (reservation == null) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        appBar: appScreenBar(context, title: 'Contrat'),
        body: EmptyState(
          icon: Icons.description_outlined,
          title: 'Contrat introuvable',
          message: "Cette réservation n'existe plus.",
          actionLabel: 'Mes réservations',
          onAction: () => context.go(Routes.reservations),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFE9EDF3),
      appBar: appScreenBar(
        context,
        title: 'Contrat de location',
        subtitle: reservation.contractNumber ?? reservation.reference,
        actions: [
          IconButton(
            tooltip: 'Imprimer',
            onPressed: () => _simulateExport(context, 'Impression'),
            icon: const Icon(Icons.print_rounded),
          ),
          IconButton(
            tooltip: 'Télécharger',
            onPressed: () => _simulateExport(context, 'Téléchargement'),
            icon: const Icon(Icons.download_rounded),
          ),
        ],
      ),
      body: ContentContainer(
        maxWidth: 820,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            Responsive.value(
              context,
              mobile: 12.0,
              tablet: 24.0,
              desktop: 28.0,
            ),
            16,
            Responsive.value(
              context,
              mobile: 12.0,
              tablet: 24.0,
              desktop: 28.0,
            ),
            28,
          ),
          children: [
            const NoticeBox(
              icon: Icons.gavel_rounded,
              color: AppColors.warning,
              title: 'Document de démonstration',
              message:
                  "Ce contrat est généré localement à partir de données "
                  "fictives. Il n'a aucune valeur juridique et ne constitue "
                  "pas un document contractuel.",
            ),
            const SizedBox(height: 16),
            _ContractDocument(reservation: reservation),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _simulateExport(context, 'Impression'),
                    icon: const Icon(Icons.print_rounded, size: 18),
                    label: const Text('Imprimer'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        _simulateExport(context, 'Téléchargement'),
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: const Text('Télécharger'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ContractDocument extends StatelessWidget {
  const _ContractDocument({required this.reservation});

  final Reservation reservation;

  @override
  Widget build(BuildContext context) {
    final r = reservation;

    return Container(
      padding: EdgeInsets.all(
        Responsive.value(context, mobile: 20.0, tablet: 36.0),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFD5DBE5)),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.1),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(),
          const SizedBox(height: 26),
          _ContractSection(
            number: '1',
            title: 'Parties au contrat',
            child: Column(
              children: [
                _DocRow(
                  label: 'Le loueur',
                  value:
                      'RentCar Tunisia SARL\n'
                      'Avenue Habib Bourguiba, Tunis 1000\n'
                      'Matricule fiscal : 1234567/A/M/000 (fictif)',
                ),
                _DocRow(
                  label: 'Le locataire',
                  value:
                      '${r.driverName}\n'
                      'Tél. : +216 ${r.driverPhone}\n'
                      '${r.driverEmail}\n'
                      'Permis n° ${r.driverLicence}',
                ),
                if (r.secondDriver)
                  const _DocRow(
                    label: 'Second conducteur',
                    value:
                        'Déclaré — identité à présenter au comptoir '
                        '(démonstration)',
                  ),
              ],
            ),
          ),
          _ContractSection(
            number: '2',
            title: 'Véhicule loué',
            child: Column(
              children: [
                _DocRow(label: 'Marque et modèle', value: r.car.fullName),
                _DocRow(label: 'Année', value: '${r.car.year}'),
                _DocRow(label: 'Catégorie', value: r.car.category.label),
                _DocRow(
                  label: 'Motorisation',
                  value:
                      '${r.car.fuel.label} · ${r.car.transmission.label}',
                ),
                _DocRow(
                  label: 'Immatriculation',
                  value: _plate(r.car.id),
                ),
                _DocRow(
                  label: 'Kilométrage inclus',
                  value:
                      '${r.car.mileageLimitPerDay} km par jour, '
                      '0,350 TND / km supplémentaire',
                ),
              ],
            ),
          ),
          _ContractSection(
            number: '3',
            title: 'Durée et lieux',
            child: Column(
              children: [
                _DocRow(
                  label: 'Début de location',
                  value:
                      '${Formatters.dateLong(r.range.start)} à '
                      '${r.pickupTime}',
                ),
                _DocRow(
                  label: 'Fin de location',
                  value:
                      '${Formatters.dateLong(r.range.end)} à ${r.returnTime}',
                ),
                _DocRow(
                  label: 'Durée',
                  value: Formatters.pluralDays(r.days),
                ),
                _DocRow(label: 'Agence de départ', value: r.pickupCity),
                _DocRow(label: 'Agence de retour', value: r.returnCity),
              ],
            ),
          ),
          _ContractSection(
            number: '4',
            title: 'Conditions financières',
            child: Column(
              children: [
                _DocRow(
                  label: 'Tarif journalier',
                  value: Formatters.money(r.car.pricePerDay),
                ),
                _DocRow(
                  label: 'Location (${Formatters.pluralDays(r.days)})',
                  value: Formatters.money(r.carTotal),
                ),
                if (r.extras.isNotEmpty)
                  _DocRow(
                    label: 'Options',
                    value: r.extras
                        .map(
                          (e) =>
                              '${e.label} — ${Formatters.money(e.totalFor(r.days))}',
                        )
                        .join('\n'),
                  ),
                _DocRow(
                  label: 'Frais de dossier',
                  value: Formatters.money(Reservation.serviceFee),
                ),
                _DocRow(label: 'TVA (19 %)', value: Formatters.money(r.vat)),
                _DocRow(
                  label: 'TOTAL TTC',
                  value: Formatters.money(r.total),
                  bold: true,
                ),
                _DocRow(
                  label: 'Caution (bloquée)',
                  value: Formatters.money(r.car.deposit),
                ),
                _DocRow(
                  label: 'Règlement',
                  value:
                      '${r.payment?.method.label ?? 'Non défini'} — '
                      '${r.payment?.status.label ?? 'En attente'}'
                      '${r.payment?.maskedCard != null ? ' (${r.payment!.maskedCard})' : ''}',
                ),
              ],
            ),
          ),
          _ContractSection(
            number: '5',
            title: 'Obligations du locataire',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final clause in _clauses)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 7),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '— ',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            clause,
                            style: const TextStyle(
                              fontSize: 12.5,
                              height: 1.55,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (r.notes.isNotEmpty)
            _ContractSection(
              number: '6',
              title: 'Observations',
              child: Text(
                r.notes,
                style: const TextStyle(
                  fontSize: 12.5,
                  height: 1.55,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          const SizedBox(height: 14),
          const Divider(),
          const SizedBox(height: 20),
          _signatures(),
          const SizedBox(height: 24),
          Center(
            child: Text(
              'Document généré le ${Formatters.dateTime(DateTime.now())} — '
              'spécimen sans valeur juridique',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10.5,
                color: AppColors.textMuted,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'RENTCAR TUNISIA',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      color: AppColors.navy,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Location de véhicules · Tunis — Sousse — Sfax — Djerba',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: AppColors.warningSoft,
                border: Border.all(color: AppColors.warning),
              ),
              child: const Text(
                'SPÉCIMEN',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: Color(0xFF92400E),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Container(height: 2.5, color: AppColors.navy),
        const SizedBox(height: 18),
        const Center(
          child: Text(
            'CONTRAT DE LOCATION DE VÉHICULE',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
              color: AppColors.navy,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _MetaBox(
                label: 'N° de contrat',
                value: reservation.contractNumber ?? '—',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetaBox(
                label: 'Référence',
                value: reservation.reference,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetaBox(
                label: 'Établi le',
                value: Formatters.date(reservation.createdAt),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _signatures() {
    return Row(
      children: [
        Expanded(
          child: _SignatureBox(
            title: 'Le loueur',
            name: 'RentCar Tunisia',
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _SignatureBox(
            title: 'Le locataire',
            name: reservation.driverName,
          ),
        ),
      ],
    );
  }

  /// Immatriculation tunisienne fictive dérivée de l'identifiant du véhicule.
  static String _plate(String carId) {
    final digits = carId.replaceAll(RegExp(r'\D'), '');
    final serial = digits.isEmpty ? '000' : digits.padLeft(3, '0');
    return '${100 + int.parse(serial)} TU 2${serial.substring(serial.length - 2)}';
  }

  static const List<String> _clauses = [
    'Le véhicule doit être restitué dans son état initial, avec le même '
        'niveau de carburant qu\'au départ.',
    'Seuls les conducteurs déclarés au contrat sont autorisés à conduire le '
        'véhicule.',
    'La conduite hors du territoire tunisien est interdite sans autorisation '
        'écrite préalable du loueur.',
    'Tout retard de restitution supérieur à une heure entraîne la facturation '
        'd\'une journée supplémentaire.',
    'Les amendes et contraventions émises pendant la période de location '
        'restent à la charge du locataire.',
    'En cas de sinistre, le locataire doit informer le loueur sous 24 heures '
        'et fournir un constat amiable.',
    'La caution est restituée après vérification de l\'état du véhicule, dans '
        'un délai de 7 jours ouvrés.',
  ];
}

class _ContractSection extends StatelessWidget {
  const _ContractSection({
    required this.number,
    required this.title,
    required this.child,
  });

  final String number;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 22,
                width: 22,
                alignment: Alignment.center,
                color: AppColors.navy,
                child: Text(
                  number,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                  color: AppColors.navy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _DocRow extends StatelessWidget {
  const _DocRow({
    required this.label,
    required this.value,
    this.bold = false,
  });

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 148,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.5,
                fontWeight: bold ? FontWeight.w900 : FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaBox extends StatelessWidget {
  const _MetaBox({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6FA),
        border: Border.all(color: const Color(0xFFDDE3EC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 9.5,
              letterSpacing: 0.5,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SignatureBox extends StatelessWidget {
  const _SignatureBox({required this.title, required this.name});

  final String title;
  final String name;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            color: AppColors.navy,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          name,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          height: 72,
          decoration: BoxDecoration(
            border: Border.all(
              color: const Color(0xFFD5DBE5),
              style: BorderStyle.solid,
            ),
            color: const Color(0xFFFAFBFD),
          ),
          child: const Center(
            child: Text(
              'Signature',
              style: TextStyle(
                fontSize: 10.5,
                color: Color(0xFFB8C0CC),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'Lu et approuvé — date et signature',
          style: TextStyle(fontSize: 9.5, color: AppColors.textMuted),
        ),
      ],
    );
  }
}
