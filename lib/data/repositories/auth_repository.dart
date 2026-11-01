import 'package:flutter/foundation.dart';

import '../../core/utils/password_hasher.dart';
import '../local/app_database.dart';
import '../local/user_dao.dart';
import '../mock/mock_users.dart';
import '../models/user_profile.dart';
import '../services/google_auth_service.dart';

/// Cause précise d'un échec (l'écran affiche le message traduit
/// correspondant ; [AuthException.message] reste le texte français).
enum AuthErrorCode {
  accountNotFound,
  wrongPassword,
  locked,
  emailTaken,
  phoneTaken,
  wrongCurrentPassword,
  deleteFailed,
}

class AuthException implements Exception {
  const AuthException(this.message, {this.code});
  final String message;
  final AuthErrorCode? code;

  static const accountNotFound = AuthException(
    'Aucun compte ne correspond à cet e-mail.',
    code: AuthErrorCode.accountNotFound,
  );
  static const wrongPassword = AuthException(
    'Mot de passe incorrect.',
    code: AuthErrorCode.wrongPassword,
  );
  static const emailTaken = AuthException(
    'Un compte existe déjà avec cet e-mail.',
    code: AuthErrorCode.emailTaken,
  );
  static const phoneTaken = AuthException(
    'Ce numéro de téléphone est déjà utilisé.',
    code: AuthErrorCode.phoneTaken,
  );
  static const wrongCurrentPassword = AuthException(
    'Mot de passe actuel incorrect.',
    code: AuthErrorCode.wrongCurrentPassword,
  );
  static const deleteFailed = AuthException(
    'La suppression du compte a échoué.',
    code: AuthErrorCode.deleteFailed,
  );

  @override
  String toString() => message;
}

/// Authentification locale :
/// - mobile / desktop → table `users` de sqflite (comptes persistants,
///   mots de passe hachés SHA-256 salés avec l'id) ;
/// - web → mémoire (comptes perdus au rechargement de la page).
///
/// Aucun serveur, aucun jeton : à remplacer par un vrai service d'identité.
class AuthRepository {
  const AuthRepository();

  final UserDao _dao = const UserDao();
  final GoogleAuthService _google = const GoogleAuthService();

  static const Duration _latency = Duration(milliseconds: 900);

  /// « Continuer avec Google » :
  /// - e-mail déjà en BD → ce compte (marqué vérifié, photo ajoutée si
  ///   absente) ;
  /// - sinon → nouveau compte sans mot de passe, e-mail vérifié, photo
  ///   Google, ville Tunis.
  ///
  /// Retourne `null` si l'utilisateur annule. Lance [GoogleAuthException]
  /// (pas d'internet, configuration…).
  Future<UserProfile?> signInWithGoogle() async {
    final google = await _google.signIn();
    if (google == null) return null;

    if (_useSqlite) {
      await _ensureDemoAccount();
      final existing = await _dao.findByEmail(google.email);
      if (existing != null) {
        var user = existing.profile;
        // Google a prouvé que l'adresse appartient à l'utilisateur.
        final needsUpdate =
            !user.emailVerified ||
            ((user.avatarUrl ?? '').isEmpty && google.photoUrl != null);
        if (needsUpdate) {
          user = user.copyWith(
            emailVerified: true,
            avatarUrl: (user.avatarUrl ?? '').isEmpty ? google.photoUrl : null,
          );
          await _dao.update(user);
        }
        return user;
      }

      final user = _newGoogleUser(google);
      await _dao.insert(user, passwordHash: null);
      return user;
    }

    // --- Web : mémoire (Google n'y est de toute façon pas pris en charge) ---
    final saved = _memoryProfiles[google.email];
    if (saved != null) return saved;
    final user = _newGoogleUser(google);
    _memoryProfiles[google.email] = user;
    return user;
  }

  UserProfile _newGoogleUser(GoogleProfile g) => UserProfile(
    id: 'usr-${DateTime.now().millisecondsSinceEpoch}',
    firstName: g.firstName,
    lastName: g.lastName,
    email: g.email,
    phone: '',
    city: 'Tunis',
    avatarUrl: g.photoUrl,
    emailVerified: true,
    memberSince: DateTime.now(),
    publicUsername: '${g.firstName}_TN',
  );

  /// Déconnexion Google (le sélecteur de compte réapparaîtra).
  Future<void> signOutGoogle() => _google.signOut();

