/// Rôles applicatifs.
enum UserRole {
  /// Gestion : voitures, enchères, quiz / examens.
  admin,

  /// Client particulier : location, panier, enchères, tests.
  user,

  /// Client entreprise : mêmes droits que [user].
  company,
}

extension UserRoleX on UserRole {
  String get id => name;

  String get label => switch (this) {
        UserRole.admin => 'Administrateur',
        UserRole.user => 'Utilisateur',
        UserRole.company => 'Entreprise',
      };

  bool get isAdmin => this == UserRole.admin;

  /// Peut réserver, panier, enchérir, passer les quiz.
  bool get isClient => this == UserRole.user || this == UserRole.company;

  static UserRole fromId(String? raw) {
    for (final r in UserRole.values) {
      if (r.name == raw) return r;
    }
    return UserRole.user;
  }
}
