import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// Canal d'envoi du code de réinitialisation.
enum OtpChannel { email, sms }

/// Résultat de [OtpService.verify].
enum OtpVerifyResult { valid, wrongCode, expired, tooManyAttempts, noCode }

/// Code envoyé à l'utilisateur. La vérification se fait sur le hash ;
/// [plainCode] sert uniquement à l'envoi (e-mail) ou à l'affichage démo (SMS).
class OtpSession {
  OtpSession._({
    required this.userId,
    required this.channel,
    required this.maskedDestination,
    required this.plainCode,
    required this.expiresAt,
    required this.resendAvailableAt,
    required this._codeHash,
  });

  final String userId;
  final OtpChannel channel;

  /// Destination masquée : t***@gmail.com ou +216 ** *** 678.
  final String maskedDestination;

  /// Code en clair : envoyé par EmailJS (canal e-mail) ou affiché à l'écran
  /// (canal SMS, mode démo). Ne jamais le journaliser.
  final String plainCode;

  final DateTime expiresAt;
  final DateTime resendAvailableAt;
  final String _codeHash;

  int attemptsLeft = OtpService.maxAttempts;

  /// Passe à `true` après un code correct (autorise le nouveau mot de passe).
  bool verified = false;

  bool get isExpired => !DateTime.now().isBefore(expiresAt);
  bool get isExhausted => attemptsLeft <= 0;

  Duration get timeLeft => _remaining(expiresAt);
  Duration get resendIn => _remaining(resendAvailableAt);
  bool get canResend => resendIn == Duration.zero;

  static Duration _remaining(DateTime until) {
    final left = until.difference(DateTime.now());
    return left.isNegative ? Duration.zero : left;
  }
}

/// Logique du code OTP à 6 chiffres :
/// expiration 5 min, 3 essais maximum, renvoi possible après 60 s.
///
/// Un seul code actif à la fois : en émettre un nouveau annule le précédent.
class OtpService {
  OtpService({Random? random}) : _random = random ?? Random.secure();

  static const int codeLength = 6;
  static const int maxAttempts = 3;
  static const Duration validity = Duration(minutes: 5);
  static const Duration resendDelay = Duration(seconds: 60);

  final Random _random;
  OtpSession? _session;

  OtpSession? get session => _session;

  /// Génère un nouveau code pour [userId]. [destination] est l'e-mail ou le
  /// téléphone en clair ; seule sa version masquée est gardée.
  OtpSession issue({
    required String userId,
    required OtpChannel channel,
    required String destination,
  }) {
    final code = List.generate(codeLength, (_) => _random.nextInt(10)).join();
    final now = DateTime.now();
    return _session = OtpSession._(
      userId: userId,
      channel: channel,
      maskedDestination: channel == OtpChannel.email
          ? maskEmail(destination)
          : maskPhone(destination),
      plainCode: code,
      expiresAt: now.add(validity),
      resendAvailableAt: now.add(resendDelay),
      codeHash: _hash(userId, code),
    );
  }

  /// Vérifie [code]. Chaque code faux consomme un essai ; au 3ᵉ échec le
  /// code est invalidé et il faut en demander un nouveau.
  OtpVerifyResult verify(String code) {
    final s = _session;
    if (s == null) return OtpVerifyResult.noCode;
    if (s.isExpired) return OtpVerifyResult.expired;
    if (s.isExhausted) return OtpVerifyResult.tooManyAttempts;

    if (_hash(s.userId, code.trim()) == s._codeHash) {
      s.verified = true;
      return OtpVerifyResult.valid;
    }
    s.attemptsLeft--;
    return s.isExhausted
        ? OtpVerifyResult.tooManyAttempts
        : OtpVerifyResult.wrongCode;
  }

  /// Annule un code qui n'a pas pu être envoyé et remet [previous]
  /// (le code encore valide avant un renvoi raté), ou rien.
  void rollback(OtpSession? previous) => _session = previous;

  /// Oublie le code en cours (changement de méthode, fin du parcours).
  void clear() => _session = null;

  // ---------------------------------------------------------------------------

  /// tayechi@gmail.com → t***@gmail.com
  static String maskEmail(String email) {
    final value = email.trim().toLowerCase();
    final at = value.indexOf('@');
    if (at <= 0) return '***';
    return '${value[0]}***${value.substring(at)}';
  }

  /// 22 345 678 / +216 22345678 → +216 ** *** 678
  static String maskPhone(String phone) {
    var digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 8 && digits.startsWith('216')) {
      digits = digits.substring(3);
    }
    final end = digits.length >= 3
        ? digits.substring(digits.length - 3)
        : digits;
    return '+216 ** *** $end';
  }

  static String _hash(String userId, String code) =>
      sha256.convert(utf8.encode('otp:$userId:$code')).toString();
}
