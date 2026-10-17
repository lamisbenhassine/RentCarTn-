import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive.dart';
import '../../data/models/payment.dart';
import '../../data/models/reservation.dart';
import '../../state/reservation_provider.dart';
import '../../widgets/common.dart';
import '../../widgets/status_badge.dart';
import '../shell/main_shell.dart';

/// Reçu de paiement simulé.
class ReceiptScreen extends StatelessWidget {
  const ReceiptScreen({super.key, required this.reservationId});

  final String reservationId;

  @override
  Widget build(BuildContext context) {
    final reservation = context.watch<ReservationProvider>().byId(
      reservationId,
    );

    if (reservation == null || reservation.payment == null) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        appBar: appScreenBar(context, title: 'Reçu'),
        body: EmptyState(
          icon: Icons.receipt_long_outlined,
          title: 'Reçu indisponible',
          message: "Aucun paiement n'est associé à cette réservation.",
          actionLabel: 'Mes réservations',
          onAction: () => context.go(Routes.reservations),
        ),
      );
    }

    final payment = reservation.payment!;

    return Scaffold(
      backgroundColor: const Color(0xFFE9EDF3),
      appBar: appScreenBar(
        context,
        title: 'Reçu de paiement',
        subtitle: payment.id,
        actions: [
          IconButton(
            tooltip: 'Télécharger',
            onPressed: () => _simulate(context),
            icon: const Icon(Icons.download_rounded),
          ),
        ],
      ),
      body: ContentContainer(
        maxWidth: 560,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            Responsive.value(context, mobile: 16.0, tablet: 24.0),
            20,
            Responsive.value(context, mobile: 16.0, tablet: 24.0),
            28,
          ),
          children: [
            _ReceiptCard(reservation: reservation, payment: payment),
            const SizedBox(height: 18),
            const NoticeBox(
              icon: Icons.science_outlined,
              color: AppColors.warning,
              message:
                  "Reçu de démonstration. Aucune transaction bancaire réelle "
                  "n'a été effectuée.",
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _simulate(context),
                icon: const Icon(Icons.download_rounded, size: 18),
                label: const Text('Télécharger le reçu'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _simulate(BuildContext context) {
    AppSnack.info(
      context,
      'Téléchargement simulé : aucun fichier n\'est généré en démo.',
    );
  }
}

class _ReceiptCard extends StatelessWidget {
  const _ReceiptCard({required this.reservation, required this.payment});

  final Reservation reservation;
  final PaymentRecord payment;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFD5DBE5)),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.08),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'RENTCAR TUNISIA',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.4,
                    color: AppColors.navy,
                  ),
                ),
              ),
              StatusBadge.payment(payment.status),
            ],
          ),
          const SizedBox(height: 3),
          const Text(
            'Reçu de paiement — spécimen',
            style: TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
          const SizedBox(height: 18),
          const Divider(),
          const SizedBox(height: 10),
          InfoRow(label: 'N° de transaction', value: payment.id, dense: true),
          InfoRow(
            label: 'Date',
            value: Formatters.dateTime(payment.date),
            dense: true,
          ),
          InfoRow(
            label: 'Réservation',
            value: reservation.reference,
            dense: true,
          ),
          InfoRow(
            label: 'Client',
            value: reservation.driverName,
            dense: true,
          ),
          InfoRow(
            label: 'Mode de paiement',
            value: payment.maskedCard == null
                ? payment.method.label
                : '${payment.method.label} (${payment.maskedCard})',
            dense: true,
          ),
          const SizedBox(height: 10),
          const Divider(),
          const SizedBox(height: 10),
          InfoRow(
            label: 'Véhicule',
            value: reservation.car.fullName,
            dense: true,
          ),
          InfoRow(
            label: 'Période',
            value:
                '${Formatters.date(reservation.range.start)} → '
                '${Formatters.date(reservation.range.end)}',
            dense: true,
          ),
          InfoRow(
            label: 'Location',
            value: Formatters.money(reservation.carTotal),
            dense: true,
          ),
          if (reservation.extras.isNotEmpty)
            InfoRow(
              label: 'Options',
              value: Formatters.money(reservation.extrasTotal),
              dense: true,
            ),
          InfoRow(
            label: 'Frais de dossier',
            value: Formatters.money(Reservation.serviceFee),
            dense: true,
          ),
          InfoRow(
            label: 'TVA (19 %)',
            value: Formatters.money(reservation.vat),
            dense: true,
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: const BoxDecoration(color: Color(0xFFF4F6FA)),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'MONTANT RÉGLÉ',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                      color: AppColors.navy,
                    ),
                  ),
                ),
                Text(
                  Formatters.money(payment.amount),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    color: AppColors.accent,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Center(
            child: Text(
              'Merci de votre confiance.\n'
              'Émis le ${Formatters.dateTime(DateTime.now())}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10.5,
                height: 1.5,
                color: AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
