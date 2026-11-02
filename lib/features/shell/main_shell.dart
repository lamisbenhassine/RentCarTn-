import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../l10n/l10n.dart';
import '../../state/admin_complaint_provider.dart';
import '../../state/auth_provider.dart';
import '../../state/cart_provider.dart';
import '../../state/complaint_provider.dart';
import '../../state/notification_provider.dart';
import '../admin/admin_users_screen.dart' show roleLabel;

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

/// Raccourci hors onglets (rail grand écran + drawer téléphone).
class _Shortcut {
  const _Shortcut(this.icon, this.label, this.path, {this.badge = 0});

  final IconData icon;
  final String label;
  final String path;

  /// Pastille (réclamations avec nouvelle réponse / en attente). 0 → rien.
  final int badge;
}

/// Raccourcis groupés : « Mon activité » puis « Administration » (admin).
typedef _ShortcutSections = ({
  List<_Shortcut> activity,
  List<_Shortcut> admin,
});

/// SOURCE UNIQUE des raccourcis, partagée par [_RailShortcuts] et
/// [_ShortcutDrawer] (à appeler dans un build : écoute les providers).
_ShortcutSections _shortcuts(BuildContext context) {
  final l = context.l10n;
  final isAdmin = context.watch<AuthProvider>().isAdmin;
  return (
    activity: [
      const _Shortcut(
        Icons.event_note_rounded,
        'Réservations',
        Routes.reservations,
      ),
      const _Shortcut(
        Icons.emoji_events_rounded,
        'Mes enchères',
        Routes.myAuctions,
      ),
      _Shortcut(
        Icons.inventory_2_rounded,
        isAdmin ? 'Gestion flotte' : 'Ventes flotte',
        Routes.fleet,
      ),
      // L'admin traite les réclamations dans « Administration ».
      if (!isAdmin)
        _Shortcut(
          Icons.support_agent_rounded,
          l.myComplaintsTitle,
          Routes.complaints,
          badge: context.watch<ComplaintProvider>().unreadCount,
        ),
    ],
    admin: [
      if (isAdmin) ...[
        _Shortcut(
          Icons.admin_panel_settings_outlined,
          l.adminComplaintsTitle,
          Routes.adminComplaints,
          badge: context.watch<AdminComplaintProvider>().pendingCount,
        ),
        _Shortcut(
          Icons.manage_accounts_outlined,
          l.adminUsersTitle,
          Routes.adminUsers,
        ),
      ],
    ],
  );
}

