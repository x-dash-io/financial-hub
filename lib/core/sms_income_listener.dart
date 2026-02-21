import 'dart:async';
import 'package:flutter/services.dart';
import 'package:sms_advanced/sms_advanced.dart';
import 'package:financial_hub/core/sms_parser.dart';

typedef OnIncomeParsed = void Function(ParsedIncome income);

/// Listens for MPESA income SMS. Sender must be exactly "MPESA".
/// Never persists raw SMS body; only parsed fields passed to callback.
class SmsIncomeListener {
  SmsReceiver? _receiver;
  StreamSubscription? _sub;
  bool _starting = false;

  Future<bool> start(OnIncomeParsed onParsed) async {
    if (_sub != null) return true;
    if (_starting) return false;

    _starting = true;
    final started = Completer<bool>();

    try {
      _receiver ??= SmsReceiver();
      final stream = _receiver!.onSmsReceived;
      if (stream == null) {
        _starting = false;
        return false;
      }

      _sub = stream.listen(
        (SmsMessage msg) {
          if (!MpesaSmsParser.isValidSender(msg.address)) return;
          final ts = msg.date ?? msg.dateSent ?? DateTime.now();
          final parsed = MpesaSmsParser.parse(msg.body ?? '', timestamp: ts);
          if (parsed != null) onParsed(parsed);
        },
        onError: (Object error, StackTrace _) {
          if (!_isMissingPluginError(error)) return;
          stop();
          if (!started.isCompleted) started.complete(false);
        },
      );

      // `receiveBroadcastStream.listen` activates platform channel asynchronously.
      // Give it a tick to surface MissingPluginException before reporting success.
      Future<void>.delayed(const Duration(milliseconds: 80), () {
        if (!started.isCompleted) started.complete(_sub != null);
      });

      return await started.future;
    } on MissingPluginException {
      stop();
      return false;
    } finally {
      _starting = false;
    }
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
    _receiver = null;
  }

  bool _isMissingPluginError(Object error) {
    return error is MissingPluginException ||
        error.toString().contains('MissingPluginException');
  }
}