  /// `true` si le compte a un mot de passe local. `false` pour un compte
  /// créé via Google : la suppression se confirme alors en tapant un mot.
  Future<bool> hasPassword(UserProfile user) async {
    if (_useSqlite) {
      final record = await _dao.findById(user.id);
      return record?.passwordHash?.isNotEmpty ?? false;
    }
    return MockUsers.credentials.containsKey(user.email.trim().toLowerCase());
  }

  /// Supprime définitivement le compte (ligne `users`).
  /// [password] est obligatoire si le compte en a un
  /// ([AuthException.wrongCurrentPassword] sinon). Échec BD →
  /// [AuthException.deleteFailed]. Compte Google → accès Google révoqué.
  Future<void> deleteAccount(UserProfile user, {String? password}) async {
    await Future<void>.delayed(_latency);

    if (!_useSqlite) {
      final email = user.email.trim().toLowerCase();
      final expected = MockUsers.credentials[email];
      if (expected != null && expected != password) {
        throw AuthException.wrongCurrentPassword;
      }
      MockUsers.credentials.remove(email);
      _memoryProfiles.remove(email);
      return;
    }

    final record = await _dao.findById(user.id);
    if (record == null) throw AuthException.deleteFailed;

    final hash = record.passwordHash;
    final isGoogleAccount = hash == null || hash.isEmpty;
    if (!isGoogleAccount &&
        (password == null || !PasswordHasher.verify(user.id, password, hash))) {
      throw AuthException.wrongCurrentPassword;
    }

    try {
      final deleted = await _dao.delete(user.id);
      if (deleted == 0) throw AuthException.deleteFailed;
    } on AuthException {
      rethrow;
    } catch (e) {
      // Ex. contrainte de clé étrangère (réservations liées en BD).
      debugPrint('[AuthRepository] Suppression du compte échouée : $e');
      throw AuthException.deleteFailed;
    }

    if (isGoogleAccount) await _google.disconnect();
  }

  /// Le compte démo n'est inséré qu'une fois par lancement de l'app.
  static Future<void>? _demoSeed;

  bool get _useSqlite => AppDatabase.instance.isSupported;

  Future<UserProfile> login(String email, String password) async {
    await Future<void>.delayed(_latency);
    final normalized = email.trim().toLowerCase();

    if (_useSqlite) {
      await _ensureDemoAccount();
      final record = await _dao.findByEmail(normalized);
      if (record == null) throw AuthException.accountNotFound;
      if (!PasswordHasher.verify(
        record.profile.id,
        password,
        record.passwordHash,
      )) {
        throw AuthException.wrongPassword;
      }
      return record.profile;
    }

    // --- Web : mémoire ---
    final expected = MockUsers.credentials[normalized];
    if (expected == null) throw AuthException.accountNotFound;
    if (expected != password) throw AuthException.wrongPassword;
    if (normalized == MockUsers.demoEmail) return MockUsers.demoUser;

    final saved = _memoryProfiles[normalized];
    if (saved != null) return saved;

    final local = normalized.split('@').first;
    return UserProfile(
      id: 'usr-${local.hashCode.abs()}',
      firstName: local.isEmpty ? 'Client' : _capitalize(local),
      lastName: 'Tunisie',
      email: normalized,
      phone: '20 000 000',
      memberSince: DateTime.now(),
      publicUsername: '${_capitalize(local)}_TN',
    );
  }

