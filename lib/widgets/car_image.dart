import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// Image de véhicule avec état de chargement et repli dessiné si la source
/// distante est indisponible (mode hors ligne, URL expirée).
class CarImage extends StatelessWidget {
  const CarImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.height,
    this.width,
    this.darken = false,
  });

  final String url;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final double? height;
  final double? width;

  /// Assombrit l'image pour faire ressortir un texte superposé.
  final bool darken;

  @override
  Widget build(BuildContext context) {
    Widget image = url.isEmpty
        ? const _ImageFallback()
        : Image.network(
            url,
            fit: fit,
            height: height,
            width: width,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return const _ImageSkeleton();
            },
            errorBuilder: (_, _, _) => const _ImageFallback(),
          );

    if (darken) {
      image = Stack(
        fit: StackFit.expand,
        children: [
          image,
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  AppColors.navy.withValues(alpha: 0.75),
                ],
              ),
            ),
          ),
        ],
      );
    }

    final sized = SizedBox(height: height, width: width, child: image);

    if (borderRadius == null) return sized;
    return ClipRRect(borderRadius: borderRadius!, child: sized);
  }
}

class _ImageSkeleton extends StatefulWidget {
  const _ImageSkeleton();

  @override
  State<_ImageSkeleton> createState() => _ImageSkeletonState();
}

class _ImageSkeletonState extends State<_ImageSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return DecoratedBox(
          decoration: BoxDecoration(
            color: Color.lerp(
              const Color(0xFFE9EDF3),
              const Color(0xFFF6F8FB),
              _controller.value,
            ),
          ),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppColors.navyGradient),
      child: Center(
        child: Icon(
          Icons.directions_car_filled_rounded,
          color: Colors.white.withValues(alpha: 0.35),
          size: 48,
        ),
      ),
    );
  }
}