/// Icône avec pastille rouge (masquée à 0).
Widget _withBadge(Widget icon, int count) => count <= 0
    ? icon
    : Badge(
        label: Text(count > 99 ? '99+' : '$count'),
        backgroundColor: AppColors.danger,
        child: icon,
      );

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
      // Téléphone : barre compacte (☰ + logo) qui ouvre le drawer des
      // raccourcis. Barre inférieure inchangée.
      return Scaffold(
        drawer: _ShortcutDrawer(location: location),
        body: Column(
          children: [
            Builder(
              builder: (scaffoldContext) => _TopBar(
                index: _index,
                onSelect: (i) => _go(context, i),
                onMenu: () => Scaffold.of(scaffoldContext).openDrawer(),
              ),
            ),
            // La barre gère déjà la zone de la barre d'état.
            Expanded(
              child: MediaQuery.removePadding(
                context: context,
                removeTop: true,
                child: child,
              ),
            ),
          ],
        ),
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
    final sections = _shortcuts(context);
    final shortcuts = [...sections.activity, ...sections.admin];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final _Shortcut(:icon, :label, :path, :badge) in shortcuts)
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
                      icon: _withBadge(Icon(icon, size: 19), badge),
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
                    icon: _withBadge(
                      Icon(icon, color: AppColors.textMuted),
                      badge,
                    ),
                  ),
          ),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.index, required this.onSelect, this.onMenu});

  final int index;
  final ValueChanged<int> onSelect;

  /// Téléphone : bouton ☰ (drawer) et barre compacte. `null` = grand écran,
  /// barre complète inchangée.
  final VoidCallback? onMenu;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final cartCount = context.watch<CartProvider>().count;

    if (onMenu != null) {
      // Panier, cloche et avatar restent dans les en-têtes des onglets et
      // la barre inférieure : pas de doublon ici.
      return Container(
        decoration: const BoxDecoration(
          color: AppColors.surfaceAlt,
          border: Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          bottom: false,
          child: SizedBox(
            height: 52,
            child: Row(
              children: [
                const SizedBox(width: 4),
                IconButton(
                  tooltip: context.l10n.navMenu,
                  onPressed: onMenu,
                  icon: _withBadge(
                    const Icon(Icons.menu_rounded),
                    _menuBadge(context),
                  ),
                ),
                InkWell(
                  onTap: () => onSelect(0),
                  borderRadius: BorderRadius.circular(10),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                    child: BrandLogo(compact: true),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

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
          const SizedBox(width: 4),
          const NotificationBell(),
          const SizedBox(width: 4),
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

/// Total des pastilles du drawer (affiché sur le bouton ☰).
int _menuBadge(BuildContext context) {
  final s = _shortcuts(context);
  return [...s.activity, ...s.admin].fold(0, (sum, x) => sum + x.badge);
}

/// Drawer téléphone : en-tête (avatar, nom, e-mail, rôle), raccourcis
/// « Mon activité » / « Administration » (mêmes données que le rail),
/// Déconnexion. S'ouvre côté début de ligne (droite en arabe).
class _ShortcutDrawer extends StatelessWidget {
  const _ShortcutDrawer({required this.location});

  /// Page affichée sous le drawer (surbrillance de l'entrée).
  final String location;

  void _open(BuildContext context, String path) {
    final router = GoRouter.of(context);
    Navigator.of(context).pop(); // ferme le drawer
    router.push(path);
  }

  Future<void> _logout(BuildContext context) async {
    final l = context.l10n;
    final auth = context.read<AuthProvider>();
    Navigator.of(context).pop();
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.logout_rounded, color: AppColors.danger),
        title: Text(l.profileLogoutTitle),
        content: Text(l.profileLogoutMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l.profileStayLoggedIn),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: Text(l.commonLogout),
          ),
        ],
      ),
    );
    if (ok == true) await auth.logout(); // le routeur renvoie à la connexion
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final user = context.watch<AuthProvider>().user;
    final sections = _shortcuts(context);

    Widget title(String text) => Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 18, 20, 6),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.1,
          color: AppColors.textMuted,
        ),
      ),
    );

    Widget tile(_Shortcut s) {
      final selected = location.startsWith(s.path);
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        child: ListTile(
          selected: selected,
          selectedColor: AppColors.accent,
          selectedTileColor: AppColors.accent.withValues(alpha: 0.12),
          iconColor: AppColors.textMuted,
          textColor: AppColors.textSecondary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          leading: Icon(s.icon, size: 22),
          title: Text(
            s.label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          trailing: s.badge > 0
              ? Badge(
                  label: Text(s.badge > 99 ? '99+' : '${s.badge}'),
                  backgroundColor: AppColors.danger,
                )
              : null,
          onTap: () => _open(context, s.path),
        ),
      );
    }

    return Drawer(
      backgroundColor: AppColors.surfaceAlt,
      child: Column(
        children: [
          // En-tête : compte connecté.
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(gradient: AppColors.navyGradient),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(20, 20, 16, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.accent,
                      child: Text(
                        user?.initials ?? '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      user?.fullName ?? 'Invité',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (user != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        user.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 12.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          roleLabel(l, user.role),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 8),
              children: [
                title(l.navMyActivity),
                for (final s in sections.activity) tile(s),
                if (sections.admin.isNotEmpty) ...[
                  title(l.navAdministration),
                  for (final s in sections.admin) tile(s),
                ],
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: ListTile(
                iconColor: AppColors.danger,
                textColor: AppColors.danger,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                leading: const Icon(Icons.logout_rounded),
                title: Text(
                  l.commonLogout,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                onTap: () => _logout(context),
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

/// Cloche notifications (badge = non lues).
class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key, this.dark = false});

  final bool dark;

  @override
  Widget build(BuildContext context) {
    final unread = context.watch<NotificationProvider>().unreadCount;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          tooltip: 'Notifications',
          onPressed: () => context.push(Routes.notifications),
          icon: Icon(
            unread > 0
                ? Icons.notifications_rounded
                : Icons.notifications_none_rounded,
            color: dark ? Colors.white : null,
          ),
        ),
        if (unread > 0)
          Positioned(
            right: 4,
            top: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              constraints: const BoxConstraints(minWidth: 18),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: dark ? AppColors.navy : AppColors.surfaceAlt,
                  width: 1.5,
                ),
              ),
              child: Text(
                unread > 99 ? '99+' : '$unread',
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
