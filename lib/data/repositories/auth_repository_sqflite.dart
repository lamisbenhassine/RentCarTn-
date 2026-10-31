import 'package:sqflite/sqflite.dart';

import '../local/app_database.dart';
import '../local/database_constants.dart';
import '../models/user_profile.dart';
import '../models/user_role.dart';
import 'auth_password.dart';
import 'auth_repository.dart';

/// Auth via table [users] (sqflite).
/// Session aussi en sqflite (évite le crash SharedPreferences release Android).
class SqfliteAuthRepository implements AuthRepository {
  static const _sessionTable = 'auth_session';
  static const defaultAdminEmail = 'admin@rentcar.tn';
  static const defaultAdminPassword = 'admin123';

  Future<Database> get _db async =>
      await AppDatabase.instance.database as Database;

  Future<void> _ensureSessionTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_sessionTable (
        id INTEGER PRIMARY KEY NOT NULL CHECK (id = 1),
        user_id TEXT NOT NULL
      )
    ''');
  }

  UserProfile _fromRow(Map<String, Object?> row) {
    return UserProfile(
      id: (row['id'] ?? '').toString(),
      firstName: (row['first_name'] ?? '').toString(),
      lastName: (row['last_name'] ?? '').toString(),
      email: (row['email'] ?? '').toString(),
      phone: (row['phone'] as String?) ?? '',
      role: UserRoleX.fromId(row['role']?.toString()),
      city: (row['city'] as String?) ?? 'Tunis',
      publicUsername:
          (row['public_username'] as String?) ?? 'Utilisateur_TN',
      memberSince: DateTime.tryParse((row['member_since'] as String?) ?? '') ??
          DateTime.now(),
    );
  }

  Future<T> _withDbRepair<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on DatabaseException catch (e) {
      // Schéma cassé / table manquante → reset une fois puis réessaie.
      try {
        await AppDatabase.instance.reset();
        return await action();
      } catch (_) {
        throw AuthException('Base locale inaccessible : $e');
      }
    }
  }

  @override
  Future<void> ensureDefaultAdmin() async {
    await _withDbRepair(() async {
      final db = await _db;
      final now = DateTime.now().toIso8601String();
      // Upsert : garantit admin@rentcar.tn / admin123 sur chaque démarrage APK.
      await db.insert(
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
          'member_since': now,
          'created_at': now,
          'updated_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  @override
  Future<UserProfile> login(String email, String password) async {
    return _withDbRepair(() async {
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
      final stored = (row['password_hash'] ?? '').toString();
      if (stored.isEmpty || stored != hashPassword(password)) {
        throw const AuthException('Mot de passe incorrect.');
      }
      final user = _fromRow(row);
      await saveSession(user.id);
      return user;
    });
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
    return _withDbRepair(() async {
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
      final stamp = now.toIso8601String();

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
          'member_since': stamp,
          'created_at': stamp,
          'updated_at': stamp,
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
    });
  }

  @override
  Future<UserProfile?> byId(String id) async {
    try {
      final rows = await (await _db).query(
        DatabaseConstants.users,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (rows.isEmpty) return null;
      return _fromRow(rows.first);
    } catch (_) {
      return null;
    }
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
    final db = await _db;
    await _ensureSessionTable(db);
    await db.insert(
      _sessionTable,
      {'id': 1, 'user_id': userId},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<String?> readSessionUserId() async {
    final db = await _db;
    await _ensureSessionTable(db);
    final rows = await db.query(_sessionTable, where: 'id = 1', limit: 1);
    if (rows.isEmpty) return null;
    return rows.first['user_id']?.toString();
  }

  @override
  Future<void> clearSession() async {
    final db = await _db;
    await _ensureSessionTable(db);
    await db.delete(_sessionTable);
  }
}
