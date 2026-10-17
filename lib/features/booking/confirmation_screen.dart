import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive.dart';
import '../../data/models/payment.dart';
import '../../data/models/reservation.dart';
import '../../widgets/car_image.dart';
import '../../widgets/common.dart';
import '../../widgets/status_badge.dart';

class ConfirmationScreen extends StatelessWidget {
  const ConfirmationScreen({super.key, required this.reservations});

  final List<Reservation> reservations;

  @override
  Widget build(BuildContext context) {
    if (reservations.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        body: EmptyState(
          icon: Icons.inbox_rounded,
          title: 'Aucune réservation à afficher',
          message: 'Revenez à vos réservations pour consulter vos locations.',
          actionLabel: 'Mes réservations',
          onAction: () => context.go(Routes.reservations),
        ),
      );
    }

    final total = reservations.fold(0.0, (s, r) => s + r.total);
    final first = reservations.first;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: ContentContainer(
          maxWidth: 760,
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              Responsive.value(
                context,
                mobile: 16.0,
                tablet: 24.0,
                desktop: 28.0,
              ),
              24,
              Responsive.value(
                context,
                mobile: 16.0,
                tablet: 24.0,
                desktop: 28.0,
              ),
              28,
            ),
            children: [
              const _SuccessHeader(),
              const SizedBox(height: 24),
              AppCard(
                elevated: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Référence de réservation',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        StatusBadge.payment(
                          first.payment?.status ?? PaymentStatus.enAttente,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      reservations.map((r) => r.reference).join(' · '),
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Divider(height: 26),
                    InfoRow(
                      label: 'Véhicules réservés',
                      value: '${reservations.length}',
                      dense: true,
                    ),
                    InfoRow(
                      label: 'Mode de paiement',
                      value:
                          first.payment?.method.label ?? 'Non renseigné',
                      dense: true,
                    ),
                    InfoRow(
                      label: 'Montant total',
                      value: Formatters.money(total),
                      bold: true,
                      valueColor: AppColors.accent,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Vos locations',
                style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              for (final reservation in reservations)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ReservationTile(reservation: reservation),
                ),
              const SizedBox(height: 10),
              const NoticeBox(
                icon: Icons.description_outlined,
                title: 'Contrat de location généré',
                message:
                    "Un contrat de démonstration a été créé pour chaque "
                    "réservation. Il peut être prévisualisé, imprimé ou "
                    "téléchargé en simulation depuis la fiche de réservation.",
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () =>
                      context.push(Routes.contract(first.id)),
                  icon: const Icon(Icons.article_rounded, size: 19),
                  label: const Text('Voir le contrat de location'),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => context.go(Routes.reservations),
                  icon: const Icon(Icons.event_note_rounded, size: 19),
                  label: const Text('Mes réservations'),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: TextButton(
                  onPressed: () => context.go(Routes.home),
                  child: const Text("Retour à l'accueil"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuccessHeader extends StatefulWidget {
  const _SuccessHeader();

  @override
  State<_SuccessHeader> createState() => _SuccessHeaderState();
}

class _SuccessHeaderState extends State<_SuccessHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ScaleTransition(
          scale: CurvedAnimation(
            parent: _controller,
            curve: Curves.elasticOut,
          ),
          child: Container(
            height: 92,
            width: 92,
            decoration: const BoxDecoration(
              color: AppColors.successSoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              size: 54,
              color: AppColors.success,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Réservation confirmée !',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        const Text(
          "Merci pour votre confiance. Un e-mail de confirmation serait "
          "envoyé dans une version connectée à un serveur.",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            height: 1.55,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _ReservationTile extends StatelessWidget {
  const _ReservationTile({required this.reservation});

  final Reservation reservation;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      onTap: () => context.push(Routes.reservation(reservation.id)),
      child: Row(
        children: [
          CarImage(
            url: reservation.car.mainImage,
            height: 68,
            width: 92,
            borderRadius: BorderRadius.circular(12),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reservation.car.fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${Formatters.date(reservation.range.start)} → '
                  '${Formatters.date(reservation.range.end)}',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: Text(
                    'Contrat ${reservation.contractNumber}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
        ],
      ),
    );
  }
}
