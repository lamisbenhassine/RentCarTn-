import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Hash simple du mot de passe (local, pas un serveur distant).
String hashPassword(String password) {
  final bytes = utf8.encode('rentcar-tunisia:$password');
  return sha256.convert(bytes).toString();
}
