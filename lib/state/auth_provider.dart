import 'package:flutter/foundation.dart';

import '../data/models/user_profile.dart';
import '../data/repositories/auth_repository.dart';

/// Session utilisateur maintenue uniquement en mémoire (démo frontend).
class AuthProvider extends ChangeNotifier {
  AuthProvider({AuthRepository? repository})
    : _repository = repository ?? const AuthRepository();

  final AuthRepository _repository;

  UserProfile? _user;
  bool _busy = false;
  String? _error;

  UserProfile? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get busy => _busy;
  String? get error => _error;

  /// Pseudonyme utilisé dans les enchères publiques.
  String get publicUsername => _user?.publicUsername ?? 'Vous';

  Future<bool> login(String email, String password) async {
    _setBusy(true);
    try {
      _user = await _repository.login(email, password);
      _error = null;
      return true;
    } on AuthException catch (e) {
      _error = e.message;
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
      );
      _error = null;
      return true;
    } on AuthException catch (e) {
      _error = e.message;
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
    } finally {
      _setBusy(false);
    }
  }

  void updateProfile(UserProfile updated) {
    _user = updated;
    notifyListeners();
  }

  void logout() {
    _user = null;
    _error = null;
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
