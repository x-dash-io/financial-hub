import 'dart:async';
import 'package:sms_advanced/sms_advanced.dart';
import 'package:financial_hub/core/sms_parser.dart';

typedef OnIncomeParsed = void Function(ParsedIncome income);

/// Listens for MPESA income SMS. Sender must be exactly "MPESA".
/// Never persists raw SMS body; only parsed fields passed to callback.
class SmsIncomeListener {
  SmsReceiver? _receiver;
  StreamSubscription? _sub;

  void start(OnIncomeParsed onParsed) {
    if (_receiver != null) return;
    _receiver = SmsReceiver();
    final stream = _receiver!.onSmsReceived;
    if (stream == null) return;
    _sub = stream.listen((SmsMessage msg) {
      if (!MpesaSmsParser.isValidSender(msg.address)) return;
      final ts = msg.date ?? msg.dateSent ?? DateTime.now();
      final parsed = MpesaSmsParser.parse(msg.body ?? '', timestamp: ts);
      if (parsed != null) onParsed(parsed);
    });
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
    _receiver = null;
  }
}
