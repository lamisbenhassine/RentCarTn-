import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';

/// Couleurs qui changent entre clair et sombre. Les couleurs d'état
/// (succès, alerte, danger…) et le bleu marine restent communs.
class _Palette {
  const _Palette({
    required this.brightness,
    required this.background,
    required this.card,
    required this.border,
    required this.text,
    required this.textSecondary,
    required this.textMuted,
    required this.primary,
    required this.link,
    required this.secondary,
    required this.outlinedForeground,
    required this.snackBar,
    required this.overlayStyle,
  });

  final Brightness brightness;

  /// Fond d'écran (Scaffold).
  final Color background;

  /// Cartes, champs, feuilles, dialogues.
  final Color card;
  final Color border;
  final Color text;
  final Color textSecondary;
  final Color textMuted;

  /// Boutons pleins, focus des champs, barre de progression.
  final Color primary;

  /// Boutons texte / liens.
  final Color link;
  final Color secondary;
  final Color outlinedForeground;
  final Color snackBar;
  final SystemUiOverlayStyle overlayStyle;

  /// Valeurs identiques à l'ancien thème clair.
  static const light = _Palette(
    brightness: Brightness.light,
    background: AppColors.surface,
    card: AppColors.surfaceAlt,
    border: AppColors.border,
    text: AppColors.textPrimary,
    textSecondary: AppColors.textSecondary,
    textMuted: AppColors.textMuted,
    primary: AppColors.accent,
    link: AppColors.accent,
    secondary: AppColors.navy,
    outlinedForeground: AppColors.navy,
    snackBar: AppColors.navy,
    overlayStyle: SystemUiOverlayStyle.dark,
  );

  /// Bleu marine de la marque en fond, accent bleu éclairci pour le
  /// contraste (texte clair ≥ 4,5:1 sur les fonds).
  static const dark = _Palette(
    brightness: Brightness.dark,
    background: AppColors.navy, // #0B1220
    card: AppColors.navySoft, // #141E33
    border: Color(0xFF26324A),
    text: Color(0xFFE8EDF5),
    textSecondary: Color(0xFFA9B4C6),
    textMuted: Color(0xFF7D889B),
    primary: Color(0xFF3B82F6),
    link: AppColors.accentLight, // #60A5FA
    secondary: AppColors.accentLight,
    outlinedForeground: Color(0xFFE8EDF5),
    snackBar: AppColors.navyCard,
    overlayStyle: SystemUiOverlayStyle.light,
  );
}

/// Thèmes de l'app. Correspondance utilisée par les écrans adaptés
/// (`Theme.of(context).colorScheme`) :
/// - `surfaceContainerLow` → fond d'écran (ancien `AppColors.surface`)
/// - `surface` → cartes / champs (ancien `AppColors.surfaceAlt`)
/// - `onSurface` / `onSurfaceVariant` / `outline` → texte principal /
///   secondaire / discret
/// - `outlineVariant` → bordures (ancien `AppColors.border`)
/// - `primary` → accent
class AppTheme {
  AppTheme._();

  static const double radiusSm = 10;
  static const double radiusMd = 16;
  static const double radiusLg = 22;
  static const double radiusXl = 30;

  static ThemeData get light => _build(_Palette.light);
  static ThemeData get dark => _build(_Palette.dark);

  static ThemeData _build(_Palette p) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: p.brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.accent,
        brightness: p.brightness,
        primary: p.primary,
        onPrimary: Colors.white,
        secondary: p.secondary,
        onSecondary: p.brightness == Brightness.light
            ? Colors.white
            : AppColors.navy,
        surface: p.card,
        onSurface: p.text,
        onSurfaceVariant: p.textSecondary,
        outline: p.textMuted,
        outlineVariant: p.border,
        surfaceContainerLow: p.background,
        error: AppColors.danger,
      ),
      scaffoldBackgroundColor: p.background,
    );

    return base.copyWith(
      textTheme: _textTheme(base.textTheme, p),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        foregroundColor: p.text,
        systemOverlayStyle: p.overlayStyle,
        titleTextStyle: TextStyle(
          color: p.text,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: p.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: BorderSide(color: p.border),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: p.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: p.border,
          disabledForegroundColor: p.textMuted,
          elevation: 0,
          minimumSize: const Size(0, 54),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.outlinedForeground,
          minimumSize: const Size(0, 54),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          side: BorderSide(color: p.border, width: 1.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.link,
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.card,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        hintStyle: TextStyle(color: p.textMuted, fontSize: 15),
        labelStyle: TextStyle(color: p.textSecondary, fontSize: 15),
        prefixIconColor: p.textMuted,
        suffixIconColor: p.textMuted,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: p.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: p.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: p.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.6),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: p.card,
        selectedColor: p.brightness == Brightness.light
            ? AppColors.navy
            : p.primary,
        side: BorderSide(color: p.border),
        labelStyle: TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          color: p.textSecondary,
        ),
        secondaryLabelStyle: const TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXl),
        ),
      ),
      dividerTheme: DividerThemeData(color: p.border, thickness: 1, space: 1),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.card,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: p.snackBar,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSm),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: p.card,
        surfaceTintColor: Colors.transparent,
        indicatorColor: p.primary.withValues(alpha: 0.12),
        elevation: 0,
        height: 70,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 11.5,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? p.link : p.textMuted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 24,
            color: selected ? p.link : p.textMuted,
          );
        }),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: p.link,
        unselectedLabelColor: p.textMuted,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: p.border,
        labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: p.primary,
        linearTrackColor: p.border,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: p.textSecondary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      ),
    );
  }

  static TextTheme _textTheme(TextTheme base, _Palette p) {
    return base.copyWith(
      displaySmall: base.displaySmall?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -1,
        color: p.text,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.8,
        color: p.text,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.6,
        color: p.text,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        color: p.text,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: p.text,
      ),
      titleSmall: base.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: p.text,
      ),
      bodyLarge: base.bodyLarge?.copyWith(color: p.text, height: 1.45),
      bodyMedium: base.bodyMedium?.copyWith(
        color: p.textSecondary,
        height: 1.5,
      ),
      bodySmall: base.bodySmall?.copyWith(color: p.textMuted, height: 1.4),
      labelLarge: base.labelLarge?.copyWith(fontWeight: FontWeight.w700),
    );
  }

  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: AppColors.navy.withValues(alpha: 0.06),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: AppColors.navy.withValues(alpha: 0.08),
      blurRadius: 30,
      offset: const Offset(0, 12),
    ),
  ];
}

/// Raccourci pour les écrans adaptés au mode sombre : `context.cs.onSurface`.
extension ThemeColors on BuildContext {
  ColorScheme get cs => Theme.of(this).colorScheme;
}
