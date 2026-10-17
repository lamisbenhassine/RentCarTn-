import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive.dart';
import '../../data/models/reservation.dart';
import '../../state/load_state.dart';
import '../../state/reservation_provider.dart';
import '../../widgets/car_image.dart';
import '../../widgets/common.dart';
import '../../widgets/status_badge.dart';
import '../shell/main_shell.dart';

class MyReservationsScreen extends StatefulWidget {
  const MyReservationsScreen({super.key});

  @override
  State<MyReservationsScreen> createState() => _MyReservationsScreenState();
}

class _MyReservationsScreenState extends State<MyReservationsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 4, vsync: this);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReservationProvider>().load();
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReservationProvider>();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: appScreenBar(
        context,
        title: 'Mes réservations',
        subtitle: '${provider.reservations.length} location'
            '${provider.reservations.length > 1 ? 's' : ''} au total',
      ),
      body: ContentContainer(
        child: Column(
          children: [
            Container(
              color: AppColors.surface,
              child: TabBar(
                controller: _tabs,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: [
                  for (final status in ReservationStatus.values)
                    Tab(
                      text:
                          '${_tabLabel(status)} '
                          '(${provider.countByStatus(status)})',
                    ),
                ],
              ),
            ),
            Expanded(
              child: provider.state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: _tabs,
                      children: [
                        for (final status in ReservationStatus.values)
                          _ReservationList(
                            reservations: provider.byStatus(status),
                            status: status,
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  static String _tabLabel(ReservationStatus status) => switch (status) {
    ReservationStatus.aVenir => 'À venir',
    ReservationStatus.enCours => 'En cours',
    ReservationStatus.terminee => 'Terminées',
    ReservationStatus.annulee => 'Annulées',
  };
}

class _ReservationList extends StatelessWidget {
  const _ReservationList({required this.reservations, required this.status});

  final List<Reservation> reservations;
  final ReservationStatus status;

  @override
  Widget build(BuildContext context) {
    if (reservations.isEmpty) {
      return EmptyState(
        icon: switch (status) {
          ReservationStatus.aVenir => Icons.event_available_rounded,
          ReservationStatus.enCours => Icons.directions_car_rounded,
          ReservationStatus.terminee => Icons.history_rounded,
          ReservationStatus.annulee => Icons.event_busy_rounded,
        },
        title: _emptyTitle,
        message: _emptyMessage,
        actionLabel: status == ReservationStatus.aVenir
            ? 'Réserver un véhicule'
            : null,
        onAction: status == ReservationStatus.aVenir
            ? () => context.go(Routes.catalog)
            : null,
      );
    }

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(
        Responsive.value(context, mobile: 16.0, tablet: 24.0, desktop: 28.0),
        18,
        Responsive.value(context, mobile: 16.0, tablet: 24.0, desktop: 28.0),
        28,
      ),
      itemCount: reservations.length,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (_, i) => ReservationCard(reservation: reservations[i]),
    );
  }

  String get _emptyTitle => switch (status) {
    ReservationStatus.aVenir => 'Aucune réservation à venir',
    ReservationStatus.enCours => 'Aucune location en cours',
    ReservationStatus.terminee => 'Aucune location terminée',
    ReservationStatus.annulee => 'Aucune réservation annulée',
  };

  String get _emptyMessage => switch (status) {
    ReservationStatus.aVenir =>
      'Réservez dès maintenant votre prochain véhicule dans notre catalogue.',
    ReservationStatus.enCours =>
      'Vos locations actives apparaîtront ici pendant la période de location.',
    ReservationStatus.terminee =>
      'L\'historique de vos locations passées s\'affichera ici.',
    ReservationStatus.annulee =>
      'Les réservations que vous annulez seront listées ici.',
  };
}

class ReservationCard extends StatelessWidget {
  const ReservationCard({super.key, required this.reservation});

  final Reservation reservation;

  @override
  Widget build(BuildContext context) {
    final r = reservation;

    return AppCard(
      padding: const EdgeInsets.all(14),
      onTap: () => context.push(Routes.reservation(r.id)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StatusBadge.reservation(r.status),
              const SizedBox(width: 8),
              if (r.payment != null) StatusBadge.payment(r.payment!.status),
              const Spacer(),
              Text(
                r.reference,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CarImage(
                url: r.car.mainImage,
                height: 76,
                width: 102,
                borderRadius: BorderRadius.circular(13),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.car.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    SpecChip(
                      icon: Icons.calendar_month_rounded,
                      label:
                          '${Formatters.date(r.range.start)} → '
                          '${Formatters.date(r.range.end)}',
                    ),
                    const SizedBox(height: 5),
                    SpecChip(
                      icon: Icons.place_rounded,
                      label: '${r.pickupCity} → ${r.returnCity}',
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Durée',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: AppColors.textMuted,
                        ),
                      ),
                      Text(
                        Formatters.pluralDays(r.days),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Contrat',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: AppColors.textMuted,
                        ),
                      ),
                      Text(
                        r.contractNumber ?? '—',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Total TTC',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: AppColors.textMuted,
                      ),
                    ),
                    Text(
                      Formatters.money(r.total),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (r.cancelReason != null) ...[
            const SizedBox(height: 10),
            Text(
              r.cancelReason!,
              style: const TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: AppColors.danger,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.push(Routes.reservation(r.id)),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 42),
                  ),
                  icon: const Icon(Icons.visibility_outlined, size: 17),
                  label: const Text('Détails'),
                ),
              ),
              if (r.contractNumber != null) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => context.push(Routes.contract(r.id)),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 42),
                      backgroundColor: AppColors.navy,
                    ),
                    icon: const Icon(Icons.article_rounded, size: 17),
                    label: const Text('Contrat'),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
