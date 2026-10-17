import 'package:flutter/material.dart';

/// Palette de l'identité visuelle RentCar Tunisia.
/// Bleu marine profond + accent bleu électrique + blanc.
class AppColors {
  AppColors._();

  static const Color navy = Color(0xFF0B1220);
  static const Color navySoft = Color(0xFF141E33);
  static const Color navyCard = Color(0xFF1B2740);
  static const Color ink = Color(0xFF101828);

  static const Color accent = Color(0xFF2563EB);
  static const Color accentLight = Color(0xFF60A5FA);
  static const Color accentDark = Color(0xFF1D4ED8);

  static const Color surface = Color(0xFFF7F9FC);
  static const Color surfaceAlt = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE3E8EF);

  static const Color textPrimary = Color(0xFF0B1220);
  static const Color textSecondary = Color(0xFF5A6678);
  static const Color textMuted = Color(0xFF8E99A8);

  static const Color success = Color(0xFF16A34A);
  static const Color successSoft = Color(0xFFDCFCE7);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningSoft = Color(0xFFFEF3C7);
  static const Color danger = Color(0xFFDC2626);
  static const Color dangerSoft = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF0EA5E9);
  static const Color infoSoft = Color(0xFFE0F2FE);
  static const Color gold = Color(0xFFD4A017);

  static const LinearGradient navyGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [navy, navySoft, Color(0xFF1E3A8A)],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent, Color(0xFF3B82F6)],
  );
}
