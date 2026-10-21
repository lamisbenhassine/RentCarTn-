import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive.dart';
import '../../data/models/auction.dart';
import '../../data/models/car.dart';
import '../../state/auction_provider.dart';
import '../../state/load_state.dart';
import '../../widgets/car_image.dart';
import '../../widgets/common.dart';
import '../../widgets/countdown.dart';
import '../../widgets/status_badge.dart';
import '../shell/main_shell.dart';

class AuctionDetailsScreen extends StatefulWidget {
  const AuctionDetailsScreen({super.key, required this.auctionId});

  final String auctionId;

  @override
  State<AuctionDetailsScreen> createState() => _AuctionDetailsScreenState();
}

class _AuctionDetailsScreenState extends State<AuctionDetailsScreen> {
  final _bidCtrl = TextEditingController();
  int _imageIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<AuctionProvider>().load();
      if (!mounted) return;
      _prefillBid();
    });
  }

  @override
  void dispose() {
    _bidCtrl.dispose();
    super.dispose();
  }

  void _prefillBid() {
    final auction = context.read<AuctionProvider>().byId(widget.auctionId);
    if (auction == null) return;
    _bidCtrl.text = auction.minimumNextBid.toStringAsFixed(0);
  }

  Future<void> _placeBid(Auction auction) async {
    FocusScope.of(context).unfocus();
    final raw = _bidCtrl.text.replaceAll(RegExp(r'[^\d.]'), '');
    final amount = double.tryParse(raw);

    if (amount == null) {
      AppSnack.error(context, 'Saisissez un montant valide en dinars.');
      return;
    }

    final result = await context.read<AuctionProvider>().placeBid(
      auction.id,
      amount,
    );
    if (!mounted) return;
    if (result.ok) {
      AppSnack.success(context, result.message);
      _prefillBid();
    } else {
      AppSnack.error(context, result.message);
    }
  }

  Future<void> _raise500(Auction auction) async {
    final result =
        await context.read<AuctionProvider>().raiseByIncrement(auction.id);
    if (!mounted) return;
    if (result.ok) {
      AppSnack.success(context, result.message);
      _prefillBid();
    } else {
      AppSnack.error(context, result.message);
    }
  }

  Future<void> _simulateBid(Auction auction) async {
    final result = await context.read<AuctionProvider>().simulateCompetingBid(
      auction.id,
    );
    if (!mounted) return;
    result.ok
        ? AppSnack.info(context, result.message)
        : AppSnack.error(context, result.message);
    if (result.ok) _prefillBid();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AuctionProvider>();
    final auction = provider.byId(widget.auctionId);

    if (provider.state.isLoading && auction == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (auction == null) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        appBar: appScreenBar(context, title: 'Enchère'),
        body: EmptyState(
          icon: Icons.gavel_rounded,
          title: 'Enchère introuvable',
          message: "Cette vente n'existe plus.",
          actionLabel: 'Voir les enchères',
          onAction: () => context.go(Routes.auctions),
        ),
      );
    }

    final wide = Responsive.isWide(context);
    final gallery = _Gallery(
      auction: auction,
      index: _imageIndex,
      onIndexChanged: (i) => setState(() => _imageIndex = i),
    );

    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HeaderBlock(auction: auction),
        const SizedBox(height: 18),
        _PriceBlock(auction: auction),
        const SizedBox(height: 18),
        if (auction.isOpen)
          _BidBlock(
            auction: auction,
            controller: _bidCtrl,
            onBid: () => _placeBid(auction),
            onRaise500: () => _raise500(auction),
          )
        else
          _ClosedBlock(auction: auction),
        const SizedBox(height: 18),
        _SimulationPanel(
          auction: auction,
          onSimulateBid: () => _simulateBid(auction),
          onEndSoon: () async {
            await provider.simulateEndingSoon(auction.id);
            if (!context.mounted) return;
            AppSnack.info(
              context,
              'Compte à rebours ramené à 45 secondes (test).',
            );
          },
          onClose: () async {
            await provider.simulateClose(auction.id);
            if (!context.mounted) return;
            AppSnack.info(context, 'Vente clôturée (test).');
          },
        ),
        const SizedBox(height: 22),
        _SectionTitle('Historique des offres (${auction.bidCount})'),
        _BidHistory(auction: auction),
        const SizedBox(height: 22),
        _SectionTitle('Description du véhicule'),
        Text(
          auction.description,
          style: const TextStyle(
            fontSize: 14,
            height: 1.65,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 22),
        _SectionTitle('Fiche technique'),
        _SpecsBlock(auction: auction),
        if (auction.inspectionNotes.isNotEmpty) ...[
          const SizedBox(height: 22),
          _SectionTitle('Rapport d\'inspection'),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < auction.inspectionNotes.length; i++) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 3),
                        child: Icon(
                          Icons.build_circle_outlined,
                          size: 16,
                          color: AppColors.accent,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          auction.inspectionNotes[i],
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (i != auction.inspectionNotes.length - 1)
                    const SizedBox(height: 10),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: 22),
        _SectionTitle('Règlement de la vente'),
        const _RulesBlock(),
        const SizedBox(height: 16),
        const NoticeBox(
          icon: Icons.schedule_rounded,
          color: AppColors.warning,
          title: 'Limite de la démonstration',
          message:
              "Le compte à rebours et la clôture reposent sur l'horloge de "
              "cet appareil. Une vente réelle doit valider l'heure et chaque "
              "offre côté serveur.",
        ),
      ],
    );

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: appScreenBar(
        context,
        title: auction.fullName,
        subtitle: '${auction.year} · ${auction.city}',
        actions: [
          IconButton(
            tooltip: 'Mes enchères',
            onPressed: () => context.push(Routes.myAuctions),
            icon: const Icon(Icons.emoji_events_outlined),
          ),
        ],
      ),
      body: ContentContainer(
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            Responsive.value(
              context,
              mobile: 16.0,
              tablet: 24.0,
              desktop: 32.0,
            ),
            12,
            Responsive.value(
              context,
              mobile: 16.0,
              tablet: 24.0,
              desktop: 32.0,
            ),
            28,
          ),
          children: [
            if (wide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 5,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                      child: SizedBox(height: 420, child: gallery),
                    ),
                  ),
                  const SizedBox(width: 30),
                  Expanded(flex: 6, child: info),
                ],
              )
            else ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                child: SizedBox(height: 230, child: gallery),
              ),
              const SizedBox(height: 18),
              info,
            ],
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ Blocs

