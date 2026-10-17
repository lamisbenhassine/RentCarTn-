import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../state/auth_provider.dart';
import '../../state/cart_provider.dart';

class _NavItem {
  const _NavItem(this.label, this.icon, this.activeIcon, this.path);

  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String path;
}

const List<_NavItem> _items = [
  _NavItem(
    'Accueil',
    Icons.home_outlined,
    Icons.home_rounded,
    Routes.home,
  ),
  _NavItem(
    'Location',
    Icons.directions_car_outlined,
    Icons.directions_car_rounded,
    Routes.catalog,
  ),
  _NavItem(
    'Enchères',
    Icons.gavel_outlined,
    Icons.gavel_rounded,
    Routes.auctions,
  ),
  _NavItem(
    'Code',
    Icons.menu_book_outlined,
    Icons.menu_book_rounded,
    Routes.learning,
  ),
  _NavItem(
    'Profil',
    Icons.person_outline_rounded,
    Icons.person_rounded,
    Routes.profile,
  ),
];

/// Ossature de navigation : barre inférieure sur mobile, rail latéral sur
/// tablette et web.
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.child, required this.location});

  final Widget child;
  final String location;

  int get _index {
    final i = _items.indexWhere((item) => location.startsWith(item.path));
    return i < 0 ? 0 : i;
  }

  void _go(BuildContext context, int index) {
    final target = _items[index].path;
    if (location != target) context.go(target);
  }

  @override
  Widget build(BuildContext context) {
    final wide = Responsive.isWide(context);

    if (!wide) {
      return Scaffold(
        body: child,
        bottomNavigationBar: _BottomBar(
          index: _index,
          onSelect: (i) => _go(context, i),
        ),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          _TopBar(index: _index, onSelect: (i) => _go(context, i)),
          Expanded(
            child: Row(
              children: [
                _SideRail(index: _index, onSelect: (i) => _go(context, i)),
                const VerticalDivider(width: 1),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.index, required this.onSelect});

  final int index;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: onSelect,
        destinations: [
          for (final item in _items)
            NavigationDestination(
              icon: Icon(item.icon),
              selectedIcon: Icon(item.activeIcon),
              label: item.label,
            ),
        ],
      ),
    );
  }
}

class _SideRail extends StatelessWidget {
  const _SideRail({required this.index, required this.onSelect});

  final int index;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final extended = Responsive.isDesktop(context);

