import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/services/email_service.dart';
import '../../data/services/otp_service.dart';
import '../../l10n/l10n.dart';
import '../../widgets/common.dart';

/// Messages OTP qui dépendent d'un résultat de service.
abstract final class OtpMessages {
  /// Message clair pour un échec EmailJS (réseau ou refus du service).
  static String sendFailed(AppLocalizations l, EmailSendException e) =>
      e.statusCode == null
      ? l.otpSendFailedNetwork
      : l.otpSendFailedService(e.statusCode!);

  /// Erreur affichée sous le champ après une vérification ratée.
  static String verifyError(
    AppLocalizations l,
    OtpVerifyResult result,
    int attemptsLeft,
  ) => switch (result) {
    OtpVerifyResult.wrongCode => l.otpWrongCode(attemptsLeft),
    OtpVerifyResult.tooManyAttempts => l.otpTooManyAttempts,
    OtpVerifyResult.expired => l.otpExpired,
    _ => l.otpRequestNew,
  };
}

/// Saisie d'un code OTP : champ 6 chiffres, temps restant, essais,
/// « Vérifier », « Renvoyer » (après 60 s) et une action secondaire.
///
/// Sans état : l'écran parent rafraîchit chaque seconde (comptes à rebours).
class OtpCodePanel extends StatelessWidget {
  const OtpCodePanel({
    super.key,
    required this.session,
    required this.controller,
    required this.onVerify,
    required this.onResend,
    required this.secondaryLabel,
    required this.onSecondary,
    this.errorText,
    this.sending = false,
    this.onChanged,
  });

  final OtpSession session;
  final TextEditingController controller;
  final VoidCallback onVerify;
  final VoidCallback onResend;

  /// Ex. « Changer de méthode » ou « Modifier l'adresse e-mail ».
  final String secondaryLabel;
  final VoidCallback onSecondary;

  final String? errorText;

  /// Envoi d'un nouveau code en cours.
  final bool sending;

  /// Appelé à chaque saisie (pour effacer l'erreur). Le code est vérifié
  /// automatiquement au 6ᵉ chiffre.
  final ValueChanged<String>? onChanged;

  static String _mmss(Duration d) {
    final s = (d.inMilliseconds / 1000).ceil();
    return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final dead = session.isExpired || session.isExhausted;
    final error = errorText ?? (session.isExpired ? l.otpExpired : null);
    final timeLeft = session.timeLeft;
    final resendIn = (session.resendIn.inMilliseconds / 1000).ceil();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Un code se lit toujours de gauche à droite, même en arabe.
        Directionality(
          textDirection: TextDirection.ltr,
          child: TextField(
            controller: controller,
            enabled: !dead,
            autofocus: true,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: OtpService.codeLength,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: 12,
              color: context.cs.onSurface,
            ),
            decoration: InputDecoration(
              hintText: '••••••',
              counterText: '',
              errorText: error,
              errorMaxLines: 2,
            ),
            onChanged: (value) {
              onChanged?.call(value);
              if (value.length == OtpService.codeLength) onVerify();
            },
          ),
        ),
        const SizedBox(height: 10),
        if (!dead)
          Row(
            children: [
              Icon(
                Icons.timer_outlined,
                size: 16,
                color: timeLeft.inSeconds < 60
                    ? AppColors.warning
                    : context.cs.outline,
              ),
              const SizedBox(width: 6),
              Text(
                l.otpValidFor(_mmss(timeLeft)),
                style: TextStyle(
                  fontSize: 12.5,
                  color: context.cs.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              Text(
                l.otpAttemptsLeft(session.attemptsLeft),
                style: TextStyle(
                  fontSize: 12.5,
                  color: context.cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: dead || sending ? null : onVerify,
            child: Text(l.otpVerify),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              onPressed: session.canResend && !sending ? onResend : null,
              icon: sending
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded, size: 18),
              label: Text(
                sending
                    ? l.otpSending
                    : session.canResend
                    ? l.otpResend
                    : l.otpResendIn(resendIn),
              ),
            ),
            Flexible(
              child: TextButton(
                onPressed: sending ? null : onSecondary,
                child: Text(secondaryLabel, textAlign: TextAlign.end),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Encadré rouge « E-mail non envoyé ».
class SendErrorBox extends StatelessWidget {
  const SendErrorBox({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return NoticeBox(
      icon: Icons.error_outline_rounded,
      color: AppColors.danger,
      title: context.l10n.otpEmailNotSent,
      message: message,
    );
  }
}
