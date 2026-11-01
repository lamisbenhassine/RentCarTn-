import 'package:flutter_test/flutter_test.dart';
import 'package:rentcar_tunisia/data/services/otp_service.dart';

void main() {
  group('OtpService', () {
    test('masque e-mail et téléphone', () {
      expect(OtpService.maskEmail('tayechi@gmail.com'), 't***@gmail.com');
      expect(OtpService.maskPhone('22 345 678'), '+216 ** *** 678');
      expect(OtpService.maskPhone('+216 22345678'), '+216 ** *** 678');
    });

    test('code correct accepté', () {
      final otp = OtpService();
      final s = otp.issue(
        userId: 'u1',
        channel: OtpChannel.email,
        destination: 'a@b.tn',
      );
      expect(s.plainCode, hasLength(6));
      expect(otp.verify(s.plainCode), OtpVerifyResult.valid);
      expect(s.verified, isTrue);
    });

    test('3 codes faux invalident le code', () {
      final otp = OtpService();
      final s = otp.issue(
        userId: 'u1',
        channel: OtpChannel.sms,
        destination: '22345678',
      );
      final wrong = s.plainCode == '000000' ? '111111' : '000000';
      expect(otp.verify(wrong), OtpVerifyResult.wrongCode);
      expect(otp.verify(wrong), OtpVerifyResult.wrongCode);
      expect(otp.verify(wrong), OtpVerifyResult.tooManyAttempts);
      // Même le bon code est refusé ensuite.
      expect(otp.verify(s.plainCode), OtpVerifyResult.tooManyAttempts);
    });

    test('renvoi bloqué pendant 60 s, code valable 5 min', () {
      final otp = OtpService();
      final s = otp.issue(
        userId: 'u1',
        channel: OtpChannel.email,
        destination: 'a@b.tn',
      );
      expect(s.canResend, isFalse);
      expect(s.timeLeft.inSeconds, inInclusiveRange(299, 300));
      expect(s.resendIn.inSeconds, inInclusiveRange(59, 60));
    });
  });
}
