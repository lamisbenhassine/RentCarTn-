import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../state/auth_provider.dart';
import '../../widgets/common.dart';
import 'auth_scaffold.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    await context.read<AuthProvider>().sendResetLink(_email.text);
    if (!mounted) return;
    setState(() => _sent = true);
  }

  @override
  Widget build(BuildContext context) {
    final busy = context.watch<AuthProvider>().busy;

    return AuthScaffold(
      title: _sent ? 'Vérifiez votre boîte mail' : 'Mot de passe oublié',
      subtitle: _sent
          ? 'Un lien de réinitialisation vient d\'être simulé pour '
                '${_email.text.trim()}.'
          : 'Saisissez votre adresse e-mail : nous vous enverrons un lien de '
                'réinitialisation.',
      child: _sent ? _successView() : _formView(busy),
    );
  }

  Widget _formView(bool busy) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Adresse e-mail',
              hintText: 'nom@exemple.tn',
              prefixIcon: Icon(Icons.mail_outline_rounded),
            ),
            validator: Validators.email,
          ),
          const SizedBox(height: 20),
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
                  : const Text('Envoyer le lien'),
            ),
          ),
          const SizedBox(height: 16),
          const NoticeBox(
            message:
                "Aucun e-mail n'est réellement envoyé : cette étape est "
                "simulée pour la démonstration.",
          ),
          const SizedBox(height: 14),
          Center(
            child: TextButton(
              onPressed: () => context.go(Routes.login),
              child: const Text('Retour à la connexion'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _successView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppColors.successSoft,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.success.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.mark_email_read_rounded,
                size: 46,
                color: AppColors.success,
              ),
              const SizedBox(height: 14),
              const Text(
                'Lien envoyé (simulation)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Dans une version connectée à un backend, vous recevriez un "
                "e-mail contenant un lien valable 30 minutes.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: AppColors.textSecondary,
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
            child: const Text('Retour à la connexion'),
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: TextButton(
            onPressed: () => setState(() => _sent = false),
            child: const Text('Modifier l\'adresse e-mail'),
          ),
        ),
      ],
    );
  }
}
