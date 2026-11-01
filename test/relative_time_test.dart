import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:rentcar_tunisia/core/utils/relative_time.dart';
import 'package:rentcar_tunisia/l10n/app_localizations.dart';

void main() {
  final fr = lookupAppLocalizations(const Locale('fr'));
  final now = DateTime(2026, 10, 30, 15, 0);

  // Formats de date (fait par main() dans l'app).
  setUpAll(() => initializeDateFormatting());

  String rel(DateTime d) => relativeTime(fr, d, now: now);

  test('secondes, minutes, heures', () {
    expect(rel(now.subtract(const Duration(seconds: 20))), 'à l\'instant');
    expect(rel(now.subtract(const Duration(minutes: 5))), 'il y a 5 min');
    expect(rel(now.subtract(const Duration(hours: 1))), 'il y a 1 heure');
    expect(rel(now.subtract(const Duration(hours: 3))), 'il y a 3 heures');
  });

  test('jours calendaires : hier, il y a 2 jours', () {
    expect(rel(DateTime(2026, 10, 29, 9)), 'hier');
    expect(rel(DateTime(2026, 10, 28, 20)), 'il y a 2 jours');
  });

  test('au-delà de 30 jours : la date', () {
    expect(rel(DateTime(2026, 8, 1)), isNot(contains('il y a')));
  });
}
