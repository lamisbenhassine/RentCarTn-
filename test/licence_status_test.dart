import 'package:flutter_test/flutter_test.dart';
import 'package:rentcar_tunisia/data/models/licence_status.dart';
import 'package:rentcar_tunisia/data/models/user_profile.dart';

void main() {
  final today = DateTime(2026, 10, 28, 15, 30);

  UserProfile withExpiry(DateTime? expiry) => UserProfile(
    id: 'u1',
    firstName: 'A',
    lastName: 'B',
    email: 'a@b.tn',
    phone: '22345678',
    licenceExpiry: expiry,
  );

  test('date inconnue → unknown, jamais bloquant', () {
    final u = withExpiry(null);
    expect(u.licenceStatus(now: today), LicenceStatus.unknown);
    expect(u.licenceValidUntil(DateTime(2030)), isTrue);
  });

  test('plus de 30 jours → valide', () {
    final u = withExpiry(DateTime(2026, 11, 28));
    expect(u.daysUntilLicenceExpiry(now: today), 31);
    expect(u.licenceStatus(now: today), LicenceStatus.valid);
  });

  test('30 jours ou moins (aujourd’hui inclus) → expire bientôt', () {
    expect(
      withExpiry(DateTime(2026, 11, 27)).licenceStatus(now: today),
      LicenceStatus.expiringSoon,
    );
    expect(
      withExpiry(DateTime(2026, 10, 28)).licenceStatus(now: today),
      LicenceStatus.expiringSoon,
    );
  });

  test('veille → expiré', () {
    final u = withExpiry(DateTime(2026, 10, 27));
    expect(u.daysUntilLicenceExpiry(now: today), -1);
    expect(u.licenceStatus(now: today), LicenceStatus.expired);
  });

  test('valable jusqu’au jour d’expiration inclus', () {
    final u = withExpiry(DateTime(2026, 11, 10));
    expect(u.licenceValidUntil(DateTime(2026, 11, 10)), isTrue);
    expect(u.licenceValidUntil(DateTime(2026, 11, 11)), isFalse);
  });
}
