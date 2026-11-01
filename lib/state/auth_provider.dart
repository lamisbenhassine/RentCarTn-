import 'package:flutter/foundation.dart';

import '../data/local/session_storage.dart';
import '../data/models/user_profile.dart';
import '../data/models/user_role.dart';
import '../data/repositories/auth_repository.dart';
import '../data/services/google_auth_service.dart';

/// Session utilisateur (sqflite sur téléphone, prefs sur web).
///
/// - Équipe : session portée par [AuthRepository] (table auth_session),
///   rôles admin / user / company, compte admin par défaut.
/// - Module User : « Se souvenir de moi », blocage 60 s après 3 échecs,
///   Google, vérification de l'e-mail, mot de passe oublié (OTP), profil,
///   changement de mot de passe, suppression du compte.
class AuthProvider extends ChangeNotifier {
  AuthProvider({AuthRepository? repository, SessionStorage? session})
    : _repository = repository ?? AuthRepositoryFactory.create(),
      _session = session ?? const SessionStorage();

  final AuthRepository _repository;

  /// Préférences locales : blocage de connexion, préférences par compte.
  final SessionStorage _session;

  /// Échecs autorisés avant blocage, et durée du blocage.
  static const int maxAttempts = 3;
  static const Duration lockDuration = Duration(seconds: 60);

  UserProfile? _user;
  bool _busy = false;
  bool _restoring = true;
  String? _error;
  AuthErrorCode? _errorCode;
  int _failedAttempts = 0;
  DateTime? _lockedUntil;

  UserProfile? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get busy => _busy;
  bool get restoring => _restoring;
  String? get error => _error;

  UserRole get role => _user?.role ?? UserRole.user;
  bool get isAdmin => _user?.isAdmin ?? false;
  bool get isClient => _user?.isClient ?? false;
  bool get isCompany => _user?.isCompany ?? false;
  bool get isParticular => _user?.isParticular ?? false;

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

  /// Au lancement : admin par défaut, blocage en cours, puis compte de la
  /// session (s'il existe toujours).
  Future<void> restoreSession() async {
    _restoring = true;
    notifyListeners();
    try {
      await _repository.ensureDefaultAdmin();
      try {
        _lockedUntil = await _session.readLockedUntil();
      } catch (_) {}
      var id = await _repository.readSessionUserId();
      // « Se souvenir de moi » de l'ancienne branche module-user
      // (shared_preferences) : repris une fois dans la session de l'équipe.
      if (id == null) {
        try {
          id = await _session.readLegacyUserId();
          if (id != null) {
            await _repository.saveSession(id);
            await _session.clearLegacyUserId();
          }
        } catch (_) {}
      }
      if (id != null) {
        _user = await _repository.byId(id);
        if (_user == null) await _repository.clearSession();
      }
    } catch (_) {
      _user = null;
    } finally {
      _restoring = false;
      notifyListeners();
    }
  }

  /// Le repository enregistre la session à chaque connexion ; sans
  /// « Se souvenir de moi », elle est effacée (pas de reconnexion auto).
  Future<void> _applyRemember(bool remember) async {
    if (!remember) await _repository.clearSession();
  }

  /// « Continuer avec Google ». Retourne `true` si connecté.
  /// Annulation → `false` avec [googleError] à `null` (aucun message).
  Future<bool> loginWithGoogle({bool remember = true}) async {
    _googleError = null;
    _setBusy(true);
    try {
      final user = await _repository.signInWithGoogle();
      if (user == null) return false; // annulé
      _user = user;
      _error = null;
      _errorCode = null;
      await _applyRemember(remember);
      return true;
    } on GoogleAuthException catch (e) {
      _googleError = e.reason;
      return false;
    } finally {
      _setBusy(false);
    }
  }

  Future<bool> login(
    String email,
    String password, {
    bool remember = true,
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
      await _saveLock(null);
      await _applyRemember(remember);
      return true;
    } on AuthException catch (e) {
      _failedAttempts++;
      if (_failedAttempts >= maxAttempts) {
        _failedAttempts = 0;
        _lockedUntil = DateTime.now().add(lockDuration);
        await _saveLock(_lockedUntil);
        _errorCode = AuthErrorCode.locked;
        _error = 'Trop de tentatives. Connexion bloquée pendant 60 secondes.';
      } else {
        _errorCode = e.code;
        _error = e.message;
      }
      return false;
    } catch (e) {
      _error = 'Connexion impossible : $e';
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
    UserRole role = UserRole.user,
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
        role: role,
        address: address,
        latitude: latitude,
        longitude: longitude,
      );
      _error = null;
      _errorCode = null;
      return true;
    } on AuthException catch (e) {
      _error = e.message;
      _errorCode = e.code;
      return false;
    } catch (e) {
      _error = 'Inscription impossible : $e';
      return false;
    } finally {
      _setBusy(false);
    }
  }

  /// Vérifie l'étape 1 de l'inscription : e-mail et téléphone déjà pris ?
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

  /// Équipe : vérifie qu'un compte existe pour [email].
  Future<bool> sendResetLink(String email) async {
    _setBusy(true);
    try {
      await _repository.sendResetLink(email);
      _error = null;
      return true;
    } on AuthException catch (e) {
      _error = e.message;
      _errorCode = e.code;
      return false;
    } catch (_) {
      _error = 'Demande impossible.';
      return false;
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
      await _saveLock(null);
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

  /// Sauvegarde le profil. Retourne `false` si l'e-mail ou le téléphone
  /// appartient déjà à un autre compte ([error] renseigné).
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

    // Préférences liées au compte + blocage.
    try {
      await _session.clearForDeletedAccount(current.id);
    } catch (_) {}
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

  /// Déconnexion : efface la session et la session Google.
  Future<void> logout() async {
    _user = null;
    _error = null;
    _errorCode = null;
    _googleError = null;
    notifyListeners();
    await _repository.clearSession();
    await _repository.signOutGoogle();
  }

  void clearError() {
    if (_error == null && _errorCode == null) return;
    _error = null;
    _errorCode = null;
    notifyListeners();
  }

  Future<void> _saveLock(DateTime? until) async {
    try {
      await _session.saveLockedUntil(until);
    } catch (_) {}
  }

  void _setBusy(bool value) {
    _busy = value;
    notifyListeners();
  }
}
