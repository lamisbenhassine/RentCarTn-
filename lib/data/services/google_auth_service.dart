import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

import '../../core/config/google_secrets.dart';

/// Pourquoi la connexion Google a échoué (l'annulation n'en fait pas partie :
/// elle renvoie simplement `null`).
enum GoogleAuthFailure {
  network,
  configuration,
  unsupported,

  /// Aucun compte Google utilisable proposé par le téléphone.
  noAccount,

  /// Compte refusé (ex. pas dans les utilisateurs test de l'écran de
  /// consentement OAuth en mode Test).
  notAllowed,
  unknown,
}

class GoogleAuthException implements Exception {
  const GoogleAuthException(this.reason, [this.detail]);

  final GoogleAuthFailure reason;
  final String? detail;

  @override
  String toString() => 'GoogleAuthException($reason): $detail';
}

/// Infos utiles du compte Google.
class GoogleProfile {
  const GoogleProfile({
    required this.email,
    required this.firstName,
    required this.lastName,
    this.photoUrl,
  });

  final String email;
  final String firstName;
  final String lastName;
  final String? photoUrl;
}

/// Connexion Google (package google_sign_in 7 : initialize → authenticate).
/// Android, sans Firebase : le Web Client ID sert de `serverClientId`.
class GoogleAuthService {
  const GoogleAuthService();

  static const _placeholder = 'COLLE_TON_WEB_CLIENT_ID';

  /// `initialize` ne doit être appelé qu'une fois par lancement.
  static Future<void>? _init;

  Future<void> _ensureInitialized() {
    return _init ??= GoogleSignIn.instance
        .initialize(serverClientId: GoogleSecrets.webClientId.trim())
        .catchError((Object e) {
          _init = null; // permettre un nouvel essai
          throw e;
        });
  }

  /// Ouvre le sélecteur de compte Google.
  /// Retourne `null` si l'utilisateur annule (ce n'est pas une erreur).
  Future<GoogleProfile?> signIn() async {
    final clientId = GoogleSecrets.webClientId.trim();
    if (clientId.isEmpty ||
        clientId == _placeholder ||
        !clientId.endsWith('.apps.googleusercontent.com')) {
      debugPrint(
        '[GoogleSignIn] Web Client ID manquant ou invalide dans '
        'lib/core/config/google_secrets.dart : "$clientId"',
      );
      throw const GoogleAuthException(
        GoogleAuthFailure.configuration,
        'webClientId non renseigné',
      );
    }

    try {
      await _ensureInitialized();
      if (!GoogleSignIn.instance.supportsAuthenticate()) {
        // Ex. web : il faudrait le bouton rendu par Google (renderButton).
        throw const GoogleAuthException(GoogleAuthFailure.unsupported);
      }
      if (!await _hasInternet()) {
        throw const GoogleAuthException(GoogleAuthFailure.network);
      }

      final account = await GoogleSignIn.instance.authenticate();
      return _profileFrom(account);
    } on GoogleSignInException catch (e) {
      // Annulation volontaire : retour à la connexion, sans message.
      if (e.code == GoogleSignInExceptionCode.canceled) {
        debugPrint('[GoogleSignIn] Annulé par l\'utilisateur');
        return null;
      }

      debugPrint(
        '[GoogleSignIn] code=${e.code.name} — ${e.description} — '
        '${e.details}',
      );
      throw GoogleAuthException(_classify(e), e.description);
    } on GoogleAuthException {
      rethrow;
    } catch (e) {
      debugPrint('[GoogleSignIn] Erreur inattendue : $e');
      throw GoogleAuthException(GoogleAuthFailure.unknown, '$e');
    }
  }

  /// Déconnexion Google (au logout) : la prochaine fois, le sélecteur de
  /// compte s'affiche de nouveau.
  Future<void> signOut() async {
    if (_init == null) return; // Google jamais utilisé pendant ce lancement
    try {
      await GoogleSignIn.instance.signOut();
    } catch (e) {
      debugPrint('[GoogleSignIn] signOut : $e');
    }
  }

