import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/router/app_router.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/formatters.dart';
import '../data/models/licence_status.dart';
import '../data/models/user_profile.dart';

/// Bannière d'accueil : permis qui expire dans 30 jours ou moins (orange),
/// ou déjà expiré (rouge). Rien sinon.
class LicenceExpiryBanner extends StatelessWidget {
  const LicenceExpiryBanner({super.key, required this.user});

  final UserProfile user;

  @override
  Widget build(BuildContext context) {
    final status = user.licenceStatus();
    if (status != LicenceStatus.expiringSoon &&
        status != LicenceStatus.expired) {
      return const SizedBox.shrink();
    }

    final expired = status == LicenceStatus.expired;
    final days = user.daysUntilLicenceExpiry()!;
    final date = Formatters.dateLong(user.licenceExpiry!);
    final color = expired ? AppColors.danger : AppColors.warning;

    final (title, message) = expired
        ? (
            'Permis de conduire expiré',
            'Votre permis a expiré le $date. Vous ne pourrez pas finaliser '
                'de réservation tant qu’il n’est pas mis à jour.',
          )
        : (
            days == 0
                ? 'Votre permis expire aujourd’hui'
                : 'Votre permis expire dans $days jour${days > 1 ? 's' : ''}',
            'Date d’expiration : $date. Pensez à le renouveler puis à '
                'mettre à jour votre profil.',
          );

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 8, 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  expired
                      ? Icons.gpp_bad_outlined
                      : Icons.warning_amber_rounded,
                  color: color,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        message,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => context.push(Routes.editProfile),
                icon: const Icon(Icons.edit_calendar_rounded, size: 18),
                label: const Text('Mettre à jour mon permis'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
