import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show NumberFormat;
import 'package:provider/provider.dart';

import '../../core/router/app_router.dart';
import '../../core/services/location_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive.dart';
import '../../data/models/licence_status.dart';
import '../../data/models/profile_completion.dart';
import '../../data/models/user_profile.dart';
import '../../data/services/complaint_trust_service.dart';
import '../../data/services/trust_score_service.dart';
import '../../l10n/l10n.dart';
import '../../state/load_state.dart';
import '../../data/models/user_role.dart';
import '../../state/auction_provider.dart';
import '../../state/admin_complaint_provider.dart';
import '../../state/admin_user_provider.dart';
import '../../state/auth_provider.dart';
import '../../state/complaint_provider.dart';
import '../../state/learning_provider.dart';
import '../../state/reminder_provider.dart';
import '../../state/notification_provider.dart';
import '../../state/reservation_provider.dart';
import '../../state/theme_provider.dart';
import '../../widgets/common.dart';
import '../../widgets/language_selector.dart';
import '../../widgets/user_avatar.dart';
import '../shell/main_shell.dart';
import 'avatar_picker.dart';
import 'change_password_sheet.dart';
import 'delete_account_sheet.dart';

/// Permet à la barre de complétion de lancer « Mettre à jour ma position »
/// (la position ne se saisit pas dans edit_profile_screen).
final _positionCardKey = GlobalKey<_PositionCardState>();

