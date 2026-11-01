import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/utils/validators.dart';

/// Langue de l'application (fr / en / ar), gardée dans shared_preferences.
///
/// Premier lancement : langue du téléphone si elle est prise en charge,
/// sinon français.
class LocaleProvider extends ChangeNotifier {
  static const List<String> supportedCodes = ['fr', 'en', 'ar'];
  static const String _prefsKey = 'app_locale';

  Locale _locale = const Locale('fr');

  Locale get locale => _locale;
  bool get isRtl => _locale.languageCode == 'ar';

  /// À appeler avant runApp.
  Future<void> load() async {
    String? saved;
    try {
      saved = (await SharedPreferences.getInstance()).getString(_prefsKey);
    } catch (_) {
      // Préférences illisibles : on retombe sur la langue du téléphone.
    }
    final device =
        WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    _apply(saved ?? device);
  }

  Future<void> setLocale(String languageCode) async {
    if (languageCode == _locale.languageCode) return;
    _apply(languageCode);
    notifyListeners();
    try {
      await (await SharedPreferences.getInstance()).setString(
        _prefsKey,
        _locale.languageCode,
      );
    } catch (_) {
      // Langue appliquée pour la session, même si non enregistrée.
    }
  }

  void _apply(String code) {
    _locale = Locale(supportedCodes.contains(code) ? code : 'fr');
    // Les validateurs n'ont pas de BuildContext : on leur passe la langue.
    Validators.setLocale(_locale);
  }
}
