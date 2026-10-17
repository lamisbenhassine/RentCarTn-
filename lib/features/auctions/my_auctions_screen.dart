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
import '../../widgets/car_image.dart';
import '../../widgets/common.dart';
import '../../widgets/countdown.dart';
import '../../widgets/status_badge.dart';
import '../shell/main_shell.dart';

class MyAuctionsScreen extends StatefulWidget {
  const MyAuctionsScreen({super.key});

  @override
  State<MyAuctionsScreen> createState() => _MyAuctionsScreenState();
}

class _MyAuctionsScreenState extends State<MyAuctionsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 6, vsync: this);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuctionProvider>().load();
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AuctionProvider>();

    final tabs = <(String, List<Auction>)>[
      ('Participations', provider.participating),
      ('En tête', provider.leading),
      ('Surenchéri', provider.outbid),
      ('Gagnées', provider.won),
      ('Perdues', provider.lost),
      ('Historique', provider.history),
    ];

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: appScreenBar(
        context,
        title: 'Mes enchères',
        subtitle:
            '${provider.myBids.length} offre'
            '${provider.myBids.length > 1 ? 's' : ''} déposée'
            '${provider.myBids.length > 1 ? 's' : ''}',
      ),
      body: ContentContainer(
        child: Column(
          children: [
            _SummaryStrip(provider: provider),
            TabBar(
              controller: _tabs,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: [
                for (final (label, list) in tabs)
                  Tab(text: '$label (${list.length})'),
              ],
            ),
            Expanded(
              child: provider.state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: _tabs,
                      children: [
                        for (var i = 0; i < tabs.length; i++)
                          i == 5
                              ? _BidsHistoryList(provider: provider)
                              : _AuctionList(
                                  auctions: tabs[i].$2,
                                  emptyLabel: tabs[i].$1,
                                ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip({required this.provider});

  final AuctionProvider provider;

  @override
  Widget build(BuildContext context) {
    final engaged = provider.participating.fold(
      0.0,
      (sum, a) => sum + (a.userBestBid ?? 0),
    );

    final stats = <(IconData, String, String, Color)>[
      (
        Icons.gavel_rounded,
        '${provider.participating.length}',
        'En cours',
        AppColors.accent,
      ),
      (
        Icons.trending_up_rounded,
        '${provider.leading.length}',
        'En tête',
        AppColors.success,
      ),
      (
        Icons.emoji_events_rounded,
        '${provider.won.length}',
        'Gagnées',
        AppColors.gold,
      ),
      (
        Icons.payments_rounded,
        Formatters.moneyShort(engaged),
        'Engagé',
        AppColors.navy,
      ),
    ];

    return Padding(
      padding: EdgeInsets.fromLTRB(
        Responsive.value(context, mobile: 16.0, tablet: 24.0, desktop: 28.0),
        12,
        Responsive.value(context, mobile: 16.0, tablet: 24.0, desktop: 28.0),
        14,
      ),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: Responsive.value(context, mobile: 2, tablet: 4),
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 2.4,
        children: [
          for (final (icon, value, label, color) in stats)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 13,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Icon(icon, size: 18, color: color),
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
            ),
        ],
      ),
    );
  }
}

class _AuctionList extends StatelessWidget {
  const _AuctionList({required this.auctions, required this.emptyLabel});

  final List<Auction> auctions;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    if (auctions.isEmpty) {
      return EmptyState(
        icon: Icons.gavel_rounded,
        title: 'Rien dans « $emptyLabel »',
        message:
            'Participez à une vente depuis la place de marché pour voir vos '
            'enchères apparaître ici.',
        actionLabel: 'Voir les enchères',
        onAction: () => context.go(Routes.auctions),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(
        Responsive.value(context, mobile: 16.0, tablet: 24.0, desktop: 28.0),
        16,
        Responsive.value(context, mobile: 16.0, tablet: 24.0, desktop: 28.0),
        28,
      ),
      itemCount: auctions.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _MyAuctionTile(auction: auctions[i]),
    );
  }
}

class _MyAuctionTile extends StatelessWidget {
  const _MyAuctionTile({required this.auction});

  final Auction auction;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      onTap: () => context.push(
        auction.isEnded
            ? Routes.auctionResult(auction.id)
            : Routes.auction(auction.id),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CarImage(
                url: auction.mainImage,
                height: 74,
                width: 100,
                borderRadius: BorderRadius.circular(13),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      auction.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        StatusBadge.auction(auction.computedStatus),
                        const SizedBox(width: 8),
                        if (auction.isOpen)
                          Expanded(
                            child: CountdownText(
                              endAt: auction.endAt,
                              prefixIcon: Icons.timer_outlined,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _Mini(
                            label: 'Offre actuelle',
                            value: Formatters.moneyShort(
                              auction.currentPrice,
                            ),
                            highlight: true,
                          ),
                        ),
                        Expanded(
                          child: _Mini(
                            label: 'Votre offre',
                            value: auction.userBestBid == null
                                ? '—'
                                : Formatters.moneyShort(auction.userBestBid!),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _StatusTag(auction: auction),
        ],
      ),
    );
  }
}

class _Mini extends StatelessWidget {
  const _Mini({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: highlight ? AppColors.accent : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _StatusTag extends StatelessWidget {
  const _StatusTag({required this.auction});

  final Auction auction;

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch ((
      auction.isEnded,
      auction.currentUserIsLeading,
    )) {
      (true, true) => (
        'Gagnée — félicitations',
        AppColors.success,
        Icons.emoji_events_rounded,
      ),
      (true, false) => (
        'Perdue — surenchéri avant la clôture',
        AppColors.danger,
        Icons.close_rounded,
      ),
      (false, true) => (
        'Vous êtes en tête',
        AppColors.success,
        Icons.trending_up_rounded,
      ),
      (false, false) => (
        'Surenchéri — placez une nouvelle offre',
        AppColors.warning,
        Icons.trending_down_rounded,
      ),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BidsHistoryList extends StatelessWidget {
  const _BidsHistoryList({required this.provider});

  final AuctionProvider provider;

  @override
  Widget build(BuildContext context) {
    final bids = provider.myBids;

    if (bids.isEmpty) {
      return EmptyState(
        icon: Icons.history_rounded,
        title: 'Aucune offre déposée',
        message:
            "Votre historique d'offres apparaîtra ici dès votre première "
            "enchère.",
        actionLabel: 'Voir les enchères',
        onAction: () => context.go(Routes.auctions),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(
        Responsive.value(context, mobile: 16.0, tablet: 24.0, desktop: 28.0),
        16,
        Responsive.value(context, mobile: 16.0, tablet: 24.0, desktop: 28.0),
        28,
      ),
      itemCount: bids.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final entry = bids[i];
        final isBest = entry.auction.highestBid?.id == entry.bid.id;

        return AppCard(
          padding: const EdgeInsets.all(13),
          onTap: () => context.push(
            entry.auction.isEnded
                ? Routes.auctionResult(entry.auction.id)
                : Routes.auction(entry.auction.id),
          ),
          child: Row(
            children: [
              CarImage(
                url: entry.auction.mainImage,
                height: 56,
                width: 76,
                borderRadius: BorderRadius.circular(11),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.auction.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      Formatters.relativePast(entry.bid.date),
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    Formatters.moneyShort(entry.bid.amount),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  StatusBadge(
                    label: isBest ? 'Meilleure offre' : 'Dépassée',
                    color: isBest ? AppColors.success : AppColors.textMuted,
                    dense: true,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