/// Change la photo de profil et l'enregistre tout de suite en BD.
Future<void> _changeAvatar(BuildContext context, UserProfile user) async {
  try {
    final choice = await pickAvatar(
      context,
      hasPhoto: user.avatarUrl?.isNotEmpty ?? false,
    );
    if (choice == null || !context.mounted) return;

    final auth = context.read<AuthProvider>();
    final ok = await auth.updateProfile(
      choice.isRemoved
          ? user.copyWith(clearAvatar: true)
          : user.copyWith(avatarUrl: choice.dataUrl),
    );
    if (!context.mounted) return;
    final l = context.l10n;
    if (ok) {
      AppSnack.success(
        context,
        choice.isRemoved ? l.profilePhotoRemoved : l.profilePhotoUpdated,
      );
    } else {
      AppSnack.error(context, l.authError(auth.errorCode));
    }
  } on AvatarPickException catch (e) {
    if (context.mounted) AppSnack.error(context, e.message);
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _confirmLogout(BuildContext context) async {
    final l = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.danger.withValues(alpha: 0.14),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.logout_rounded,
            color: AppColors.danger,
            size: 24,
          ),
        ),
        title: Text(l.profileLogoutTitle),
        content: Text(
          l.profileLogoutMessage,
          style: const TextStyle(fontSize: 13.5, height: 1.5),
        ),
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

    if (confirmed != true || !context.mounted) return;
    await context.read<AuthProvider>().logout();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final reservations = context.watch<ReservationProvider>();
    final auctions = context.watch<AuctionProvider>();
    final learning = context.watch<LearningProvider>();
    final notifs = context.watch<NotificationProvider>();

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: context.cs.surfaceContainerLow,
      appBar: Responsive.isWide(context)
          ? null
          : AppBar(
              backgroundColor: context.cs.surfaceContainerLow,
              automaticallyImplyLeading: false,
              toolbarHeight: 64,
              title: Text(l.profileTitle),
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
            const SizedBox(height: 14),
            _CompletionCard(user: user),
            const SizedBox(height: 18),
            _StatsRow(
              reservations: reservations.reservations.length,
              auctions: auctions.history.length,
              progress: (learning.overallProgress * 100).round(),
              spent: reservations.totalSpent,
            ),
            const SizedBox(height: 22),
            _GroupTitle(l.profileGroupTrust),
            _TrustCard(user: user),
            const SizedBox(height: 22),
            _GroupTitle(l.profileGroupInfo),
            _PersonalInfoCard(user: user),
            const SizedBox(height: 12),
            _LicenceCard(user: user),
            const SizedBox(height: 12),
            _PositionCard(key: _positionCardKey, user: user),
            const SizedBox(height: 22),
            _GroupTitle(l.profileGroupAccount),
            _MenuCard(
              items: [
                _MenuItem(
                  icon: Icons.person_outline_rounded,
                  label: l.profileEdit,
                  subtitle: l.profileEditSubtitle,
                  onTap: () => context.push(Routes.editProfile),
                ),
                _MenuItem(
                  icon: Icons.lock_reset_rounded,
                  label: l.profileChangePassword,
                  subtitle: l.profileChangePasswordSubtitle,
                  onTap: () => showChangePasswordSheet(context),
                ),
                // Client : ses réclamations. Admin : le back office (toutes).
                if (!auth.isAdmin)
                  _MenuItem(
                    icon: Icons.support_agent_rounded,
                    label: l.myComplaintsTitle,
                    subtitle: l.myComplaintsCount(
                      context.watch<ComplaintProvider>().complaints.length,
                    ),
                    badge: context.watch<ComplaintProvider>().unreadCount,
                    onTap: () => context.push(Routes.complaints),
                  ),
                if (auth.isAdmin)
                  _MenuItem(
                    icon: Icons.admin_panel_settings_outlined,
                    label: l.adminComplaintsTitle,
                    subtitle: l.adminComplaintsMenuSub(
                      context.watch<AdminComplaintProvider>().pendingCount,
                    ),
                    badge: context.watch<AdminComplaintProvider>().pendingCount,
                    onTap: () => context.push(Routes.adminComplaints),
                  ),
                if (auth.isAdmin)
                  _MenuItem(
                    icon: Icons.manage_accounts_outlined,
                    label: l.adminUsersTitle,
                    subtitle: l.adminUsersMenuSub(
                      context.watch<AdminUserProvider>().bannedCount,
                    ),
                    onTap: () => context.push(Routes.adminUsers),
                  ),
                if (!auth.isAdmin)
                  _MenuItem(
                    icon: Icons.report_problem_outlined,
                    label: l.complaintReport,
                    subtitle: l.complaintReportSub,
                    onTap: () => context.push(Routes.complaintNew),
                  ),
                _MenuItem(
                  icon: Icons.event_note_rounded,
                  label: l.profileReservations,
                  subtitle: l.profileRentalsCount(
                    reservations.reservations.length,
                  ),
                  onTap: () => context.push(Routes.reservations),
                ),
                _MenuItem(
                  icon: Icons.shopping_bag_outlined,
                  label: l.profileCart,
                  subtitle: l.profileCartSubtitle,
                  onTap: () => context.push(Routes.cart),
                ),
                _MenuItem(
                  icon: Icons.notifications_outlined,
                  label: 'Notifications',
                  subtitle: notifs.hasUnread
                      ? '${notifs.unreadCount} non lue(s)'
                      : 'Alertes enchères et annonces',
                  onTap: () => context.push(Routes.notifications),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _GroupTitle(l.profileGroupAuctions),
            _MenuCard(
              items: [
                _MenuItem(
                  icon: Icons.emoji_events_outlined,
                  label: l.profileMyAuctions,
                  subtitle: l.profileMyAuctionsSubtitle(
                    auctions.participating.length,
                    auctions.won.length,
                  ),
                  onTap: () => context.push(Routes.myAuctions),
                ),
                _MenuItem(
                  icon: Icons.gavel_rounded,
                  label: l.profileMarketplace,
                  subtitle: l.profileMarketplaceSubtitle,
                  onTap: () => context.go(Routes.auctions),
                ),
                _MenuItem(
                  icon: Icons.inventory_2_outlined,
                  label: auth.isAdmin
                      ? 'Gestion de flotte'
                      : 'Ventes de flotte',
                  subtitle: auth.isAdmin
                      ? 'Publier et suivre les ventes'
                      : 'Consulter les ventes (lecture seule)',
                  onTap: () => context.push(Routes.fleet),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _GroupTitle(l.profileGroupLearning),
            _MenuCard(
              items: [
                _MenuItem(
                  icon: Icons.menu_book_outlined,
                  label: l.profileRoadCode,
                  subtitle: l.profileProgress(
                    (learning.overallProgress * 100).round(),
                  ),
                  onTap: () => context.go(Routes.learning),
                ),
                _MenuItem(
                  icon: Icons.quiz_outlined,
                  label: l.profileQuizResults,
                  subtitle: l.profileQuizCount(learning.completedQuizzes),
                  onTap: () => context.go(Routes.learning),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _GroupTitle(l.profileGroupApp),
            // Langue de l'application (FR / EN / عربي).
            AppCard(
              color: context.cs.surface,
              borderColor: context.cs.outlineVariant,
              child: Row(
                children: [
                  const Icon(
                    Icons.translate_rounded,
                    size: 19,
                    color: AppColors.accent,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l.commonLanguage,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: context.cs.onSurface,
                      ),
                    ),
                  ),
                  const LanguageSelector(compact: true),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Rappels (notifications locales).
            const _RemindersCard(),
            const SizedBox(height: 12),
            // Thème : Clair / Sombre / Automatique.
            AppCard(
              color: context.cs.surface,
              borderColor: context.cs.outlineVariant,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.dark_mode_outlined,
                        size: 19,
                        color: AppColors.accent,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        l.themeTitle,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: context.cs.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<ThemeMode>(
                      showSelectedIcon: false,
                      segments: [
                        ButtonSegment(
                          value: ThemeMode.light,
                          icon: const Icon(Icons.light_mode_outlined),
                          label: Text(l.themeLight),
                        ),
                        ButtonSegment(
                          value: ThemeMode.dark,
                          icon: const Icon(Icons.dark_mode_outlined),
                          label: Text(l.themeDark),
                        ),
                        ButtonSegment(
                          value: ThemeMode.system,
                          icon: const Icon(Icons.brightness_auto_outlined),
                          label: Text(l.themeSystem),
                        ),
                      ],
                      selected: {context.watch<ThemeProvider>().mode},
                      onSelectionChanged: (s) =>
                          context.read<ThemeProvider>().setMode(s.first),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _MenuCard(
              items: [
                _MenuItem(
                  icon: Icons.info_outline_rounded,
                  label: l.profileAbout,
                  subtitle: l.profileAboutSubtitle,
                  onTap: () => _showAbout(context),
                ),
                _MenuItem(
                  icon: Icons.support_agent_rounded,
                  label: l.profileSupport,
                  subtitle: l.profileSupportSubtitle,
                  onTap: () => AppSnack.info(context, l.profileSupportSnack),
                ),
                _MenuItem(
                  icon: Icons.logout_rounded,
                  label: l.commonLogout,
                  subtitle: l.profileLogoutSubtitle,
                  danger: true,
                  onTap: () => _confirmLogout(context),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Zone dangereuse : tout en bas, séparée du reste.
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => showDeleteAccountSheet(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: const BorderSide(color: AppColors.danger),
                  minimumSize: const Size(0, 50),
                ),
                icon: const Icon(Icons.delete_forever_rounded),
                label: Text(l.deleteAccount),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAbout(BuildContext context) {
    final l = context.l10n;
    showAboutDialog(
      context: context,
      applicationName: 'RentCar Tunisia',
      applicationVersion: l.profileAboutVersion,
      applicationIcon: const Icon(
        Icons.directions_car_filled_rounded,
        size: 40,
        color: AppColors.accent,
      ),
      children: [
        const SizedBox(height: 10),
        Text(
          l.profileAboutText,
          style: const TextStyle(fontSize: 13, height: 1.5),
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
          // Touche la photo pour la changer (galerie / fichiers).
          GestureDetector(
            onTap: () => _changeAvatar(context, user),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                UserAvatar(
                  initials: user.initials,
                  avatarUrl: user.avatarUrl,
                  onDark: true,
                ),
                // Badge en bas « fin de ligne » : à droite en fr/en,
                // à gauche en arabe.
                PositionedDirectional(
                  end: -2,
                  bottom: -2,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.navy, width: 2),
                    ),
                    child: const Icon(
                      Icons.photo_camera_rounded,
                      size: 13,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
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
                const SizedBox(height: 6),
                Text(
                  user.role.label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
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
                    context.l10n.profileAuctionAlias(user.publicUsername),
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
    final l = context.l10n;
    final stats = <(IconData, String, String)>[
      (Icons.event_note_rounded, '$reservations', l.profileStatReservations),
      (Icons.gavel_rounded, '$auctions', l.profileStatAuctions),
      (Icons.school_rounded, '$progress %', l.profileStatCode),
      (
        Icons.payments_rounded,
        Formatters.moneyShort(spent),
        l.profileStatSpent,
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
            color: context.cs.surface,
            borderColor: context.cs.outlineVariant,
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
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        color: context.cs.onSurface,
                      ),
                    ),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: context.cs.outline,
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

// -----------------------------------------------------------------------------
// Complétion du profil
// -----------------------------------------------------------------------------

/// Barre « Profil complété à X % » + prochaine action cliquable.
/// À 100 % : la barre disparaît, remplacée par le badge « Profil complet ✓ ».
class _CompletionCard extends StatelessWidget {
  const _CompletionCard({required this.user});

  final UserProfile user;

  /// Texte de l'action à faire pour chaque élément manquant.
  static String _stepLabel(AppLocalizations l, ProfileStep step) =>
      switch (step) {
        ProfileStep.photo => l.stepPhoto,
        ProfileStep.phone => l.stepPhone,
        ProfileStep.cin => l.stepCin,
        ProfileStep.licenceNumber => l.stepLicenceNumber,
        ProfileStep.licenceExpiry => l.stepLicenceExpiry,
        ProfileStep.address => l.stepAddress,
        ProfileStep.position => l.stepPosition,
        ProfileStep.emailVerified => l.stepEmailVerified,
      };

  static Color _barColor(int percent) {
    if (percent >= 75) return AppColors.success;
    if (percent >= 40) return AppColors.accent;
    return AppColors.warning;
  }

  void _openStep(BuildContext context, ProfileStep step) {
    switch (step) {
      case ProfileStep.position:
        // Même parcours que le bouton « Mettre à jour ma position ».
        _positionCardKey.currentState?._update();
      case ProfileStep.emailVerified:
        context.push(Routes.verifyEmail);
      default:
        context.push(Routes.editProfile);
    }
  }

  @override
  Widget build(BuildContext context) {
    final completion = user.completion;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: completion.isComplete
          ? Align(
              key: const ValueKey('complete'),
              alignment: AlignmentDirectional.centerStart,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.verified_rounded,
                      size: 17,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      context.l10n.profileComplete,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : _progress(context, completion),
    );
  }

  Widget _progress(BuildContext context, ProfileCompletion completion) {
    final l = context.l10n;
    final percent = completion.percent;
    final color = _barColor(percent);
    final next = completion.nextStep!;
    final left = completion.missing.length;

    return AppCard(
      color: context.cs.surface,
      borderColor: context.cs.outlineVariant,
      key: const ValueKey('progress'),
      padding: const EdgeInsetsDirectional.fromSTEB(
        16,
        14,
        8,
        6,
      ).resolve(Directionality.of(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l.profileCompletion(percent),
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: context.cs.onSurface,
                    ),
                  ),
                ),
                Text(
                  '${completion.doneCount}/${completion.total}',
                  style: TextStyle(fontSize: 12.5, color: context.cs.outline),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: percent / 100),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              builder: (_, value, _) => ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: LinearProgressIndicator(
                  value: value,
                  minHeight: 8,
                  backgroundColor: context.cs.outlineVariant,
                  color: color,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          // Prochaine action, cliquable.
          InkWell(
            onTap: () => _openStep(context, next),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  const Icon(
                    Icons.lightbulb_outline_rounded,
                    size: 18,
                    color: AppColors.accent,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: _stepLabel(l, next),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.accent,
                            ),
                          ),
                          if (left > 1)
                            TextSpan(
                              text: '  · ${l.profileCompletionMore(left - 1)}',
                              style: TextStyle(color: context.cs.outline),
                            ),
                        ],
                      ),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.accent,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Confiance et fidélité
// -----------------------------------------------------------------------------

extension _TierColor on LoyaltyTier {
  Color get color => switch (this) {
    LoyaltyTier.bronze => const Color(0xFFB87333),
    LoyaltyTier.silver => const Color(0xFF8A94A6),
    LoyaltyTier.gold => AppColors.gold,
  };
}

/// Jauge du score + badge de niveau + avantage, calculés depuis les
/// réservations par [TrustScoreService]. Le score est aussi enregistré
/// en BD (users.trust_score) quand il change.
class _TrustCard extends StatefulWidget {
  const _TrustCard({required this.user});

  final UserProfile user;

  @override
  State<_TrustCard> createState() => _TrustCardState();
}

class _TrustCardState extends State<_TrustCard> {
  static const _service = TrustScoreService();
  static const _complaintTrust = ComplaintTrustService();
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    // Sans effet si les réservations sont déjà chargées.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ReservationProvider>().load();
    });
  }

  /// Enregistre le score recalculé s'il diffère de celui en BD.
  void _syncScore(int score) {
    if (_syncing || score == widget.user.trustScore) return;
    _syncing = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      final current = auth.user;
      if (current != null && current.trustScore != score) {
        await auth.updateProfile(current.copyWith(trustScore: score));
      }
      _syncing = false;
    });
  }

  static Color _scoreColor(int score) {
    if (score >= 70) return AppColors.success;
    if (score >= 40) return AppColors.warning;
    return AppColors.danger;
  }

  @override
  Widget build(BuildContext context) {
    final reservations = context.watch<ReservationProvider>();
    final complaints = context.watch<ComplaintProvider>();
    // On attend aussi les réclamations : sinon le score enregistré en BD
    // serait faux un instant (sans les pénalités pour abus).
    final complaintsPending =
        complaints.state == LoadState.initial ||
        complaints.state == LoadState.loading;
    if (reservations.state != LoadState.success || complaintsPending) {
      return AppCard(
        color: context.cs.surface,
        borderColor: context.cs.outlineVariant,
        child: SizedBox(
          height: 120,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final report = _service.evaluate(
      reservations.reservations,
      extraEvents: _complaintTrust.trustEvents(complaints.complaints),
    );
    final complaintStats = _complaintTrust.stats(complaints.complaints);
    _syncScore(report.score);

    final l = context.l10n;
    final tier = report.tier;
    final scoreColor = _scoreColor(report.score);
    final toNext = report.rentalsToNextTier ?? 0;
    final advantage = switch (tier) {
      LoyaltyTier.gold => l.trustGoldAdvantage,
      LoyaltyTier.silver => l.trustToGold(toNext),
      LoyaltyTier.bronze => l.trustToSilver(toNext),
    };
    final tierName = switch (tier) {
      LoyaltyTier.bronze => l.tierBronze,
      LoyaltyTier.silver => l.tierSilver,
      LoyaltyTier.gold => l.tierGold,
    };

    return AppCard(
      color: context.cs.surface,
      borderColor: context.cs.outlineVariant,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Jauge circulaire du score.
              SizedBox(
                height: 96,
                width: 96,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(end: report.score / 100),
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeOutCubic,
                      builder: (_, value, _) => CircularProgressIndicator(
                        value: value,
                        strokeWidth: 9,
                        strokeCap: StrokeCap.round,
                        backgroundColor: context.cs.outlineVariant,
                        color: scoreColor,
                      ),
                    ),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${report.score}',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: scoreColor,
                              height: 1,
                            ),
                          ),
                          Text(
                            '/100',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: context.cs.outline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.trustTitle,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: context.cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Badge de niveau.
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: tier.color.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                          color: tier.color.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.workspace_premium_rounded,
                            size: 16,
                            color: tier.color,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            l.trustClient(tierName),
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: tier.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          tier == LoyaltyTier.gold
                              ? Icons.local_offer_rounded
                              : Icons.trending_up_rounded,
                          size: 16,
                          color: tier == LoyaltyTier.gold
                              ? AppColors.success
                              : AppColors.accent,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            advantage,
                            style: TextStyle(
                              fontSize: 12.5,
                              height: 1.35,
                              color: context.cs.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 26),
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              _TrustStat(
                Icons.check_circle_outline_rounded,
                l.trustClean(report.cleanRentals),
                AppColors.success,
              ),
              _TrustStat(
                Icons.schedule_rounded,
                l.trustLate(report.lateReturns),
                AppColors.warning,
              ),
              _TrustStat(
                Icons.report_gmailerrorred_rounded,
                l.trustComplaints(report.justifiedComplaints),
                AppColors.danger,
              ),
              if (report.abusiveComplaints > 0)
                _TrustStat(
                  Icons.gpp_bad_outlined,
                  l.trustAbusive(report.abusiveComplaints),
                  AppColors.danger,
                ),
            ],
          ),
          const Divider(height: 26),
          _ComplaintStatsRow(stats: complaintStats),
          const SizedBox(height: 10),
          Text(
            l.trustRules,
            style: TextStyle(fontSize: 11.5, color: context.cs.outline),
          ),
        ],
      ),
    );
  }
}

/// Réclamations : envoyées, résolues, note moyenne donnée. Tap → liste.
class _ComplaintStatsRow extends StatelessWidget {
  const _ComplaintStatsRow({required this.stats});

  final ComplaintStats stats;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final average = stats.averageRatingGiven;

    Widget tile(String value, String label, IconData icon, Color color) {
      return Expanded(
        child: Column(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 4),
                Text(
                  value,
                  textDirection: TextDirection.ltr,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: context.cs.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: TextStyle(fontSize: 11.5, color: context.cs.outline),
            ),
          ],
        ),
      );
    }

    return InkWell(
      onTap: () => context.push(
        context.read<AuthProvider>().isAdmin
            ? Routes.adminComplaints
            : Routes.complaints,
      ),
      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.complaintStatsTitle,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: context.cs.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              tile(
                '${stats.total}',
                l.complaintStatsTotal,
                Icons.support_agent_rounded,
                AppColors.accent,
              ),
              tile(
                '${stats.resolved}',
                l.complaintStatsResolved,
                Icons.check_circle_outline_rounded,
                AppColors.success,
              ),
              tile(
                average == null
                    ? l.complaintStatsNoRating
                    : NumberFormat('0.0', l.localeName).format(average),
                l.complaintStatsAvgGiven,
                Icons.star_rounded,
                const Color(0xFFFFB400),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrustStat extends StatelessWidget {
  const _TrustStat(this.icon, this.label, this.color);

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(fontSize: 12.5, color: context.cs.onSurfaceVariant),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Mes informations
// -----------------------------------------------------------------------------

/// Carte d'informations : titre + lignes « libellé / valeur ».
class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.rows,
    this.footer,
  });

  final IconData icon;
  final String title;
  final List<_InfoRow> rows;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: context.cs.surface,
      borderColor: context.cs.outlineVariant,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 19, color: AppColors.accent),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: context.cs.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final row in rows) row,
          if (footer != null) ...[const SizedBox(height: 10), footer!],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value, {this.badge});

  final String label;
  final String? value;

  /// Pastille optionnelle (ex. « Valide », « Expiré »).
  final (String, Color)? badge;

  @override
  Widget build(BuildContext context) {
    final empty = value == null || value!.trim().isEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: context.cs.outline),
            ),
          ),
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  empty ? context.l10n.commonNotProvided : value!,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: empty ? FontWeight.w400 : FontWeight.w600,
                    color: empty ? context.cs.outline : context.cs.onSurface,
                  ),
                ),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: badge!.$2.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      badge!.$1,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: badge!.$2,
                      ),
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

class _PersonalInfoCard extends StatelessWidget {
  const _PersonalInfoCard({required this.user});

  final UserProfile user;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final birth = user.birthDate;
    final since = user.memberSince;
    return _InfoCard(
      icon: Icons.person_outline_rounded,
      title: l.profilePersonalInfo,
      rows: [
        _InfoRow(l.profileFullName, user.fullName),
        _InfoRow(l.profileEmail, user.email),
        _InfoRow(
          l.commonPhone,
          user.phone.isEmpty ? null : '+216 ${user.phone}',
        ),
        _InfoRow(l.profileCin, user.cin),
        _InfoRow(
          l.profileBirth,
          birth == null ? null : context.dateLong(birth),
        ),
        _InfoRow(l.profileAddress, user.address),
        _InfoRow(
          l.profileMemberSince,
          since == null ? null : context.dateLong(since),
        ),
      ],
    );
  }
}

class _LicenceCard extends StatelessWidget {
  const _LicenceCard({required this.user});

  final UserProfile user;

  /// Pastille selon [UserLicence.licenceStatus] (même règle que l'accueil
  /// et le checkout).
  (String, Color)? _badge(AppLocalizations l) => switch (user.licenceStatus()) {
    LicenceStatus.unknown => null,
    LicenceStatus.valid => (l.licenceValid, AppColors.success),
    LicenceStatus.expiringSoon => (l.licenceExpiringSoon, AppColors.warning),
    LicenceStatus.expired => (l.licenceExpired, AppColors.danger),
  };

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final expiry = user.licenceExpiry;
    return _InfoCard(
      icon: Icons.credit_card_rounded,
      title: l.profileLicence,
      rows: [
        _InfoRow(l.profileLicenceNumber, user.licenceNumber),
        _InfoRow(
          l.profileLicenceExpiry,
          expiry == null ? null : context.dateLong(expiry),
          badge: _badge(l),
        ),
      ],
    );
  }
}

/// Position GPS + agence par défaut, avec « Mettre à jour ma position ».
class _PositionCard extends StatefulWidget {
  const _PositionCard({super.key, required this.user});

  final UserProfile user;

  @override
  State<_PositionCard> createState() => _PositionCardState();
}

class _PositionCardState extends State<_PositionCard> {
  static const _location = LocationService();
  bool _loading = false;

  /// Appelé aussi par la barre de complétion (« Enregistrez votre position »).
  Future<void> _update() async {
    if (_loading) return;
    setState(() => _loading = true);
    final DetectedLocation found;
    try {
      found = await _location.detect();
    } on LocationException catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        await _showLocationError(e);
      }
      return;
    }
    if (!mounted) return;
    setState(() => _loading = false);

    final user = widget.user;
    final replaceAddress = await _confirm(found, user);
    if (replaceAddress == null || !mounted) return;

    final auth = context.read<AuthProvider>();
    final ok = await auth.updateProfile(
      user.copyWith(
        latitude: found.latitude,
        longitude: found.longitude,
        city: found.nearestCity,
        address: replaceAddress ? found.address : null,
      ),
    );
    if (!mounted) return;
    final l = context.l10n;
    if (ok) {
      AppSnack.success(context, l.profileDefaultAgencySet(found.nearestCity));
    } else {
      AppSnack.error(context, l.authError(auth.errorCode));
    }
  }

  /// Retourne `null` si annulé, sinon s'il faut remplacer l'adresse.
  Future<bool?> _confirm(DetectedLocation found, UserProfile user) {
    final l = context.l10n;
    var replaceAddress = user.address.trim().isEmpty;
    final hasAddress = found.address != null;

    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          icon: const Icon(Icons.my_location_rounded, color: AppColors.accent),
          title: Text(l.profileNewPosition),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                found.address ?? l.commonAddressUnavailable,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                l.commonNearestAgency(
                      found.nearestCity,
                      found.distanceKm.toStringAsFixed(1),
                    ) +
                    (found.nearestCity == user.city
                        ? ' — ${l.profileUnchanged}'
                        : ''),
                style: TextStyle(
                  fontSize: 13.5,
                  color: context.cs.onSurfaceVariant,
                ),
              ),
              if (hasAddress)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: replaceAddress,
                  onChanged: (v) =>
                      setDialogState(() => replaceAddress = v ?? false),
                  title: Text(
                    l.profileUseThisAddress,
                    style: const TextStyle(fontSize: 13.5),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l.commonCancel),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, hasAddress && replaceAddress),
              child: Text(l.commonSave),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showLocationError(LocationException e) {
    final openSettings = switch (e.reason) {
      LocationFailure.serviceDisabled => _location.openLocationSettings,
      LocationFailure.deniedForever => _location.openAppSettings,
      _ => null,
    };
    final l = context.l10n;
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.location_off_rounded, color: AppColors.warning),
        title: Text(l.commonPositionUnavailable),
        content: Text(l.locationError(e.reason)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l.commonClose),
          ),
          if (openSettings != null)
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                openSettings();
              },
              child: Text(l.commonOpenSettings),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final user = widget.user;
    final lat = user.latitude;
    final lng = user.longitude;
    return _InfoCard(
      icon: Icons.place_outlined,
      title: l.profilePositionTitle,
      rows: [
        _InfoRow(l.profileDefaultAgency, user.city),
        _InfoRow(
          l.profileCoordinates,
          lat == null || lng == null
              ? null
              : '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}',
        ),
      ],
      footer: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: _loading ? null : _update,
          icon: _loading
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2.2),
                )
              : const Icon(Icons.my_location_rounded),
          label: Text(_loading ? l.commonLocating : l.profileUpdatePosition),
        ),
      ),
    );
  }
}

