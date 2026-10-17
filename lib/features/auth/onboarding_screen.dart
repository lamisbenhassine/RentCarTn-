import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../data/mock/mock_images.dart';
import '../../widgets/car_image.dart';
import '../shell/main_shell.dart';

class _Slide {
  const _Slide(this.image, this.title, this.text, this.icon);
  final String image;
  final String title;
  final String text;
  final IconData icon;
}

final List<_Slide> _slides = [
  _Slide(
    Img.roadDesert,
    'Louez la voiture idéale\npartout en Tunisie',
    "Plus de 15 modèles disponibles à Tunis, Sousse, Sfax, Hammamet et Djerba. "
        "Réservation en quelques minutes, prix en dinars, sans surprise.",
    Icons.directions_car_filled_rounded,
  ),
  _Slide(
    Img.sedanRed,
    'Enchérissez sur nos\nvéhicules d\'occasion',
    "Chaque mois, notre flotte se renouvelle. Participez aux ventes aux "
        "enchères et repartez avec une voiture entretenue par nos soins.",
    Icons.gavel_rounded,
  ),
  _Slide(
    Img.coastRoad,
    'Maîtrisez le code\nde la route tunisien',
    "Panneaux, priorités, ronds-points, stationnement : un module pédagogique "
        "complet avec quiz interactifs pour conduire sereinement.",
    Icons.menu_book_rounded,
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isLast => _page == _slides.length - 1;

  void _next() {
    if (_isLast) {
      context.go(Routes.login);
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final wide = Responsive.isWide(context);

    return Scaffold(
      backgroundColor: AppColors.navy,
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: _slides.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (_, i) => _SlideView(slide: _slides[i], wide: wide),
          ),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 16,
            left: 20,
            child: const BrandLogo(light: true),
          ),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 24,
            right: 16,
            child: TextButton(
              onPressed: () => context.go(Routes.login),
              style: TextButton.styleFrom(foregroundColor: Colors.white70),
              child: const Text('Passer'),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                wide ? 48 : 24,
                24,
                wide ? 48 : 24,
                MediaQuery.paddingOf(context).bottom + 28,
              ),
              child: ContentContainer(
                maxWidth: 640,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0; i < _slides.length; i++)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            height: 6,
                            width: i == _page ? 26 : 8,
                            decoration: BoxDecoration(
                              color: i == _page
                                  ? AppColors.accentLight
                                  : Colors.white24,
                              borderRadius: BorderRadius.circular(100),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 26),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _next,
                        child: Text(
                          _isLast ? 'Commencer' : 'Suivant',
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () => context.go(Routes.register),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Créer un compte'),
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

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide, required this.wide});

  final _Slide slide;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        CarImage(url: slide.image, fit: BoxFit.cover),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.navy.withValues(alpha: 0.65),
                AppColors.navy.withValues(alpha: 0.88),
                AppColors.navy,
              ],
              stops: const [0, 0.55, 1],
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              wide ? 48 : 24,
              0,
              wide ? 48 : 24,
              wide ? 230 : 210,
            ),
            child: ContentContainer(
              maxWidth: 640,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.accentLight.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Icon(
                      slide.icon,
                      color: AppColors.accentLight,
                      size: 26,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    slide.title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: wide ? 40 : 30,
                      height: 1.15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    slide.text,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.78),
                      fontSize: wide ? 16 : 14.5,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
