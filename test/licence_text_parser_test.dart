import 'package:flutter_test/flutter_test.dart';
import 'package:rentcar_tunisia/data/services/licence_text_parser.dart';

void main() {
  final now = DateTime(2026, 10, 30);

  test('permis tunisien complet (texte latin + arabe)', () {
    const text = '''
REPUBLIQUE TUNISIENNE
الجمهورية التونسية
PERMIS DE CONDUIRE
رخصة السياقة
Nom : BEN AMOR
Né le : 12/06/1994
Délivré le : 18.02.2015
Permis N° 09/884512
Valable jusqu'au : 17-02-2030
''';
    final r = parseLicenceText(text, now: now);
    expect(r.licenceNumber, '09/884512');
    expect(r.expiry, DateTime(2030, 2, 17));
    expect(r.isComplete, isTrue);
    expect(r.isExpired(now: now), isFalse);
  });

  test('date sur la ligne qui suit le mot-clé', () {
    final r = parseLicenceText('Date d\'expiration\n05.09.2031', now: now);
    expect(r.expiry, DateTime(2031, 9, 5));
  });

  test('sans mot-clé : la date la plus tardive', () {
    final r = parseLicenceText('12/06/1994\n18/02/2015\n17/02/2030', now: now);
    expect(r.expiry, DateTime(2030, 2, 17));
  });

  test('une seule date sans mot-clé → pas d’expiration (naissance ?)', () {
    final r = parseLicenceText('Né le 12/06/1994', now: now);
    expect(r.expiry, isNull);
  });

  test('numéro seul, sans date', () {
    final r = parseLicenceText('PERMIS DE CONDUIRE\nN° 12 / 345678', now: now);
    expect(r.licenceNumber, '12/345678');
    expect(r.expiry, isNull);
    expect(r.isComplete, isFalse);
  });

  test('format applicatif TN-2015-884512', () {
    final r = parseLicenceText('Licence: TN 2015 884512', now: now);
    expect(r.licenceNumber, 'TN-2015-884512');
  });

  test('permis expiré', () {
    final r = parseLicenceText('N° 09/884512\nExpire le 01/03/2024', now: now);
    expect(r.isExpired(now: now), isTrue);
  });

  test('dates invalides ignorées (31/02, mois 13)', () {
    final r = parseLicenceText('Valable : 31/02/2030 13/13/2030', now: now);
    expect(r.expiry, isNull);
  });

  test('texte sans information', () {
    final r = parseLicenceText('Bonjour\nmerci', now: now);
    expect(r.isEmpty, isTrue);
  });
}
