import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive.dart';
import '../../data/models/auction.dart';
import '../../state/auction_provider.dart';
import '../../state/load_state.dart';
import '../../widgets/auction_card.dart';
import '../../widgets/common.dart';
import '../shell/main_shell.dart';

class AuctionsScreen extends StatefulWidget {
  const AuctionsScreen({super.key});

  @override
  State<AuctionsScreen> createState() => _AuctionsScreenState();
}

class _AuctionsScreenState extends State<AuctionsScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuctionProvider>().load();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openFilters() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _AuctionFiltersSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AuctionProvider>();
    final auctions = provider.filteredAuctions;
    final wide = Responsive.isWide(context);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: wide
          ? null
          : AppBar(
              backgroundColor: AppColors.surface,
              automaticallyImplyLeading: false,
              toolbarHeight: 64,
              title: const Text('Ventes aux enchères'),
              actions: [
                IconButton(
                  tooltip: 'Mes enchères',
                  onPressed: () => context.push(Routes.myAuctions),
                  icon: const Icon(Icons.emoji_events_outlined),
                ),
                const SizedBox(width: 6),
              ],
            ),
      body: ContentContainer(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                Responsive.value(
                  context,
                  mobile: 16.0,
                  tablet: 24.0,
                  desktop: 32.0,
                ),
                wide ? 24 : 4,
                Responsive.value(
                  context,
                  mobile: 16.0,
                  tablet: 24.0,
                  desktop: 32.0,
                ),
                10,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (wide) ...[
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Ventes aux enchères',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => context.push(Routes.myAuctions),
                          icon: const Icon(
                            Icons.emoji_events_outlined,
                            size: 18,
                          ),
                          label: const Text('Mes enchères'),
                        ),
                        const SizedBox(width: 10),
                        OutlinedButton.icon(
                          onPressed: () => context.push(Routes.fleet),
                          icon: const Icon(Icons.inventory_2_outlined, size: 18),
                          label: const Text('Gestion flotte'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  _StatsStrip(provider: provider),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchCtrl,
                          onChanged: provider.setQuery,
                          decoration: InputDecoration(
                            hintText: 'Rechercher un véhicule…',
                            prefixIcon: const Icon(Icons.search_rounded),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            suffixIcon: _searchCtrl.text.isEmpty
                                ? null
                                : IconButton(
                                    onPressed: () {
                                      _searchCtrl.clear();
                                      provider.setQuery('');
                                    },
                                    icon: const Icon(
                                      Icons.close_rounded,
                                      size: 19,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _FilterButton(
                        count: provider.activeFilterCount,
                        onTap: _openFilters,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _StatusChips(provider: provider),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '${auctions.length} vente'
                        '${auctions.length > 1 ? 's' : ''}',
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      DropdownButtonHideUnderline(
                        child: DropdownButton<AuctionSort>(
                          value: provider.sort,
                          isDense: true,
                          icon: const Icon(
                            Icons.expand_more_rounded,
                            size: 18,
                          ),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.accent,
                          ),
                          items: [
                            for (final sort in AuctionSort.values)
                              DropdownMenuItem(
                                value: sort,
                                child: Text(sort.label),
                              ),
                          ],
                          onChanged: (v) {
                            if (v != null) provider.setSort(v);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(child: _body(provider, auctions)),
          ],
        ),
      ),
    );
  }

  Widget _body(AuctionProvider provider, List<Auction> auctions) {
    if (provider.state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.state.isError) {
      return ErrorState(
        message: provider.errorMessage ?? 'Erreur inconnue.',
        onRetry: () => provider.load(force: true),
      );
    }
    if (auctions.isEmpty) {
      return EmptyState(
        icon: Icons.gavel_rounded,
        title: 'Aucune vente trouvée',
        message:
            'Aucune enchère ne correspond à vos critères. Élargissez votre '
            'recherche ou réinitialisez les filtres.',
        actionLabel: 'Réinitialiser',
        onAction: () {
          _searchCtrl.clear();
          provider.resetFilters();
        },
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.load(force: true),
      child: GridView.builder(
        padding: shellPadding(context).copyWith(top: 6),
        itemCount: auctions.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: Responsive.gridColumns(context),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          mainAxisExtent: 470,
        ),
        itemBuilder: (_, i) => AuctionCard(
          auction: auctions[i],
          userTag: auctions[i].userHasBid
              ? BidStatusTag(auction: auctions[i])
              : null,
          onTap: () => context.push(
            auctions[i].isEnded
                ? Routes.auctionResult(auctions[i].id)
                : Routes.auction(auctions[i].id),
          ),
        ),
      ),
    );
  }
}

class _StatsStrip extends StatelessWidget {
  const _StatsStrip({required this.provider});

  final AuctionProvider provider;

  @override
  Widget build(BuildContext context) {
    final stats = <(IconData, String, String)>[
      (Icons.sensors_rounded, '${provider.openCount}', 'En cours'),
      (
        Icons.timer_outlined,
        '${provider.endingSoon.length}',
        'Fin < 24 h',
      ),
      (Icons.gavel_rounded, '${provider.totalBids}', 'Offres'),
      (
        Icons.trending_up_rounded,
        Formatters.moneyShort(provider.pipelineValue),
        'Valeur en jeu',
      ),
    ];

    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: stats.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final (icon, value, label) = stats[i];
          return Container(
            width: 148,
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Icon(icon, size: 19, color: AppColors.accent),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.4,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatusChips extends StatelessWidget {
  const _StatusChips({required this.provider});

  final AuctionProvider provider;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          ChoiceChip(
            label: const Text('Toutes'),
            selected: provider.status == null,
            onSelected: (_) => provider.setStatus(provider.status),
          ),
          const SizedBox(width: 8),
          for (final status in AuctionStatus.values) ...[
            ChoiceChip(
              label: Text(status.label),
              selected: provider.status == status,
              onSelected: (_) => provider.setStatus(status),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: Container(
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(Icons.tune_rounded, color: AppColors.navy),
          ),
        ),
        if (count > 0)
          Positioned(
            right: -4,
            top: -4,
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: const BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _AuctionFiltersSheet extends StatelessWidget {
  const _AuctionFiltersSheet();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AuctionProvider>();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.45,
      builder: (context, controller) => Column(
        children: [
          const SizedBox(height: 12),
          Container(
            height: 4,
            width: 44,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(100),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Filtres',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: provider.resetFilters,
                  child: const Text('Tout effacer'),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
              children: [
                const _FilterLabel('Marque'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final brand in provider.availableBrands)
                      FilterChip(
                        label: Text(brand),
                        selected: provider.selectedBrands.contains(brand),
                        onSelected: (_) => provider.toggleBrand(brand),
                      ),
                  ],
                ),
                const SizedBox(height: 22),
                const _FilterLabel('État du véhicule'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final condition in VehicleCondition.values)
                      FilterChip(
                        label: Text(condition.shortLabel),
                        selected: provider.condition == condition,
                        onSelected: (_) => provider.setCondition(condition),
                      ),
                  ],
                ),
                const SizedBox(height: 22),
                const _FilterLabel('Statut de la vente'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final status in AuctionStatus.values)
                      FilterChip(
                        label: Text(status.label),
                        selected: provider.status == status,
                        onSelected: (_) => provider.setStatus(status),
                      ),
                  ],
                ),
                const SizedBox(height: 22),
                _FilterLabel(
                  'Prix actuel : ${Formatters.moneyShort(provider.minPrice)} '
                  '– ${Formatters.moneyShort(provider.maxPrice)}',
                ),
                RangeSlider(
                  values: RangeValues(
                    provider.minPrice.clamp(0, provider.priceCeiling),
                    provider.maxPrice.clamp(0, provider.priceCeiling),
                  ),
                  min: 0,
                  max: provider.priceCeiling,
                  divisions: 20,
                  onChanged: (v) => provider.setPriceRange(v.start, v.end),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(
              20,
              14,
              20,
              14 + MediaQuery.paddingOf(context).bottom,
            ),
            decoration: const BoxDecoration(
              color: AppColors.surfaceAlt,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Afficher ${provider.filteredAuctions.length} vente'
                  '${provider.filteredAuctions.length > 1 ? 's' : ''}',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterLabel extends StatelessWidget {
  const _FilterLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}