  Future<UserProfile> register({
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
    await Future<void>.delayed(_latency);
    final normalized = email.trim().toLowerCase();

    final user = UserProfile(
      id: 'usr-${DateTime.now().millisecondsSinceEpoch}',
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      email: normalized,
      phone: phone.trim(),
      city: city,
      address: address.trim(),
      latitude: latitude,
      longitude: longitude,
      memberSince: DateTime.now(),
      publicUsername: '${firstName.trim()}_TN',
    );

    if (_useSqlite) {
      await _ensureDemoAccount();
      if (await _dao.findByEmail(normalized) != null) {
        throw AuthException.emailTaken;
      }
      if (await _dao.findByPhone(phone) != null) {
        throw AuthException.phoneTaken;
      }
      await _dao.insert(
        user,
        passwordHash: PasswordHasher.hash(user.id, password),
      );
      return user;
    }

    // --- Web : mémoire ---
    if (MockUsers.credentials.containsKey(normalized)) {
      throw AuthException.emailTaken;
    }
    MockUsers.credentials[normalized] = password;
    _memoryProfiles[normalized] = user;
    return user;
  }

  /// Recharge un compte mémorisé (« Se souvenir de moi »). `null` s'il
  /// n'existe plus (ex. compte créé sur web avant un rechargement).
  Future<UserProfile?> findUserById(String id) async {
    if (_useSqlite) {
      await _ensureDemoAccount();
      return (await _dao.findById(id))?.profile;
    }
    if (id == MockUsers.demoUser.id) return MockUsers.demoUser;
    for (final profile in _memoryProfiles.values) {
      if (profile.id == id) return profile;
    }
    return null;
  }

  /// `true` si un compte utilise déjà cet e-mail (vérifié dès l'étape 1).
  Future<bool> isEmailTaken(String email) async {
    final normalized = email.trim().toLowerCase();
    if (_useSqlite) {
      await _ensureDemoAccount();
      return await _dao.findByEmail(normalized) != null;
    }
    return MockUsers.credentials.containsKey(normalized);
  }

  /// `true` si un compte utilise déjà ce numéro (mobile uniquement).
  Future<bool> isPhoneTaken(String phone) async {
    if (!_useSqlite) return false;
    await _ensureDemoAccount();
    return await _dao.findByPhone(phone) != null;
  }

  /// Enregistre les modifications du profil (e-mail et téléphone uniques).
  Future<UserProfile> updateProfile(UserProfile user) async {
    if (!_useSqlite) {
      _memoryProfiles[user.email.trim().toLowerCase()] = user;
      return user;
    }

    final byEmail = await _dao.findByEmail(user.email);
    if (byEmail != null && byEmail.profile.id != user.id) {
      throw AuthException.emailTaken;
    }
    final byPhone = await _dao.findByPhone(user.phone);
    if (byPhone != null && byPhone.profile.id != user.id) {
      throw AuthException.phoneTaken;
    }
    await _dao.update(user);
    return user;
  }

  /// Change le mot de passe après vérification de l'actuel.
  Future<void> changePassword({
    required UserProfile user,
    required String currentPassword,
    required String newPassword,
  }) async {
    await Future<void>.delayed(_latency);

    if (!_useSqlite) {
      final email = user.email.trim().toLowerCase();
      if (MockUsers.credentials[email] != currentPassword) {
        throw AuthException.wrongCurrentPassword;
      }
      MockUsers.credentials[email] = newPassword;
      return;
    }

    final record = await _dao.findByEmail(user.email);
    if (record == null ||
        !PasswordHasher.verify(user.id, currentPassword, record.passwordHash)) {
      throw AuthException.wrongCurrentPassword;
    }
    await _dao.updatePassword(
      user.id,
      PasswordHasher.hash(user.id, newPassword),
    );
  }

  /// Mot de passe oublié : retrouve le compte par e-mail ou téléphone.
  /// Lance [AuthException.accountNotFound] s'il n'existe pas.
  Future<UserProfile> findAccountForReset({
    String? email,
    String? phone,
  }) async {
    await Future<void>.delayed(_latency);

    if (_useSqlite) {
      await _ensureDemoAccount();
      final record = email != null
          ? await _dao.findByEmail(email)
          : await _dao.findByPhone(phone ?? '');
      if (record == null) throw AuthException.accountNotFound;
      return record.profile;
    }

    // --- Web : mémoire ---
    final candidates = [MockUsers.demoUser, ..._memoryProfiles.values];
    String digits(String v) => v.replaceAll(RegExp(r'\D'), '');
    for (final user in candidates) {
      final match = email != null
          ? user.email == email.trim().toLowerCase()
          : digits(user.phone) == digits(phone ?? '');
      if (match) return user;
    }
    throw AuthException.accountNotFound;
  }

  /// Enregistre le nouveau mot de passe (haché) après vérification OTP.
  Future<void> resetPassword(UserProfile user, String newPassword) async {
    await Future<void>.delayed(_latency);
    if (_useSqlite) {
      await _dao.updatePassword(
        user.id,
        PasswordHasher.hash(user.id, newPassword),
      );
    } else {
      MockUsers.credentials[user.email.trim().toLowerCase()] = newPassword;
    }
  }

  // ---------------------------------------------------------------------------

  /// Profils créés sur web pendant la session.
  static final Map<String, UserProfile> _memoryProfiles = {};

  /// Crée demo@rentcar.tn dans la BD s'il n'existe pas encore.
  Future<void> _ensureDemoAccount() {
    return _demoSeed ??= () async {
      if (await _dao.findByEmail(MockUsers.demoEmail) != null) return;
      final demo = MockUsers.demoUser;
      await _dao.insert(
        demo,
        passwordHash: PasswordHasher.hash(demo.id, MockUsers.demoPassword),
      );
    }();
  }

  static String _capitalize(String value) =>
      value.isEmpty ? value : value[0].toUpperCase() + value.substring(1);
}
