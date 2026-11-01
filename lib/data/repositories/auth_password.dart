import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Hash simple du mot de passe (local, pas un serveur distant).
String hashPassword(String password) {
  final bytes = utf8.encode('rentcar-tunisia:$password');
  return sha256.convert(bytes).toString();
}

/// Ancien format du module User (SHA-256 salé avec l'id du compte), encore
/// présent sur les téléphones qui avaient la branche module-user.
String _legacyHash(String userId, String password) =>
    sha256.convert(utf8.encode('$userId:$password')).toString();

/// Vérifie [password] contre le hash stocké, dans le format actuel ou
/// l'ancien. Hash vide (compte Google sans mot de passe) → `false`.
bool verifyPassword({
  required String userId,
  required String password,
  required String? stored,
}) {
  if (stored == null || stored.isEmpty) return false;
  return stored == hashPassword(password) ||
      stored == _legacyHash(userId, password);
}

/// `true` si le hash est dans l'ancien format (à ré-enregistrer).
bool isLegacyHash(String stored, String password) =>
    stored != hashPassword(password);
