import 'package:flutter/foundation.dart';

import '../data/local/session_storage.dart';
import '../data/models/user_profile.dart';
import '../data/repositories/auth_repository.dart';
import '../data/services/google_auth_service.dart';

/// Session utilisateur courante. Les comptes sont persistés en SQLite sur
/// mobile (voir [AuthRepository]). « Se souvenir de moi » garde l'id du
/// compte dans shared_preferences pour reconnecter au lancement.
class AuthProvider extends ChangeNotifier {
  AuthProvider({AuthRepository? repository, SessionStorage? session})
    : _repository = repository ?? const AuthRepository(),
      _session = session ?? const SessionStorage();

  final AuthRepository _repository;
  final SessionStorage _session;

  /// Échecs autorisés avant blocage, et durée du blocage.
  static const int maxAttempts = 3;
  static const Duration lockDuration = Duration(seconds: 60);

  UserProfile? _user;
  bool _busy = false;
  String? _error;
  AuthErrorCode? _errorCode;
  int _failedAttempts = 0;
  DateTime? _lockedUntil;

  UserProfile? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get busy => _busy;
  String? get error => _error;

  /// Cause du dernier échec de connexion (compte introuvable, mauvais mot
  /// de passe, blocage).
  AuthErrorCode? get errorCode => _errorCode;

  /// Tentatives restantes avant le blocage de 60 s.
  int get attemptsLeft => maxAttempts - _failedAttempts;

  /// Temps restant de blocage ([Duration.zero] si la connexion est permise).
  Duration get lockRemaining {
    final until = _lockedUntil;
    if (until == null) return Duration.zero;
    final left = until.difference(DateTime.now());
    return left.isNegative ? Duration.zero : left;
  }

  bool get isLocked => lockRemaining > Duration.zero;

  /// Pseudonyme utilisé dans les enchères publiques.
  String get publicUsername => _user?.publicUsername ?? 'Vous';

  GoogleAuthFailure? _googleError;

  /// Raison du dernier échec « Continuer avec Google » (`null` si réussi
  /// ou simplement annulé par l'utilisateur).
  GoogleAuthFailure? get googleError => _googleError;

  /// « Continuer avec Google ». Retourne `true` si connecté.
  /// Annulation → `false` avec [googleError] à `null` (aucun message).
  /// La session est mémorisée comme avec « Se souvenir de moi ».
  Future<bool> loginWithGoogle({bool remember = true}) async {
    _googleError = null;
    _setBusy(true);
    try {
      final user = await _repository.signInWithGoogle();
      if (user == null) return false; // annulé
      _user = user;
      _error = null;
      _errorCode = null;
      if (remember) {
        await _session.saveUserId(user.id);
      } else {
        await _session.clearUserId();
      }
      return true;
    } on GoogleAuthException catch (e) {
      _googleError = e.reason;
      return false;
    } finally {
      _setBusy(false);
    }
  }

  /// À appeler au lancement (avant runApp) : recharge le blocage en cours
  /// et reconnecte le compte mémorisé, s'il existe toujours.
  Future<void> restoreSession() async {
    try {
      _lockedUntil = await _session.readLockedUntil();
      final userId = await _session.readUserId();
      if (userId == null) return;
      _user = await _repository.findUserById(userId);
      if (_user == null) await _session.clearUserId();
    } catch (_) {
      // Préférences illisibles : on démarre simplement déconnecté.
      _user = null;
    }
  }

  Future<bool> login(
    String email,
    String password, {
    bool remember = false,
  }) async {
    if (isLocked) {
      _errorCode = AuthErrorCode.locked;
      _error = 'Trop de tentatives. Patientez avant de réessayer.';
      notifyListeners();
      return false;
    }

    _setBusy(true);
    try {
      _user = await _repository.login(email, password);
      _error = null;
      _errorCode = null;
      _failedAttempts = 0;
      _lockedUntil = null;
      await _session.saveLockedUntil(null);
      if (remember) {
        await _session.saveUserId(_user!.id);
      } else {
        await _session.clearUserId();
      }
      return true;
    } on AuthException catch (e) {
      _failedAttempts++;
      if (_failedAttempts >= maxAttempts) {
        _failedAttempts = 0;
        _lockedUntil = DateTime.now().add(lockDuration);
        await _session.saveLockedUntil(_lockedUntil);
        _errorCode = AuthErrorCode.locked;
        _error = 'Trop de tentatives. Connexion bloquée pendant 60 secondes.';
      } else {
        _errorCode = e.code;
        _error = e.message;
      }
      return false;
    } finally {
      _setBusy(false);
    }
  }

  Future<bool> register({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
    String city = 'Tunis',
    String address = '',
    double? latitude,
    double? longitude,
  }) async {
    _setBusy(true);
    try {
      _user = await _repository.register(
        firstName: firstName,
        lastName: lastName,
        email: email,
        phone: phone,
        password: password,
        city: city,
        address: address,
        latitude: latitude,
        longitude: longitude,
      );
      _error = null;
      return true;
    } on AuthException catch (e) {
      _error = e.message;
      _errorCode = e.code;
      return false;
    } finally {
      _setBusy(false);
    }
  }