class _GroupTitle extends StatelessWidget {
  const _GroupTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 4, bottom: 10),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
          color: context.cs.outline,
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
    this.badge = 0,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final bool danger;

  /// Pastille (ex. réclamations avec une mise à jour non lue). 0 → aucune.
  final int badge;
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({required this.items});

  final List<_MenuItem> items;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: context.cs.surface,
      borderColor: context.cs.outlineVariant,
      padding: EdgeInsets.zero,
      child: // Material transparent : effet d'appui des ListTile visible dans
          // la carte colorée (AppCard dessine sa couleur avec un Container).
          Material(
            type: MaterialType.transparency,
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
                        color:
                            (items[i].danger
                                    ? AppColors.danger
                                    : AppColors.accent)
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
                            : context.cs.onSurface,
                      ),
                    ),
                    subtitle: Text(
                      items[i].subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: context.cs.outline),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (items[i].badge > 0)
                          Badge(
                            label: Text('${items[i].badge}'),
                            backgroundColor: AppColors.danger,
                          ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: context.cs.outline,
                        ),
                      ],
                    ),
                  ),
                  if (i != items.length - 1)
                    const Divider(height: 1, indent: 68, endIndent: 16),
                ],
              ],
            ),
          ),
    );
  }
}

// -----------------------------------------------------------------------------
// Rappels
// -----------------------------------------------------------------------------

