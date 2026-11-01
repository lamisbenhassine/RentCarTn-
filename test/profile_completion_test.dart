import 'package:flutter_test/flutter_test.dart';
import 'package:rentcar_tunisia/data/models/profile_completion.dart';
import 'package:rentcar_tunisia/data/models/user_profile.dart';

void main() {
  const empty = UserProfile(
    id: 'u1',
    firstName: 'A',
    lastName: 'B',
    email: 'a@b.tn',
    phone: '',
  );

  test('profil vide → 0 %, première action = photo', () {
    final c = empty.completion;
    expect(c.percent, 0);
    expect(c.nextStep, ProfileStep.photo);
    expect(c.isComplete, isFalse);
  });

  test('chaque élément compte pareil (12,5 %)', () {
    final c = empty.copyWith(phone: '22345678', cin: '09876543').completion;
    expect(c.doneCount, 2);
    expect(c.percent, 25);
    expect(c.nextStep, ProfileStep.photo);
  });

  test('espaces seuls = non renseigné', () {
    expect(empty.copyWith(address: '   ').completion.percent, 0);
  });

  test('position : latitude ET longitude', () {
    expect(empty.copyWith(latitude: 36.8).completion.percent, 0);
    expect(
      empty.copyWith(latitude: 36.8, longitude: 10.1).completion.percent,
      13,
    );
  });

  test('profil complet → 100 %, aucune action', () {
    final c = empty
        .copyWith(
          avatarUrl: 'data:image/png;base64,AA==',
          phone: '22345678',
          cin: '09876543',
          licenceNumber: 'TN-2015-884512',
          licenceExpiry: DateTime(2030),
          address: '14 rue de Marseille',
          latitude: 36.8,
          longitude: 10.1,
          emailVerified: true,
        )
        .completion;
    expect(c.percent, 100);
    expect(c.isComplete, isTrue);
    expect(c.nextStep, isNull);
  });
}
