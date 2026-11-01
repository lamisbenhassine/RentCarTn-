import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';

/// Couleur des étoiles (lisible en clair comme en sombre).
const Color ratingStarColor = Color(0xFFFFB400);

/// 1 à 5 étoiles. Avec [onChanged] : sélection au toucher, avec un rebond
/// en cascade des étoiles allumées. Sans [onChanged] : affichage seul.
class RatingStars extends StatelessWidget {
  const RatingStars({
    super.key,
    required this.value,
    this.onChanged,
    this.size = 22,
  });

  /// 0 = aucune étoile.
  final int value;
  final ValueChanged<int>? onChanged;
  final double size;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final outline = Theme.of(context).colorScheme.outline;
    final interactive = onChanged != null;

    final stars = [
      for (var i = 1; i <= 5; i++)
        _Star(
          // La clé change avec la note : les étoiles allumées rejouent
          // leur animation, l'une après l'autre.
          key: ValueKey('star-$i-${interactive ? value : 0}'),
          filled: i <= value,
          animate: interactive && i <= value,
          delay: Duration(milliseconds: 60 * (i - 1)),
          size: size,
          color: i <= value ? ratingStarColor : outline,
          onTap: interactive ? () => onChanged!(i) : null,
          semanticLabel: l.ratingStars(i),
          selected: i == value,
        ),
    ];

    if (interactive) {
      return Row(mainAxisSize: MainAxisSize.min, children: stars);
    }
    return Semantics(
      label: l.ratingStars(value),
      excludeSemantics: true,
      child: Row(mainAxisSize: MainAxisSize.min, children: stars),
    );
  }
}

class _Star extends StatefulWidget {
  const _Star({
    super.key,
    required this.filled,
    required this.animate,
    required this.delay,
    required this.size,
    required this.color,
    required this.onTap,
    required this.semanticLabel,
    required this.selected,
  });

  final bool filled;
  final bool animate;
  final Duration delay;
  final double size;
  final Color color;
  final VoidCallback? onTap;
  final String semanticLabel;
  final bool selected;

  @override
  State<_Star> createState() => _StarState();
}

class _StarState extends State<_Star> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  /// Grossit puis revient avec un léger rebond.
  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 1, end: 1.35), weight: 40),
    TweenSequenceItem(
      tween: Tween(
        begin: 1.35,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.elasticOut)),
      weight: 60,
    ),
  ]).animate(_controller);

  @override
  void initState() {
    super.initState();
    if (widget.animate) {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final icon = ScaleTransition(
      scale: _scale,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        child: Icon(
          widget.filled ? Icons.star_rounded : Icons.star_outline_rounded,
          key: ValueKey(widget.filled),
          size: widget.size,
          color: widget.color,
        ),
      ),
    );

    if (widget.onTap == null) return icon;
    return Semantics(
      button: true,
      selected: widget.selected,
      label: widget.semanticLabel,
      excludeSemantics: true,
      child: InkResponse(
        onTap: widget.onTap,
        radius: widget.size * 0.9,
        child: Padding(padding: const EdgeInsets.all(4), child: icon),
      ),
    );
  }
}
