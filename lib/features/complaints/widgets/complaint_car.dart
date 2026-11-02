import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/car.dart';
import '../../../l10n/l10n.dart';
import '../../../state/car_provider.dart';
import '../../../state/load_state.dart';
import '../../../widgets/car_image.dart';
import '../../../widgets/common.dart';

/// Ouvre la liste des voitures du catalogue (table cars, via CarProvider).
/// Retourne la voiture choisie, ou `null` si la feuille est fermée.
Future<Car?> showComplaintCarPicker(
  BuildContext context, {
  String? selectedId,
}) {
  return showModalBottomSheet<Car>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _CarPickerSheet(selectedId: selectedId),
  );
}

/// Miniature de la voiture (photo du catalogue ou icône si retirée).
class ComplaintCarThumb extends StatelessWidget {
  const ComplaintCarThumb({super.key, required this.car, this.size = 56});

  final Car? car;
  final double size;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppTheme.radiusSm);
    if (car == null) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: context.cs.surfaceContainerHighest,
          borderRadius: radius,
        ),
        child: Icon(Icons.no_crash_outlined, color: context.cs.outline),
      );
    }
    return CarImage(
      url: car!.mainImage,
      width: size * 1.3,
      height: size,
      borderRadius: radius,
    );
  }
}

/// Champ « Véhicule concerné » du formulaire : ouvre [showComplaintCarPicker].
class ComplaintCarField extends StatelessWidget {
  const ComplaintCarField({
    super.key,
    required this.car,
    required this.fallbackLabel,
    required this.required,
    required this.fromReservation,
    required this.error,
    required this.onTap,
    this.onClear,
  });

  /// Voiture choisie, trouvée dans le catalogue.
  final Car? car;

  /// Libellé enregistré si la voiture n'existe plus en base (modification).
  final String? fallbackLabel;
  final bool required;
  final bool fromReservation;
  final bool error;
  final VoidCallback onTap;

  /// Retirer le choix (catégories où le véhicule est facultatif).
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final hasValue = car != null || fallbackLabel != null;
    final borderColor = error
        ? AppColors.danger
        : (hasValue ? context.cs.primary : context.cs.outlineVariant);

    final String title;
    final String subtitle;
    if (car != null) {
      title = car!.title;
      subtitle = fromReservation
          ? '${car!.city} · ${l.complaintCarFromReservation}'
          : car!.city;
    } else if (fallbackLabel != null) {
      title = fallbackLabel!;
      subtitle = l.complaintCarRemoved;
    } else {
      title = l.complaintCarPick;
      subtitle = required
          ? l.complaintCarRequiredHint
          : l.complaintCarOptionalHint;
    }

    return Material(
      color: context.cs.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        side: BorderSide(color: borderColor, width: hasValue ? 1.6 : 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              hasValue
                  ? ComplaintCarThumb(car: car, size: 48)
                  : Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: context.cs.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      ),
                      child: Icon(
                        Icons.directions_car_rounded,
                        color: context.cs.primary,
                      ),
                    ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: hasValue
                            ? context.cs.onSurface
                            : context.cs.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: car == null && fallbackLabel != null
                            ? AppColors.warning
                            : context.cs.outline,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasValue && onClear != null)
                IconButton(
                  tooltip: MaterialLocalizations.of(context)
                      .deleteButtonTooltip,
                  onPressed: onClear,
                  icon: const Icon(Icons.close_rounded),
                )
              else
                Icon(Icons.expand_more_rounded, color: context.cs.outline),
            ],
          ),
        ),
      ),
    );
  }
}

/// Carte du véhicule dans le détail d'une réclamation : photo, marque,
/// modèle, ville ; clic → fiche de la voiture. Voiture supprimée →
/// libellé enregistré + « Véhicule retiré du catalogue ».
class ComplaintCarCard extends StatelessWidget {
  const ComplaintCarCard({super.key, required this.carId, required this.label});

  final String? carId;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cars = context.watch<CarProvider>();
    if (cars.state == LoadState.initial) {
      WidgetsBinding.instance.addPostFrameCallback((_) => cars.load());
    }
    final car = carId == null ? null : cars.carById(carId!);
    // Catalogue pas encore chargé : on attend avant d'annoncer « retiré ».
    final loading =
        car == null &&
        carId != null &&
        (cars.state == LoadState.initial || cars.state.isLoading);

