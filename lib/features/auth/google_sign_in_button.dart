import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../data/services/google_auth_service.dart';
import '../../l10n/l10n.dart';
import '../../state/auction_provider.dart';
import '../../state/auth_provider.dart';
import '../../widgets/common.dart';

/// Séparateur « ——— ou ——— » entre le formulaire et Google.
class OrDivider extends StatelessWidget {
  const OrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            context.l10n.commonOr,
            style: TextStyle(fontSize: 13, color: context.cs.outline),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}

/// Bouton « Continuer avec Google » (connexion et inscription).
/// Compte existant → connexion ; sinon → compte créé avec l'e-mail vérifié.
class GoogleSignInButton extends StatefulWidget {
  const GoogleSignInButton({super.key});

  @override
  State<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<GoogleSignInButton> {
  bool _loading = false;

  Future<void> _signIn() async {
    final auth = context.read<AuthProvider>();
    setState(() => _loading = true);
    final ok = await auth.loginWithGoogle();
    if (!mounted) return;
    setState(() => _loading = false);

    final l = context.l10n;
    if (ok) {
      context.read<AuctionProvider>().setUsername(
        auth.publicUsername,
        userId: auth.user?.id,
      );
      AppSnack.success(context, l.loginWelcome(auth.user!.firstName));
      context.go(Routes.home);
      return;
    }

    // Annulation : googleError == null → aucun message.
    final error = auth.googleError;
    if (error == null) return;
    AppSnack.error(context, switch (error) {
      GoogleAuthFailure.network => l.googleErrorNetwork,
      GoogleAuthFailure.configuration => l.googleErrorConfig,
      GoogleAuthFailure.unsupported => l.googleErrorUnsupported,
      GoogleAuthFailure.noAccount => l.googleErrorNoAccount,
      GoogleAuthFailure.notAllowed => l.googleErrorNotAllowed,
      GoogleAuthFailure.unknown => l.googleErrorUnknown,
    });
  }

  @override
  Widget build(BuildContext context) {
    final busy = context.watch<AuthProvider>().busy;

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: busy || _loading ? null : _signIn,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 52),
          backgroundColor: context.cs.surface,
          side: BorderSide(color: context.cs.outlineVariant),
          foregroundColor: context.cs.onSurface,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_loading)
              const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2.2),
              )
            else
              const _GoogleLogo(),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                context.l10n.googleContinue,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// « G » Google aux couleurs officielles (sans image à embarquer).
class _GoogleLogo extends StatelessWidget {
  const _GoogleLogo();

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (rect) => const SweepGradient(
        colors: [
          Color(0xFFEA4335), // rouge
          Color(0xFFFBBC05), // jaune
          Color(0xFF34A853), // vert
          Color(0xFF4285F4), // bleu
          Color(0xFFEA4335),
        ],
        stops: [0.0, 0.3, 0.55, 0.8, 1.0],
      ).createShader(rect),
      child: const Text(
        'G',
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, height: 1),
      ),
    );
  }
}
