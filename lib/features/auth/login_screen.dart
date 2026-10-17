import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/validators.dart';
import '../../data/mock/mock_users.dart';
import '../../state/auction_provider.dart';
import '../../state/auth_provider.dart';
import '../../widgets/common.dart';
import 'auth_scaffold.dart';

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

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final ok = await auth.login(_emailCtrl.text, _passwordCtrl.text);
    if (!mounted) return;

    if (ok) {
      context.read<AuctionProvider>().setUsername(auth.publicUsername);
      AppSnack.success(context, 'Bienvenue ${auth.user!.firstName} !');
      context.go(Routes.home);
    } else {
      AppSnack.error(context, auth.error ?? 'Connexion impossible.');
    }
  }

  void _fillDemo() {
    _emailCtrl.text = MockUsers.demoEmail;
    _passwordCtrl.text = MockUsers.demoPassword;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final busy = context.watch<AuthProvider>().busy;

    return AuthScaffold(
      title: 'Content de vous revoir',
      subtitle: 'Connectez-vous pour gérer vos locations et vos enchères.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(
                labelText: 'Adresse e-mail',
                hintText: 'nom@exemple.tn',
                prefixIcon: Icon(Icons.mail_outline_rounded),
              ),
              validator: Validators.email,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordCtrl,
              obscureText: _obscure,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => busy ? null : _submit(),
              decoration: InputDecoration(
                labelText: 'Mot de passe',
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
              validator: (v) => (v == null || v.isEmpty)
                  ? 'Le mot de passe est obligatoire'
                  : null,
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Checkbox(
                  value: _remember,
                  onChanged: (v) => setState(() => _remember = v ?? false),
                ),
                const Text(
                  'Se souvenir de moi',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => context.push(Routes.forgotPassword),
                  child: const Text('Mot de passe oublié ?'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: busy ? null : _submit,
                child: busy
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Se connecter'),
              ),
            ),
            const SizedBox(height: 18),
            _DemoHint(onFill: _fillDemo),
            const SizedBox(height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Pas encore de compte ?',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                TextButton(
                  onPressed: () => context.push(Routes.register),
                  child: const Text('Créer un compte'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DemoHint extends StatelessWidget {
  const _DemoHint({required this.onFill});

  final VoidCallback onFill;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.navy.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.science_outlined,
            size: 19,
            color: AppColors.accent,
          ),
          const SizedBox(width: 11),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Compte de démonstration',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  '${MockUsers.demoEmail} · ${MockUsers.demoPassword}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          TextButton(onPressed: onFill, child: const Text('Remplir')),
        ],
      ),
    );
  }
}
