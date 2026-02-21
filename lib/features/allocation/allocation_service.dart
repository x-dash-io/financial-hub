import 'package:financial_hub/core/allocation_engine.dart';
import 'package:financial_hub/core/ledger_service.dart';
import 'package:financial_hub/features/pockets/pockets_repository.dart';

/// Runs allocation and persists to Supabase.
/// Transactions are source of truth; cached_balance updated by DB trigger.
class AllocationService {
  final _repo = PocketsRepository();
  final _ledger = LedgerService();

  /// Allocates [income] to the active plan. Inserts transactions only; trigger updates cached_balance.
  Future<Map<String, int>> allocate({
    required String planId,
    required int income,
    String? reference,
    String? source,
  }) async {
    final allocations = await _repo.getAllocations(planId);
    final pockets = await _repo.getPockets(planId);
    final savingsPocket = pockets.where((p) => p.isSavings).firstOrNull;
    if (savingsPocket == null) throw StateError('No savings pocket');
    final rules = allocations
        .map(
          (a) => AllocationRule(pocketId: a.pocketId, percentage: a.percentage),
        )
        .toList();
    final result = AllocationEngine.allocate(
      income: income,
      allocations: rules,
      savingsPocketId: savingsPocket.id,
    );
    for (final e in result.entries) {
      if (e.value <= 0) continue;
      await _ledger.recordCredit(
        pocketId: e.key,
        amount: e.value,
        reference: reference,
        source: source,
      );
    }
    return result;
  }
}
