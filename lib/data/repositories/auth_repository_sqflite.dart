import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../local/app_database.dart';
import '../local/database_constants.dart';
import '../models/user_profile.dart';
import '../models/user_role.dart';
import 'auth_password.dart';
import 'auth_repository.dart';

/// Auth via table [users] (sqflite).
class SqfliteAuthRepository implements AuthRepository {
  static const _sessionKey = 'auth_session_user_id';
  static const defaultAdminEmail = 'admin@rentcar.tn';
  static const defaultAdminPassword = 'admin123';

  Future<Database> get _db async =>
      await AppDatabase.instance.database as Database;

  UserProfile _fromRow(Map<String, Object?> row) {
    return UserProfile(
      id: row['id']! as String,
      firstName: row['first_name']! as String,
      lastName: row['last_name']! as String,
      email: row['email']! as String,
      phone: (row['phone'] as String?) ?? '',
      role: UserRoleX.fromId(row['role'] as String?),
      city: (row['city'] as String?) ?? 'Tunis',
      publicUsername:
          (row['public_username'] as String?) ?? 'Utilisateur_TN',
      memberSince: DateTime.tryParse((row['member_since'] as String?) ?? '') ??
          DateTime.now(),
    );
  }

  @override
  Future<void> ensureDefaultAdmin() async {
    final rows = await (await _db).query(
      DatabaseConstants.users,
      columns: ['id'],
      where: 'role = ?',
      whereArgs: [UserRole.admin.name],
      limit: 1,
    );
    if (rows.isNotEmpty) return;

    final now = DateTime.now();
    await (await _db).insert(
      DatabaseConstants.users,
      {
        'id': 'usr-admin',
        'first_name': 'Admin',
        'last_name': 'RentCar',
        'email': defaultAdminEmail,
        'phone': '20 000 000',
        'password_hash': hashPassword(defaultAdminPassword),
        'role': UserRole.admin.name,
        'city': 'Tunis',
        'public_username': 'Admin_TN',
        'member_since': now.toIso8601String(),
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  @override
  Future<UserProfile> login(String email, String password) async {
    await ensureDefaultAdmin();
    final normalized = email.trim().toLowerCase();
    final rows = await (await _db).query(
      DatabaseConstants.users,
      where: 'email = ?',
      whereArgs: [normalized],
      limit: 1,
    );
    if (rows.isEmpty) {
      throw const AuthException('Aucun compte ne correspond à cet e-mail.');
    }
    final row = rows.first;
    final stored = row['password_hash'] as String? ?? '';
    if (stored != hashPassword(password)) {
      throw const AuthException('Mot de passe incorrect.');
    }
    final user = _fromRow(row);
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
    final existing = await (await _db).query(
      DatabaseConstants.users,
      columns: ['id'],
      where: 'email = ?',
      whereArgs: [normalized],
      limit: 1,
    );
    if (existing.isNotEmpty) {
      throw const AuthException('Un compte existe déjà avec cet e-mail.');
    }

    final now = DateTime.now();
    final id = 'usr-${now.millisecondsSinceEpoch}';
    final first = firstName.trim();
    final last = lastName.trim();
    final username = first.isEmpty ? 'Utilisateur_TN' : '${first}_TN';

    await (await _db).insert(
      DatabaseConstants.users,
      {
        'id': id,
        'first_name': first,
        'last_name': last,
        'email': normalized,
        'phone': phone.trim(),
        'password_hash': hashPassword(password),
        'role': role.name,
        'city': city,
        'public_username': username,
        'member_since': now.toIso8601String(),
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.abort,
    );

    final user = UserProfile(
      id: id,
      firstName: first,
      lastName: last,
      email: normalized,
      phone: phone.trim(),
      role: role,
      city: city,
      memberSince: now,
      publicUsername: username,
    );
    await saveSession(user.id);
    return user;
  }

  @override
  Future<UserProfile?> byId(String id) async {
    final rows = await (await _db).query(
      DatabaseConstants.users,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _fromRow(rows.first);
  }

  @override
  Future<void> sendResetLink(String email) async {
    final normalized = email.trim().toLowerCase();
    final rows = await (await _db).query(
      DatabaseConstants.users,
      columns: ['id'],
      where: 'email = ?',
      whereArgs: [normalized],
      limit: 1,
    );
    if (rows.isEmpty) {
      throw const AuthException('Aucun compte ne correspond à cet e-mail.');
    }
  }

  @override
  Future<void> saveSession(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, userId);
  }

  @override
  Future<String?> readSessionUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_sessionKey);
  }

  @override
  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
  }
}
