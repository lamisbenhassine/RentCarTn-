import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive.dart';
import '../../data/models/car.dart';
import '../../state/car_provider.dart';
import '../../state/cart_provider.dart';
import '../../state/load_state.dart';
import '../../widgets/car_card.dart';
import '../../widgets/common.dart';
import '../shell/main_shell.dart';
import 'filters_sheet.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key, this.initialCategory, this.initialQuery});

  final String? initialCategory;
  final String? initialQuery;

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<CarProvider>();
      await provider.load();
      if (!mounted) return;

      if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
        _searchCtrl.text = widget.initialQuery!;
        provider.setQuery(widget.initialQuery!);
      }
      final categoryId = widget.initialCategory;
      if (categoryId != null && provider.category == null) {
        for (final c in CarCategory.values) {
          if (c.id == categoryId) {
            provider.setCategory(c);
            break;
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _openFilters() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const FiltersSheet(),
    );
  }

  void _openSort() {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        final provider = context.read<CarProvider>();
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
              const SizedBox(height: 16),
              const Text(
                'Trier par',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              RadioGroup<CarSort>(
                groupValue: provider.sort,
                onChanged: (v) {
                  if (v != null) provider.setSort(v);
                  Navigator.of(sheetContext).pop();
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final option in CarSort.values)
                      RadioListTile<CarSort>(
                        value: option,
                        title: Text(option.label),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CarProvider>();
    final cars = provider.filteredCars;
    final wide = Responsive.isWide(context);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: wide
          ? null
          : AppBar(
              backgroundColor: AppColors.surface,
              automaticallyImplyLeading: false,
              toolbarHeight: 64,
              title: const Text('Location de véhicules'),
              actions: [
                IconButton(
                  tooltip: 'Gérer les véhicules',
                  onPressed: () => context.push(Routes.manageCars),
                  icon: const Icon(Icons.edit_note_rounded),
                ),
                CartButton(count: context.watch<CartProvider>().count),
                const SizedBox(width: 6),
              ],
            ),
      body: SafeArea(
        top: false,
        child: ContentContainer(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  Responsive.pagePadding(context).horizontal / 2,
                  wide ? 24 : 4,
                  Responsive.pagePadding(context).horizontal / 2,
                  12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (wide) ...[
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Location de véhicules',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => context.push(Routes.manageCars),
                            icon: const Icon(Icons.edit_note_rounded, size: 18),
                            label: const Text('Gérer'),
                          ),
                          const SizedBox(width: 10),
                          CartButton(
                            count: context.watch<CartProvider>().count,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                    _SearchBar(
                      controller: _searchCtrl,
                      onChanged: provider.setQuery,
                      onFilters: _openFilters,
                      onSort: _openSort,
                      filterCount: provider.activeFilterCount,
                    ),
                    const SizedBox(height: 12),
                    _CategoryChips(provider: provider),
                    const SizedBox(height: 10),
                    _ResultsBar(
                      count: cars.length,
                      sortLabel: provider.sort.label,
                      hasFilters: provider.activeFilterCount > 0 ||
                          provider.query.isNotEmpty,
                      onReset: () {
                        _searchCtrl.clear();
                        provider.resetFilters();
                      },
                    ),
                  ],
                ),
              ),
              Expanded(child: _body(provider, cars, wide)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(CarProvider provider, List<Car> cars, bool wide) {
    if (provider.state.isLoading) {
      return GridView.builder(
        padding: shellPadding(context).copyWith(top: 4),
        itemCount: 6,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: Responsive.gridColumns(context),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          mainAxisExtent: 352,
        ),
        itemBuilder: (_, _) => const CarCardSkeleton(),
      );
    }

    if (provider.state.isError) {
      return ErrorState(
        message: provider.errorMessage ?? 'Erreur inconnue.',
        onRetry: () => provider.load(force: true),
      );
    }

    if (cars.isEmpty) {
      return EmptyState(
        icon: Icons.search_off_rounded,
        title: 'Aucun véhicule trouvé',
        message:
            'Aucun résultat ne correspond à votre recherche. Essayez '
            'd\'élargir vos critères ou de réinitialiser les filtres.',
        actionLabel: 'Réinitialiser les filtres',
        onAction: () {
          _searchCtrl.clear();
          provider.resetFilters();
        },
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.load(force: true),
      child: GridView.builder(
        padding: shellPadding(context).copyWith(top: 4),
        itemCount: cars.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: Responsive.gridColumns(context),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          mainAxisExtent: 352,
        ),
        itemBuilder: (_, i) => CarCard(
          car: cars[i],
          onTap: () => context.push(Routes.car(cars[i].id)),
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.onFilters,
    required this.onSort,
    required this.filterCount,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onFilters;
  final VoidCallback onSort;
  final int filterCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Rechercher une voiture…',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: controller.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        controller.clear();
                        onChanged('');
                      },
                      icon: const Icon(Icons.close_rounded, size: 19),
                    ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        _IconAction(
          icon: Icons.tune_rounded,
          onTap: onFilters,
          badge: filterCount,
          tooltip: 'Filtres',
        ),
        const SizedBox(width: 8),
        _IconAction(
          icon: Icons.swap_vert_rounded,
          onTap: onSort,
          tooltip: 'Trier',
        ),
      ],
    );
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({
    required this.icon,
    required this.onTap,
    required this.tooltip,
    this.badge = 0,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  final int badge;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Stack(
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
              child: Icon(icon, color: AppColors.navy),
            ),
          ),
          if (badge > 0)
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
                  '$badge',
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
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({required this.provider});

  final CarProvider provider;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          ChoiceChip(
            label: const Text('Toutes'),
            selected: provider.category == null,
            onSelected: (_) => provider.setCategory(provider.category),
          ),
          const SizedBox(width: 8),
          for (final category in CarCategory.values) ...[
            ChoiceChip(
              label: Text(category.label),
              selected: provider.category == category,
              onSelected: (_) => provider.setCategory(category),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _ResultsBar extends StatelessWidget {
  const _ResultsBar({
    required this.count,
    required this.sortLabel,
    required this.hasFilters,
    required this.onReset,
  });

  final int count;
  final String sortLabel;
  final bool hasFilters;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '${Formatters.number(count)} véhicule${count > 1 ? 's' : ''}',
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '· $sortLabel',
          style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
        ),
        const Spacer(),
        if (hasFilters)
          TextButton.icon(
            onPressed: onReset,
            icon: const Icon(Icons.restart_alt_rounded, size: 17),
            label: const Text('Réinitialiser'),
          ),
      ],
    );
  }
}
