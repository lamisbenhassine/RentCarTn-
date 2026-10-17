import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/models/learning.dart';

/// Panneau routier dessiné (aucun asset image nécessaire).
class RoadSignWidget extends StatelessWidget {
  const RoadSignWidget({super.key, required this.sign, this.size = 76});

  final RoadSign sign;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: size,
      width: size,
      child: CustomPaint(
        painter: _SignPainter(sign: sign),
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(size * 0.2),
            child: FittedBox(
              child: Text(
                sign.glyph,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: _glyphColor,
                  height: 1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color get _glyphColor => switch (sign.category) {
    SignCategory.obligation => Colors.white,
    SignCategory.indication => Colors.white,
    _ => const Color(0xFF111827),
  };
}

class _SignPainter extends CustomPainter {
  _SignPainter({required this.sign});

  final RoadSign sign;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final border = Paint()
      ..style = PaintingStyle.fill
      ..color = _borderColor;
    final fill = Paint()
      ..style = PaintingStyle.fill
      ..color = _fillColor;

    switch (sign.shape) {
      case SignShape.triangle:
        final outer = Path()
          ..moveTo(w / 2, h * 0.04)
          ..lineTo(w * 0.97, h * 0.9)
          ..lineTo(w * 0.03, h * 0.9)
          ..close();
        final inner = Path()
          ..moveTo(w / 2, h * 0.2)
          ..lineTo(w * 0.86, h * 0.82)
          ..lineTo(w * 0.14, h * 0.82)
          ..close();
        canvas.drawPath(outer, border);
        canvas.drawPath(inner, fill);

      case SignShape.cercle:
        canvas.drawCircle(Offset(w / 2, h / 2), w / 2, border);
        canvas.drawCircle(Offset(w / 2, h / 2), w * 0.38, fill);

      case SignShape.carre:
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, w, h),
          Radius.circular(w * 0.1),
        );
        final innerRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.07, h * 0.07, w * 0.86, h * 0.86),
          Radius.circular(w * 0.07),
        );
        canvas.drawRRect(rect, border);
        canvas.drawRRect(innerRect, fill);

      case SignShape.octogone:
        canvas.drawPath(_octagon(w, h, 0.5), border);
        canvas.drawPath(_octagon(w, h, 0.43), fill);

      case SignShape.losange:
        final outer = Path()
          ..moveTo(w / 2, 0)
          ..lineTo(w, h / 2)
          ..lineTo(w / 2, h)
          ..lineTo(0, h / 2)
          ..close();
        final inner = Path()
          ..moveTo(w / 2, h * 0.14)
          ..lineTo(w * 0.86, h / 2)
          ..lineTo(w / 2, h * 0.86)
          ..lineTo(w * 0.14, h / 2)
          ..close();
        canvas.drawPath(outer, border);
        canvas.drawPath(inner, fill);
    }
  }

  Path _octagon(double w, double h, double radiusFactor) {
    final path = Path();
    final cx = w / 2;
    final cy = h / 2;
    final r = w * radiusFactor;
    for (var i = 0; i < 8; i++) {
      final angle = (i * 45 + 22.5) * math.pi / 180;
      final x = cx + r * math.cos(angle);
      final y = cy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    return path..close();
  }

  Color get _borderColor => switch (sign.category) {
    SignCategory.danger => const Color(0xFFDC2626),
    SignCategory.interdiction => const Color(0xFFB91C1C),
    SignCategory.obligation => const Color(0xFF1D4ED8),
    SignCategory.indication => const Color(0xFF0F766E),
    SignCategory.priorite => const Color(0xFFD97706),
  };

  Color get _fillColor => switch (sign.category) {
    SignCategory.obligation => const Color(0xFF2563EB),
    SignCategory.indication => const Color(0xFF0F766E),
    SignCategory.priorite => const Color(0xFFFDE68A),
    _ => Colors.white,
  };

  @override
  bool shouldRepaint(covariant _SignPainter oldDelegate) =>
      oldDelegate.sign.id != sign.id;
}
