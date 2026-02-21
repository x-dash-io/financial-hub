import 'package:financial_hub/core/supabase_client.dart';
import 'package:financial_hub/core/ledger_service.dart';

class SpendingService {
  final _ledger = LedgerService();

  /// Attempts to spend [amount] from [pocketId]. Returns true if successful.
  /// Rejects if insufficient balance or pocket is savings.
  /// Inserts transaction only; trigger updates cached_balance.
  Future<bool> spend({
    required String pocketId,
    required int amount,
    required String profileId,
    required bool isSavings,
    required int currentBalance,
  }) async {
    if (isSavings) {
      await _logBehavioral(
        profileId,
        'savings_withdrawal_attempt',
        pocketId,
        amount,
      );
      return false;
    }
    if (currentBalance < amount) {
      await _logBehavioral(profileId, 'overspend_attempt', pocketId, amount);
      return false;
    }
    await _ledger.recordDebit(
      pocketId: pocketId,
      amount: amount,
      reference: 'spend',
    );
    await _logBehavioral(profileId, 'spend_within_budget', pocketId, amount);
    return true;
  }

  Future<void> _logBehavioral(
    String profileId,
    String eventType,
    String? pocketId,
    int amount,
  ) async {
    await supabase.from('behavioral_events').insert({
      'profile_id': profileId,
      'event_type': eventType,
      'pocket_id': pocketId,
      'amount': amount,
      'payload': {},
    });
  }
}
