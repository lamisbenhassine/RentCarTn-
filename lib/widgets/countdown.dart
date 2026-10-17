import 'dart:async';

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/utils/formatters.dart';

/// Compte à rebours jusqu'à la clôture d'une enchère.
///
/// Limite connue : l'horloge utilisée est celle de l'appareil. Une vente
/// réelle doit synchroniser l'heure de fin avec le serveur.
class CountdownText extends StatefulWidget {
  const CountdownText({
    super.key,
    required this.endAt,
    this.style,
    this.urgentThreshold = const Duration(hours: 1),
    this.prefixIcon,
    this.onFinished,
    this.forcedColor,
  });

  final DateTime endAt;
  final TextStyle? style;
  final Duration urgentThreshold;
  final IconData? prefixIcon;
  final VoidCallback? onFinished;

  /// Ignore la coloration automatique (utile sur fond sombre).
  final Color? forcedColor;

  @override
  State<CountdownText> createState() => _CountdownTextState();
}

class _CountdownTextState extends State<CountdownText> {
  Timer? _timer;
  late Duration _remaining;
  bool _notified = false;

  @override
  void initState() {
    super.initState();
    _remaining = _compute();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _remaining = _compute());
      if (_remaining == Duration.zero && !_notified) {
        _notified = true;
        widget.onFinished?.call();
      }
    });
  }

  @override
  void didUpdateWidget(covariant CountdownText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.endAt != widget.endAt) {
      _notified = false;
      _remaining = _compute();
    }
  }

  Duration _compute() {
    final diff = widget.endAt.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ended = _remaining == Duration.zero;
    final urgent = !ended && _remaining <= widget.urgentThreshold;
    final color =
        widget.forcedColor ??
        (ended
            ? AppColors.textMuted
            : urgent
            ? AppColors.danger
            : AppColors.textPrimary);

    final text = ended ? 'Enchère terminée' : Formatters.countdown(_remaining);

    final style =
        (widget.style ??
                const TextStyle(fontSize: 14, fontWeight: FontWeight.w800))
            .copyWith(color: color);

    if (widget.prefixIcon == null) return Text(text, style: style);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(widget.prefixIcon, size: (style.fontSize ?? 14) + 2, color: color),
        const SizedBox(width: 5),
        Flexible(
          child: Text(text, style: style, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}

/// Pastille de compte à rebours posée sur une image.
class CountdownPill extends StatelessWidget {
  const CountdownPill({super.key, required this.endAt, this.ended = false});

  final DateTime endAt;
  final bool ended;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: ended
            ? AppColors.textMuted.withValues(alpha: 0.9)
            : AppColors.navy.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(100),
      ),
      child: ended
          ? const Text(
              'Terminée',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            )
          : CountdownText(
              endAt: endAt,
              prefixIcon: Icons.timer_outlined,
              forcedColor: Colors.white,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
    );
  }
}