    return Container(
      color: AppColors.surfaceAlt,
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.sizeOf(context).height - 140,
          ),
          child: IntrinsicHeight(
            child: NavigationRail(
              extended: extended,
              minExtendedWidth: 212,
              backgroundColor: AppColors.surfaceAlt,
              selectedIndex: index,
              onDestinationSelected: onSelect,
              labelType: extended
                  ? NavigationRailLabelType.none
                  : NavigationRailLabelType.all,
              indicatorColor: AppColors.accent.withValues(alpha: 0.12),
              selectedIconTheme: const IconThemeData(color: AppColors.accent),
              unselectedIconTheme: const IconThemeData(
                color: AppColors.textMuted,
              ),
              selectedLabelTextStyle: const TextStyle(
                color: AppColors.accent,
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
              ),
              unselectedLabelTextStyle: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
                fontSize: 13.5,
              ),
              trailing: Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: _RailShortcuts(extended: extended),
                  ),
                ),
              ),
              destinations: [
                for (final item in _items)
                  NavigationRailDestination(
                    icon: Icon(item.icon),
                    selectedIcon: Icon(item.activeIcon),
                    label: Text(item.label),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RailShortcuts extends StatelessWidget {
  const _RailShortcuts({required this.extended});

  final bool extended;

  @override
  Widget build(BuildContext context) {
    final shortcuts = <(IconData, String, String)>[
      (Icons.event_note_rounded, 'Réservations', Routes.reservations),
      (Icons.emoji_events_rounded, 'Mes enchères', Routes.myAuctions),
      (Icons.inventory_2_rounded, 'Gestion flotte', Routes.fleet),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (icon, label, path) in shortcuts)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 8),
            child: extended
                ? SizedBox(
                    width: 190,
                    child: TextButton.icon(
                      onPressed: () => context.push(path),
                      style: TextButton.styleFrom(
                        alignment: Alignment.centerLeft,
                        foregroundColor: AppColors.textSecondary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                      ),
                      icon: Icon(icon, size: 19),
                      label: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          label,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ),
                  )
                : IconButton(
                    tooltip: label,
                    onPressed: () => context.push(path),
                    icon: Icon(icon, color: AppColors.textMuted),
                  ),
          ),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.index, required this.onSelect});

  final int index;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final cartCount = context.watch<CartProvider>().count;

    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: AppColors.surfaceAlt,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => onSelect(0),
            borderRadius: BorderRadius.circular(10),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              child: BrandLogo(compact: true),
            ),
          ),
          const Spacer(),
          CartButton(count: cartCount),
          const SizedBox(width: 10),
          IconButton(
            tooltip: 'Mes réservations',
            onPressed: () => context.push(Routes.reservations),
            icon: const Icon(Icons.event_note_rounded),
          ),
          const SizedBox(width: 10),
          InkWell(
            onTap: () => onSelect(4),
            borderRadius: BorderRadius.circular(100),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 17,
                    backgroundColor: AppColors.navy,
                    child: Text(
                      user?.initials ?? '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    user?.firstName ?? 'Invité',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Logo texte de l'application.
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.compact = false, this.light = false});

  final bool compact;
  final bool light;

  @override
  Widget build(BuildContext context) {
    final titleColor = light ? Colors.white : AppColors.textPrimary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: compact ? 34 : 44,
          width: compact ? 34 : 44,
          decoration: BoxDecoration(
            gradient: AppColors.accentGradient,
            borderRadius: BorderRadius.circular(compact ? 10 : 14),
          ),
          child: Icon(
            Icons.directions_car_filled_rounded,
            color: Colors.white,
            size: compact ? 20 : 26,
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'RentCar',
              style: TextStyle(
                fontSize: compact ? 16 : 20,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.6,
                color: titleColor,
                height: 1.1,
              ),
            ),
            Text(
              'TUNISIA',
              style: TextStyle(
                fontSize: compact ? 9 : 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 2.2,
                color: light
                    ? AppColors.accentLight
                    : AppColors.accent,
                height: 1.1,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Bouton panier avec pastille de comptage.
class CartButton extends StatelessWidget {
  const CartButton({super.key, required this.count, this.dark = false});

  final int count;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          tooltip: 'Panier',
          onPressed: () => context.push(Routes.cart),
          icon: Icon(
            Icons.shopping_bag_outlined,
            color: dark ? Colors.white : null,
          ),
        ),
        if (count > 0)
          Positioned(
            right: 4,
            top: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              constraints: const BoxConstraints(minWidth: 18),
              decoration: BoxDecoration(
                color: AppColors.danger,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: AppColors.surfaceAlt, width: 1.5),
              ),
              child: Text(
                '$count',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// En-tête de page standard pour les écrans secondaires.
PreferredSizeWidget appScreenBar(
  BuildContext context, {
  required String title,
  String? subtitle,
  List<Widget> actions = const [],
  bool showBack = true,
}) {
  return AppBar(
    automaticallyImplyLeading: false,
    toolbarHeight: subtitle == null ? 64 : 76,
    backgroundColor: AppColors.surface,
    leading: showBack
        ? IconButton(
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(Routes.home);
              }
            },
            icon: const Icon(Icons.arrow_back_rounded),
          )
        : null,
    title: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        if (subtitle != null)
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
      ],
    ),
    actions: [...actions, const SizedBox(width: 8)],
    shape: const Border(bottom: BorderSide(color: AppColors.border)),
  );
}

/// Marge de contenu homogène pour les pages du shell.
EdgeInsets shellPadding(BuildContext context) => EdgeInsets.fromLTRB(
  Responsive.value(context, mobile: 16.0, tablet: 24.0, desktop: 32.0),
  0,
  Responsive.value(context, mobile: 16.0, tablet: 24.0, desktop: 32.0),
  Responsive.isWide(context) ? 32 : 24,
);

/// Conteneur utilisé pour les blocs sombres (bandeaux, promos).
BoxDecoration navyBlock({double radius = AppTheme.radiusLg}) => BoxDecoration(
  gradient: AppColors.navyGradient,
  borderRadius: BorderRadius.circular(radius),
);
