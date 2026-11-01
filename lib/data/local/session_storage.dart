import 'package:shared_preferences/shared_preferences.dart';

/// Petites données de session (shared_preferences, mobile + web) :
/// - l'id du compte mémorisé par « Se souvenir de moi » ;
/// - la fin du blocage après trop d'échecs de connexion.
class SessionStorage {
  const SessionStorage();

  static const _kUserId = 'session_user_id';
  static const _kLockedUntil = 'login_locked_until';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<String?> readUserId() async => (await _prefs).getString(_kUserId);

  Future<void> saveUserId(String userId) async =>
      (await _prefs).setString(_kUserId, userId);

  Future<void> clearUserId() async => (await _prefs).remove(_kUserId);

  /// Compte supprimé : efface la session « Se souvenir de moi », le
  /// blocage de connexion et toute préférence dont la clé contient l'id du
  /// compte (convention pour les futures préférences par utilisateur).
  /// La langue de l'app (`app_locale`) est un réglage de l'appareil : gardée.
  Future<void> clearForDeletedAccount(String userId) async {
    final prefs = await _prefs;
    await prefs.remove(_kUserId);
    await prefs.remove(_kLockedUntil);
    for (final key in prefs.getKeys().toList()) {
      if (key.contains(userId)) await prefs.remove(key);
    }
  }

  Future<DateTime?> readLockedUntil() async {
    final ms = (await _prefs).getInt(_kLockedUntil);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<void> saveLockedUntil(DateTime? until) async {
    final prefs = await _prefs;
    if (until == null) {
      await prefs.remove(_kLockedUntil);
    } else {
      await prefs.setInt(_kLockedUntil, until.millisecondsSinceEpoch);
    }
  }
}
