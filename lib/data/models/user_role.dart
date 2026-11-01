/// Rôles applicatifs.
enum UserRole {
  /// Gestion complète : créer / modifier / supprimer voitures & ventes.
  admin,

  /// Client particulier : location courte durée (jours / semaines).
  user,

  /// Client entreprise : flotte multi-véhicules, location longue durée
  /// (mois / années, ex. 3 ans).
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

  bool get isCompany => this == UserRole.company;

  bool get isParticular => this == UserRole.user;

  /// Peut réserver, panier, enchérir, passer les quiz.
  bool get isClient => this == UserRole.user || this == UserRole.company;

  static UserRole fromId(String? raw) {
    for (final r in UserRole.values) {
      if (r.name == raw) return r;
    }
    return UserRole.user;
  }
}
