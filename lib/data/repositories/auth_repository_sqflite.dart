import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../local/app_database.dart';
import '../local/database_constants.dart';
import '../models/user_profile.dart';
import '../models/user_role.dart';
import '../services/google_auth_service.dart';
import 'auth_password.dart';
import 'auth_repository.dart';

/// Auth via table [users] (sqflite).
/// Session aussi en sqflite (évite le crash SharedPreferences release Android).
class SqfliteAuthRepository implements AuthRepository {
  SqfliteAuthRepository({GoogleAuthService? google})
    : _google = google ?? const GoogleAuthService();

  static const _sessionTable = 'auth_session';
  static const defaultAdminEmail = 'admin@rentcar.tn';
  static const defaultAdminPassword = 'admin123';

  final GoogleAuthService _google;

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

  // ---------------------------------------------------------------------------
  // Lignes ↔ UserProfile (colonnes de l'équipe + module User)
  // ---------------------------------------------------------------------------

  UserProfile _fromRow(Map<String, Object?> row) {
    return UserProfile(
      id: (row['id'] ?? '').toString(),
      firstName: (row['first_name'] ?? '').toString(),
      lastName: (row['last_name'] ?? '').toString(),
      email: (row['email'] ?? '').toString(),
      phone: (row['phone'] as String?) ?? '',
      role: UserRoleX.fromId(row['role']?.toString()),
      city: (row['city'] as String?) ?? 'Tunis',
      publicUsername: (row['public_username'] as String?) ?? 'Utilisateur_TN',
      memberSince: _date(row['member_since']) ?? DateTime.now(),
      cin: (row['cin'] as String?) ?? '',
      licenceNumber: (row['licence_number'] as String?) ?? '',
      address: (row['address'] as String?) ?? '',
      birthDate: _date(row['birth_date']),
      avatarUrl: row['avatar_url'] as String?,
      latitude: (row['latitude'] as num?)?.toDouble(),
      longitude: (row['longitude'] as num?)?.toDouble(),
      licenceExpiry: _date(row['licence_expiry']),
      trustScore: (row['trust_score'] as num?)?.toInt() ?? 50,
      emailVerified: (row['email_verified'] as num?) == 1,
    );
  }

  /// Colonnes du profil (sans mot de passe ni dates techniques).
  Map<String, Object?> _toRow(UserProfile u) => {
    'id': u.id,
    'first_name': u.firstName,
    'last_name': u.lastName,
    'email': u.email.trim().toLowerCase(),
    'phone': u.phone,
    'role': u.role.name,
    'city': u.city,
    'public_username': u.publicUsername,
    'cin': u.cin,
    'licence_number': u.licenceNumber,
    'address': u.address,
    'birth_date': u.birthDate?.toIso8601String(),
    'avatar_url': u.avatarUrl,
    'latitude': u.latitude,
    'longitude': u.longitude,
    'licence_expiry': u.licenceExpiry?.toIso8601String(),
    'trust_score': u.trustScore,
    'email_verified': u.emailVerified ? 1 : 0,
  };

  static DateTime? _date(Object? value) =>
      value is String && value.isNotEmpty ? DateTime.tryParse(value) : null;

  static String _digits(String phone) => phone.replaceAll(RegExp(r'\s'), '');

