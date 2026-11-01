import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/locale_provider.dart';

/// Sélecteur FR / EN / عربي. Chaque libellé est écrit dans sa propre
/// langue : il reste le même quelle que soit la langue de l'app.
class LanguageSelector extends StatelessWidget {
  const LanguageSelector({super.key, this.compact = false});

  /// Version réduite (écran de connexion).
  final bool compact;

  static const _labels = {'fr': 'FR', 'en': 'EN', 'ar': 'عربي'};

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LocaleProvider>();

    return SegmentedButton<String>(
      showSelectedIcon: false,
      style: compact
          ? const ButtonStyle(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            )
          : null,
      segments: [
        for (final code in LocaleProvider.supportedCodes)
          ButtonSegment(value: code, label: Text(_labels[code]!)),
      ],
      selected: {provider.locale.languageCode},
      onSelectionChanged: (s) => provider.setLocale(s.first),
    );
  }
}
