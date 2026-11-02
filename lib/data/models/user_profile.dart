import 'user_role.dart';

/// Profil utilisateur (auth locale sqflite / prefs).
class UserProfile {
  const UserProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    this.role = UserRole.user,
    this.cin = '',
    this.licenceNumber = '',
    this.city = 'Tunis',
    this.address = '',
    this.birthDate,
    this.avatarUrl,
    this.memberSince,
    this.publicUsername = 'Utilisateur_TN',
    this.latitude,
    this.longitude,
    this.licenceExpiry,
    this.trustScore = 50,
    this.emailVerified = false,
    this.bannedUntil,
    this.banPermanent = false,
    this.banReason,
    this.bannedBy,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final UserRole role;
  final String cin;
  final String licenceNumber;
  final String city;
  final String address;
  final DateTime? birthDate;
  final String? avatarUrl;
  final DateTime? memberSince;

  /// Pseudonyme affiché dans les enchères publiques.
  final String publicUsername;

  /// Dernière position connue (optionnelle).
  final double? latitude;
  final double? longitude;

  /// Date d'expiration du permis de conduire.
  final DateTime? licenceExpiry;

  /// Score de confiance du client (0 à 100).
  final int trustScore;

  /// `true` une fois le code reçu par e-mail saisi (verify_email_screen).
  /// Tant que `false`, le routeur bloque l'accès à l'application.
  final bool emailVerified;

  /// Bannissement par l'admin : fin prévue (temporaire), ou [banPermanent].
  /// Écrits uniquement par banUser / unbanUser (jamais par updateProfile).
  final DateTime? bannedUntil;
  final bool banPermanent;
  final String? banReason;

  /// Nom de l'admin qui a banni le compte.
  final String? bannedBy;

  /// Compte suspendu à [now] : définitif, ou date de fin pas encore passée.
  bool isBannedAt(DateTime now) =>
      banPermanent || (bannedUntil != null && bannedUntil!.isAfter(now));

  bool get isBanned => isBannedAt(DateTime.now());

  /// Bannissement temporaire terminé mais pas encore levé en base
  /// (réactivation automatique à la prochaine vérification).
  bool get hasExpiredBan => !banPermanent && bannedUntil != null && !isBanned;

  String get fullName => '$firstName $lastName';

  bool get isAdmin => role.isAdmin;
  bool get isClient => role.isClient;
  bool get isCompany => role.isCompany;
  bool get isParticular => role.isParticular;

  String get initials {
    final f = firstName.isNotEmpty ? firstName[0] : '';
    final l = lastName.isNotEmpty ? lastName[0] : '';
    return '$f$l'.toUpperCase();
  }

  UserProfile copyWith({
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    UserRole? role,
    String? cin,
    String? licenceNumber,
    String? city,
    String? address,
    DateTime? birthDate,
    String? avatarUrl,
    String? publicUsername,
    double? latitude,
    double? longitude,
    DateTime? licenceExpiry,
    int? trustScore,
    bool? emailVerified,
    DateTime? bannedUntil,
    bool? banPermanent,
    String? banReason,
    String? bannedBy,
    bool clearAvatar = false,

    /// Lève le bannissement (efface les 4 champs).
    bool clearBan = false,
  }) {
    return UserProfile(
      id: id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      cin: cin ?? this.cin,
      licenceNumber: licenceNumber ?? this.licenceNumber,
      city: city ?? this.city,
      address: address ?? this.address,
      birthDate: birthDate ?? this.birthDate,
      avatarUrl: clearAvatar ? null : (avatarUrl ?? this.avatarUrl),
      memberSince: memberSince,
      publicUsername: publicUsername ?? this.publicUsername,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      licenceExpiry: licenceExpiry ?? this.licenceExpiry,
      trustScore: trustScore ?? this.trustScore,
      emailVerified: emailVerified ?? this.emailVerified,
      bannedUntil: clearBan ? null : (bannedUntil ?? this.bannedUntil),
      banPermanent: clearBan ? false : (banPermanent ?? this.banPermanent),
      banReason: clearBan ? null : (banReason ?? this.banReason),
      bannedBy: clearBan ? null : (bannedBy ?? this.bannedBy),
    );
  }
}
