import 'package:sqflite/sqflite.dart';

import '../models/user_profile.dart';
import 'app_database.dart';
import 'database_constants.dart';

/// Ligne `users` : le profil + le hash du mot de passe (jamais exposé à l'UI).
class UserRecord {
  const UserRecord({required this.profile, required this.passwordHash});

  final UserProfile profile;
  final String? passwordHash;
}

/// Accès sqflite à la table `users` (mobile uniquement).
class UserDao {
  const UserDao();

  Future<Database> get _db async =>
      await AppDatabase.instance.database as Database;

  Future<UserRecord?> findByEmail(String email) async {
    final db = await _db;
    final rows = await db.query(
      DatabaseConstants.users,
      where: 'email = ?',
      whereArgs: [email.trim().toLowerCase()],
      limit: 1,
    );
    return rows.isEmpty ? null : _fromRow(rows.first);
  }

  Future<UserRecord?> findById(String id) async {
    final db = await _db;
    final rows = await db.query(
      DatabaseConstants.users,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : _fromRow(rows.first);
  }

  /// Recherche par téléphone en ignorant les espaces ("22 345 678" = "22345678").
  /// Téléphone vide (comptes Google) → aucun résultat : sinon tous les
  /// comptes sans numéro se « partageraient » le même téléphone.
  Future<UserRecord?> findByPhone(String phone) async {
    if (_digits(phone).isEmpty) return null;
    final db = await _db;
    final rows = await db.query(
      DatabaseConstants.users,
      where: "REPLACE(phone, ' ', '') = ?",
      whereArgs: [_digits(phone)],
      limit: 1,
    );
    return rows.isEmpty ? null : _fromRow(rows.first);
  }

  /// [passwordHash] `null` pour un compte créé via Google (pas de mot de
  /// passe local ; « Mot de passe oublié » permet d'en définir un).
  Future<void> insert(UserProfile user, {required String? passwordHash}) async {
    final db = await _db;
    final now = DateTime.now().toIso8601String();
    await db.insert(DatabaseConstants.users, {
      ..._toRow(user),
      'password_hash': passwordHash,
      'member_since': (user.memberSince ?? DateTime.now()).toIso8601String(),
      'created_at': now,
      'updated_at': now,
    }, conflictAlgorithm: ConflictAlgorithm.abort);
  }

  /// Met à jour le profil (le mot de passe n'est pas touché).
  Future<void> update(UserProfile user) async {
    final db = await _db;
    await db.update(
      DatabaseConstants.users,
      {..._toRow(user), 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<void> updatePassword(String userId, String passwordHash) async {
    final db = await _db;
    await db.update(
      DatabaseConstants.users,
      {
        'password_hash': passwordHash,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  /// Supprime le compte. Retourne le nombre de lignes supprimées (0 ou 1).
  Future<int> delete(String userId) async {
    final db = await _db;
    return db.delete(
      DatabaseConstants.users,
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  // ---------------------------------------------------------------------------

  Map<String, Object?> _toRow(UserProfile u) => {
    'id': u.id,
    'first_name': u.firstName,
    'last_name': u.lastName,
    'email': u.email.trim().toLowerCase(),
    'phone': u.phone,
    'cin': u.cin,
    'licence_number': u.licenceNumber,
    'city': u.city,
    'address': u.address,
    'birth_date': u.birthDate?.toIso8601String(),
    'avatar_url': u.avatarUrl,
    'public_username': u.publicUsername,
    'latitude': u.latitude,
    'longitude': u.longitude,
    'licence_expiry': u.licenceExpiry?.toIso8601String(),
    'trust_score': u.trustScore,
    'email_verified': u.emailVerified ? 1 : 0,
  };

  UserRecord _fromRow(Map<String, Object?> r) {
    return UserRecord(
      passwordHash: r['password_hash'] as String?,
      profile: UserProfile(
        id: r['id']! as String,
        firstName: r['first_name']! as String,
        lastName: r['last_name']! as String,
        email: r['email']! as String,
        phone: (r['phone'] as String?) ?? '',
        cin: (r['cin'] as String?) ?? '',
        licenceNumber: (r['licence_number'] as String?) ?? '',
        city: (r['city'] as String?) ?? 'Tunis',
        address: (r['address'] as String?) ?? '',
        birthDate: _date(r['birth_date']),
        avatarUrl: r['avatar_url'] as String?,
        memberSince: _date(r['member_since']),
        publicUsername: (r['public_username'] as String?) ?? 'Utilisateur_TN',
        latitude: (r['latitude'] as num?)?.toDouble(),
        longitude: (r['longitude'] as num?)?.toDouble(),
        licenceExpiry: _date(r['licence_expiry']),
        trustScore: (r['trust_score'] as num?)?.toInt() ?? 50,
        emailVerified: (r['email_verified'] as num?) == 1,
      ),
    );
  }

  static DateTime? _date(Object? value) =>
      value is String && value.isNotEmpty ? DateTime.tryParse(value) : null;

  static String _digits(String phone) => phone.replaceAll(RegExp(r'\s'), '');
}
