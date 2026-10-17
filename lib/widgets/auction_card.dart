import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/formatters.dart';
import '../data/models/auction.dart';
import '../data/models/car.dart';
import 'car_image.dart';
import 'common.dart';
import 'countdown.dart';
import 'status_badge.dart';

/// Carte d'une vente aux enchères dans la place de marché.
class AuctionCard extends StatelessWidget {
  const AuctionCard({
    super.key,
    required this.auction,
    required this.onTap,
    this.userTag,
  });

  final Auction auction;
  final VoidCallback onTap;

  /// Étiquette contextuelle (« Vous êtes en tête », « Surenchéri »…).
  final Widget? userTag;

  @override
  Widget build(BuildContext context) {
    final status = auction.computedStatus;
    final ended = status == AuctionStatus.terminee ||
        status == AuctionStatus.annulee;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: AppColors.border),
          boxShadow: AppTheme.softShadow,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 170,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CarImage(url: auction.mainImage, fit: BoxFit.cover),
                  if (ended)
                    Container(color: AppColors.navy.withValues(alpha: 0.42)),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: StatusBadge.auction(status),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: CountdownPill(
                      endAt: auction.endAt,
                      ended: ended,
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: StatusBadge.condition(auction.condition),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    auction.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 14,
                    runSpacing: 6,
                    children: [
                      SpecChip(
                        icon: Icons.speed_rounded,
                        label: Formatters.mileage(auction.mileage),
                      ),
                      SpecChip(
                        icon: Icons.local_gas_station_rounded,
                        label: auction.fuel.label,
                      ),
                      SpecChip(
                        icon: Icons.place_rounded,
                        label: auction.city,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    auction.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      height: 1.4,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
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
                              Text(
                                auction.hasBids
                                    ? 'Enchère actuelle'
                                    : 'Prix de départ',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textMuted,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                Formatters.moneyShort(auction.currentPrice),
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
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'Offres',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textMuted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${auction.bidCount}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (userTag != null) ...[
                    const SizedBox(height: 10),
                    userTag!,
                  ],
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: onTap,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 46),
                        backgroundColor: ended
                            ? AppColors.navySoft
                            : AppColors.accent,
                      ),
                      icon: Icon(
                        ended ? Icons.visibility_rounded : Icons.gavel_rounded,
                        size: 18,
                      ),
                      label: Text(
                        ended ? 'Voir le résultat' : "Voir l'enchère",
                      ),
                    ),
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

/// Étiquette d'état de participation de l'utilisateur.
class BidStatusTag extends StatelessWidget {
  const BidStatusTag({super.key, required this.auction});

  final Auction auction;

  @override
  Widget build(BuildContext context) {
    if (!auction.userHasBid) return const SizedBox.shrink();

    final (label, color, icon) = switch ((
      auction.isEnded,
      auction.currentUserIsLeading,
    )) {
      (true, true) => (
        'Gagnée',
        AppColors.success,
        Icons.emoji_events_rounded,
      ),
      (true, false) => ('Perdue', AppColors.danger, Icons.close_rounded),
      (false, true) => (
        'Vous êtes en tête',
        AppColors.success,
        Icons.trending_up_rounded,
      ),
      (false, false) => (
        'Surenchéri',
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
        border: Border.all(color: color.withValues(alpha: 0.3)),
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
          if (auction.userBestBid != null)
            Text(
              'Votre offre : ${Formatters.moneyShort(auction.userBestBid!)}',
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
        ],
      ),
    );
  }
}
