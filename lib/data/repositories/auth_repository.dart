import '../local/app_database.dart';
import '../models/user_profile.dart';
import '../models/user_role.dart';
import 'auth_repository_prefs.dart';
import 'auth_repository_sqflite.dart';

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

/// Contrat auth locale (sign-in / sign-up).
///
/// Équipe : connexion, inscription avec rôle, session, admin par défaut.
/// Module User : Google, vérification e-mail, mot de passe oublié (OTP),
/// profil complet, changement de mot de passe, suppression du compte.
abstract class AuthRepository {
  Future<UserProfile> login(String email, String password);

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
  });

  Future<UserProfile?> byId(String id);

  Future<void> sendResetLink(String email);

  Future<void> saveSession(String userId);

  Future<String?> readSessionUserId();

  Future<void> clearSession();

  /// Compte admin par défaut si aucun admin n'existe encore.
  Future<void> ensureDefaultAdmin();

  // --- Module User --------------------------------------------------------

  /// « Continuer avec Google » : compte existant (marqué vérifié) ou nouveau
  /// compte sans mot de passe. `null` si l'utilisateur annule.
  Future<UserProfile?> signInWithGoogle();

  /// Déconnexion Google (le sélecteur de compte réapparaîtra).
  Future<void> signOutGoogle();

  /// `true` si le compte a un mot de passe local (`false` : compte Google).
  Future<bool> hasPassword(UserProfile user);

  /// Supprime définitivement le compte ([password] requis s'il en a un).
  Future<void> deleteAccount(UserProfile user, {String? password});

  /// Inscription étape 1 : e-mail / téléphone déjà utilisés ?
  Future<bool> isEmailTaken(String email);
  Future<bool> isPhoneTaken(String phone);

  /// Enregistre le profil (e-mail et téléphone uniques).
  Future<UserProfile> updateProfile(UserProfile user);

  Future<void> changePassword({
    required UserProfile user,
    required String currentPassword,
    required String newPassword,
  });

  /// Mot de passe oublié : retrouve le compte par e-mail ou téléphone.
  Future<UserProfile> findAccountForReset({String? email, String? phone});

  /// Nouveau mot de passe après vérification du code OTP.
  Future<void> resetPassword(UserProfile user, String newPassword);
}

/// - Mobile / APK → **sqflite**
/// - Web (Chrome) → **shared_preferences**
class AuthRepositoryFactory {
  static AuthRepository create() {
    if (AppDatabase.instance.isSupported) {
      return SqfliteAuthRepository();
    }
    return PrefsAuthRepository();
  }
}
