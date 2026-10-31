import 'package:flutter/foundation.dart';

import '../data/models/user_profile.dart';
import '../data/models/user_role.dart';
import '../data/repositories/auth_repository.dart';

/// Session utilisateur (sqflite sur téléphone, prefs sur web).
class AuthProvider extends ChangeNotifier {
  AuthProvider({AuthRepository? repository})
      : _repository = repository ?? AuthRepositoryFactory.create();

  final AuthRepository _repository;

  UserProfile? _user;
  bool _busy = false;
  bool _restoring = true;
  String? _error;

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

  /// Pseudonyme utilisé dans les enchères publiques.
  String get publicUsername => _user?.publicUsername ?? 'Vous';

  Future<void> restoreSession() async {
    _restoring = true;
    notifyListeners();
    try {
      await _repository.ensureDefaultAdmin();
      final id = await _repository.readSessionUserId();
      if (id != null) {
        _user = await _repository.byId(id);
        if (_user == null) {
          await _repository.clearSession();
        }
      }
    } catch (_) {
      _user = null;
    } finally {
      _restoring = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _setBusy(true);
    try {
      _user = await _repository.login(email, password);
      _error = null;
      return true;
    } on AuthException catch (e) {
      _error = e.message;
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
      );
      _error = null;
      return true;
    } on AuthException catch (e) {
      _error = e.message;
      return false;
    } catch (e) {
      _error = 'Inscription impossible : $e';
      return false;
    } finally {
      _setBusy(false);
    }
  }

  Future<bool> sendResetLink(String email) async {
    _setBusy(true);
    try {
      await _repository.sendResetLink(email);
      _error = null;
      return true;
    } on AuthException catch (e) {
      _error = e.message;
      return false;
    } catch (_) {
      _error = 'Demande impossible.';
      return false;
    } finally {
      _setBusy(false);
    }
  }

  void updateProfile(UserProfile updated) {
    _user = updated;
    notifyListeners();
  }

  Future<void> logout() async {
    _user = null;
    _error = null;
    await _repository.clearSession();
    notifyListeners();
  }

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  void _setBusy(bool value) {
    _busy = value;
    notifyListeners();
  }
}
