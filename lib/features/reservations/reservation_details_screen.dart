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
import '../../widgets/car_image.dart';
import '../../widgets/common.dart';
import '../../widgets/status_badge.dart';
import '../shell/main_shell.dart';

class ReservationDetailsScreen extends StatelessWidget {
  const ReservationDetailsScreen({super.key, required this.reservationId});

  final String reservationId;

  Future<void> _cancel(BuildContext context, Reservation r) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(
          Icons.event_busy_rounded,
          size: 30,
          color: AppColors.danger,
        ),
        title: const Text('Annuler la réservation ?'),
        content: Text(
          "La réservation ${r.reference} sera annulée et le paiement "
          "marqué comme remboursé (simulation). Cette action est "
          "irréversible dans la démonstration.",
          style: const TextStyle(fontSize: 13.5, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Conserver'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Annuler la réservation'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;
    context.read<ReservationProvider>().cancel(r.id);
    if (!context.mounted) return;
    AppSnack.info(context, 'Réservation ${r.reference} annulée.');
  }

  @override
  Widget build(BuildContext context) {
    final r = context.watch<ReservationProvider>().byId(reservationId);

    if (r == null) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        appBar: appScreenBar(context, title: 'Réservation'),
        body: EmptyState(
          icon: Icons.event_busy_rounded,
          title: 'Réservation introuvable',
          message: "Cette réservation n'existe plus.",
          actionLabel: 'Mes réservations',
          onAction: () => context.go(Routes.reservations),
        ),
      );
    }

    final canCancel = r.status == ReservationStatus.aVenir;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: appScreenBar(
        context,
        title: r.car.fullName,
        subtitle: r.reference,
      ),
      body: ContentContainer(
        maxWidth: 820,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            Responsive.value(
              context,
              mobile: 16.0,
              tablet: 24.0,
              desktop: 28.0,
            ),
            12,
            Responsive.value(
              context,
              mobile: 16.0,
              tablet: 24.0,
              desktop: 28.0,
            ),
            28,
          ),
          children: [
            CarImage(
              url: r.car.mainImage,
              height: 200,
              borderRadius: BorderRadius.circular(20),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                StatusBadge.reservation(r.status),
                const SizedBox(width: 8),
                if (r.payment != null) StatusBadge.payment(r.payment!.status),
              ],
            ),
            const SizedBox(height: 18),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _CardTitle('Période de location'),
                  InfoRow(
                    label: 'Prise en charge',
                    value:
                        '${Formatters.dateLong(r.range.start)} · '
                        '${r.pickupTime}',
                    icon: Icons.flight_land_rounded,
                    dense: true,
                  ),
                  InfoRow(
                    label: 'Restitution',
                    value:
                        '${Formatters.dateLong(r.range.end)} · '
                        '${r.returnTime}',
                    icon: Icons.flight_takeoff_rounded,
                    dense: true,
                  ),
                  InfoRow(
                    label: 'Durée',
                    value: Formatters.pluralDays(r.days),
                    icon: Icons.schedule_rounded,
                    dense: true,
                  ),
                  InfoRow(
                    label: 'Agences',
                    value: '${r.pickupCity} → ${r.returnCity}',
                    icon: Icons.place_rounded,
                    dense: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _CardTitle('Véhicule'),
                  InfoRow(
                    label: 'Modèle',
                    value: r.car.title,
                    dense: true,
                  ),
                  InfoRow(
                    label: 'Catégorie',
                    value: r.car.category.label,
                    dense: true,
                  ),
                  InfoRow(
                    label: 'Motorisation',
                    value:
                        '${r.car.fuel.label} · ${r.car.transmission.label}',
                    dense: true,
                  ),
                  InfoRow(
                    label: 'Places',
                    value: '${r.car.seats}',
                    dense: true,
                  ),
                  InfoRow(
                    label: 'Caution',
                    value: Formatters.money(r.car.deposit),
                    dense: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _CardTitle('Conducteur'),
                  InfoRow(label: 'Nom', value: r.driverName, dense: true),
                  InfoRow(
                    label: 'Téléphone',
                    value: '+216 ${r.driverPhone}',
                    dense: true,
                  ),
                  InfoRow(label: 'E-mail', value: r.driverEmail, dense: true),
                  InfoRow(
                    label: 'Permis',
                    value: r.driverLicence,
                    dense: true,
                  ),
                  if (r.secondDriver)
                    const InfoRow(
                      label: 'Second conducteur',
                      value: 'Déclaré',
                      dense: true,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _CardTitle('Montants'),
                  InfoRow(
                    label:
                        'Location (${Formatters.pluralDays(r.days)})',
                    value: Formatters.money(r.carTotal),
                    dense: true,
                  ),
                  for (final extra in r.extras)
                    InfoRow(
                      label: extra.label,
                      value: Formatters.money(extra.totalFor(r.days)),
                      dense: true,
                    ),
                  InfoRow(
                    label: 'Frais de dossier',
                    value: Formatters.money(Reservation.serviceFee),
                    dense: true,
                  ),
                  InfoRow(
                    label: 'TVA (19 %)',
                    value: Formatters.money(r.vat),
                    dense: true,
                  ),
                  const Divider(height: 22),
                  InfoRow(
                    label: 'Total TTC',
                    value: Formatters.money(r.total),
                    bold: true,
                    valueColor: AppColors.accent,
                  ),
                  if (r.payment != null) ...[
                    const SizedBox(height: 8),
                    InfoRow(
                      label: 'Paiement',
                      value:
                          '${r.payment!.method.label} · '
                          '${r.payment!.status.label}',
                      dense: true,
                    ),
                  ],
                ],
              ),
            ),
            if (r.notes.isNotEmpty) ...[
              const SizedBox(height: 14),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _CardTitle('Remarques'),
                    Text(
                      r.notes,
                      style: const TextStyle(
                        fontSize: 13.5,
                        height: 1.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            if (r.contractNumber != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => context.push(Routes.contract(r.id)),
                  icon: const Icon(Icons.article_rounded, size: 18),
                  label: const Text('Consulter le contrat'),
                ),
              ),
            if (r.payment != null) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => context.push(Routes.receipt(r.id)),
                  icon: const Icon(Icons.receipt_long_rounded, size: 18),
                  label: const Text('Voir le reçu de paiement'),
                ),
              ),
            ],
            if (canCancel) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () => _cancel(context, r),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    minimumSize: const Size(0, 50),
                  ),
                  icon: const Icon(Icons.cancel_outlined, size: 18),
                  label: const Text('Annuler la réservation'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CardTitle extends StatelessWidget {
  const _CardTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 15.5,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.2,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}
