import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive.dart';
import '../../data/models/auction.dart';
import '../../state/auction_provider.dart';
import '../../state/load_state.dart';
import '../../widgets/car_image.dart';
import '../../widgets/common.dart';
import '../../widgets/status_badge.dart';
import '../shell/main_shell.dart';
import 'create_auction_sheet.dart';

/// Écran de gestion des ventes de flotte — démonstration frontend.
/// Permet de suivre, relancer, annuler et créer des ventes simulées.
class FleetManagementScreen extends StatefulWidget {
  const FleetManagementScreen({super.key});

  @override
  State<FleetManagementScreen> createState() => _FleetManagementScreenState();
}

class _FleetManagementScreenState extends State<FleetManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuctionProvider>().load();
    });
  }

  Future<void> _createAuction() async {
    final created = await showModalBottomSheet<Auction>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const CreateAuctionSheet(),
    );
    if (created == null || !mounted) return;
    AppSnack.success(
      context,
      'Vente « ${created.title} » publiée · '
      'fin dans ${created.remaining.inMinutes} min.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AuctionProvider>();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: appScreenBar(
        context,
        title: 'Gestion des ventes de flotte',
        subtitle: 'Sélection parc · durée · prix · publication',
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton.icon(
              onPressed: _createAuction,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Mettre en vente'),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createAuction,
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Mettre en vente'),
      ),
      body: provider.state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ContentContainer(
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  Responsive.value(
                    context,
                    mobile: 16.0,
                    tablet: 24.0,
                    desktop: 32.0,
                  ),
                  16,
                  Responsive.value(
                    context,
                    mobile: 16.0,
                    tablet: 24.0,
                    desktop: 32.0,
                  ),
                  90,
                ),
                children: [
                  const NoticeBox(
                    icon: Icons.admin_panel_settings_outlined,
                    title: 'Espace gestionnaire',
                    message:
                        'Choisissez un véhicule du catalogue, complétez '
                        'kilométrage / accident / état, fixez le prix de '
                        'départ et la durée (30 min ou 1 h…). Les offres '
                        'sont persistées localement.',
                  ),
                  const SizedBox(height: 16),
                  _KpiGrid(provider: provider),
                  const SizedBox(height: 22),
                  SectionHeader(
                    title: 'Ventes en cours',
                    subtitle:
                        '${provider.liveAuctions.length} véhicule'
                        '${provider.liveAuctions.length > 1 ? 's' : ''} '
                        'actuellement aux enchères',
                  ),
                  if (provider.liveAuctions.isEmpty)
                    const AppCard(
                      child: EmptyState(
                        compact: true,
                        icon: Icons.gavel_rounded,
                        title: 'Aucune vente active',
                        message:
                            'Publiez une nouvelle vente pour alimenter la '
                            'place de marché.',
                      ),
                    )
                  else
                    for (final auction in provider.liveAuctions)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _FleetRow(auction: auction),
                      ),
                  const SizedBox(height: 18),
                  SectionHeader(
                    title: 'Ventes clôturées',
                    subtitle: 'Résultats et relances possibles',
                  ),
                  for (final auction in provider.auctions.where(
                    (a) => a.isEnded,
                  ))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _FleetRow(auction: auction),
                    ),
                  if (provider.upcoming.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    SectionHeader(
                      title: 'Ventes programmées',
                      subtitle: 'Ouverture planifiée',
                    ),
                    for (final auction in provider.upcoming)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _FleetRow(auction: auction),
                      ),
                  ],
                ],
              ),
            ),
    );
  }
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.provider});

  final AuctionProvider provider;

  @override
  Widget build(BuildContext context) {
    final kpis = <(IconData, String, String, Color)>[
      (
        Icons.directions_car_rounded,
        '${provider.totalAuctions}',
        'Véhicules en portefeuille',
        AppColors.accent,
      ),
      (
        Icons.sensors_rounded,
        '${provider.openCount}',
        'Ventes actives',
        AppColors.success,
      ),
      (
        Icons.gavel_rounded,
        '${provider.totalBids}',
        'Offres reçues',
        AppColors.gold,
      ),
      (
        Icons.payments_rounded,
        Formatters.moneyShort(provider.estimatedRevenue),
        'Produit des ventes conclues',
        AppColors.navy,
      ),
      (
        Icons.trending_up_rounded,
        Formatters.moneyShort(provider.pipelineValue),
        'Valeur en cours de négociation',
        AppColors.info,
      ),
      (
        Icons.flag_rounded,
        '${provider.endedCount}',
        'Ventes clôturées',
        AppColors.textSecondary,
      ),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: Responsive.value(context, mobile: 2, tablet: 3),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: Responsive.value(
        context,
        mobile: 1.5,
        tablet: 1.9,
        desktop: 2.2,
      ),
      children: [
        for (final (icon, value, label, color) in kpis)
          AppCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.11),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: color),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.6,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        height: 1.3,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _FleetRow extends StatelessWidget {
  const _FleetRow({required this.auction});

  final Auction auction;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AuctionProvider>();

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CarImage(
                url: auction.mainImage,
                height: 66,
                width: 90,
                borderRadius: BorderRadius.circular(12),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      auction.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${Formatters.mileage(auction.mileage)} · '
                      '${auction.condition.shortLabel} · ${auction.city}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    StatusBadge.auction(auction.computedStatus),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    Formatters.moneyShort(auction.currentPrice),
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w900,
                      color: AppColors.accent,
                    ),
                  ),
                  Text(
                    '${auction.bidCount} offre'
                    '${auction.bidCount > 1 ? 's' : ''}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => context.push(
                  auction.isEnded
                      ? Routes.auctionResult(auction.id)
                      : Routes.auction(auction.id),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 38),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  textStyle: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                icon: const Icon(Icons.visibility_outlined, size: 16),
                label: const Text('Consulter'),
              ),
              if (auction.isOpen)
                OutlinedButton.icon(
                  onPressed: () async {
                    await provider.cancelAuction(auction.id);
                    if (!context.mounted) return;
                    AppSnack.info(context, 'Vente annulée.');
                  },
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 38),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.danger),
                    textStyle: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  icon: const Icon(Icons.block_rounded, size: 16),
                  label: const Text('Annuler'),
                ),
              if (!auction.isOpen)
                ElevatedButton.icon(
                  onPressed: () async {
                    await provider.relaunch(
                      auction.id,
                      duration: const Duration(hours: 1),
                    );
                    if (!context.mounted) return;
                    AppSnack.success(context, 'Vente relancée pour 1 heure.');
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 38),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    backgroundColor: AppColors.navy,
                    textStyle: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  icon: const Icon(Icons.replay_rounded, size: 16),
                  label: const Text('Relancer'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
