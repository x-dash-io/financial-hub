/// Strict MPESA income SMS parser.
/// - Only accepts sender == "MPESA" (exact match).
/// - Parses only messages containing: "Confirmed. You have received", Ksh amount, alphanumeric reference.
/// - If any required field fails, discards message.
/// - Never persists raw SMS body.
class MpesaSmsParser {
  static const String validSender = 'MPESA';

  /// Required phrase for valid income confirmation.
  static const String _requiredPhrase = 'Confirmed. You have received';

  /// Returns true only if sender is exactly "MPESA" (exact match, case-sensitive).
  static bool isValidSender(String? sender) {
    if (sender == null || sender.isEmpty) return false;
    return sender.trim() == validSender;
  }

  /// Parses SMS body. Returns null if any required field fails.
  /// Required: "Confirmed. You have received", Ksh <number>, alphanumeric reference.
  /// Never persists raw body.
  static ParsedIncome? parse(String body, {DateTime? timestamp}) {
    if (body.isEmpty) return null;
    if (!body.contains(_requiredPhrase)) return null;

    final amount = _parseAmount(body);
    if (amount == null || amount <= 0) return null;

    final reference = _parseReference(body);
    if (reference == null || reference.isEmpty) return null;

    return ParsedIncome(
      amount: amount,
      reference: reference,
      timestamp: timestamp ?? DateTime.now(),
      sender: validSender,
    );
  }

  /// Amount pattern: Ksh <number> (e.g. Ksh 1,500.00 or Ksh 500)
  static int? _parseAmount(String body) {
    final m = RegExp(
      r'Ksh\s+([\d,]+(?:\.\d{2})?)',
      caseSensitive: false,
    ).firstMatch(body);
    if (m == null) return null;
    final s = m.group(1)?.replaceAll(',', '').split('.').first ?? '';
    return int.tryParse(s);
  }

  /// Transaction reference: alphanumeric code (e.g. ABC12XYZ, AGT1234567890).
  /// Looks for common patterns: ref/Ref/REF followed by alphanumeric, or standalone 8+ char code.
  static String? _parseReference(String body) {
    final patterns = [
      RegExp(
        r'(?:ref\.?|reference)\s*[:\s]*([A-Z0-9]{6,20})',
        caseSensitive: false,
      ),
      RegExp(r'\b([A-Z]{2,4}\d{6,14})\b'),
      RegExp(r'\b([A-Z0-9]{8,20})\b'),
    ];
    for (final p in patterns) {
      final m = p.firstMatch(body);
      if (m != null) return m.group(1);
    }
    return null;
  }
}

/// Parsed income result. Persist only: amount, reference, timestamp, sender.
class ParsedIncome {
  final int amount;
  final String reference;
  final DateTime timestamp;
  final String sender;

  ParsedIncome({
    required this.amount,
    required this.reference,
    required this.timestamp,
    required this.sender,
  });
}
