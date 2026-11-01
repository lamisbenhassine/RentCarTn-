import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Hachage des mots de passe : SHA-256, salé avec l'id utilisateur.
///
/// Le sel (id) est unique par compte : deux comptes avec le même mot de
/// passe n'ont donc pas le même hash.
abstract final class PasswordHasher {
  static String hash(String userId, String password) {
    final bytes = utf8.encode('$userId:$password');
    return sha256.convert(bytes).toString();
  }

  static bool verify(String userId, String password, String? storedHash) {
    if (storedHash == null || storedHash.isEmpty) return false;
    return hash(userId, password) == storedHash;
  }
}
