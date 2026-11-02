import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/ban_record.dart';
import '../models/user_profile.dart';
import '../models/user_role.dart';
import '../services/google_auth_service.dart';
import 'auth_password.dart';
import 'auth_repository.dart';

/// Auth web (Chrome) via shared_preferences — sqflite indisponible.
class PrefsAuthRepository implements AuthRepository {
  PrefsAuthRepository({GoogleAuthService? google})
    : _google = google ?? const GoogleAuthService();

  static const _usersKey = 'auth_users_v1';
  static const _sessionKey = 'auth_session_user_id';
  static const _banHistoryKey = 'auth_ban_history_v1';

  /// Champs du bannissement : jamais écrasés par updateProfile.
  static const _banKeys = [
    'bannedUntil',
    'banPermanent',
    'banReason',
    'bannedBy',
  ];
  static const defaultAdminEmail = 'admin@rentcar.tn';
  static const defaultAdminPassword = 'admin123';

  final GoogleAuthService _google;

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  /// Comptes indexés par e-mail.
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
    DateTime? date(Object? v) =>
        v is String && v.isNotEmpty ? DateTime.tryParse(v) : null;
    return UserProfile(
      id: map['id']! as String,
      firstName: map['firstName']! as String,
      lastName: map['lastName']! as String,
      email: map['email']! as String,
      phone: (map['phone'] as String?) ?? '',
      role: UserRoleX.fromId(map['role'] as String?),
      city: (map['city'] as String?) ?? 'Tunis',
      publicUsername: (map['publicUsername'] as String?) ?? 'Utilisateur_TN',
      memberSince: date(map['memberSince']) ?? DateTime.now(),
      cin: (map['cin'] as String?) ?? '',
      licenceNumber: (map['licenceNumber'] as String?) ?? '',
      address: (map['address'] as String?) ?? '',
      birthDate: date(map['birthDate']),
      avatarUrl: map['avatarUrl'] as String?,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      licenceExpiry: date(map['licenceExpiry']),
      trustScore: (map['trustScore'] as num?)?.toInt() ?? 50,
      emailVerified: map['emailVerified'] == true,
      bannedUntil: date(map['bannedUntil']),
      banPermanent: map['banPermanent'] == true,
      banReason: map['banReason'] as String?,
      bannedBy: map['bannedBy'] as String?,
    );
  }

  /// Profil → map (le hash du mot de passe est conservé à part).
  Map<String, Object?> _toMap(UserProfile u, {required String passwordHash}) =>
      {
        'id': u.id,
        'firstName': u.firstName,
        'lastName': u.lastName,
        'email': u.email.trim().toLowerCase(),
        'phone': u.phone,
        'passwordHash': passwordHash,
        'role': u.role.name,
        'city': u.city,
        'publicUsername': u.publicUsername,
        'memberSince': (u.memberSince ?? DateTime.now()).toIso8601String(),
        'cin': u.cin,
        'licenceNumber': u.licenceNumber,
        'address': u.address,
        'birthDate': u.birthDate?.toIso8601String(),
        'avatarUrl': u.avatarUrl,
        'latitude': u.latitude,
        'longitude': u.longitude,
        'licenceExpiry': u.licenceExpiry?.toIso8601String(),
        'trustScore': u.trustScore,
        'emailVerified': u.emailVerified,
      };

  static String _digits(String v) => v.replaceAll(RegExp(r'\D'), '');

  Map<String, Object?>? _byPhone(
    Map<String, Map<String, Object?>> users,
    String phone,
  ) {
    final digits = _digits(phone);
    if (digits.isEmpty) return null;
    for (final row in users.values) {
      if (_digits((row['phone'] as String?) ?? '') == digits) return row;
    }
    return null;
  }

  Map<String, Object?>? _byId(
    Map<String, Map<String, Object?>> users,
    String id,
  ) {
    for (final row in users.values) {
      if (row['id'] == id) return row;
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Équipe
  // ---------------------------------------------------------------------------

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
      'emailVerified': true,
    };
    await _saveUsers(users);
  }

  @override
  Future<UserProfile> login(String email, String password) async {
    await ensureDefaultAdmin();
    final normalized = email.trim().toLowerCase();
    final users = await _loadUsers();
    final row = users[normalized];
    if (row == null) throw AuthException.accountNotFound;
    if (!verifyPassword(
      userId: row['id']! as String,
      password: password,
      stored: row['passwordHash'] as String?,
    )) {
      throw AuthException.wrongPassword;
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
    String address = '',
    double? latitude,
    double? longitude,
  }) async {
    await ensureDefaultAdmin();
    if (role == UserRole.admin) {
      throw const AuthException(
        'Le compte administrateur ne peut pas être créé ici.',
      );
    }

    final normalized = email.trim().toLowerCase();
    final users = await _loadUsers();
    if (users.containsKey(normalized)) throw AuthException.emailTaken;
    if (_byPhone(users, phone) != null) throw AuthException.phoneTaken;

    final now = DateTime.now();
    final first = firstName.trim();
    final user = UserProfile(
      id: 'usr-${now.millisecondsSinceEpoch}',
      firstName: first,
      lastName: lastName.trim(),
      email: normalized,
      phone: phone.trim(),
      role: role,
      city: city,
      address: address.trim(),
      latitude: latitude,
      longitude: longitude,
      memberSince: now,
      publicUsername: first.isEmpty ? 'Utilisateur_TN' : '${first}_TN',
    );
    users[normalized] = _toMap(user, passwordHash: hashPassword(password));
    await _saveUsers(users);
    await saveSession(user.id);
    return user;
  }

  @override
  Future<UserProfile?> byId(String id) async {
    final row = _byId(await _loadUsers(), id);
    return row == null ? null : _fromMap(row);
  }

  @override
  Future<void> sendResetLink(String email) async {
    final users = await _loadUsers();
    if (!users.containsKey(email.trim().toLowerCase())) {
      throw AuthException.accountNotFound;
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

  // ---------------------------------------------------------------------------
  // Module User
  // ---------------------------------------------------------------------------

  @override
  Future<UserProfile?> signInWithGoogle() async {
    final google = await _google.signIn();
    if (google == null) return null;
    final users = await _loadUsers();
    final existing = users[google.email.trim().toLowerCase()];
    if (existing != null) {
      final user = _fromMap(existing).copyWith(emailVerified: true);
      await updateProfile(user);
      await saveSession(user.id);
      return user;
    }
    final user = UserProfile(
      id: 'usr-${DateTime.now().millisecondsSinceEpoch}',
      firstName: google.firstName,
      lastName: google.lastName,
      email: google.email,
      phone: '',
      avatarUrl: google.photoUrl,
      emailVerified: true,
      memberSince: DateTime.now(),
      publicUsername: '${google.firstName}_TN',
    );
    users[user.email.trim().toLowerCase()] = _toMap(user, passwordHash: '');
    await _saveUsers(users);
    await saveSession(user.id);
    return user;
  }

  @override
  Future<void> signOutGoogle() => _google.signOut();

  @override
  Future<bool> hasPassword(UserProfile user) async {
    final row = _byId(await _loadUsers(), user.id);
    return ((row?['passwordHash'] as String?) ?? '').isNotEmpty;
  }

  @override
  Future<void> deleteAccount(UserProfile user, {String? password}) async {
    final users = await _loadUsers();
    final row = _byId(users, user.id);
    if (row == null) throw AuthException.deleteFailed;
    final stored = (row['passwordHash'] as String?) ?? '';
    if (stored.isNotEmpty &&
        !verifyPassword(
          userId: user.id,
          password: password ?? '',
          stored: stored,
        )) {
      throw AuthException.wrongCurrentPassword;
    }
    users.removeWhere((_, r) => r['id'] == user.id);
    await _saveUsers(users);
    await clearSession();
    if (stored.isEmpty) await _google.disconnect();
  }

  @override
  Future<bool> isEmailTaken(String email) async =>
      (await _loadUsers()).containsKey(email.trim().toLowerCase());

  @override
  Future<bool> isPhoneTaken(String phone) async =>
      _byPhone(await _loadUsers(), phone) != null;

  @override
  Future<UserProfile> updateProfile(UserProfile user) async {
    final users = await _loadUsers();
    final current = _byId(users, user.id);
    final email = user.email.trim().toLowerCase();
    final owner = users[email];
    if (owner != null && owner['id'] != user.id) throw AuthException.emailTaken;
    final phoneOwner = _byPhone(users, user.phone);
    if (phoneOwner != null && phoneOwner['id'] != user.id) {
      throw AuthException.phoneTaken;
    }
    // L'e-mail peut changer : la clé suit.
    users.removeWhere((_, r) => r['id'] == user.id);
    users[email] = {
      ..._toMap(
        user,
        passwordHash: (current?['passwordHash'] as String?) ?? '',
      ),
      for (final k in _banKeys)
        if (current?[k] != null) k: current![k],
    };
    await _saveUsers(users);
    return user;
  }

  @override
  Future<void> changePassword({
    required UserProfile user,
    required String currentPassword,
    required String newPassword,
  }) async {
    final users = await _loadUsers();
    final row = _byId(users, user.id);
    if (row == null ||
        !verifyPassword(
          userId: user.id,
          password: currentPassword,
          stored: row['passwordHash'] as String?,
        )) {
      throw AuthException.wrongCurrentPassword;
    }
    row['passwordHash'] = hashPassword(newPassword);
    await _saveUsers(users);
  }

  @override
  Future<UserProfile> findAccountForReset({
    String? email,
    String? phone,
  }) async {
    await ensureDefaultAdmin();
    final users = await _loadUsers();
    final row = email != null
        ? users[email.trim().toLowerCase()]
        : _byPhone(users, phone ?? '');
    if (row == null) throw AuthException.accountNotFound;
    return _fromMap(row);
  }

  @override
  Future<void> resetPassword(UserProfile user, String newPassword) async {
    final users = await _loadUsers();
    final row = _byId(users, user.id);
    if (row == null) throw AuthException.accountNotFound;
    row['passwordHash'] = hashPassword(newPassword);
    await _saveUsers(users);
  }

  // ---------------------------------------------------------------------------
  // Bannissement
  // ---------------------------------------------------------------------------

  Future<List<BanRecord>> _loadBans() async {
    final raw = (await _prefs).getString(_banHistoryKey);
    if (raw == null || raw.isEmpty) return [];
    return [
      for (final e in jsonDecode(raw) as List)
        BanRecord.fromJson(Map<String, Object?>.from(e as Map)),
    ];
  }

  Future<void> _saveBans(List<BanRecord> bans) async {
    await (await _prefs).setString(
      _banHistoryKey,
      jsonEncode([for (final b in bans) b.toJson()]),
    );
  }

  /// Clôt le bannissement ouvert du compte (remplacé ou levé).
  List<BanRecord> _closeOpen(
    List<BanRecord> bans,
    String userId,
    DateTime at,
    String by,
  ) => [
    for (final b in bans)
      b.userId == userId && b.liftedAt == null
          ? b.copyWith(liftedAt: at, liftedBy: by)
          : b,
  ];

  @override
  Future<List<UserProfile>> getAllUsers() async {
    final list = (await _loadUsers()).values.map(_fromMap).toList()
      ..sort(
        (a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
      );
    return list;
  }

  @override
  Future<UserProfile> banUser(BanRecord record) async {
    final users = await _loadUsers();
    final row = _byId(users, record.userId);
    if (row == null) throw AuthException.accountNotFound;
    row
      ..['bannedUntil'] = record.end?.toIso8601String()
      ..['banPermanent'] = record.permanent
      ..['banReason'] = record.reason
      ..['bannedBy'] = record.adminName ?? record.adminId;
    final by = record.adminName ?? record.adminId;
    final bans = _closeOpen(await _loadBans(), record.userId, record.start, by)
      ..add(record);
    await _saveUsers(users);
    await _saveBans(bans);
    return _fromMap(row);
  }

  @override
  Future<UserProfile> unbanUser(
    String userId, {
    required String liftedBy,
    DateTime? at,
  }) async {
    final users = await _loadUsers();
    final row = _byId(users, userId);
    if (row == null) throw AuthException.accountNotFound;
    for (final k in _banKeys) {
      row.remove(k);
    }
    await _saveUsers(users);
    await _saveBans(
      _closeOpen(await _loadBans(), userId, at ?? DateTime.now(), liftedBy),
    );
    return _fromMap(row);
  }

  @override
  Future<List<BanRecord>> getBanHistory(String userId) async {
    final list = (await _loadBans()).where((b) => b.userId == userId).toList()
      ..sort((a, b) => b.start.compareTo(a.start));
    return list;
  }
}
