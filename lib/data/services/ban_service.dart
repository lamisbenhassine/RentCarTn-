import 'package:flutter/foundation.dart';

import '../models/ban_record.dart';
import '../models/user_profile.dart';
import '../repositories/auth_repository.dart';
import 'email_service.dart';

/// Refus d'un bannissement (règles du back office).
enum BanErrorCode { notFound, adminTarget, selfTarget, endInPast, noReason }

class BanException implements Exception {
  const BanException(this.code);

  final BanErrorCode code;

  @override
  String toString() => 'BanException(${code.name})';
}

/// Bannissement temporaire ou définitif d'un compte par l'admin.
///
/// - impossible de bannir un admin ou soi-même ;
/// - une durée, une date de fin (dans le futur) ou « définitif » ;
/// - fin automatique : [refresh] lève un bannissement échu dès que le
///   compte est vérifié (connexion, restauration, retour au premier plan) ;
/// - e-mails de bannissement / réactivation (modèle EmailJS n° 2).
class BanService {
  BanService({
    AuthRepository? repository,
    EmailService? email,
    DateTime Function()? clock,
  }) : _repository = repository ?? AuthRepositoryFactory.create(),
       _email = email ?? EmailService(),
       _clock = clock ?? DateTime.now;

  final AuthRepository _repository;
  final EmailService _email;
  final DateTime Function() _clock;

  /// [BanRecord.liftedBy] d'une fin automatique.
  static const autoLiftedBy = 'Automatique';

  static String adminName(UserProfile admin) {
    final name = admin.fullName.trim();
    return name.isEmpty ? 'Admin RentCar' : name;
  }

  /// Bannit [userId] pour [duration], jusqu'à [until], ou [permanent].
  Future<UserProfile> banUser({
    required String userId,
    required UserProfile admin,
    required String reason,
    Duration? duration,
    DateTime? until,
    bool permanent = false,
    String? complaintId,
  }) async {
    final text = reason.trim();
    if (text.isEmpty) throw const BanException(BanErrorCode.noReason);
    if (userId == admin.id) throw const BanException(BanErrorCode.selfTarget);
    final target = await _repository.byId(userId);
    if (target == null) throw const BanException(BanErrorCode.notFound);
    if (target.isAdmin) throw const BanException(BanErrorCode.adminTarget);

    final now = _clock();
    final end = permanent
        ? null
        : (until ?? (duration == null ? null : now.add(duration)));
    if (!permanent && (end == null || !end.isAfter(now))) {
      throw const BanException(BanErrorCode.endInPast);
    }
    return _repository.banUser(
      BanRecord(
        id: 'ban-${now.microsecondsSinceEpoch}',
        userId: userId,
        adminId: admin.id,
        adminName: adminName(admin),
        reason: text,
        start: now,
        end: end,
        permanent: permanent,
        complaintId: complaintId,
      ),
    );
  }

  Future<UserProfile> unbanUser(String userId, {required UserProfile admin}) =>
      _repository.unbanUser(userId, liftedBy: adminName(admin), at: _clock());

  Future<List<BanRecord>> getBanHistory(String userId) =>
      _repository.getBanHistory(userId);

  /// Bannissement temporaire échu → levé en base (« Automatique », daté de
  /// la fin prévue). Retourne le compte à jour.
  Future<UserProfile> refresh(UserProfile user) async {
    final until = user.bannedUntil;
    if (user.banPermanent || until == null || user.isBannedAt(_clock())) {
      return user;
    }
    try {
      debugPrint('[Ban] Fin automatique pour ${user.id} ($until)');
      return await _repository.unbanUser(
        user.id,
        liftedBy: autoLiftedBy,
        at: until,
      );
    } catch (e) {
      debugPrint('[Ban] Réactivation non enregistrée : $e');
      return user.copyWith(clearBan: true);
    }
  }

  // ---------------------------------------------------------------------------
  // E-mails (ne lancent jamais d'exception : `false` si non envoyé)
  // ---------------------------------------------------------------------------

  Future<bool> sendBanMail(UserProfile user) {
    final end = user.bannedUntil;
    final intro = user.banPermanent || end == null
        ? 'Votre compte RentCar Tunisia a été suspendu définitivement.'
        : 'Votre compte RentCar Tunisia est suspendu jusqu\'au '
              '${formatDate(end)} (${formatDuration(end.difference(_clock()))}).';
    return _notice(
      user,
      subject: 'Votre compte RentCar Tunisia est suspendu',
      intro: intro,
      message:
          'Motif : ${user.banReason ?? '—'}\n'
          'Pour contester cette décision, répondez à cet e-mail ou contactez '
          'le support.',
      status: user.banPermanent ? 'Suspendu (définitif)' : 'Suspendu',
    );
  }

  Future<bool> sendUnbanMail(UserProfile user) => _notice(
    user,
    subject: 'Votre compte RentCar Tunisia est réactivé',
    intro: 'Bonne nouvelle : votre compte a été réactivé.',
    message: 'Vous pouvez de nouveau vous connecter à l\'application.',
    status: 'Actif',
  );

  Future<bool> _notice(
    UserProfile user, {
    required String subject,
    required String intro,
    required String message,
    required String status,
  }) async {
    if (user.email.trim().isEmpty ||
        !EmailService.complaintTemplateConfigured) {
      debugPrint('[Ban] E-mail non envoyé (adresse ou modèle n° 2 manquant)');
      return false;
    }
    try {
      await _email.sendNotice(
        email: user.email,
        name: user.fullName,
        subject: subject,
        intro: intro,
        message: message,
        status: status,
      );
      return true;
    } catch (e) {
      debugPrint('[Ban] E-mail non envoyé : $e');
      return false;
    }
  }

  /// 03/11/2026 à 14:30 (e-mails : toujours en français).
  static String formatDate(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year} à '
        '${two(d.hour)}:${two(d.minute)}';
  }

  /// « 7 jours », « 5 h », « 2 min » (arrondi au supérieur).
  static String formatDuration(Duration d) {
    if (d.inMinutes < 60) {
      final m = d.inSeconds <= 0 ? 0 : (d.inSeconds / 60).ceil();
      return '$m min';
    }
    if (d.inHours < 24) return '${(d.inMinutes / 60).ceil()} h';
    final days = (d.inHours / 24).round();
    return days == 1 ? '1 jour' : '$days jours';
  }
}
