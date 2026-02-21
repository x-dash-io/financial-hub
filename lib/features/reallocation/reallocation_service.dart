import 'package:financial_hub/core/ledger_service.dart';
import 'package:financial_hub/core/supabase_client.dart';

class ReallocationService {
  final _ledger = LedgerService();

  /// Reallocates [amount] from [sourcePocketId] to [destPocketId].
  /// Enforces: source not Savings, sufficient balance.
  /// Inserts transactions only; trigger updates cached_balance.
  Future<bool> reallocate({
    required String sourcePocketId,
    required String destPocketId,
    required int amount,
    required String profileId,
    required bool sourceIsSavings,
    required int sourceBalance,
  }) async {
    if (sourceIsSavings) return false;
    if (sourceBalance < amount) return false;
    await _ledger.recordReallocation(
      sourcePocketId: sourcePocketId,
      destPocketId: destPocketId,
      amount: amount,
    );
    await supabase.from('behavioral_events').insert({
      'profile_id': profileId,
      'event_type': 'reallocation',
      'pocket_id': sourcePocketId,
      'amount': amount,
      'payload': {'dest_pocket_id': destPocketId},
    });
    return true;
  }
}
