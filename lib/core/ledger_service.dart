import 'package:financial_hub/core/supabase_client.dart';

/// Ledger service: transactions are the source of truth.
/// Balance changes MUST go through transaction inserts only.
/// pockets.cached_balance is updated automatically by DB trigger.
class LedgerService {
  /// Record a credit (positive amount) to a pocket. Inserts transaction; trigger updates cached_balance.
  Future<void> recordCredit({
    required String pocketId,
    required int amount,
    String? reference,
    String? source,
    String type = 'credit',
  }) async {
    if (amount <= 0) throw ArgumentError('Credit amount must be positive');
    await supabase.from('transactions').insert({
      'pocket_id': pocketId,
      'amount': amount,
      'type': type,
      'reference': reference,
      if (source != null) 'source': source,
    });
  }

  /// Record a debit (negative amount) from a pocket.
  Future<void> recordDebit({
    required String pocketId,
    required int amount,
    String? reference,
    String type = 'debit',
  }) async {
    if (amount <= 0)
      throw ArgumentError('Debit amount must be positive (stored as negative)');
    await supabase.from('transactions').insert({
      'pocket_id': pocketId,
      'amount': -amount,
      'type': type,
      'reference': reference,
    });
  }

  /// Record reallocation: out from source, in to dest. Both as single transaction inserts.
  Future<void> recordReallocation({
    required String sourcePocketId,
    required String destPocketId,
    required int amount,
  }) async {
    if (amount <= 0)
      throw ArgumentError('Reallocation amount must be positive');
    await supabase.from('transactions').insert([
      {
        'pocket_id': sourcePocketId,
        'amount': -amount,
        'type': 'reallocation_out',
        'reference': 'reallocate',
      },
      {
        'pocket_id': destPocketId,
        'amount': amount,
        'type': 'reallocation_in',
        'reference': 'reallocate',
      },
    ]);
  }
}
