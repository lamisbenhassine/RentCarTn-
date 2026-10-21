import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive.dart';
import '../../data/models/car.dart';
import '../../data/models/date_range.dart';
import '../../data/models/reservation.dart';
import '../../state/car_provider.dart';
import '../../state/load_state.dart';
import '../../state/cart_provider.dart';
import '../../widgets/car_image.dart';
import '../../widgets/common.dart';
import '../../widgets/status_badge.dart';

class CarDetailsScreen extends StatefulWidget {
  const CarDetailsScreen({super.key, required this.carId});

  final String carId;

  @override
  State<CarDetailsScreen> createState() => _CarDetailsScreenState();
}

class _CarDetailsScreenState extends State<CarDetailsScreen> {
  int _imageIndex = 0;
  late DateTime _start;
  late DateTime _end;
  String _pickupCity = 'Tunis';
  String _returnCity = 'Tunis';
  final Set<String> _selectedExtras = {};

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _start = DateTime(now.year, now.month, now.day).add(
      const Duration(days: 1),
    );
    _end = _start.add(const Duration(days: 3));
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<CarProvider>().load();
      if (!mounted) return;
      final car = context.read<CarProvider>().carById(widget.carId);
      if (car != null) {
        setState(() {
          _pickupCity = car.city;
          _returnCity = car.city;
        });
      }
    });
  }

  DateRange get _range => DateRange(_start, _end);

  Future<void> _pickDates(Car car) async {
    final now = DateTime.now();
    final result = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(start: _start, end: _end),
      helpText: 'Période de location',
      saveText: 'Valider',
      locale: const Locale('fr', 'FR'),
    );
    if (result == null) return;
    setState(() {
      _start = result.start;
      _end = result.end;
    });
  }

  List<RentalExtra> _extrasFor(CarProvider provider) => provider.extras
      .where((e) => _selectedExtras.contains(e.id))
      .toList();

  double _total(Car car, List<RentalExtra> extras) {
    final days = _range.days;
    final base = car.pricePerDay * days;
    final extrasTotal = extras.fold(0.0, (s, e) => s + e.totalFor(days));
    return base + extrasTotal;
  }

  void _addToCart(Car car, CarProvider provider, {bool thenCheckout = false}) {
    final cart = context.read<CartProvider>();
    final result = cart.add(
      car: car,
      range: _range,
      pickupCity: _pickupCity,
      returnCity: _returnCity,
      extras: _extrasFor(provider),
    );

    if (!result.ok) {
      AppSnack.error(context, result.message);
      return;
    }
    AppSnack.success(context, result.message);
    if (thenCheckout) {
      context.push(Routes.cart);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CarProvider>();
    final car = provider.carById(widget.carId);

    if (provider.state.isLoading && car == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (car == null) {
      return Scaffold(
        appBar: AppBar(),
        body: EmptyState(
          icon: Icons.car_crash_rounded,
          title: 'Véhicule introuvable',
          message: "Ce véhicule n'existe plus dans notre catalogue.",
          actionLabel: 'Retour au catalogue',
          onAction: () => context.go(Routes.catalog),
        ),
      );
    }

    final extras = _extrasFor(provider);
    final conflict = car.conflictFor(_range);
    final bookable = car.available && conflict == null;
    final wide = Responsive.isWide(context);

    final gallery = _Gallery(
      car: car,
      index: _imageIndex,
      onIndexChanged: (i) => setState(() => _imageIndex = i),
    );

    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TitleBlock(car: car),
        const SizedBox(height: 20),
        _SpecsGrid(car: car),
        const SizedBox(height: 22),
        _Section(
          title: 'Description',
          child: Text(
            car.description,
            style: const TextStyle(
              fontSize: 14,
              height: 1.65,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        _Section(
          title: 'Équipements',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final feature in car.features)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_rounded,
                        size: 14,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        feature,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        _Section(
          title: 'Disponibilité et dates',
          child: _AvailabilityBlock(
            car: car,
            range: _range,
            conflict: conflict,
            onPickDates: () => _pickDates(car),
          ),
        ),
        _Section(
          title: 'Lieux de prise en charge et de retour',
          child: _LocationBlock(
            cities: provider.cities,
            pickupCity: _pickupCity,
            returnCity: _returnCity,
            onPickup: (v) => setState(() => _pickupCity = v),
            onReturn: (v) => setState(() => _returnCity = v),
          ),
        ),
        _Section(
          title: 'Options supplémentaires',
          child: Column(
            children: [
              for (final extra in provider.extras)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  value: _selectedExtras.contains(extra.id),
                  onChanged: (v) => setState(() {
                    if (v ?? false) {
                      _selectedExtras.add(extra.id);
                    } else {
                      _selectedExtras.remove(extra.id);
                    }
                  }),
                  title: Text(
                    extra.label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    extra.oneShot
                        ? '${Formatters.moneyShort(extra.pricePerDay)} '
                              '(forfait)'
                        : '${Formatters.moneyShort(extra.pricePerDay)} / jour',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
            ],
          ),
        ),
        _Section(
          title: 'Conditions de location',
          child: _ConditionsBlock(car: car),
        ),
        _Section(
          title: 'Estimation du prix',
          child: _PriceBreakdown(
            car: car,
            days: _range.days,
            extras: extras,
          ),
        ),
        const SizedBox(height: 10),
        const NoticeBox(
          icon: Icons.science_outlined,
          message:
              "Tarifs, disponibilités et conditions sont simulés pour la "
              "démonstration.",
        ),
      ],
    );

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: wide ? 0 : 290,
            backgroundColor: AppColors.surface,
            surfaceTintColor: AppColors.surface,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: _CircleButton(
                icon: Icons.arrow_back_rounded,
                onTap: () => context.canPop()
                    ? context.pop()
                    : context.go(Routes.catalog),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: _CircleButton(
                  icon: Icons.shopping_bag_outlined,
                  onTap: () => context.push(Routes.cart),
                  badge: context.watch<CartProvider>().count,
                ),
              ),
            ],
            flexibleSpace: wide
                ? null
                : FlexibleSpaceBar(background: gallery),
          ),
          SliverToBoxAdapter(
            child: ContentContainer(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  Responsive.value(
                    context,
                    mobile: 16.0,
                    tablet: 24.0,
                    desktop: 32.0,
                  ),
                  wide ? 8 : 20,
                  Responsive.value(
                    context,
                    mobile: 16.0,
                    tablet: 24.0,
                    desktop: 32.0,
                  ),
                  32,
                ),
                child: wide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 5,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusLg,
                              ),
                              child: SizedBox(height: 420, child: gallery),
                            ),
                          ),
                          const SizedBox(width: 32),
                          Expanded(flex: 6, child: details),
                        ],
                      )
                    : details,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomActionBar(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Total ${Formatters.pluralDays(_range.days)}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    Formatters.money(_total(car, extras)),
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            OutlinedButton(
              onPressed: bookable ? () => _addToCart(car, provider) : null,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 52),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: const Icon(Icons.add_shopping_cart_rounded, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: bookable
                    ? () => _addToCart(car, provider, thenCheckout: true)
                    : null,
                child: Text(bookable ? 'Réserver' : 'Indisponible'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ Galerie

class _Gallery extends StatelessWidget {
  const _Gallery({
    required this.car,
    required this.index,
    required this.onIndexChanged,
  });

  final Car car;
  final int index;
  final ValueChanged<int> onIndexChanged;

  @override
  Widget build(BuildContext context) {
    final images = car.images.isEmpty ? [''] : car.images;

    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          itemCount: images.length,
          onPageChanged: onIndexChanged,
          itemBuilder: (_, i) => CarImage(url: images[i], fit: BoxFit.cover),
        ),
        if (!car.available)
          Container(color: AppColors.navy.withValues(alpha: 0.4)),
        Positioned(
          bottom: 16,
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
        Positioned(
          bottom: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.navy.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              '${index + 1}/${images.length}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.onTap,
    this.badge = 0,
  });

  final IconData icon;
  final VoidCallback onTap;
  final int badge;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: AppColors.surfaceAlt,
          shape: const CircleBorder(
            side: BorderSide(color: AppColors.border),
          ),
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: SizedBox(
              height: 40,
              width: 40,
              child: Icon(icon, size: 20, color: AppColors.navy),
            ),
          ),
        ),
        if (badge > 0)
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: const BoxDecoration(
                color: AppColors.danger,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$badge',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
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

// ------------------------------------------------------------------- Blocs

class _TitleBlock extends StatelessWidget {
  const _TitleBlock({required this.car});

  final Car car;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StatusBadge.availability(car.available),
        const SizedBox(height: 14),
        Text(car.fullName, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 6),
        Row(
          children: [
            const Icon(
              Icons.place_rounded,
              size: 16,
              color: AppColors.textMuted,
            ),
            const SizedBox(width: 2),
            Text(
              car.city,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Année ${car.year}',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              Formatters.moneyShort(car.pricePerDay),
              style: const TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.w900,
                letterSpacing: -1,
                color: AppColors.accent,
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 5, left: 4),
              child: Text(
                '/ jour',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SpecsGrid extends StatelessWidget {
  const _SpecsGrid({required this.car});

  final Car car;

  @override
  Widget build(BuildContext context) {
    final specs = <(IconData, String, String)>[
      (Icons.branding_watermark_rounded, 'Marque', car.brand),
      (Icons.event_seat_rounded, 'Places', '${car.seats}'),
      (Icons.sensor_door_rounded, 'Portes', '${car.doors}'),
      (Icons.luggage_rounded, 'Bagages', '${car.luggage}'),
      (
        Icons.ac_unit_rounded,
        'Climatisation',
        car.airConditioning ? 'Oui' : 'Non',
      ),
      (Icons.calendar_month_rounded, 'Année', '${car.year}'),
      (Icons.place_rounded, 'Lieu', car.city),
      (
        Icons.payments_rounded,
        'Prix / jour',
        Formatters.moneyShort(car.pricePerDay),
      ),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: Responsive.value(context, mobile: 2, tablet: 4),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 2.5,
      children: [
        for (final (icon, label, value) in specs)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: AppColors.accent),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16.5,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _AvailabilityBlock extends StatelessWidget {
  const _AvailabilityBlock({
    required this.car,
    required this.range,
    required this.conflict,
    required this.onPickDates,
  });

  final Car car;
  final DateRange range;
  final DateRange? conflict;
  final VoidCallback onPickDates;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppCard(
          onTap: onPickDates,
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  size: 19,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Période sélectionnée',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${Formatters.date(range.start)} → '
                      '${Formatters.date(range.end)}  '
                      '(${Formatters.pluralDays(range.days)})',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.edit_calendar_rounded, size: 19),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (!car.available)
          const NoticeBox(
            icon: Icons.do_not_disturb_on_rounded,
            color: AppColors.danger,
            title: 'Véhicule indisponible',
            message:
                "Ce véhicule est actuellement retiré du parc (maintenance). "
                "La réservation est désactivée.",
          )
        else if (conflict != null)
          NoticeBox(
            icon: Icons.event_busy_rounded,
            color: AppColors.danger,
            title: 'Déjà réservé sur cette période',
            message:
                'Indisponible du ${Formatters.date(conflict!.start)} au '
                '${Formatters.date(conflict!.end)}. Modifiez vos dates pour '
                'réserver ce véhicule.',
          )
        else
          const NoticeBox(
            icon: Icons.event_available_rounded,
            color: AppColors.success,
            title: 'Disponible sur ces dates',
            message:
                "Le véhicule peut être réservé pour la période sélectionnée.",
          ),
        if (car.bookedRanges.isNotEmpty) ...[
          const SizedBox(height: 14),
          const Text(
            'Périodes déjà réservées',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final booked in car.bookedRanges)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.dangerSoft,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    '${Formatters.dayMonth(booked.start)} → '
                    '${Formatters.dayMonth(booked.end)}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.danger,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _LocationBlock extends StatelessWidget {
  const _LocationBlock({
    required this.cities,
    required this.pickupCity,
    required this.returnCity,
    required this.onPickup,
    required this.onReturn,
  });

  final List<String> cities;
  final String pickupCity;
  final String returnCity;
  final ValueChanged<String> onPickup;
  final ValueChanged<String> onReturn;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DropdownButtonFormField<String>(
          initialValue: cities.contains(pickupCity) ? pickupCity : cities.first,
          decoration: const InputDecoration(
            labelText: 'Prise en charge',
            prefixIcon: Icon(Icons.flight_land_rounded),
          ),
          items: [
            for (final c in cities) DropdownMenuItem(value: c, child: Text(c)),
          ],
          onChanged: (v) => onPickup(v ?? pickupCity),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: cities.contains(returnCity) ? returnCity : cities.first,
          decoration: const InputDecoration(
            labelText: 'Retour',
            prefixIcon: Icon(Icons.flight_takeoff_rounded),
          ),
          items: [
            for (final c in cities) DropdownMenuItem(value: c, child: Text(c)),
          ],
          onChanged: (v) => onReturn(v ?? returnCity),
        ),
      ],
    );
  }
}

class _ConditionsBlock extends StatelessWidget {
  const _ConditionsBlock({required this.car});

  final Car car;

  @override
  Widget build(BuildContext context) {
    final conditions = [
      'Âge minimum du conducteur : 21 ans (30 ans pour la catégorie Luxe).',
      'Permis de conduire valide depuis au moins 2 ans.',
      'Caution de ${Formatters.moneyShort(car.deposit)} bloquée puis libérée '
          'au retour du véhicule.',
      'Kilométrage inclus : ${car.mileageLimitPerDay} km par jour, '
          '0,350 TND par km supplémentaire.',
      'Carburant : niveau identique au départ et au retour.',
      'Annulation gratuite jusqu\'à 48 h avant la prise en charge.',
      'Conduite hors Tunisie interdite sans autorisation écrite.',
    ];

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < conditions.length; i++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 3),
                  child: Icon(
                    Icons.check_circle_outline_rounded,
                    size: 16,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    conditions[i],
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            if (i != conditions.length - 1) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _PriceBreakdown extends StatelessWidget {
  const _PriceBreakdown({
    required this.car,
    required this.days,
    required this.extras,
  });

  final Car car;
  final int days;
  final List<RentalExtra> extras;

  @override
  Widget build(BuildContext context) {
    final base = car.pricePerDay * days;
    final extrasTotal = extras.fold(0.0, (s, e) => s + e.totalFor(days));
    final total = base + extrasTotal;

    return AppCard(
      child: Column(
        children: [
          InfoRow(
            label:
                '${Formatters.moneyShort(car.pricePerDay)} × '
                '${Formatters.pluralDays(days)}',
            value: Formatters.money(base),
          ),
          for (final extra in extras)
            InfoRow(
              label: extra.label,
              value: Formatters.money(extra.totalFor(days)),
              dense: true,
            ),
          const Divider(height: 22),
          InfoRow(
            label: 'Total estimé (hors taxes et frais)',
            value: Formatters.money(total),
            bold: true,
            valueColor: AppColors.accent,
          ),
          const SizedBox(height: 4),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'TVA 19 % et frais de dossier ajoutés au paiement.',
              style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}