/// Interrupteurs des rappels + autorisation + test (debug).
class _RemindersCard extends StatefulWidget {
  const _RemindersCard();

  @override
  State<_RemindersCard> createState() => _RemindersCardState();
}

class _RemindersCardState extends State<_RemindersCard> {
  /// Bouton de test : visible en debug, ou après un appui long sur le titre.
  bool _showTest = kDebugMode;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final reminders = context.watch<ReminderProvider>();
    final s = reminders.settings;
    final denied = reminders.permissionGranted == false;

    Widget toggle(
      IconData icon,
      String title,
      String subtitle,
      bool value,
      ValueChanged<bool> onChanged,
    ) => Material(
      type: MaterialType.transparency,
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        secondary: Icon(icon, color: AppColors.accent),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
            color: context.cs.onSurface,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: context.cs.outline),
        ),
        value: value,
        onChanged: reminders.supported ? onChanged : null,
      ),
    );

    return AppCard(
      color: context.cs.surface,
      borderColor: context.cs.outlineVariant,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onLongPress: () => setState(() => _showTest = true),
            child: Row(
              children: [
                const Icon(
                  Icons.notifications_active_outlined,
                  size: 19,
                  color: AppColors.accent,
                ),
                const SizedBox(width: 10),
                Text(
                  l.remindersTitle,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: context.cs.onSurface,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          if (!reminders.supported)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: NoticeBox(message: l.remindersUnsupported),
            ),
          toggle(
            Icons.badge_outlined,
            l.remindersLicence,
            l.remindersLicenceSub,
            s.licence,
            reminders.setLicence,
          ),
          toggle(
            Icons.event_note_rounded,
            l.remindersReservation,
            l.remindersReservationSub,
            s.reservation,
            reminders.setReservation,
          ),
          toggle(
            Icons.person_outline_rounded,
            l.remindersProfile,
            l.remindersProfileSub,
            s.profile,
            reminders.setProfile,
          ),
          if (denied && reminders.supported) ...[
            const SizedBox(height: 8),
            NoticeBox(
              icon: Icons.notifications_off_outlined,
              color: AppColors.warning,
              message: l.remindersDenied,
            ),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton.icon(
                onPressed: reminders.requestPermission,
                icon: const Icon(Icons.notifications_outlined, size: 18),
                label: Text(l.remindersAllow),
              ),
            ),
          ],
          if (_showTest && reminders.supported) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  AppSnack.info(context, l.remindersTestScheduled);
                  await reminders.sendTest(l);
                },
                icon: const Icon(Icons.timer_10_rounded),
                label: Text(l.remindersTest),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
