import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Thème choisi : Clair / Sombre / Automatique (suit le téléphone),
/// enregistré dans shared_preferences. Automatique par défaut.
class ThemeProvider extends ChangeNotifier {
  static const String _prefsKey = 'app_theme_mode';

  ThemeMode _mode = ThemeMode.system;

  ThemeMode get mode => _mode;

  /// À appeler avant runApp.
  Future<void> load() async {
    try {
      final saved = (await SharedPreferences.getInstance()).getString(
        _prefsKey,
      );
      _mode = ThemeMode.values.firstWhere(
        (m) => m.name == saved,
        orElse: () => ThemeMode.system,
      );
    } catch (_) {
      _mode = ThemeMode.system;
    }
  }

  Future<void> setMode(ThemeMode mode) async {
    if (mode == _mode) return;
    _mode = mode;
    notifyListeners();
    try {
      await (await SharedPreferences.getInstance()).setString(
        _prefsKey,
        mode.name,
      );
    } catch (_) {
      // Appliqué pour la session même si non enregistré.
    }
  }
}
