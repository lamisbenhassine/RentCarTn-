import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/validators.dart';
import '../../l10n/l10n.dart';
import '../../state/auth_provider.dart';
import '../../widgets/common.dart';
import '../auth/password_strength.dart';

/// Ouvre la feuille « Changer le mot de passe » (ancien + nouveau +
/// confirmation). Le nouveau mot de passe est enregistré haché en BD.
Future<void> showChangePasswordSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const _ChangePasswordSheet(),
  );
}

class _ChangePasswordSheet extends StatefulWidget {
  const _ChangePasswordSheet();

  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  bool _obscure = true;
  String? _currentError;

  @override
  void dispose() {
    _current.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() => _currentError = null);
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final ok = await auth.changePassword(
      currentPassword: _current.text,
      newPassword: _password.text,
    );
    if (!mounted) return;

    final l = context.l10n;
    if (ok) {
      Navigator.pop(context);
      AppSnack.success(context, l.changePwdDone);
    } else {
      setState(() {
        _currentError = auth.errorCode == null
            ? l.commonChangeFailed
            : l.authError(auth.errorCode);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final busy = context.watch<AuthProvider>().busy;
    final eye = IconButton(
      onPressed: () => setState(() => _obscure = !_obscure),
      icon: Icon(
        _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
      ),
    );

    return Padding(
      // Remonte la feuille au-dessus du clavier.
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.changePwdTitle,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: context.cs.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l.changePwdSubtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: context.cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _current,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: l.changePwdCurrent,
                  prefixIcon: const Icon(Icons.lock_clock_outlined),
                  suffixIcon: eye,
                  errorText: _currentError,
                ),
                validator: (v) => (v == null || v.isEmpty)
                    ? l.changePwdCurrentRequired
                    : null,
                onChanged: (_) {
                  if (_currentError != null) {
                    setState(() => _currentError = null);
                  }
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _password,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: l.commonNewPassword,
                  helperText: l.commonPasswordHelper,
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                ),
                validator: (v) {
                  final base = Validators.password(v);
                  if (base != null) return base;
                  if (v == _current.text) return l.changePwdMustDiffer;
                  return null;
                },
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 10),
              PasswordStrength(password: _password.text),
              const SizedBox(height: 14),
              TextFormField(
                controller: _confirm,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: l.changePwdConfirm,
                  prefixIcon: const Icon(Icons.lock_reset_rounded),
                ),
                validator: (v) => Validators.confirmPassword(v, _password.text),
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
                      : Text(l.commonSave),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
