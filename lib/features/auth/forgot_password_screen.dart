import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/validators.dart';
import '../../data/models/user_profile.dart';
import '../../data/services/email_service.dart';
import '../../data/services/otp_service.dart';
import '../../l10n/l10n.dart';
import '../../state/auth_provider.dart';
import '../../widgets/common.dart';
import 'auth_scaffold.dart';
import 'otp_code_panel.dart';
import 'password_strength.dart';

/// Mot de passe oublié en parcours OTP :
/// canal + identifiant → code à 6 chiffres → nouveau mot de passe → succès.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

enum _Step { identify, code, password, success }

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  static const _redirectSeconds = 5;

  final _otp = OtpService();
  final _emailService = EmailService();
  final _identifyKey = GlobalKey<FormState>();
  final _passwordKey = GlobalKey<FormState>();

  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  _Step _step = _Step.identify;
  OtpChannel _channel = OtpChannel.email;
  UserProfile? _account;

  bool _accountNotFound = false;
  String? _codeError;

  /// Envoi EmailJS en cours / dernier échec d'envoi.
  bool _sending = false;
  String? _sendError;

  bool _obscure = true;
  bool _obscureConfirm = true;

  /// Rafraîchit les comptes à rebours (expiration, renvoi, redirection).
  Timer? _ticker;
  int _redirectIn = _redirectSeconds;

  @override
  void dispose() {
    _ticker?.cancel();
    _email.dispose();
    _phone.dispose();
    _code.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _startTicker(void Function() onTick) {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      setState(onTick);
    });
  }

  // ---------------------------------------------------------------------------
  // Étape 1 : compte + envoi du code
  // ---------------------------------------------------------------------------

  Future<void> _sendCode() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _accountNotFound = false;
      _sendError = null;
    });
    if (!_identifyKey.currentState!.validate()) return;

    final byEmail = _channel == OtpChannel.email;
    final user = await context.read<AuthProvider>().findAccountForReset(
      email: byEmail ? _email.text : null,
      phone: byEmail ? null : _phone.text,
    );
    if (!mounted) return;

    if (user == null) {
      setState(() => _accountNotFound = true);
      return;
    }
    _account = user;
    await _issueCode();
  }

  /// Génère un code et l'envoie. E-mail → EmailJS ; SMS → mode démo
  /// (code affiché à l'écran). Retourne `false` si l'envoi a échoué.
  Future<bool> _issueCode() async {
    final l = context.l10n;
    final user = _account!;
    final previous = _otp.session;
    final session = _otp.issue(
      userId: user.id,
      channel: _channel,
      destination: _channel == OtpChannel.email ? user.email : user.phone,
    );

    if (_channel == OtpChannel.email) {
      setState(() {
        _sending = true;
        _sendError = null;
      });
      try {
        await _emailService.sendOtp(user.email, session.plainCode);
      } on EmailSendException catch (e) {
        debugPrint('[ForgotPassword] Envoi EmailJS échoué : $e');
        // Code jamais reçu : on l'annule et on garde l'éventuel précédent.
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
    }

    _code.clear();
    setState(() {
      _sending = false;
      _codeError = null;
      _step = _Step.code;
    });
    _startTicker(() {});
    return true;
  }

  // ---------------------------------------------------------------------------
  // Étape 2 : vérification du code
  // ---------------------------------------------------------------------------

  void _verifyCode() {
    final l = context.l10n;
    final code = _code.text.trim();
    if (code.length != OtpService.codeLength) {
      setState(() => _codeError = l.otpIncomplete);
      return;
    }
    FocusScope.of(context).unfocus();

    final result = _otp.verify(code);
    setState(() {
      switch (result) {
        case OtpVerifyResult.valid:
          _ticker?.cancel();
          _codeError = null;
          _step = _Step.password;
        case OtpVerifyResult.noCode:
          _step = _Step.identify;
        default:
          _codeError = OtpMessages.verifyError(
            l,
            result,
            _otp.session!.attemptsLeft,
          );
          if (result != OtpVerifyResult.expired) _code.clear();
      }
    });
  }

  Future<void> _resendCode() async {
    final ok = await _issueCode();
    if (ok && mounted) AppSnack.info(context, context.l10n.otpNewCodeSent);
  }

  void _changeMethod() {
    _ticker?.cancel();
    _otp.clear();
    _code.clear();
    setState(() {
      _codeError = null;
      _sendError = null;
      _step = _Step.identify;
    });
  }

  // ---------------------------------------------------------------------------
  // Étape 3 : nouveau mot de passe
  // ---------------------------------------------------------------------------

  Future<void> _savePassword() async {
    FocusScope.of(context).unfocus();
    if (!_passwordKey.currentState!.validate()) return;
    // Sécurité : on n'enregistre que si le code a bien été validé.
    if (_otp.session?.verified != true || _account == null) {
      _changeMethod();
      return;
    }

    await context.read<AuthProvider>().resetPassword(_account!, _password.text);
    if (!mounted) return;

    _otp.clear();
    setState(() {
      _step = _Step.success;
      _redirectIn = _redirectSeconds;
    });
    _startTicker(() {
      _redirectIn--;
      if (_redirectIn <= 0) {
        _ticker?.cancel();
        context.go(Routes.login);
      }
    });
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final busy = context.watch<AuthProvider>().busy;
    final session = _otp.session;
    final destination = session?.maskedDestination ?? '';

    final (title, subtitle) = switch (_step) {
      _Step.identify => (l.forgotTitle, l.forgotSubtitle),
      _Step.code => (
        l.forgotCodeTitle,
        _channel == OtpChannel.email
            ? l.forgotCodeSubtitleEmail(destination)
            : l.forgotCodeSubtitleSms(destination),
      ),
      _Step.password => (l.commonNewPassword, l.forgotPasswordSubtitle),
      _Step.success => (l.forgotSuccessTitle, l.forgotSuccessSubtitle),
    };

    return PopScope(
      // Retour Android : revient au choix de la méthode au lieu de quitter.
      canPop: _step == _Step.identify || _step == _Step.success,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _changeMethod();
      },
      child: AuthScaffold(
        title: title,
        subtitle: subtitle,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: KeyedSubtree(
            key: ValueKey(_step),
            child: switch (_step) {
              _Step.identify => _identifyView(busy),
              _Step.code => _codeView(session!),
              _Step.password => _passwordView(busy),
              _Step.success => _successView(),
            },
          ),
        ),
      ),
    );
  }

  Widget _identifyView(bool busy) {
    final l = context.l10n;
    final byEmail = _channel == OtpChannel.email;
    return Form(
      key: _identifyKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<OtpChannel>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                  value: OtpChannel.email,
                  icon: const Icon(Icons.mail_outline_rounded),
                  label: Text(l.forgotChannelEmail),
                ),
                ButtonSegment(
                  value: OtpChannel.sms,
                  icon: const Icon(Icons.sms_outlined),
                  label: Text(l.forgotChannelSms),
                ),
              ],
              selected: {_channel},
              onSelectionChanged: (s) => setState(() {
                _channel = s.first;
                _accountNotFound = false;
              }),
            ),
          ),
          const SizedBox(height: 18),
          if (byEmail)
            TextFormField(
              key: const ValueKey('email'),
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: l.forgotAccountEmail,
                hintText: l.commonEmailHint,
                prefixIcon: const Icon(Icons.mail_outline_rounded),
                errorText: _accountNotFound ? l.forgotNoAccountEmail : null,
              ),
              validator: Validators.email,
              onChanged: (_) => _clearAccountError(),
            )
          else
            TextFormField(
              key: const ValueKey('phone'),
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: l.forgotAccountPhone,
                hintText: '22 345 678',
                prefixText: '+216 ',
                prefixIcon: const Icon(Icons.phone_outlined),
                errorText: _accountNotFound ? l.forgotNoAccountPhone : null,
              ),
              validator: Validators.phone,
              onChanged: (_) => _clearAccountError(),
            ),
          if (_accountNotFound)
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                onPressed: () => context.go(Routes.register),
                child: Text(l.commonCreateAccount),
              ),
            ),
          const SizedBox(height: 20),
          if (_sendError != null) ...[
            SendErrorBox(message: _sendError!),
            const SizedBox(height: 14),
          ],
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: busy || _sending ? null : _sendCode,
              child: busy || _sending
                  ? const _ButtonLoader()
                  : Text(l.forgotReceiveCode),
            ),
          ),
          if (_sending) ...[
            const SizedBox(height: 10),
            Center(
              child: Text(
                l.forgotSendingEmail,
                style: TextStyle(fontSize: 12.5, color: context.cs.outline),
              ),
            ),
          ],
          const SizedBox(height: 16),
          NoticeBox(message: byEmail ? l.forgotEmailNotice : l.forgotSmsNotice),
          const SizedBox(height: 14),
          Center(
            child: TextButton(
              onPressed: () => context.go(Routes.login),
              child: Text(l.forgotBackToLogin),
            ),
          ),
        ],
      ),
    );
  }

  void _clearAccountError() {
    if (_accountNotFound) setState(() => _accountNotFound = false);
  }

  Widget _codeView(OtpSession session) {
    final l = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (session.channel == OtpChannel.email)
          NoticeBox(
            icon: Icons.mark_email_unread_outlined,
            color: AppColors.success,
            title: l.otpEmailSentTitle,
            message: l.otpEmailSentMessage(session.maskedDestination),
          )
        else
          NoticeBox(
            icon: Icons.science_outlined,
            color: AppColors.accent,
            title: l.forgotSmsDemoTitle,
            message:
                '${session.plainCode.substring(0, 3)} '
                '${session.plainCode.substring(3)}\n'
                '${l.forgotSmsDemoFooter}',
          ),
        if (_sendError != null) ...[
          const SizedBox(height: 12),
          SendErrorBox(message: _sendError!),
        ],
        const SizedBox(height: 18),
        OtpCodePanel(
          session: session,
          controller: _code,
          errorText: _codeError,
          sending: _sending,
          onChanged: (_) {
            if (_codeError != null) setState(() => _codeError = null);
          },
          onVerify: _verifyCode,
          onResend: _resendCode,
          secondaryLabel: l.forgotChangeMethod,
          onSecondary: _changeMethod,
        ),
      ],
    );
  }

  Widget _passwordView(bool busy) {
    final l = context.l10n;
    return Form(
      key: _passwordKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _password,
            obscureText: _obscure,
            decoration: InputDecoration(
              labelText: l.commonNewPassword,
              helperText: l.commonPasswordHelper,
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(
                  _obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
            validator: Validators.password,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 10),
          PasswordStrength(password: _password.text),
          const SizedBox(height: 16),
          TextFormField(
            controller: _confirm,
            obscureText: _obscureConfirm,
            decoration: InputDecoration(
              labelText: l.commonConfirmPassword,
              prefixIcon: const Icon(Icons.lock_reset_rounded),
              suffixIcon: IconButton(
                onPressed: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
                icon: Icon(
                  _obscureConfirm
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
            validator: (v) => Validators.confirmPassword(v, _password.text),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: busy ? null : _savePassword,
              child: busy ? const _ButtonLoader() : Text(l.forgotSavePassword),
            ),
          ),
        ],
      ),
    );
  }

  Widget _successView() {
    final l = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.verified_user_rounded,
                size: 46,
                color: AppColors.success,
              ),
              const SizedBox(height: 14),
              Text(
                l.forgotResetDone,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: context.cs.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l.forgotResetDoneMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: context.cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => context.go(Routes.login),
            child: Text(l.commonLogin),
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: Text(
            l.forgotRedirectIn(_redirectIn),
            style: TextStyle(fontSize: 12.5, color: context.cs.outline),
          ),
        ),
      ],
    );
  }
}

class _ButtonLoader extends StatelessWidget {
  const _ButtonLoader();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 22,
      width: 22,
      child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
    );
  }
}
