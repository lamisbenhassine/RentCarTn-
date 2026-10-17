import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive.dart';
import '../../data/mock/mock_images.dart';
import '../../data/models/car.dart';
import '../../data/models/date_range.dart';
import '../../data/models/reservation.dart';
import '../../state/auction_provider.dart';
import '../../state/auth_provider.dart';
import '../../state/car_provider.dart';
import '../../state/cart_provider.dart';
import '../../state/load_state.dart';
import '../../state/reservation_provider.dart';
import '../../widgets/car_card.dart';
import '../../widgets/car_image.dart';
import '../../widgets/common.dart';
import '../../widgets/countdown.dart';
import '../shell/main_shell.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchCtrl = TextEditingController();
  String _pickupCity = 'Tunis';
  DateTimeRange? _dates;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CarProvider>().load();
      context.read<AuctionProvider>().load();
      context.read<ReservationProvider>().load();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDates() async {
    final now = DateTime.now();
    final result = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
      initialDateRange: _dates,
      helpText: 'Période de location',
      saveText: 'Valider',
      locale: const Locale('fr', 'FR'),
    );
    if (result != null) setState(() => _dates = result);
  }

  void _search() {
    final cars = context.read<CarProvider>();
    cars.setQuery(_searchCtrl.text);
    if (cars.city != _pickupCity) cars.setCity(_pickupCity);
    if (_dates != null) {
      cars.setSearchRange(DateRange(_dates!.start, _dates!.end));
      cars.setOnlyAvailable(true);
    }
    context.go('${Routes.catalog}?q=${Uri.encodeComponent(_searchCtrl.text)}');
  }

  @override
  Widget build(BuildContext context) {
    final cars = context.watch<CarProvider>();
    final auth = context.watch<AuthProvider>();
    final wide = Responsive.isWide(context);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: RefreshIndicator(
        onRefresh: () => context.read<CarProvider>().load(force: true),
        child: CustomScrollView(
          slivers: [
            if (!wide)
              SliverToBoxAdapter(
                child: _MobileHeader(
                  userName: auth.user?.firstName ?? 'Invité',
                  cartCount: context.watch<CartProvider>().count,
                ),
              ),
            SliverToBoxAdapter(
              child: ContentContainer(
                child: Padding(
                  padding: shellPadding(context).copyWith(top: wide ? 28 : 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (wide) ...[
                        Text(
                          'Bonjour ${auth.user?.firstName ?? ''} 👋',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Où souhaitez-vous conduire aujourd\'hui ?',
                          style: TextStyle(
                            fontSize: 15,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 22),
                      ],
                      _SearchPanel(
                        controller: _searchCtrl,
                        city: _pickupCity,
                        cities: cars.cities,
                        dates: _dates,
                        onCityChanged: (v) =>
                            setState(() => _pickupCity = v ?? 'Tunis'),
                        onPickDates: _pickDates,
                        onSearch: _search,
                      ),
                      const SizedBox(height: 26),
                      const _QuickAccessRow(),
                      const SizedBox(height: 28),
                      _CategorySection(cars: cars),
                      const SizedBox(height: 28),
                      const _PromoBanner(),
                      const SizedBox(height: 28),
                      const _ActiveReservationCard(),
                      _FeaturedSection(cars: cars),
                      const SizedBox(height: 28),
                      const _AuctionTeaser(),
                      const SizedBox(height: 28),
                      _RecommendedSection(cars: cars),
                      const SizedBox(height: 28),
                      const _LearningTeaser(),
                      const SizedBox(height: 20),
                      const _HomeFooter(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------- En-tête

class _MobileHeader extends StatelessWidget {
  const _MobileHeader({required this.userName, required this.cartCount});

  final String userName;
  final int cartCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.paddingOf(context).top + 14,
        12,
        70,
      ),
      decoration: const BoxDecoration(
        gradient: AppColors.navyGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: BrandLogo(compact: true, light: true)),
              CartButton(count: cartCount, dark: true),
              IconButton(
                tooltip: 'Mes réservations',
                onPressed: () => context.push(Routes.reservations),
                icon: const Icon(
                  Icons.event_note_rounded,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Bonjour $userName 👋',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Trouvez la voiture parfaite pour votre séjour.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------ Barre recherche

class _SearchPanel extends StatelessWidget {
  const _SearchPanel({
    required this.controller,
    required this.city,
    required this.cities,
    required this.dates,
    required this.onCityChanged,
    required this.onPickDates,
    required this.onSearch,
  });

  final TextEditingController controller;
  final String city;
  final List<String> cities;
  final DateTimeRange? dates;
  final ValueChanged<String?> onCityChanged;
  final VoidCallback onPickDates;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final wide = Responsive.isWide(context);
    final dateLabel = dates == null
        ? 'Choisir les dates'
        : '${Formatters.dayMonth(dates!.start)} → '
              '${Formatters.dayMonth(dates!.end)}';

    return Transform.translate(
      offset: Offset(0, wide ? 0 : -52),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: AppColors.border),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          children: [
            TextField(
              controller: controller,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => onSearch(),
              decoration: InputDecoration(
                hintText: 'Marque, modèle, catégorie…',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (wide)
              Row(
                children: [
                  Expanded(child: _cityField(context)),
                  const SizedBox(width: 12),
                  Expanded(child: _dateField(context, dateLabel)),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 170,
                    child: ElevatedButton.icon(
                      onPressed: onSearch,
                      icon: const Icon(Icons.search_rounded, size: 19),
                      label: const Text('Rechercher'),
                    ),
                  ),
                ],
              )
            else ...[
              Row(
                children: [
                  Expanded(child: _cityField(context)),
                  const SizedBox(width: 10),
                  Expanded(child: _dateField(context, dateLabel)),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onSearch,
                  icon: const Icon(Icons.search_rounded, size: 19),
                  label: const Text('Rechercher un véhicule'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _cityField(BuildContext context) {
    return _FieldShell(
      icon: Icons.place_outlined,
      label: 'Lieu de prise en charge',
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: city,
          isExpanded: true,
          isDense: true,
          icon: const Icon(Icons.expand_more_rounded, size: 18),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
          items: [
            for (final c in cities)
              DropdownMenuItem(value: c, child: Text(c)),
          ],
          onChanged: onCityChanged,
        ),
      ),
    );
  }

  Widget _dateField(BuildContext context, String label) {
    return _FieldShell(
      icon: Icons.calendar_today_rounded,
      label: 'Dates de location',
      onTap: onPickDates,
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: dates == null ? AppColors.textMuted : AppColors.textPrimary,
        ),
      ),
    );
  }
}

class _FieldShell extends StatelessWidget {
  const _FieldShell({
    required this.icon,
    required this.label,
    required this.child,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: Row(
          children: [
            Icon(icon, size: 17, color: AppColors.textMuted),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
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
                  const SizedBox(height: 1),
                  child,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --------------------------------------------------------------- Raccourcis

class _QuickAccessRow extends StatelessWidget {
  const _QuickAccessRow();

  @override
  Widget build(BuildContext context) {
    final items = <(IconData, String, Color, String)>[
      (
        Icons.event_note_rounded,
        'Mes réservations',
        AppColors.accent,
        Routes.reservations,
      ),
      (
        Icons.menu_book_rounded,
        'Code de la route',
        AppColors.success,
        Routes.learning,
      ),
      (
        Icons.gavel_rounded,
        'Ventes aux enchères',
        AppColors.gold,
        Routes.auctions,
      ),
      (
        Icons.emoji_events_rounded,
        'Mes enchères',
        AppColors.danger,
        Routes.myAuctions,
      ),
    ];

    final isShellRoute =
        {Routes.learning, Routes.auctions};

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: Responsive.value(context, mobile: 2, tablet: 4),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: Responsive.value(
        context,
        mobile: 2.25,
        tablet: 1.9,
        desktop: 2.3,
      ),
      children: [
        for (final (icon, label, color, path) in items)
          AppCard(
            padding: const EdgeInsets.all(14),
            onTap: () => isShellRoute.contains(path)
                ? context.go(path)
                : context.push(path),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 19, color: color),
                ),
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// --------------------------------------------------------------- Catégories

class _CategorySection extends StatelessWidget {
  const _CategorySection({required this.cars});

  final CarProvider cars;

  static const Map<CarCategory, IconData> _icons = {
    CarCategory.economique: Icons.directions_car_rounded,
    CarCategory.berline: Icons.airport_shuttle_rounded,
    CarCategory.suv: Icons.terrain_rounded,
    CarCategory.luxe: Icons.workspace_premium_rounded,
    CarCategory.electrique: Icons.electric_bolt_rounded,
    CarCategory.utilitaire: Icons.local_shipping_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Catégories',
          subtitle: 'Choisissez le type de véhicule qui vous convient',
          actionLabel: 'Tout voir',
          onAction: () => context.go(Routes.catalog),
        ),
        SizedBox(
          height: 108,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: CarCategory.values.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final category = CarCategory.values[i];
              final count = cars.countForCategory(category);
              return SizedBox(
                width: 118,
                child: AppCard(
                  padding: const EdgeInsets.all(13),
                  onTap: () {
                    cars.resetFilters();
                    cars.setCategory(category);
                    context.go('${Routes.catalog}?categorie=${category.id}');
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _icons[category],
                          size: 19,
                          color: AppColors.accent,
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            '$count véhicule${count > 1 ? 's' : ''}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------------ Bannière

class _PromoBanner extends StatelessWidget {
  const _PromoBanner();

  @override
  Widget build(BuildContext context) {
    final wide = Responsive.isWide(context);

    return Container(
      height: wide ? 210 : 190,
      decoration: navyBlock(radius: AppTheme.radiusXl),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Opacity(
            opacity: 0.38,
            child: CarImage(url: Img.coastRoad, fit: BoxFit.cover),
          ),
          Padding(
            padding: EdgeInsets.all(wide ? 30 : 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.gold,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: const Text(
                    'OFFRE ÉTÉ 2026',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                      color: AppColors.navy,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  '-15 % sur les locations\nde 7 jours et plus',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: wide ? 28 : 21,
                    height: 1.2,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Valable sur toutes nos agences du littoral.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 42,
                  child: ElevatedButton(
                    onPressed: () => context.go(Routes.catalog),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 42),
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.navy,
                    ),
                    child: const Text("J'en profite"),
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

// --------------------------------------------------- Réservation en cours

class _ActiveReservationCard extends StatelessWidget {
  const _ActiveReservationCard();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReservationProvider>();
    final reservation = provider.activeRental ?? provider.nextUpcoming;
    if (reservation == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: AppCard(
        elevated: true,
        onTap: () => context.push(Routes.reservation(reservation.id)),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CarImage(
              url: reservation.car.mainImage,
              height: 68,
              width: 92,
              borderRadius: BorderRadius.circular(13),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    reservation.status.label == 'En cours'
                        ? 'Location en cours'
                        : 'Prochaine réservation',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: AppColors.accent,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    reservation.car.fullName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${Formatters.date(reservation.range.start)} → '
                    '${Formatters.date(reservation.range.end)} · '
                    '${reservation.pickupCity}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------------------------------------------------- Sélections

class _FeaturedSection extends StatelessWidget {
  const _FeaturedSection({required this.cars});

  final CarProvider cars;

  @override
  Widget build(BuildContext context) {
    if (cars.state.isLoading) return const _CarRowSkeleton();

    final list = cars.featured;
    if (list.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Véhicules en vedette',
          subtitle: 'Les mieux notés par nos clients',
          actionLabel: 'Voir tout',
          onAction: () => context.go(Routes.catalog),
        ),
        SizedBox(
          height: 352,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemBuilder: (_, i) => SizedBox(
              width: 290,
              child: CarCard(
                car: list[i],
                onTap: () => context.push(Routes.car(list[i].id)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RecommendedSection extends StatelessWidget {
  const _RecommendedSection({required this.cars});

  final CarProvider cars;

  @override
  Widget build(BuildContext context) {
    if (cars.state.isLoading) {
      return Column(
        children: const [
          SectionHeader(title: 'Recommandés pour vous'),
          Skeleton(height: 98, radius: 22),
          SizedBox(height: 12),
          Skeleton(height: 98, radius: 22),
        ],
      );
    }

    final list = cars.recommended;
    if (list.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Recommandés pour vous',
          subtitle: 'Les meilleurs tarifs du moment',
          actionLabel: 'Voir tout',
          onAction: () => context.go(Routes.catalog),
        ),
        if (Responsive.isWide(context))
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: list.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: Responsive.value(context, mobile: 1, tablet: 2),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              mainAxisExtent: 104,
            ),
            itemBuilder: (_, i) => CarCardCompact(
              car: list[i],
              onTap: () => context.push(Routes.car(list[i].id)),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (_, i) => CarCardCompact(
              car: list[i],
              onTap: () => context.push(Routes.car(list[i].id)),
            ),
          ),
      ],
    );
  }
}

class _CarRowSkeleton extends StatelessWidget {
  const _CarRowSkeleton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 352,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (_, _) =>
            const SizedBox(width: 290, child: CarCardSkeleton()),
      ),
    );
  }
}

// ------------------------------------------------------------------ Teasers

class _AuctionTeaser extends StatelessWidget {
  const _AuctionTeaser();

  @override
  Widget build(BuildContext context) {
    final auctions = context.watch<AuctionProvider>();
    if (auctions.state != LoadState.success) return const SizedBox.shrink();

    final live = auctions.liveAuctions.take(3).toList();
    if (live.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Ventes aux enchères en direct',
          subtitle: 'Véhicules d\'occasion de notre flotte',
          actionLabel: 'Toutes les enchères',
          onAction: () => context.go(Routes.auctions),
        ),
        for (final auction in live)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AppCard(
              padding: const EdgeInsets.all(12),
              onTap: () => context.push(Routes.auction(auction.id)),
              child: Row(
                children: [
                  CarImage(
                    url: auction.mainImage,
                    height: 62,
                    width: 82,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          auction.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${auction.bidCount} offres · '
                          '${Formatters.mileage(auction.mileage)}',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 6),
                        CountdownText(
                          endAt: auction.endAt,
                          prefixIcon: Icons.timer_outlined,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Actuelle',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: AppColors.textMuted,
                        ),
                      ),
                      Text(
                        Formatters.moneyShort(auction.currentPrice),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: AppColors.accent,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _LearningTeaser extends StatelessWidget {
  const _LearningTeaser();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.successSoft,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.success,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Code de la route tunisien',
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Panneaux, priorités, quiz interactifs : préparez votre '
                  'séjour au volant.',
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.4,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 40,
                  child: ElevatedButton(
                    onPressed: () => context.go(Routes.learning),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 40),
                      backgroundColor: AppColors.success,
                    ),
                    child: const Text("Commencer l'apprentissage"),
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

class _HomeFooter extends StatelessWidget {
  const _HomeFooter();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 16),
      child: NoticeBox(
        icon: Icons.science_outlined,
        title: 'Version de démonstration',
        message:
            "Toutes les données (véhicules, réservations, contrats, paiements "
            "et enchères) sont simulées localement. Aucun serveur, aucune "
            "transaction réelle.",
      ),
    );
  }
}