  /// Suppression de compte : révoque aussi l'accès accordé à l'app
  /// (le compte Google devra de nouveau donner son accord).
  Future<void> disconnect() async {
    try {
      await _ensureInitialized();
      await GoogleSignIn.instance.disconnect();
    } catch (e) {
      // Compte non Google, ou déjà déconnecté : sans conséquence.
      debugPrint('[GoogleSignIn] disconnect : $e');
    }
  }

  // ---------------------------------------------------------------------------

  /// Traduit l'erreur du SDK en cause compréhensible.
  ///
  /// Sur Android (google_sign_in 7, Credential Manager), une mauvaise
  /// configuration remonte souvent en `unknownError` avec un message :
  /// « [28444] Developer console is not set up correctly », « 10: » /
  /// DEVELOPER_ERROR (ancien SDK), « 12500 », ou « No credential available ».
  static GoogleAuthFailure _classify(GoogleSignInException e) {
    final text = '${e.description} ${e.details}'.toLowerCase();
    bool has(String s) => text.contains(s);

    if (e.code == GoogleSignInExceptionCode.clientConfigurationError ||
        e.code == GoogleSignInExceptionCode.providerConfigurationError ||
        has('28444') ||
        has('developer console') ||
        has('developer_error') ||
        has('[10]') ||
        has(' 10:') ||
        has('12500')) {
      return GoogleAuthFailure.configuration;
    }
    if (has('network') || has('internet') || has('7:') || has('[7]')) {
      return GoogleAuthFailure.network;
    }
    // Compte refusé à l'écran de consentement (app en mode Test et compte
    // absent des utilisateurs test) : « [16] Account reauth failed ».
    if (has('[16]') || has('reauth') || has('access_denied')) {
      return GoogleAuthFailure.notAllowed;
    }
    // Aucun compte Google proposé (aucun compte sur le téléphone, ou
    // configuration Google Cloud qui ne correspond pas à l'app).
    if (has('no credential')) return GoogleAuthFailure.noAccount;
    return GoogleAuthFailure.unknown;
  }

  /// Petite requête vers Google pour distinguer « pas d'internet » des
  /// autres erreurs (le SDK renvoie souvent un message peu clair).
  Future<bool> _hasInternet() async {
    try {
      final res = await http
          .head(Uri.parse('https://www.google.com/generate_204'))
          .timeout(const Duration(seconds: 5));
      return res.statusCode < 500;
    } catch (_) {
      return false;
    }
  }

  /// Prénom / nom : lus dans l'ID token (given_name, family_name), sinon
  /// déduits du nom affiché.
  GoogleProfile _profileFrom(GoogleSignInAccount account) {
    final claims = _decodeJwt(account.authentication.idToken);
    var first = (claims['given_name'] as String?)?.trim() ?? '';
    var last = (claims['family_name'] as String?)?.trim() ?? '';

    if (first.isEmpty) {
      final parts = (account.displayName ?? '').trim().split(RegExp(r'\s+'));
      first = parts.isNotEmpty && parts.first.isNotEmpty
          ? parts.first
          : account.email.split('@').first;
      if (last.isEmpty && parts.length > 1) last = parts.skip(1).join(' ');
    }

    return GoogleProfile(
      email: account.email.trim().toLowerCase(),
      firstName: first,
      lastName: last,
      photoUrl: account.photoUrl ?? claims['picture'] as String?,
    );
  }

  static Map<String, dynamic> _decodeJwt(String? token) {
    if (token == null) return const {};
    final parts = token.split('.');
    if (parts.length != 3) return const {};
    try {
      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final json = jsonDecode(payload);
      return json is Map<String, dynamic> ? json : const {};
    } catch (_) {
      return const {};
    }
  }
}
