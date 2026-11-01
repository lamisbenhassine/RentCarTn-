import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/validators.dart';
import '../../data/repositories/auth_repository.dart';
import '../../l10n/l10n.dart';
import '../../state/auction_provider.dart';
import '../../state/auth_provider.dart';
import '../../widgets/common.dart';
import '../../widgets/language_selector.dart';
import 'auth_scaffold.dart';
import 'google_sign_in_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  bool _remember = true;

  /// Rafraîchit le compte à rebours chaque seconde pendant le blocage.
  Timer? _lockTicker;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      if (auth.isLocked) {
        _startLockTicker();
      } else {
        auth.clearError(); // pas d'ancienne erreur en revenant sur l'écran
      }
    });
  }

  @override
  void dispose() {
    _lockTicker?.cancel();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _startLockTicker() {
    _lockTicker?.cancel();
    _lockTicker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      final auth = context.read<AuthProvider>();
      if (!auth.isLocked) {
        timer.cancel();
        auth.clearError();
      }
      setState(() {});
    });
  }

  /// Efface l'erreur affichée dès que l'utilisateur corrige sa saisie.
  void _onFieldChanged(String _) {
    final auth = context.read<AuthProvider>();
    if (!auth.isLocked) auth.clearError();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final ok = await auth.login(
      _emailCtrl.text,
      _passwordCtrl.text,
      remember: _remember,
    );
    if (!mounted) return;

    if (ok) {
      context.read<AuctionProvider>().setUsername(
        auth.publicUsername,
        userId: auth.user?.id,
      );
      if (auth.needsEmailVerification) {
        // Compte jamais vérifié : on envoie un code avant d'ouvrir l'app.
        AppSnack.info(context, context.l10n.loginVerifyEmailFirst);
        context.go(Routes.verifyEmail);
        return;
      }
      AppSnack.success(
        context,
        context.l10n.loginWelcome(auth.user!.firstName),
      );
      context.go(Routes.home);
    } else if (auth.isLocked) {
      _passwordCtrl.clear();
      _startLockTicker();
    }
    // Les autres erreurs s'affichent dans le formulaire (_LoginAlert).
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final auth = context.watch<AuthProvider>();
    final busy = auth.busy;
    final locked = auth.isLocked;
    final code = auth.errorCode;
    final secondsLeft = (auth.lockRemaining.inMilliseconds / 1000).ceil();

    // Seules les erreurs de connexion s'affichent ici (pas celles du profil).
    final loginError = locked
        ? AuthErrorCode.locked
        : (code == AuthErrorCode.accountNotFound ||
              code == AuthErrorCode.wrongPassword)
        ? code
        : null;

    return AuthScaffold(
      title: l.loginTitle,
      subtitle: l.loginSubtitle,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Align(
              alignment: AlignmentDirectional.centerEnd,
              child: LanguageSelector(compact: true),
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              enabled: !locked,
              decoration: InputDecoration(
                labelText: l.commonEmail,
                hintText: l.commonEmailHint,
                prefixIcon: const Icon(Icons.mail_outline_rounded),
                errorText: code == AuthErrorCode.accountNotFound
                    ? l.loginNoAccountWithEmail
                    : null,
              ),
              validator: Validators.email,
              onChanged: _onFieldChanged,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordCtrl,
              obscureText: _obscure,
              textInputAction: TextInputAction.done,
              enabled: !locked,
              onChanged: _onFieldChanged,
              onFieldSubmitted: (_) => busy || locked ? null : _submit(),
              decoration: InputDecoration(
                labelText: l.commonPassword,
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                errorText: code == AuthErrorCode.wrongPassword
                    ? l.loginWrongPassword
                    : null,
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              validator: Validators.passwordRequired,
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Checkbox(
                  value: _remember,
                  onChanged: (v) => setState(() => _remember = v ?? false),
                ),
                Flexible(
                  child: Text(
                    l.loginRememberMe,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: context.cs.onSurfaceVariant,
                    ),
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => context.push(Routes.forgotPassword),
                  child: Text(l.loginForgotPassword),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (loginError != null) ...[
              _LoginAlert(
                code: loginError,
                attemptsLeft: auth.attemptsLeft,
                secondsLeft: secondsLeft,
              ),
              const SizedBox(height: 14),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: busy || locked ? null : _submit,
                child: busy
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        locked ? l.loginRetryIn(secondsLeft) : l.commonLogin,
                      ),
              ),
            ),
            const SizedBox(height: 18),
            const OrDivider(),
            const SizedBox(height: 18),
            const GoogleSignInButton(),
            const SizedBox(height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  l.loginNoAccountYet,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: context.cs.onSurfaceVariant,
                  ),
                ),
                TextButton(
                  onPressed: () => context.push(Routes.register),
                  child: Text(l.commonCreateAccount),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Message d'erreur détaillé sous le formulaire de connexion.
class _LoginAlert extends StatelessWidget {
  const _LoginAlert({
    required this.code,
    required this.attemptsLeft,
    required this.secondsLeft,
  });

  final AuthErrorCode code;
  final int attemptsLeft;
  final int secondsLeft;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final tries = l.loginAttemptsLeft(attemptsLeft);

    return switch (code) {
      AuthErrorCode.accountNotFound => NoticeBox(
        icon: Icons.person_off_outlined,
        color: AppColors.danger,
        title: l.loginAccountNotFoundTitle,
        message: l.loginAccountNotFoundMessage(tries),
      ),
      AuthErrorCode.wrongPassword => NoticeBox(
        icon: Icons.lock_outline_rounded,
        color: AppColors.danger,
        title: l.loginWrongPassword,
        message: l.loginWrongPasswordMessage(tries),
      ),
      _ => NoticeBox(
        icon: Icons.timer_outlined,
        color: AppColors.warning,
        title: l.loginLockedTitle,
        message: l.loginLockedMessage(
          '0:${secondsLeft.toString().padLeft(2, '0')}',
        ),
      ),
    };
  }
}
