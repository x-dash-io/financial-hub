import 'package:flutter_test/flutter_test.dart';
import 'package:financial_hub/core/sms_parser.dart';

void main() {
  group('MpesaSmsParser', () {
    test('isValidSender accepts exactly MPESA', () {
      expect(MpesaSmsParser.isValidSender('MPESA'), true);
    });
    test('isValidSender rejects lowercase and variants', () {
      expect(MpesaSmsParser.isValidSender('mpesa'), false);
      expect(MpesaSmsParser.isValidSender('M-PESA'), false);
      expect(MpesaSmsParser.isValidSender('M-Pesa'), false);
    });
    test('parse requires Confirmed. You have received', () {
      expect(MpesaSmsParser.parse('You have received Ksh 1,500.00'), isNull);
    });
    test('parse requires Ksh amount pattern', () {
      expect(
        MpesaSmsParser.parse(
          'Confirmed. You have received KES 1,500 from X. Ref ABC123',
        ),
        isNull,
      );
    });
    test('parse requires reference', () {
      expect(
        MpesaSmsParser.parse(
          'Confirmed. You have received Ksh 1,500.00 from JOHN. No ref here.',
        ),
        isNull,
      );
    });
    test('parse extracts amount and reference from valid SMS', () {
      final body =
          'Confirmed. You have received Ksh 1,500.00 from JOHN DOE on 21/2/25. Ref ABC12XYZ.';
      final r = MpesaSmsParser.parse(body);
      expect(r, isNotNull);
      expect(r!.amount, 1500);
      expect(r.reference, isNotEmpty);
      expect(r.sender, 'MPESA');
      expect(r.timestamp, isNotNull);
    });
    test('parse accepts AGT-style reference', () {
      final body =
          'Confirmed. You have received Ksh 500.00 from 254712345678. AGT1234567890';
      final r = MpesaSmsParser.parse(body);
      expect(r, isNotNull);
      expect(r!.amount, 500);
      expect(r.reference, isNotEmpty);
    });
  });
}
