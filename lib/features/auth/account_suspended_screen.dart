import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/ban_format.dart';
import '../../core/utils/responsive.dart';
import '../../l10n/l10n.dart';
import '../../state/auth_provider.dart';
import '../../widgets/common.dart';
import '../complaints/complaint_actions.dart';

/// Adresse du support (e-mail « Contacter le support »).
const kSupportEmail = 'support@rentcar.tn';

/// « Compte suspendu » : affiché à la place de l'app quand un compte
/// banni tente de se connecter (e-mail, Google) ou est déconnecté au
/// démarrage / au retour au premier plan. Le routeur y redirige tant que
/// [AuthProvider.suspended] n'est pas `null`.
class AccountSuspendedScreen extends StatefulWidget {
  const AccountSuspendedScreen({super.key});

  @override
  State<AccountSuspendedScreen> createState() => _AccountSuspendedScreenState();
}

class _AccountSuspendedScreenState extends State<AccountSuspendedScreen> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // Compte à rebours (temps restant), à la seconde.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _back() {
    context.read<AuthProvider>().clearSuspended(); // → écran de connexion
    context.go(Routes.login);
  }

  Future<void> _contact(String email) async {
    final l = context.l10n;
    final uri = Uri(
      scheme: 'mailto',
      path: kSupportEmail,
      query: 'subject=${Uri.encodeComponent(l.suspendedMailSubject(email))}',
    );
    var opened = false;
    try {
      opened = await launchUrl(uri);
    } catch (_) {}
    if (!opened && mounted) {
      AppSnack.info(context, l.suspendedMailFailed(kSupportEmail));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final user = context.watch<AuthProvider>().suspended;
    if (user == null) return const Scaffold(body: SizedBox.shrink());

    final end = user.bannedUntil;
    final remaining = end?.difference(DateTime.now());
    // Suspension temporaire terminée pendant l'affichage.
    final over =
        !user.banPermanent && (remaining == null || remaining <= Duration.zero);

    return Scaffold(
      backgroundColor: context.cs.surfaceContainerLow,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ContentContainer(
              maxWidth: 480,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: (over ? AppColors.success : AppColors.danger)
                            .withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        over ? Icons.lock_open_rounded : Icons.block_rounded,
                        size: 48,
                        color: over ? AppColors.success : AppColors.danger,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    l.suspendedTitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    over
                        ? l.suspendedOver
                        : (user.banPermanent || end == null
                              ? l.suspendedPermanent
                              : l.suspendedUntil(banDateTime(context, end))),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14.5,
                      height: 1.5,
                      color: context.cs.onSurfaceVariant,
                    ),
                  ),
                  if (!over && !user.banPermanent && remaining != null) ...[
                    const SizedBox(height: 18),
                    AppCard(
                      color: context.cs.surface,
                      borderColor: context.cs.outlineVariant,
                      child: Column(
                        children: [
                          Text(
                            l.suspendedRemaining,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: context.cs.outline,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            banRemaining(l, remaining),
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: context.cs.onSurface,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (!over && (user.banReason ?? '').isNotEmpty) ...[
                    const SizedBox(height: 14),
                    NoticeBox(
                      icon: Icons.info_outline_rounded,
                      color: AppColors.danger,
                      title: l.suspendedReason,
                      message: user.banReason!,
                    ),
                  ],
                  const SizedBox(height: 24),
                  if (!over) ...[
                    ElevatedButton.icon(
                      onPressed: () => _contact(user.email),
                      icon: const Icon(Icons.mail_outline_rounded),
                      label: Text(l.suspendedContact),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () => callAgency(context),
                      icon: const Icon(Icons.call_outlined),
                      label: Text(l.suspendedCallAgency),
                    ),
                    const SizedBox(height: 8),
                  ],
                  over
                      ? ElevatedButton(
                          onPressed: _back,
                          child: Text(l.suspendedBack),
                        )
                      : TextButton(
                          onPressed: _back,
                          child: Text(l.suspendedBack),
                        ),
                  const SizedBox(height: 8),
                  Text(
                    kSupportEmail,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: context.cs.outline),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
