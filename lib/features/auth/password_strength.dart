import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/l10n.dart';

/// Barre de force du mot de passe (4 segments + libellé).
/// Partagée entre l'inscription et la réinitialisation.
class PasswordStrength extends StatelessWidget {
  const PasswordStrength({super.key, required this.password});

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
    final l = context.l10n;
    final (label, color) = switch (score) {
      <= 1 => (l.strengthWeak, AppColors.danger),
      2 => (l.strengthMedium, AppColors.warning),
      3 => (l.strengthGood, AppColors.info),
      _ => (l.strengthExcellent, AppColors.success),
    };

    return Row(
      children: [
        for (var i = 0; i < 4; i++)
          Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(right: i == 3 ? 0 : 5),
              decoration: BoxDecoration(
                color: i < score ? color : context.cs.outlineVariant,
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