  Future<Map<String, Object?>?> _rowByEmail(String email) async {
    final rows = await (await _db).query(
      DatabaseConstants.users,
      where: 'email = ?',
      whereArgs: [email.trim().toLowerCase()],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }

  Future<Map<String, Object?>?> _rowById(String id) async {
    final rows = await (await _db).query(
      DatabaseConstants.users,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }

  /// Téléphone vide (comptes Google) → aucun résultat.
  Future<Map<String, Object?>?> _rowByPhone(String phone) async {
    final digits = _digits(phone);
    if (digits.isEmpty) return null;
    final rows = await (await _db).query(
      DatabaseConstants.users,
      where: "REPLACE(phone, ' ', '') = ?",
      whereArgs: [digits],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }

  Future<void> _insert(UserProfile user, {required String passwordHash}) async {
    final now = DateTime.now().toIso8601String();
    await (await _db).insert(DatabaseConstants.users, {
      ..._toRow(user),
      'password_hash': passwordHash,
      'member_since': (user.memberSince ?? DateTime.now()).toIso8601String(),
      'created_at': now,
      'updated_at': now,
    }, conflictAlgorithm: ConflictAlgorithm.abort);
  }

  Future<void> _updatePassword(String userId, String hash) async {
    await (await _db).update(
      DatabaseConstants.users,
      {'password_hash': hash, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [userId],
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

  // ---------------------------------------------------------------------------
  // Équipe : admin, connexion, inscription, session
  // ---------------------------------------------------------------------------

  @override
  Future<void> ensureDefaultAdmin() async {
    await _withDbRepair(() async {
      final db = await _db;
      final now = DateTime.now().toIso8601String();
      // Garantit admin@rentcar.tn / admin123 à chaque démarrage, sans
      // supprimer la ligne (un REPLACE déclencherait les ON DELETE CASCADE
      // des réclamations et effacerait le profil de l'admin).
      await db.insert(DatabaseConstants.users, {
        'id': 'usr-admin',
        'first_name': 'Admin',
        'last_name': 'RentCar',
        'email': defaultAdminEmail,
        'phone': '20 000 000',
        'password_hash': hashPassword(defaultAdminPassword),
        'role': UserRole.admin.name,
        'city': 'Tunis',
        'public_username': 'Admin_TN',
        'email_verified': 1,
        'member_since': now,
        'created_at': now,
        'updated_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
      await db.update(
        DatabaseConstants.users,
        {
          'password_hash': hashPassword(defaultAdminPassword),
          'role': UserRole.admin.name,
          'email_verified': 1,
        },
        where: 'email = ?',
        whereArgs: [defaultAdminEmail],
      );
    });
  }

  @override
  Future<UserProfile> login(String email, String password) async {
    return _withDbRepair(() async {
      await ensureDefaultAdmin();
      final row = await _rowByEmail(email);
      if (row == null) throw AuthException.accountNotFound;
      final id = (row['id'] ?? '').toString();
      final stored = row['password_hash'] as String?;
      if (!verifyPassword(userId: id, password: password, stored: stored)) {
        throw AuthException.wrongPassword;
      }
      // Ancien format (branche module-user) : ré-enregistré au format actuel.
      if (isLegacyHash(stored!, password)) {
        await _updatePassword(id, hashPassword(password));
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
    String address = '',
    double? latitude,
    double? longitude,
  }) async {
    return _withDbRepair(() async {
      await ensureDefaultAdmin();
      if (role == UserRole.admin) {
        throw const AuthException(
          'Le compte administrateur ne peut pas être créé ici.',
        );
      }
      if (await _rowByEmail(email) != null) throw AuthException.emailTaken;
      if (await _rowByPhone(phone) != null) throw AuthException.phoneTaken;

      final now = DateTime.now();
      final first = firstName.trim();
      final user = UserProfile(
        id: 'usr-${now.millisecondsSinceEpoch}',
        firstName: first,
        lastName: lastName.trim(),
        email: email.trim().toLowerCase(),
        phone: phone.trim(),
        role: role,
        city: city,
        address: address.trim(),
        latitude: latitude,
        longitude: longitude,
        memberSince: now,
        publicUsername: first.isEmpty ? 'Utilisateur_TN' : '${first}_TN',
      );
      await _insert(user, passwordHash: hashPassword(password));
      await saveSession(user.id);
      return user;
    });
  }

  @override
  Future<UserProfile?> byId(String id) async {
    try {
      final row = await _rowById(id);
      return row == null ? null : _fromRow(row);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> sendResetLink(String email) async {
    if (await _rowByEmail(email) == null) throw AuthException.accountNotFound;
  }

  @override
  Future<void> saveSession(String userId) async {
    final db = await _db;
    await _ensureSessionTable(db);
    await db.insert(_sessionTable, {
      'id': 1,
      'user_id': userId,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
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

  // ---------------------------------------------------------------------------
  // Module User
  // ---------------------------------------------------------------------------

  @override
  Future<UserProfile?> signInWithGoogle() async {
    final google = await _google.signIn();
    if (google == null) return null;

    return _withDbRepair(() async {
      final existing = await _rowByEmail(google.email);
      if (existing != null) {
        var user = _fromRow(existing);
        // Google a prouvé que l'adresse appartient à l'utilisateur.
        final needsUpdate =
            !user.emailVerified ||
            ((user.avatarUrl ?? '').isEmpty && google.photoUrl != null);
        if (needsUpdate) {
          user = user.copyWith(
            emailVerified: true,
            avatarUrl: (user.avatarUrl ?? '').isEmpty ? google.photoUrl : null,
          );
          await updateProfile(user);
        }
        await saveSession(user.id);
        return user;
      }

      final user = UserProfile(
        id: 'usr-${DateTime.now().millisecondsSinceEpoch}',
        firstName: google.firstName,
        lastName: google.lastName,
        email: google.email,
        phone: '',
        city: 'Tunis',
        avatarUrl: google.photoUrl,
        emailVerified: true,
        memberSince: DateTime.now(),
        publicUsername: '${google.firstName}_TN',
      );
      // Pas de mot de passe local (« Mot de passe oublié » permet d'en
      // définir un) : hash vide, la colonne étant NOT NULL.
      await _insert(user, passwordHash: '');
      await saveSession(user.id);
      return user;
    });
  }

  @override
  Future<void> signOutGoogle() => _google.signOut();

  @override
  Future<bool> hasPassword(UserProfile user) async {
    final row = await _rowById(user.id);
    return ((row?['password_hash'] as String?) ?? '').isNotEmpty;
  }

  @override
  Future<void> deleteAccount(UserProfile user, {String? password}) async {
    final row = await _rowById(user.id);
    if (row == null) throw AuthException.deleteFailed;

    final stored = (row['password_hash'] as String?) ?? '';
    final isGoogleAccount = stored.isEmpty;
    if (!isGoogleAccount &&
        !verifyPassword(
          userId: user.id,
          password: password ?? '',
          stored: stored,
        )) {
      throw AuthException.wrongCurrentPassword;
    }

    try {
      final deleted = await (await _db).delete(
        DatabaseConstants.users,
        where: 'id = ?',
        whereArgs: [user.id],
      );
      if (deleted == 0) throw AuthException.deleteFailed;
    } on AuthException {
      rethrow;
    } catch (e) {
      // Ex. contrainte de clé étrangère (réservations liées en BD).
      debugPrint('[Auth] Suppression du compte échouée : $e');
      throw AuthException.deleteFailed;
    }

    await clearSession();
    if (isGoogleAccount) await _google.disconnect();
  }

  @override
  Future<bool> isEmailTaken(String email) async =>
      await _rowByEmail(email) != null;

  @override
  Future<bool> isPhoneTaken(String phone) async =>
      await _rowByPhone(phone) != null;

  @override
  Future<UserProfile> updateProfile(UserProfile user) async {
    final byEmail = await _rowByEmail(user.email);
    if (byEmail != null && byEmail['id'] != user.id) {
      throw AuthException.emailTaken;
    }
    final byPhone = await _rowByPhone(user.phone);
    if (byPhone != null && byPhone['id'] != user.id) {
      throw AuthException.phoneTaken;
    }
    await (await _db).update(
      DatabaseConstants.users,
      {..._toRow(user), 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [user.id],
    );
    return user;
  }

  @override
  Future<void> changePassword({
    required UserProfile user,
    required String currentPassword,
    required String newPassword,
  }) async {
    final row = await _rowById(user.id);
    if (row == null ||
        !verifyPassword(
          userId: user.id,
          password: currentPassword,
          stored: row['password_hash'] as String?,
        )) {
      throw AuthException.wrongCurrentPassword;
    }
    await _updatePassword(user.id, hashPassword(newPassword));
  }

  @override
  Future<UserProfile> findAccountForReset({String? email, String? phone}) {
    return _withDbRepair(() async {
      await ensureDefaultAdmin();
      final row = email != null
          ? await _rowByEmail(email)
          : await _rowByPhone(phone ?? '');
      if (row == null) throw AuthException.accountNotFound;
      return _fromRow(row);
    });
  }

  @override
  Future<void> resetPassword(UserProfile user, String newPassword) =>
      _updatePassword(user.id, hashPassword(newPassword));
}
