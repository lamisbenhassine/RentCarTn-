import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/validators.dart';
import '../../data/services/email_service.dart';
import '../../data/services/otp_service.dart';
import '../../state/auth_provider.dart';
import '../../widgets/common.dart';
import '../../l10n/l10n.dart';
import 'auth_scaffold.dart';
import 'otp_code_panel.dart';

/// Vérification de l'e-mail après inscription (ou à la connexion si le
/// compte n'est pas encore vérifié). Le routeur bloque l'application tant
/// que [UserProfile.emailVerified] est `false`.
///
/// Même modèle EmailJS que « Mot de passe oublié » ({{email}}, {{code}}).
class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _otp = OtpService();
  final _emailService = EmailService();
  final _code = TextEditingController();

  String? _codeError;
  bool _sending = false;
  String? _sendError;
  bool _saving = false;

  /// Rafraîchit le temps restant et le délai de renvoi.
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // Premier envoi automatique à l'ouverture de l'écran.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _sendCode();
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _code.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Envoi du code
  // ---------------------------------------------------------------------------

  Future<bool> _sendCode() async {
    final l = context.l10n;
    final user = context.read<AuthProvider>().user;
    if (user == null) return false;

    final previous = _otp.session;
    final session = _otp.issue(
      userId: user.id,
      channel: OtpChannel.email,
      destination: user.email,
    );
    setState(() {
      _sending = true;
      _sendError = null;
    });

    try {
      await _emailService.sendOtp(user.email, session.plainCode);
    } on EmailSendException catch (e) {
      debugPrint('[VerifyEmail] Envoi EmailJS échoué : $e');
      // Code jamais reçu : on l'annule (et on garde l'ancien s'il existe).
      _otp.rollback(previous);
      if (mounted) {
        setState(() {
          _sending = false;
          _sendError = OtpMessages.sendFailed(l, e);
        });
      }
      return false;
    }
    if (!mounted) return false;

    _code.clear();
    setState(() {
      _sending = false;
      _codeError = null;
    });
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() {});
    });
    return true;
  }

  Future<void> _resendCode() async {
    final ok = await _sendCode();
    if (ok && mounted) AppSnack.info(context, context.l10n.otpNewCodeSent);
  }

  // ---------------------------------------------------------------------------
  // Vérification
  // ---------------------------------------------------------------------------

  Future<void> _verifyCode() async {
    final l = context.l10n;
    final code = _code.text.trim();
    if (code.length != OtpService.codeLength) {
      setState(() => _codeError = l.otpIncomplete);
      return;
    }
    FocusScope.of(context).unfocus();

    final result = _otp.verify(code);
    if (result != OtpVerifyResult.valid) {
      setState(() {
        _codeError = OtpMessages.verifyError(
          l,
          result,
          _otp.session?.attemptsLeft ?? 0,
        );
        if (result != OtpVerifyResult.expired) _code.clear();
      });
      return;
    }

    // Code bon : emailVerified = true en BD, puis accueil.
    _ticker?.cancel();
    setState(() => _saving = true);
    final auth = context.read<AuthProvider>();
    final ok = await auth.markEmailVerified();
    if (!mounted) return;
    setState(() => _saving = false);

    if (ok) {
      _otp.clear();
      AppSnack.success(context, l.verifySuccess);
      context.go(Routes.home);
    } else {
      AppSnack.error(context, l.authError(auth.errorCode));
    }
  }

  // ---------------------------------------------------------------------------
  // Mauvaise adresse saisie à l'inscription
  // ---------------------------------------------------------------------------

  Future<void> _changeEmail() async {
    final auth = context.read<AuthProvider>();
    final newEmail = await showDialog<String>(
      context: context,
      builder: (_) => _ChangeEmailDialog(current: auth.user!.email),
    );
    if (newEmail == null || !mounted) return;

    final ok = await auth.updateProfile(
      auth.user!.copyWith(email: newEmail, emailVerified: false),
    );
    if (!mounted) return;
    if (!ok) {
      AppSnack.error(
        context,
        auth.errorCode == null
            ? context.l10n.commonChangeFailed
            : context.l10n.authError(auth.errorCode),
      );
      return;
    }
    // Nouvelle adresse : l'ancien code ne vaut plus rien.
    _otp.clear();
    _ticker?.cancel();
    setState(() {});
    await _sendCode();
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final session = _otp.session;
    if (user == null) return const SizedBox.shrink();

    return PopScope(
      canPop: false, // pas de retour vers l'app tant que non vérifié
      child: AuthScaffold(
        showBack: false,
        title: l.verifyTitle,
        subtitle: l.verifySubtitle(OtpService.maskEmail(user.email)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (session != null)
              NoticeBox(
                icon: Icons.mark_email_unread_outlined,
                color: AppColors.success,
                title: l.otpEmailSentTitle,
                message: l.otpEmailSentMessage(session.maskedDestination),
              )
            else if (_sending)
              const _SendingBox(),
            if (_sendError != null) ...[
              if (session != null) const SizedBox(height: 12),
              SendErrorBox(message: _sendError!),
            ],
            const SizedBox(height: 18),
            if (session != null)
              OtpCodePanel(
                session: session,
                controller: _code,
                errorText: _codeError,
                sending: _sending || _saving,
                onChanged: (_) {
                  if (_codeError != null) setState(() => _codeError = null);
                },
                onVerify: _verifyCode,
                onResend: _resendCode,
                secondaryLabel: l.verifyChangeEmail,
                onSecondary: _changeEmail,
              )
            else if (!_sending) ...[
              // Premier envoi raté : pas encore de code à saisir.
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _sendCode,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(l.verifyRetrySend),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: _changeEmail,
                  child: Text(l.verifyChangeEmail),
                ),
              ),
            ],
            const SizedBox(height: 18),
            const Divider(),
            Center(
              child: TextButton.icon(
                onPressed: _sending || _saving ? null : auth.logout,
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: Text(l.commonLogout),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SendingBox extends StatelessWidget {
  const _SendingBox();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(strokeWidth: 2.4),
        ),
        const SizedBox(width: 12),
        Text(
          context.l10n.verifySendingCode,
          style: TextStyle(fontSize: 14, color: context.cs.onSurfaceVariant),
        ),
      ],
    );
  }
}

/// Saisie d'une nouvelle adresse (faute de frappe à l'inscription).
class _ChangeEmailDialog extends StatefulWidget {
  const _ChangeEmailDialog({required this.current});

  final String current;

  @override
  State<_ChangeEmailDialog> createState() => _ChangeEmailDialogState();
}

class _ChangeEmailDialogState extends State<_ChangeEmailDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.current);

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, _email.text.trim().toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AlertDialog(
      title: Text(l.verifyChangeEmail),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _email,
          autofocus: true,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: l.verifyNewEmailLabel,
            prefixIcon: const Icon(Icons.mail_outline_rounded),
          ),
          validator: (v) {
            final base = Validators.email(v);
            if (base != null) return base;
            if (v!.trim().toLowerCase() == widget.current.toLowerCase()) {
              return l.verifySameEmail;
            }
            return null;
          },
          onFieldSubmitted: (_) => _submit(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.commonCancel),
        ),
        FilledButton(onPressed: _submit, child: Text(l.verifySendCode)),
      ],
    );
  }
}
