import 'package:flutter_test/flutter_test.dart';
import 'package:rentcar_tunisia/features/complaints/complaint_notifications.dart';

void main() {
  test('identifiant stable, distinct pour l\'alerte urgente', () {
    final a = ComplaintNotifications.idFor('cmp-1');
    expect(ComplaintNotifications.idFor('cmp-1'), a);
    expect(ComplaintNotifications.idFor('cmp-1', urgent: true), a + 1);
    expect(a, inInclusiveRange(500000, 700000));
    expect(a.isEven, isTrue);
  });
}
