import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/formatters.dart';
import '../data/models/car.dart';
import 'car_image.dart';
import 'common.dart';
import 'status_badge.dart';

/// Carte véhicule du catalogue (grille et liste verticale).
class CarCard extends StatelessWidget {
  const CarCard({
    super.key,
    required this.car,
    required this.onTap,
    this.onReserve,
    this.showAvailability = true,
  });

  final Car car;
  final VoidCallback onTap;
  final VoidCallback? onReserve;
  final bool showAvailability;

  @override
  Widget build(BuildContext context) {
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
            _Header(car: car, showAvailability: showAvailability),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          car.fullName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.star_rounded,
                        size: 16,
                        color: AppColors.gold,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        car.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${car.year} · ${car.category.label} · ${car.city}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 14,
                    runSpacing: 8,
                    children: [
                      SpecChip(
                        icon: Icons.settings_rounded,
                        label: car.transmission.label,
                      ),
                      SpecChip(
                        icon: _fuelIcon(car.fuel),
                        label: car.fuel.label,
                      ),
                      SpecChip(
                        icon: Icons.event_seat_rounded,
                        label: '${car.seats} places',
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (car.hasPromo)
                              Text(
                                Formatters.moneyShort(car.oldPricePerDay!),
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: AppColors.textMuted,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  Formatters.moneyShort(car.pricePerDay),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.5,
                                    color: AppColors.accent,
                                  ),
                                ),
                                const SizedBox(width: 3),
                                const Text(
                                  '/ jour',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: AppColors.textMuted,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 40,
                        child: ElevatedButton(
                          onPressed: onReserve ?? onTap,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(0, 40),
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            backgroundColor: car.available
                                ? AppColors.navy
                                : AppColors.border,
                            foregroundColor: car.available
                                ? Colors.white
                                : AppColors.textMuted,
                            textStyle: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          child: const Text('Détails'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static IconData _fuelIcon(FuelType fuel) => switch (fuel) {
    FuelType.electrique => Icons.electric_bolt_rounded,
    FuelType.hybride => Icons.eco_rounded,
    _ => Icons.local_gas_station_rounded,
  };
}

class _Header extends StatelessWidget {
  const _Header({required this.car, required this.showAvailability});

  final Car car;
  final bool showAvailability;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 168,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CarImage(url: car.mainImage, fit: BoxFit.cover),
          if (!car.available)
            Container(color: AppColors.navy.withValues(alpha: 0.45)),
          Positioned(
            top: 12,
            left: 12,
            child: Row(
              children: [
                if (showAvailability)
                  StatusBadge.availability(car.available, dense: true),
                if (car.hasPromo) ...[
                  const SizedBox(width: 6),
                  StatusBadge(
                    label: car.promoLabel!,
                    color: AppColors.gold,
                    filled: true,
                    dense: true,
                    icon: Icons.local_offer_rounded,
                  ),
                ],
              ],
            ),
          ),
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.navy.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                car.category.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Variante horizontale compacte (carrousels, résultats secondaires).
class CarCardCompact extends StatelessWidget {
  const CarCardCompact({super.key, required this.car, required this.onTap});

  final Car car;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          CarImage(
            url: car.mainImage,
            height: 78,
            width: 104,
            borderRadius: BorderRadius.circular(14),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  car.fullName,
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
                  '${car.year} · ${car.transmission.label}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      Formatters.moneyShort(car.pricePerDay),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: AppColors.accent,
                      ),
                    ),
                    const Text(
                      ' / jour',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const Spacer(),
                    StatusBadge.availability(car.available, dense: true),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
