import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive.dart';
import '../../data/models/user_profile.dart';
import '../../state/auction_provider.dart';
import '../../state/auth_provider.dart';
import '../../state/learning_provider.dart';
import '../../state/reservation_provider.dart';
import '../../widgets/common.dart';
import '../shell/main_shell.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: AppColors.dangerSoft,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.logout_rounded,
            color: AppColors.danger,
            size: 24,
          ),
        ),
        title: const Text('Se déconnecter ?'),
        content: const Text(
          "Vous serez redirigé vers l'écran d'accueil. Les données de la "
          "session de démonstration (panier, enchères, progression) seront "
          "conservées jusqu'à la fermeture de l'application.",
          style: TextStyle(fontSize: 13.5, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Rester connecté'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;
    context.read<AuthProvider>().logout();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final reservations = context.watch<ReservationProvider>();
    final auctions = context.watch<AuctionProvider>();
    final learning = context.watch<LearningProvider>();

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: Responsive.isWide(context)
          ? null
          : AppBar(
              backgroundColor: AppColors.surface,
              automaticallyImplyLeading: false,
              toolbarHeight: 64,
              title: const Text('Mon profil'),
            ),
      body: ContentContainer(
        maxWidth: 860,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            Responsive.value(
              context,
              mobile: 16.0,
              tablet: 24.0,
              desktop: 32.0,
            ),
            Responsive.isWide(context) ? 28 : 4,
            Responsive.value(
              context,
              mobile: 16.0,
              tablet: 24.0,
              desktop: 32.0,
            ),
            28,
          ),
          children: [
            _ProfileHeader(user: user),
            const SizedBox(height: 18),
            _StatsRow(
              reservations: reservations.reservations.length,
              auctions: auctions.history.length,
              progress: (learning.overallProgress * 100).round(),
              spent: reservations.totalSpent,
            ),
            const SizedBox(height: 22),
            const _GroupTitle('Mon compte'),
            _MenuCard(
              items: [
                _MenuItem(
                  icon: Icons.person_outline_rounded,
                  label: 'Modifier mon profil',
                  subtitle: 'Nom, téléphone, permis, adresse',
                  onTap: () => context.push(Routes.editProfile),
                ),
                _MenuItem(
                  icon: Icons.event_note_rounded,
                  label: 'Mes réservations',
                  subtitle:
                      '${reservations.reservations.length} location'
                      '${reservations.reservations.length > 1 ? 's' : ''}',
                  onTap: () => context.push(Routes.reservations),
                ),
                _MenuItem(
                  icon: Icons.shopping_bag_outlined,
                  label: 'Mon panier',
                  subtitle: 'Véhicules en attente de réservation',
                  onTap: () => context.push(Routes.cart),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const _GroupTitle('Enchères'),
            _MenuCard(
              items: [
                _MenuItem(
                  icon: Icons.emoji_events_outlined,
                  label: 'Mes enchères et offres',
                  subtitle:
                      '${auctions.participating.length} en cours · '
                      '${auctions.won.length} gagnée'
                      '${auctions.won.length > 1 ? 's' : ''}',
                  onTap: () => context.push(Routes.myAuctions),
                ),
                _MenuItem(
                  icon: Icons.gavel_rounded,
                  label: 'Place de marché',
                  subtitle: 'Véhicules d\'occasion aux enchères',
                  onTap: () => context.go(Routes.auctions),
                ),
                _MenuItem(
                  icon: Icons.inventory_2_outlined,
                  label: 'Gestion de flotte (démo)',
                  subtitle: 'Tableau de bord des ventes',
                  onTap: () => context.push(Routes.fleet),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const _GroupTitle('Apprentissage'),
            _MenuCard(
              items: [
                _MenuItem(
                  icon: Icons.menu_book_outlined,
                  label: 'Code de la route',
                  subtitle:
                      'Progression : '
                      '${(learning.overallProgress * 100).round()} %',
                  onTap: () => context.go(Routes.learning),
                ),
                _MenuItem(
                  icon: Icons.quiz_outlined,
                  label: 'Mes résultats de quiz',
                  subtitle:
                      '${learning.completedQuizzes} quiz réalisé'
                      '${learning.completedQuizzes > 1 ? 's' : ''}',
                  onTap: () => context.go(Routes.learning),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const _GroupTitle('Application'),
            _MenuCard(
              items: [
                _MenuItem(
                  icon: Icons.info_outline_rounded,
                  label: 'À propos',
                  subtitle: 'RentCar Tunisia · version démo 1.0.0',
                  onTap: () => _showAbout(context),
                ),
                _MenuItem(
                  icon: Icons.support_agent_rounded,
                  label: 'Assistance',
                  subtitle: 'contact@rentcar.tn · +216 71 000 000 (fictif)',
                  onTap: () => AppSnack.info(
                    context,
                    'Coordonnées fictives : aucun service réel.',
                  ),
                ),
                _MenuItem(
                  icon: Icons.logout_rounded,
                  label: 'Se déconnecter',
                  subtitle: 'Fermer la session de démonstration',
                  danger: true,
                  onTap: () => _confirmLogout(context),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const NoticeBox(
              icon: Icons.science_outlined,
              message:
                  "Profil de démonstration. Les modifications sont "
                  "conservées en mémoire pendant la session uniquement.",
            ),
          ],
        ),
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'RentCar Tunisia',
      applicationVersion: 'Démo 1.0.0',
      applicationIcon: const Icon(
        Icons.directions_car_filled_rounded,
        size: 40,
        color: AppColors.accent,
      ),
      children: const [
        SizedBox(height: 10),
        Text(
          "Application frontend de location de voitures, de ventes aux "
          "enchères de véhicules d'occasion et d'apprentissage du code de la "
          "route en Tunisie.\n\n"
          "Toutes les données sont simulées localement. Aucun backend, aucune "
          "base de données, aucun paiement réel.",
          style: TextStyle(fontSize: 13, height: 1.5),
        ),
      ],
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user});

  final UserProfile user;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: navyBlock(radius: AppTheme.radiusXl),
      child: Row(
        children: [
          Container(
            height: 68,
            width: 68,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.25),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                user.initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  user.fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  user.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    'Pseudo enchères : ${user.publicUsername}',
                    style: const TextStyle(
                      color: AppColors.accentLight,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => context.push(Routes.editProfile),
            icon: const Icon(Icons.edit_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.reservations,
    required this.auctions,
    required this.progress,
    required this.spent,
  });

  final int reservations;
  final int auctions;
  final int progress;
  final double spent;

  @override
  Widget build(BuildContext context) {
    final stats = <(IconData, String, String)>[
      (Icons.event_note_rounded, '$reservations', 'Réservations'),
      (Icons.gavel_rounded, '$auctions', 'Enchères'),
      (Icons.school_rounded, '$progress %', 'Code'),
      (
        Icons.payments_rounded,
        Formatters.moneyShort(spent),
        'Dépensé',
      ),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: Responsive.value(context, mobile: 2, tablet: 4),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.9,
      children: [
        for (final (icon, value, label) in stats)
          AppCard(
            padding: const EdgeInsets.all(13),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, size: 19, color: AppColors.accent),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _GroupTitle extends StatelessWidget {
  const _GroupTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
          color: AppColors.textMuted,
        ),
      ),
    );
  }
}

class _MenuItem {
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final bool danger;
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({required this.items});

  final List<_MenuItem> items;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            ListTile(
              onTap: items[i].onTap,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 6,
              ),
              leading: Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: (items[i].danger ? AppColors.danger : AppColors.accent)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  items[i].icon,
                  size: 19,
                  color: items[i].danger
                      ? AppColors.danger
                      : AppColors.accent,
                ),
              ),
              title: Text(
                items[i].label,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: items[i].danger
                      ? AppColors.danger
                      : AppColors.textPrimary,
                ),
              ),
              subtitle: Text(
                items[i].subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
              trailing: const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMuted,
              ),
            ),
            if (i != items.length - 1)
              const Divider(height: 1, indent: 68, endIndent: 16),
          ],
        ],
      ),
    );
  }
}