  /// Vérifie l'étape 1 de l'inscription : e-mail et téléphone déjà pris ?
  /// (l'écran affiche le message traduit).
  Future<({bool emailTaken, bool phoneTaken})> checkIdentityAvailable({
    required String email,
    required String phone,
  }) async {
    _setBusy(true);
    try {
      return (
        emailTaken: await _repository.isEmailTaken(email),
        phoneTaken: await _repository.isPhoneTaken(phone),
      );
    } finally {
      _setBusy(false);
    }
  }

  /// Mot de passe oublié, étape 1 : retrouve le compte. `null` si
  /// introuvable ([error] et [errorCode] renseignés).
  Future<UserProfile?> findAccountForReset({
    String? email,
    String? phone,
  }) async {
    _setBusy(true);
    try {
      final user = await _repository.findAccountForReset(
        email: email,
        phone: phone,
      );
      _error = null;
      _errorCode = null;
      return user;
    } on AuthException catch (e) {
      _error = e.message;
      _errorCode = e.code;
      return null;
    } finally {
      _setBusy(false);
    }
  }

  /// Mot de passe oublié, dernière étape (code OTP déjà vérifié).
  /// L'identité étant prouvée, le blocage de connexion est levé.
  Future<void> resetPassword(UserProfile user, String newPassword) async {
    _setBusy(true);
    try {
      await _repository.resetPassword(user, newPassword);
      _failedAttempts = 0;
      _lockedUntil = null;
      _error = null;
      _errorCode = null;
      await _session.saveLockedUntil(null);
    } finally {
      _setBusy(false);
    }
  }

  /// `true` si un utilisateur est connecté mais n'a pas encore vérifié
  /// son e-mail (le routeur l'envoie alors sur l'écran de vérification).
  bool get needsEmailVerification => _user != null && !_user!.emailVerified;

  /// Code e-mail validé : enregistre emailVerified = true en BD.
  Future<bool> markEmailVerified() async {
    final current = _user;
    if (current == null) return false;
    return updateProfile(current.copyWith(emailVerified: true));
  }

  /// Sauvegarde le profil (SQLite sur mobile). Retourne `false` si l'e-mail
  /// ou le téléphone appartient déjà à un autre compte ([error] renseigné).
  Future<bool> updateProfile(UserProfile updated) async {
    try {
      _user = await _repository.updateProfile(updated);
      _error = null;
      _errorCode = null;
      return true;
    } on AuthException catch (e) {
      _error = e.message;
      _errorCode = e.code;
      return false;
    } finally {
      notifyListeners();
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final current = _user;
    if (current == null) return false;
    _setBusy(true);
    try {
      await _repository.changePassword(
        user: current,
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      _error = null;
      _errorCode = null;
      return true;
    } on AuthException catch (e) {
      _error = e.message;
      _errorCode = e.code;
      return false;
    } finally {
      _setBusy(false);
    }
  }

  /// `true` si le compte connecté a un mot de passe (sinon compte Google).
  Future<bool> hasLocalPassword() async {
    final current = _user;
    if (current == null) return false;
    return _repository.hasPassword(current);
  }

  /// Supprime définitivement le compte connecté, puis déconnecte.
  /// Retourne `false` si le mot de passe est faux ou si la suppression
  /// échoue ([errorCode] renseigné).
  Future<bool> deleteAccount({String? password}) async {
    final current = _user;
    if (current == null) return false;
    _setBusy(true);
    try {
      await _repository.deleteAccount(current, password: password);
    } on AuthException catch (e) {
      _error = e.message;
      _errorCode = e.code;
      _setBusy(false);
      return false;
    }

    // Préférences liées + session mémorisée + blocage + Google.
    try {
      await _session.clearForDeletedAccount(current.id);
    } catch (_) {
      // Le compte n'existe plus en BD : une préférence restante est sans effet
      // (restoreSession ne retrouvera pas l'id et l'effacera).
    }
    await _repository.signOutGoogle();

    _user = null;
    _error = null;
    _errorCode = null;
    _googleError = null;
    _failedAttempts = 0;
    _lockedUntil = null;
    _busy = false;
    notifyListeners();
    return true;
  }

  /// Déconnexion : oublie aussi le compte mémorisé et la session Google.
  void logout() {
    _user = null;
    _error = null;
    _errorCode = null;
    _googleError = null;
    _session.clearUserId();
    _repository.signOutGoogle();
    notifyListeners();
  }

  void clearError() {
    if (_error == null && _errorCode == null) return;
    _error = null;
    _errorCode = null;
    notifyListeners();
  }

  void _setBusy(bool value) {
    _busy = value;
    notifyListeners();
  }
}