    final title = car?.fullName ?? label ?? '';
    // Sans carId (réclamation antérieure au catalogue) : libellé seul.
    final subtitle = car != null
        ? '${car.year} · ${car.city}'
        : (loading || carId == null ? '' : l.complaintCarRemoved);

    return AppCard(
      color: context.cs.surface,
      borderColor: context.cs.outlineVariant,
      padding: const EdgeInsets.all(12),
      onTap: car == null ? null : () => context.push(Routes.car(car.id)),
      child: Row(
        children: [
          ComplaintCarThumb(car: car, size: 60),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.complaintCarLabel,
                  style: TextStyle(fontSize: 12, color: context.cs.outline),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: context.cs.onSurface,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        car != null
                            ? Icons.location_on_outlined
                            : Icons.info_outline_rounded,
                        size: 14,
                        color: car != null
                            ? context.cs.outline
                            : AppColors.warning,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: car != null
                                ? context.cs.onSurfaceVariant
                                : AppColors.warning,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (car != null)
            Tooltip(
              message: l.complaintCarOpen,
              child: Icon(
                Icons.chevron_right_rounded,
                color: context.cs.outline,
              ),
            )
          else if (loading)
            const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
    );
  }
}

class _CarPickerSheet extends StatefulWidget {
  const _CarPickerSheet({this.selectedId});

  final String? selectedId;

  @override
  State<_CarPickerSheet> createState() => _CarPickerSheetState();
}

class _CarPickerSheetState extends State<_CarPickerSheet> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    // Catalogue vide (pas encore chargé) : on le charge depuis la base.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final cars = context.read<CarProvider>();
      if (cars.allCars.isEmpty) cars.load(force: true);
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  /// Recherche sur la marque, le modèle et la ville (sans les filtres du
  /// catalogue, qui appartiennent à l'écran de recherche).
  List<Car> _filter(List<Car> all) {
    final q = _query.trim().toLowerCase();
    final list = all.where((c) {
      if (q.isEmpty) return true;
      return '${c.brand} ${c.model} ${c.city}'.toLowerCase().contains(q);
    }).toList()..sort((a, b) => a.title.compareTo(b.title));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final provider = context.watch<CarProvider>();
    final all = provider.allCars;
    final cars = _filter(all);

    final Widget content;
    if (all.isEmpty &&
        (provider.state == LoadState.initial || provider.state.isLoading)) {
      content = const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (all.isEmpty && provider.state.isError) {
      content = EmptyState(
        compact: true,
        icon: Icons.cloud_off_rounded,
        title: l.complaintCarLoadError,
        message: provider.errorMessage ?? '',
        actionLabel: l.complaintCarRetry,
        onAction: () => provider.load(force: true),
      );
    } else if (all.isEmpty) {
      content = EmptyState(
        compact: true,
        icon: Icons.directions_car_outlined,
        title: l.complaintCarEmpty,
        message: '',
      );
    } else if (cars.isEmpty) {
      content = EmptyState(
        compact: true,
        icon: Icons.search_off_rounded,
        title: l.complaintCarNoMatch(_query.trim()),
        message: '',
      );
    } else {
      content = ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        itemCount: cars.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, i) => _CarRow(
          car: cars[i],
          selected: cars[i].id == widget.selectedId,
          onTap: () => Navigator.pop(context, cars[i]),
        ),
      );
    }

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Text(
                  l.complaintCarLabel,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (all.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: TextField(
                    controller: _search,
                    textInputAction: TextInputAction.search,
                    onChanged: (v) => setState(() => _query = v),
                    decoration: InputDecoration(
                      hintText: l.complaintCarSearch,
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: () {
                                _search.clear();
                                setState(() => _query = '');
                              },
                            ),
                    ),
                  ),
                ),
              Flexible(child: content),
            ],
          ),
        ),
      ),
    );
  }
}

class _CarRow extends StatelessWidget {
  const _CarRow({
    required this.car,
    required this.selected,
    required this.onTap,
  });

  final Car car;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = context.cs.primary;
    return Material(
      color: selected ? accent.withValues(alpha: 0.10) : context.cs.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        side: BorderSide(
          color: selected ? accent : context.cs.outlineVariant,
          width: selected ? 1.6 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              ComplaintCarThumb(car: car, size: 48),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      car.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: context.cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${car.year} · ${car.city}',
                      style: TextStyle(fontSize: 12, color: context.cs.outline),
                    ),
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: selected ? accent : context.cs.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
