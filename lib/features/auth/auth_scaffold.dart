import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../data/mock/mock_images.dart';
import '../../widgets/car_image.dart';
import '../shell/main_shell.dart';

/// Mise en page commune aux écrans d'authentification :
/// formulaire seul sur mobile, formulaire + visuel sur grand écran.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.showBack = true,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final wide = Responsive.isWide(context);

    final form = SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        wide ? 48 : 22,
        24,
        wide ? 48 : 22,
        32 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: ContentContainer(
        maxWidth: 460,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showBack)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: IconButton(
                  onPressed: () =>
                      context.canPop() ? context.pop() : context.go('/'),
                  icon: const Icon(Icons.arrow_back_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.surfaceAlt,
                    side: const BorderSide(color: AppColors.border),
                  ),
                ),
              ),
            const BrandLogo(),
            const SizedBox(height: 30),
            Text(title, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 28),
            child,
          ],
        ),
      ),
    );

    if (!wide) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        body: SafeArea(child: form),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Row(
        children: [
          Expanded(child: SafeArea(child: Center(child: form))),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CarImage(url: Img.driving, fit: BoxFit.cover),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.navy.withValues(alpha: 0.35),
                            AppColors.navy.withValues(alpha: 0.92),
                          ],
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: Padding(
                        padding: const EdgeInsets.all(36),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Votre mobilité,\nnotre métier.',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 34,
                                height: 1.15,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -1,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              "Location, enchères et apprentissage du code de "
                              "la route réunis dans une seule plateforme.",
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.75),
                                fontSize: 15,
                                height: 1.6,
                              ),
                            ),
                            const SizedBox(height: 26),
                            Row(
                              children: const [
                                _Stat('15+', 'Véhicules'),
                                SizedBox(width: 28),
                                _Stat('12', 'Villes'),
                                SizedBox(width: 28),
                                _Stat('4.8', 'Note moyenne'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.value, this.label);

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AppColors.accentLight,
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
