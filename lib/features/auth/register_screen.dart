import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../core/utils/validators.dart';
import '../../data/mock/mock_cars.dart';
import '../../state/auction_provider.dart';
import '../../state/auth_provider.dart';
import '../../widgets/common.dart';
import 'auth_scaffold.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  String _city = 'Tunis';
  bool _obscure = true;
  bool _obscureConfirm = true;
  bool _acceptTerms = false;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptTerms) {
      AppSnack.error(
        context,
        "Vous devez accepter les conditions d'utilisation.",
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final ok = await auth.register(
      firstName: _firstName.text,
      lastName: _lastName.text,
      email: _email.text,
      phone: _phone.text,
      password: _password.text,
      city: _city,
    );
    if (!mounted) return;

    if (ok) {
      context.read<AuctionProvider>().setUsername(auth.publicUsername);
      AppSnack.success(context, 'Compte créé avec succès. Bienvenue !');
      context.go(Routes.home);
    } else {
      AppSnack.error(context, auth.error ?? 'Inscription impossible.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = context.watch<AuthProvider>().busy;
    final wide = Responsive.isWide(context);

    return AuthScaffold(
      title: 'Créer votre compte',
      subtitle:
          'Quelques informations suffisent pour réserver votre première '
          'voiture.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (wide)
              Row(
                children: [
                  Expanded(child: _firstNameField()),
                  const SizedBox(width: 14),
                  Expanded(child: _lastNameField()),
                ],
              )
            else ...[
              _firstNameField(),
              const SizedBox(height: 16),
              _lastNameField(),
            ],
            const SizedBox(height: 16),
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
            const SizedBox(height: 16),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Téléphone',
                hintText: '22 345 678',
                prefixText: '+216 ',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              validator: Validators.phone,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _city,
              decoration: const InputDecoration(
                labelText: 'Ville',
                prefixIcon: Icon(Icons.place_outlined),
              ),
              items: [
                for (final city in MockCars.villes)
                  DropdownMenuItem(value: city, child: Text(city)),
              ],
              onChanged: (v) => setState(() => _city = v ?? 'Tunis'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _password,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: 'Mot de passe',
                helperText: '6 caractères minimum, lettres et chiffres',
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
            _PasswordStrength(password: _password.text),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirm,
              obscureText: _obscureConfirm,
              decoration: InputDecoration(
                labelText: 'Confirmer le mot de passe',
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
              validator: (v) =>
                  Validators.confirmPassword(v, _password.text),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: _acceptTerms,
                  onChanged: (v) => setState(() => _acceptTerms = v ?? false),
                ),
                const Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Text(
                      "J'accepte les conditions générales de location et la "
                      "politique de confidentialité.",
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
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
                    : const Text('Créer mon compte'),
              ),
            ),
            const SizedBox(height: 16),
            const NoticeBox(
              message:
                  "Démonstration : le compte est créé en mémoire locale. "
                  "Aucune donnée n'est envoyée ni conservée après fermeture "
                  "de l'application.",
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Déjà inscrit ?',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                TextButton(
                  onPressed: () => context.go(Routes.login),
                  child: const Text('Se connecter'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _firstNameField() => TextFormField(
    controller: _firstName,
    textCapitalization: TextCapitalization.words,
    decoration: const InputDecoration(
      labelText: 'Prénom',
      prefixIcon: Icon(Icons.person_outline_rounded),
    ),
    validator: Validators.name,
  );

  Widget _lastNameField() => TextFormField(
    controller: _lastName,
    textCapitalization: TextCapitalization.words,
    decoration: const InputDecoration(labelText: 'Nom'),
    validator: Validators.name,
  );
}

class _PasswordStrength extends StatelessWidget {
  const _PasswordStrength({required this.password});

  final String password;

  int get _score {
    var score = 0;
    if (password.length >= 6) score++;
    if (password.length >= 10) score++;
    if (password.contains(RegExp(r'\d')) &&
        password.contains(RegExp(r'[A-Za-z]'))) {
      score++;
    }
    if (password.contains(RegExp(r'[^A-Za-z0-9]'))) score++;
    return score;
  }

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox.shrink();

    final score = _score;
    final (label, color) = switch (score) {
      <= 1 => ('Faible', AppColors.danger),
      2 => ('Moyen', AppColors.warning),
      3 => ('Bon', AppColors.info),
      _ => ('Excellent', AppColors.success),
    };

    return Row(
      children: [
        for (var i = 0; i < 4; i++)
          Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(right: i == 3 ? 0 : 5),
              decoration: BoxDecoration(
                color: i < score ? color : AppColors.border,
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}
