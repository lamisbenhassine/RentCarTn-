import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_profile.dart';
import '../models/user_role.dart';
import 'auth_password.dart';
import 'auth_repository.dart';

/// Auth web (Chrome) via shared_preferences — sqflite indisponible.
class PrefsAuthRepository implements AuthRepository {
  static const _usersKey = 'auth_users_v1';
  static const _sessionKey = 'auth_session_user_id';
  static const defaultAdminEmail = 'admin@rentcar.tn';
  static const defaultAdminPassword = 'admin123';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<Map<String, Map<String, Object?>>> _loadUsers() async {
    final raw = (await _prefs).getString(_usersKey);
    if (raw == null || raw.isEmpty) return {};
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return {
      for (final e in decoded.entries)
        e.key: Map<String, Object?>.from(e.value as Map),
    };
  }

  Future<void> _saveUsers(Map<String, Map<String, Object?>> users) async {
    await (await _prefs).setString(_usersKey, jsonEncode(users));
  }

  UserProfile _fromMap(Map<String, Object?> map) {
    return UserProfile(
      id: map['id']! as String,
      firstName: map['firstName']! as String,
      lastName: map['lastName']! as String,
      email: map['email']! as String,
      phone: (map['phone'] as String?) ?? '',
      role: UserRoleX.fromId(map['role'] as String?),
      city: (map['city'] as String?) ?? 'Tunis',
      publicUsername: (map['publicUsername'] as String?) ?? 'Utilisateur_TN',
      memberSince: DateTime.tryParse((map['memberSince'] as String?) ?? '') ??
          DateTime.now(),
    );
  }

  @override
  Future<void> ensureDefaultAdmin() async {
    final users = await _loadUsers();
    final hasAdmin = users.values.any(
      (u) => (u['role'] as String?) == UserRole.admin.name,
    );
    if (hasAdmin) return;

    final now = DateTime.now();
    users[defaultAdminEmail] = {
      'id': 'usr-admin',
      'firstName': 'Admin',
      'lastName': 'RentCar',
      'email': defaultAdminEmail,
      'phone': '20 000 000',
      'passwordHash': hashPassword(defaultAdminPassword),
      'role': UserRole.admin.name,
      'city': 'Tunis',
      'publicUsername': 'Admin_TN',
      'memberSince': now.toIso8601String(),
    };
    await _saveUsers(users);
  }

  @override
  Future<UserProfile> login(String email, String password) async {
    await ensureDefaultAdmin();
    final normalized = email.trim().toLowerCase();
    final users = await _loadUsers();
    final row = users[normalized];
    if (row == null) {
      throw const AuthException('Aucun compte ne correspond à cet e-mail.');
    }
    if ((row['passwordHash'] as String?) != hashPassword(password)) {
      throw const AuthException('Mot de passe incorrect.');
    }
    final user = _fromMap(row);
    await saveSession(user.id);
    return user;
  }

  @override
  Future<UserProfile> register({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
    String city = 'Tunis',
    UserRole role = UserRole.user,
  }) async {
    await ensureDefaultAdmin();
    if (role == UserRole.admin) {
      throw const AuthException(
        'Le compte administrateur ne peut pas être créé ici.',
      );
    }

    final normalized = email.trim().toLowerCase();
    final users = await _loadUsers();
    if (users.containsKey(normalized)) {
      throw const AuthException('Un compte existe déjà avec cet e-mail.');
    }

    final now = DateTime.now();
    final id = 'usr-${now.millisecondsSinceEpoch}';
    final first = firstName.trim();
    final last = lastName.trim();
    final username = first.isEmpty ? 'Utilisateur_TN' : '${first}_TN';

    final row = <String, Object?>{
      'id': id,
      'firstName': first,
      'lastName': last,
      'email': normalized,
      'phone': phone.trim(),
      'passwordHash': hashPassword(password),
      'role': role.name,
      'city': city,
      'publicUsername': username,
      'memberSince': now.toIso8601String(),
    };
    users[normalized] = row;
    await _saveUsers(users);

    final user = _fromMap(row);
    await saveSession(user.id);
    return user;
  }

  @override
  Future<UserProfile?> byId(String id) async {
    final users = await _loadUsers();
    for (final row in users.values) {
      if (row['id'] == id) return _fromMap(row);
    }
    return null;
  }

  @override
  Future<void> sendResetLink(String email) async {
    final normalized = email.trim().toLowerCase();
    final users = await _loadUsers();
    if (!users.containsKey(normalized)) {
      throw const AuthException('Aucun compte ne correspond à cet e-mail.');
    }
  }

  @override
  Future<void> saveSession(String userId) async {
    await (await _prefs).setString(_sessionKey, userId);
  }

  @override
  Future<String?> readSessionUserId() async {
    return (await _prefs).getString(_sessionKey);
  }

  @override
  Future<void> clearSession() async {
    await (await _prefs).remove(_sessionKey);
  }
}