class _Gallery extends StatelessWidget {
  const _Gallery({
    required this.auction,
    required this.index,
    required this.onIndexChanged,
  });

  final Auction auction;
  final int index;
  final ValueChanged<int> onIndexChanged;

  @override
  Widget build(BuildContext context) {
    final images = auction.images.isEmpty ? [''] : auction.images;

    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          itemCount: images.length,
          onPageChanged: onIndexChanged,
          itemBuilder: (_, i) => CarImage(url: images[i], fit: BoxFit.cover),
        ),
        Positioned(
          top: 12,
          left: 12,
          child: StatusBadge.auction(auction.computedStatus),
        ),
        Positioned(
          top: 12,
          right: 12,
          child: CountdownPill(
            endAt: auction.endAt,
            ended: !auction.isOpen,
          ),
        ),
        Positioned(
          bottom: 14,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < images.length; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  height: 6,
                  width: i == index ? 22 : 6,
                  decoration: BoxDecoration(
                    color: i == index ? Colors.white : Colors.white54,
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeaderBlock extends StatelessWidget {
  const _HeaderBlock({required this.auction});

  final Auction auction;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            StatusBadge.condition(auction.condition),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.navy.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                auction.previousOwnerLabel,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          auction.title,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            SpecChip(
              icon: Icons.speed_rounded,
              label: Formatters.mileage(auction.mileage),
            ),
            SpecChip(
              icon: Icons.cake_outlined,
              label: '${auction.ageYears} an${auction.ageYears > 1 ? 's' : ''}',
            ),
            SpecChip(
              icon: auction.hadAccident
                  ? Icons.car_crash_rounded
                  : Icons.verified_outlined,
              label: auction.hadAccident ? 'Accidentée' : 'Sans accident',
            ),
            SpecChip(
              icon: Icons.health_and_safety_outlined,
              label: auction.condition.shortLabel,
            ),
            SpecChip(icon: Icons.place_rounded, label: auction.city),
            SpecChip(
              icon: Icons.event_seat_rounded,
              label: '${auction.seats} places',
            ),
          ],
        ),
        if (auction.extraInfo.trim().isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            auction.extraInfo.trim(),
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}

class _PriceBlock extends StatelessWidget {
  const _PriceBlock({required this.auction});

  final Auction auction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: navyBlock(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      auction.hasBids
                          ? 'Enchère la plus élevée'
                          : 'Prix de départ',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.65),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      Formatters.moneyShort(auction.currentPrice),
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.2,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      auction.hasBids
                          ? 'Meneur : ${auction.leadingBidder}'
                          : 'Aucune offre pour le moment',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: auction.currentUserIsLeading
                            ? AppColors.accentLight
                            : Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Temps restant',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.65),
                    ),
                  ),
                  const SizedBox(height: 4),
                  CountdownText(
                    endAt: auction.endAt,
                    forcedColor: auction.isOpen
                        ? Colors.white
                        : Colors.white60,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Fin : ${Formatters.dateTime(auction.endAt)}',
                    style: TextStyle(
                      fontSize: 10.5,
                      color: Colors.white.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Row(
              children: [
                _MiniStat(
                  label: 'Offres',
                  value: '${auction.bidCount}',
                ),
                const _Separator(),
                _MiniStat(
                  label: 'Départ',
                  value: Formatters.moneyShort(auction.startingPrice),
                ),
                const _Separator(),
                _MiniStat(
                  label: 'Incrément',
                  value: Formatters.moneyShort(auction.minIncrement),
                ),
              ],
            ),
          ),
          if (auction.reservePrice != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  auction.reserveMet
                      ? Icons.check_circle_rounded
                      : Icons.lock_clock_rounded,
                  size: 16,
                  color: auction.reserveMet
                      ? AppColors.accentLight
                      : Colors.white70,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    auction.reserveMet
                        ? 'Prix de réserve atteint : le véhicule sera vendu.'
                        : 'Prix de réserve non atteint '
                              '(${Formatters.moneyShort(auction.reservePrice!)}).',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _Separator extends StatelessWidget {
  const _Separator();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      color: Colors.white.withValues(alpha: 0.15),
    );
  }
}

class _BidBlock extends StatelessWidget {
  const _BidBlock({
    required this.auction,
    required this.controller,
    required this.onBid,
    required this.onRaise500,
  });

