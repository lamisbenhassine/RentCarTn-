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
import '../../widgets/car_image.dart';
import '../../widgets/common.dart';
import '../../widgets/status_badge.dart';
import '../shell/main_shell.dart';

/// Résultat d'une vente clôturée : gagnant, montant, véhicule.
class AuctionResultScreen extends StatelessWidget {
  const AuctionResultScreen({super.key, required this.auctionId});

  final String auctionId;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AuctionProvider>();
    final auction = provider.byId(auctionId);

    if (auction == null) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        appBar: appScreenBar(context, title: 'Résultat'),
        body: EmptyState(
          icon: Icons.gavel_rounded,
          title: 'Enchère introuvable',
          message: "Cette vente n'existe plus.",
          actionLabel: 'Voir les enchères',
          onAction: () => context.go(Routes.auctions),
        ),
      );
    }

    if (!auction.isEnded) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        appBar: appScreenBar(context, title: 'Résultat'),
        body: EmptyState(
          icon: Icons.timer_outlined,
          title: 'Vente encore ouverte',
          message:
              'Le résultat sera disponible après la clôture, prévue le '
              '${Formatters.dateTime(auction.endAt)}.',
          actionLabel: "Voir l'enchère",
          onAction: () => context.pushReplacement(Routes.auction(auction.id)),
        ),
      );
    }

    final winner = auction.winner;
    final userWon = auction.currentUserIsLeading && auction.userHasBid;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: appScreenBar(
        context,
        title: 'Résultat de la vente',
        subtitle: auction.title,
      ),
      body: ContentContainer(
        maxWidth: 760,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            Responsive.value(context, mobile: 16.0, tablet: 24.0),
            16,
            Responsive.value(context, mobile: 16.0, tablet: 24.0),
            28,
          ),
          children: [
            _ResultBanner(
              auction: auction,
              userWon: userWon,
              hasWinner: winner != null,
            ),
            const SizedBox(height: 18),
            AppCard(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  CarImage(
                    url: auction.mainImage,
                    height: 76,
                    width: 104,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          auction.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 5),
                        SpecChip(
                          icon: Icons.speed_rounded,
                          label: Formatters.mileage(auction.mileage),
                        ),
                        const SizedBox(height: 4),
                        SpecChip(
                          icon: Icons.place_rounded,
                          label: auction.city,
                        ),
                      ],
                    ),
                  ),
                  StatusBadge.condition(auction.condition),
                ],
              ),
            ),
            const SizedBox(height: 14),
            AppCard(
              child: Column(
                children: [
                  InfoRow(
                    label: 'Statut',
                    value: winner == null
                        ? 'Terminée sans adjudication'
                        : 'Adjugée',
                    dense: true,
                    valueColor: winner == null
                        ? AppColors.textMuted
                        : AppColors.success,
                  ),
                  InfoRow(
                    label: 'Prix de départ',
                    value: Formatters.moneyShort(auction.startingPrice),
                    dense: true,
                  ),
                  InfoRow(
                    label: 'Offre gagnante',
                    value: winner == null
                        ? '—'
                        : Formatters.money(winner.amount),
                    dense: true,
                    bold: winner != null,
                    valueColor: winner != null ? AppColors.accent : null,
                  ),
                  InfoRow(
                    label: 'Adjudicataire',
                    value: winner == null
                        ? 'Aucun'
                        : (winner.isCurrentUser ? 'Vous' : winner.bidderName),
                    dense: true,
                  ),
                  InfoRow(
                    label: "Nombre d'offres",
                    value: '${auction.bidCount}',
                    dense: true,
                  ),
                  if (auction.reservePrice != null)
                    InfoRow(
                      label: 'Prix de réserve',
                      value: auction.reserveMet
                          ? 'Atteint'
                          : 'Non atteint '
                                '(${Formatters.moneyShort(auction.reservePrice!)})',
                      dense: true,
                      valueColor: auction.reserveMet
                          ? AppColors.success
                          : AppColors.warning,
                    ),
                  InfoRow(
                    label: 'Clôturée le',
                    value: Formatters.dateTime(auction.endAt),
                    dense: true,
                  ),
                ],
              ),
            ),
            if (auction.userHasBid) ...[
              const SizedBox(height: 14),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Votre participation',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    InfoRow(
                      label: 'Votre meilleure offre',
                      value: Formatters.money(auction.userBestBid ?? 0),
                      dense: true,
                    ),
                    InfoRow(
                      label: 'Offres déposées',
                      value:
                          '${auction.bids.where((b) => b.isCurrentUser).length}',
                      dense: true,
                    ),
                    InfoRow(
                      label: 'Résultat',
                      value: userWon ? 'Gagnée' : 'Perdue',
                      dense: true,
                      valueColor: userWon
                          ? AppColors.success
                          : AppColors.danger,
                      bold: true,
                    ),
                  ],
                ),
              ),
            ],
            if (userWon) ...[
              const SizedBox(height: 14),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Reçu d\'adjudication',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    InfoRow(
                      label: 'Montant à régler',
                      value: Formatters.money(auction.currentPrice),
                      dense: true,
                      bold: true,
                      valueColor: AppColors.accent,
                    ),
                    InfoRow(
                      label: 'Statut paiement',
                      value: auction.paymentStatus.label,
                      dense: true,
                      valueColor:
                          auction.paymentStatus == AuctionPaymentStatus.paid
                              ? AppColors.success
                              : AppColors.warning,
                      bold: true,
                    ),
                    if (auction.paidAt != null)
                      InfoRow(
                        label: 'Payé le',
                        value: Formatters.dateTime(auction.paidAt!),
                        dense: true,
                      ),
                    const SizedBox(height: 8),
                    Text(
                      auction.paymentStatus == AuctionPaymentStatus.paid
                          ? 'Paiement enregistré. Présentez-vous en agence '
                              'avec ce reçu pour retirer le véhicule.'
                          : 'Rendez-vous en agence RentCar pour payer. '
                              'Quand le paiement est effectué, validez ci-dessous '
                              'pour passer le reçu à « Payé ».',
                      style: const TextStyle(
                        fontSize: 12.5,
                        height: 1.45,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (auction.paymentStatus != AuctionPaymentStatus.paid)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final ok = await context
                          .read<AuctionProvider>()
                          .markPaid(auction.id);
                      if (!context.mounted) return;
                      if (ok) {
                        AppSnack.success(
                          context,
                          'Reçu mis à jour : paiement confirmé.',
                        );
                      } else {
                        AppSnack.error(context, 'Paiement impossible.');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                    ),
                    icon: const Icon(Icons.payments_rounded, size: 18),
                    label: const Text('Confirmer le paiement en agence'),
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                    ),
                    icon: const Icon(Icons.check_circle_rounded, size: 18),
                    label: const Text('Payé'),
                  ),
                ),
              const SizedBox(height: 10),
            ],
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => context.push(Routes.myAuctions),
                icon: const Icon(Icons.emoji_events_outlined, size: 18),
                label: const Text('Mes enchères'),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: TextButton(
                onPressed: () => context.go(Routes.auctions),
                child: const Text('Retour à la place de marché'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultBanner extends StatelessWidget {
  const _ResultBanner({
    required this.auction,
    required this.userWon,
    required this.hasWinner,
  });

  final Auction auction;
  final bool userWon;
  final bool hasWinner;

  @override
  Widget build(BuildContext context) {
    final (color, icon, title, message) = !hasWinner
        ? (
            AppColors.textMuted,
            Icons.remove_circle_outline_rounded,
            'Terminée sans gagnant',
            "Aucune offre n'a été déposée avant la clôture. Le véhicule sera "
                "remis en vente prochainement.",
          )
        : userWon
        ? (
            AppColors.success,
            Icons.emoji_events_rounded,
            'Félicitations, vous avez gagné !',
            "Votre offre de "
                "${Formatters.moneyShort(auction.currentPrice)} a remporté "
                "cette vente. Réglez en agence pour finaliser.",
          )
        : auction.userHasBid
        ? (
            AppColors.danger,
            Icons.sentiment_dissatisfied_rounded,
            'Enchère perdue',
            "${auction.leadingBidder} a remporté le véhicule pour "
                "${Formatters.moneyShort(auction.currentPrice)}.",
          )
        : (
            AppColors.accent,
            Icons.flag_rounded,
            'Vente adjugée',
            "${auction.leadingBidder} a remporté le véhicule pour "
                "${Formatters.moneyShort(auction.currentPrice)}.",
          );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Container(
            height: 76,
            width: 76,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 40, color: color),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.55,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
