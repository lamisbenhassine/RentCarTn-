import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/car.dart';
import '../../state/car_provider.dart';

/// Panneau de filtres du catalogue (bottom sheet).
class FiltersSheet extends StatelessWidget {
  const FiltersSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CarProvider>();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return Column(
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
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                children: [
                  _Group(
                    title: 'Disponibilité',
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: provider.onlyAvailable,
                      onChanged: provider.setOnlyAvailable,
                      title: const Text(
                        'Véhicules disponibles uniquement',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        provider.searchRange == null
                            ? 'Masque les véhicules indisponibles'
                            : 'Selon la période sélectionnée',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                  _Group(
                    title: 'Prix par jour',
                    trailing:
                        '${Formatters.moneyShort(provider.minPrice)} – '
                        '${Formatters.moneyShort(provider.maxPrice)}',
                    child: RangeSlider(
                      values: RangeValues(
                        provider.minPrice.clamp(0, provider.priceCeiling),
                        provider.maxPrice.clamp(0, provider.priceCeiling),
                      ),
                      min: 0,
                      max: provider.priceCeiling,
                      divisions: 20,
                      labels: RangeLabels(
                        provider.minPrice.round().toString(),
                        provider.maxPrice.round().toString(),
                      ),
                      onChanged: (values) =>
                          provider.setPriceRange(values.start, values.end),
                    ),
                  ),
                  _Group(
                    title: 'Catégorie',
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final c in CarCategory.values)
                          FilterChip(
                            label: Text(c.label),
                            selected: provider.category == c,
                            onSelected: (_) => provider.setCategory(c),
                          ),
                      ],
                    ),
                  ),
                  _Group(
                    title: 'Marque',
                    child: Wrap(
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
                  ),
                  _Group(
                    title: 'Boîte de vitesses',
                    child: Wrap(
                      spacing: 8,
                      children: [
                        for (final t in Transmission.values)
                          FilterChip(
                            label: Text(t.label),
                            selected: provider.transmission == t,
                            onSelected: (_) => provider.setTransmission(t),
                          ),
                      ],
                    ),
                  ),
                  _Group(
                    title: 'Carburant',
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final f in FuelType.values)
                          FilterChip(
                            label: Text(f.label),
                            selected: provider.fuel == f,
                            onSelected: (_) => provider.setFuel(f),
                          ),
                      ],
                    ),
                  ),
                  _Group(
                    title: 'Nombre de places minimum',
                    child: Wrap(
                      spacing: 8,
                      children: [
                        for (final seats in [2, 4, 5, 7])
                          FilterChip(
                            label: Text('$seats+'),
                            selected: provider.minSeats == seats,
                            onSelected: (_) => provider.setMinSeats(seats),
                          ),
                      ],
                    ),
                  ),
                  _Group(
                    title: 'Agence / ville',
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final city
                            in provider.allCars
                                .map((c) => c.city)
                                .toSet()
                                .toList()
                              ..sort())
                          FilterChip(
                            label: Text(city),
                            selected: provider.city == city,
                            onSelected: (_) => provider.setCity(city),
                          ),
                      ],
                    ),
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
                    'Afficher ${provider.filteredCars.length} véhicule'
                    '${provider.filteredCars.length > 1 ? 's' : ''}',
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.title, required this.child, this.trailing});

  final String title;
  final Widget child;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (trailing != null)
                Text(
                  trailing!,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accent,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