  final Auction auction;
  final TextEditingController controller;
  final VoidCallback onBid;
  final VoidCallback onRaise500;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      elevated: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Placer une offre',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              if (auction.currentUserIsLeading)
                StatusBadge(
                  label: 'Vous êtes en tête',
                  color: AppColors.success,
                  icon: Icons.trending_up_rounded,
                  dense: true,
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Prix actuel : ${Formatters.moneyShort(auction.currentPrice)} · '
            'minimum : ${Formatters.moneyShort(auction.minimumNextBid)}',
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: onRaise500,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
              ),
              icon: const Icon(Icons.trending_up_rounded, size: 20),
              label: Text(
                'Surenchérir + ${Formatters.moneyShort(auction.minIncrement)}',
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Ou saisir un montant précis',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(9),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Montant personnalisé',
                    suffixText: 'TND',
                    prefixIcon: Icon(Icons.payments_outlined),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: onBid,
                  icon: const Icon(Icons.gavel_rounded, size: 18),
                  label: const Text('Enchérir'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ClosedBlock extends StatelessWidget {
  const _ClosedBlock({required this.auction});

  final Auction auction;

  @override
  Widget build(BuildContext context) {
    final upcoming = auction.computedStatus == AuctionStatus.aVenir;

    if (upcoming) {
      return NoticeBox(
        icon: Icons.schedule_rounded,
        color: AppColors.info,
        title: "La vente n'a pas encore commencé",
        message:
            'Ouverture des enchères le '
            '${Formatters.dateTime(auction.startAt)}.',
      );
    }

    return Column(
      children: [
        NoticeBox(
          icon: Icons.flag_rounded,
          color: auction.hasBids ? AppColors.success : AppColors.textMuted,
          title: auction.hasBids
              ? 'Vente terminée — adjugée'
              : 'Vente terminée sans offre',
          message: auction.hasBids
              ? 'Remportée par ${auction.leadingBidder} pour '
                    '${Formatters.moneyShort(auction.currentPrice)}. '
                    'Les offres ne sont plus acceptées.'
              : "Aucune offre n'a été déposée avant la clôture. Le véhicule "
                    "sera remis en vente.",
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => context.push(Routes.auctionResult(auction.id)),
            icon: const Icon(Icons.emoji_events_rounded, size: 18),
            label: const Text('Voir le résultat détaillé'),
          ),
        ),
      ],
    );
  }
}

class _SimulationPanel extends StatelessWidget {
  const _SimulationPanel({
    required this.auction,
    required this.onSimulateBid,
    required this.onEndSoon,
    required this.onClose,
  });

  final Auction auction;
  final VoidCallback onSimulateBid;
  final VoidCallback onEndSoon;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warningSoft,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.science_rounded,
                size: 19,
                color: Color(0xFF92400E),
              ),
              const SizedBox(width: 9),
              const Expanded(
                child: Text(
                  'Panneau de simulation (démo)',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF92400E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            "Ces actions génèrent des événements fictifs pour démontrer le "
            "comportement des enchères. Les offres créées ici sont "
            "explicitement marquées « simulée ».",
            style: TextStyle(
              fontSize: 12,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ElevatedButton.icon(
                onPressed: auction.isOpen ? onSimulateBid : null,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(0, 42),
                  backgroundColor: AppColors.warning,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.person_add_alt_rounded, size: 17),
                label: const Text('Offre concurrente'),
              ),
              OutlinedButton.icon(
                onPressed: auction.isOpen ? onEndSoon : null,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 42),
                  foregroundColor: const Color(0xFF92400E),
                  side: const BorderSide(color: AppColors.warning),
                ),
                icon: const Icon(Icons.timer_rounded, size: 17),
                label: const Text('Fin dans 45 s'),
              ),
              OutlinedButton.icon(
                onPressed: auction.isOpen ? onClose : null,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 42),
                  foregroundColor: AppColors.danger,
                  side: const BorderSide(color: AppColors.danger),
                ),
                icon: const Icon(Icons.stop_circle_outlined, size: 17),
                label: const Text('Clôturer'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BidHistory extends StatelessWidget {
  const _BidHistory({required this.auction});

  final Auction auction;

  @override
  Widget build(BuildContext context) {
    final bids = auction.sortedBids;

    if (bids.isEmpty) {
      return const AppCard(
        child: EmptyState(
          compact: true,
          icon: Icons.history_rounded,
          title: 'Aucune offre',
          message:
              "Soyez le premier à enchérir sur ce véhicule au prix de départ.",
        ),
      );
    }

    final highest = auction.highestBid;

    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: [
          for (var i = 0; i < bids.length; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 17,
                    backgroundColor: bids[i].isCurrentUser
                        ? AppColors.accent
                        : AppColors.surface,
                    child: Icon(
                      bids[i].isCurrentUser
                          ? Icons.person_rounded
                          : Icons.account_circle_rounded,
                      size: 18,
                      color: bids[i].isCurrentUser
                          ? Colors.white
                          : AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                bids[i].isCurrentUser
                                    ? 'Vous'
                                    : bids[i].bidderName,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            if (bids[i].id == highest?.id) ...[
                              const SizedBox(width: 6),
                              const StatusBadge(
                                label: 'En tête',
                                color: AppColors.success,
                                dense: true,
                              ),
                            ],
                            if (bids[i].isSimulated) ...[
                              const SizedBox(width: 6),
                              const StatusBadge(
                                label: 'Simulée',
                                color: AppColors.warning,
                                dense: true,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          Formatters.relativePast(bids[i].date),
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    Formatters.moneyShort(bids[i].amount),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: bids[i].id == highest?.id
                          ? AppColors.accent
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (i != bids.length - 1)
              const Divider(height: 1, indent: 60, endIndent: 14),
          ],
        ],
      ),
    );
  }
}

class _SpecsBlock extends StatelessWidget {
  const _SpecsBlock({required this.auction});

  final Auction auction;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          InfoRow(label: 'Marque', value: auction.brand, dense: true),
          InfoRow(label: 'Modèle', value: auction.model, dense: true),
          InfoRow(label: 'Année', value: '${auction.year}', dense: true),
          InfoRow(
            label: 'Kilométrage',
            value: Formatters.mileage(auction.mileage),
            dense: true,
          ),
          InfoRow(
            label: 'Carburant',
            value: auction.fuel.label,
            dense: true,
          ),
          InfoRow(
            label: 'Transmission',
            value: auction.transmission.label,
            dense: true,
          ),
          InfoRow(
            label: 'État général',
            value: auction.condition.label,
            dense: true,
          ),
          InfoRow(
            label: 'Lieu de retrait',
            value: auction.city,
            dense: true,
          ),
          InfoRow(
            label: 'Ouverture',
            value: Formatters.dateTime(auction.startAt),
            dense: true,
          ),
          InfoRow(
            label: 'Clôture',
            value: Formatters.dateTime(auction.endAt),
            dense: true,
          ),
        ],
      ),
    );
  }
}

class _RulesBlock extends StatelessWidget {
  const _RulesBlock();

  static const List<String> _rules = [
    "Toute offre est ferme et définitive : elle ne peut pas être retirée.",
    "Une offre doit dépasser l'enchère en cours en respectant l'incrément "
        "minimal affiché.",
    "L'enchérisseur le plus élevé à l'heure de clôture remporte le véhicule.",
    "Si le prix de réserve n'est pas atteint, le vendeur peut refuser la "
        "vente.",
    "Le véhicule est vendu dans l'état décrit ; une visite préalable est "
        "recommandée.",
    "Le paiement et le retrait doivent intervenir sous 7 jours ouvrés après "
        "l'adjudication.",
    "Les frais de mutation et de carte grise sont à la charge de l'acheteur.",
  ];

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < _rules.length; i++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 20,
                  width: 20,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.navy.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${i + 1}',
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navy,
                    ),
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    _rules[i],
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            if (i != _rules.length - 1) const SizedBox(height: 11),
          ],
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16.5,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}
