import 'package:financial_hub/core/supabase_client.dart';
import 'package:financial_hub/shared/models/pocket.dart';
import 'package:financial_hub/shared/models/money_plan_allocation.dart';
import 'package:financial_hub/shared/models/latest_allocation_snapshot.dart';

class PocketsRepository {
  Future<Map<String, dynamic>?> getProfile() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return null;
    final res = await supabase
        .from('profiles')
        .select()
        .eq('user_id', userId)
        .maybeSingle();
    return res;
  }

  Future<List<Pocket>> getPockets(String planId) async {
    final res = await supabase
        .from('pockets')
        .select()
        .eq('plan_id', planId)
        .order('is_savings', ascending: false);
    return (res as List)
        .map((e) => Pocket.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<MoneyPlanAllocation>> getAllocations(String planId) async {
    final res = await supabase
        .from('money_plan_allocations')
        .select()
        .eq('plan_id', planId);
    return (res as List)
        .map((e) => MoneyPlanAllocation.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<int> getPocketBalance(String pocketId) async {
    final res = await supabase
        .from('pockets')
        .select('cached_balance')
        .eq('id', pocketId)
        .maybeSingle();
    final bal = res?['cached_balance'] ?? res?['balance'];
    return (bal as num?)?.toInt() ?? 0;
  }

  Future<LatestAllocationSnapshot?> getLatestAllocation(String planId) async {
    final res = await supabase
        .from('transactions')
        .select(
          'pocket_id, amount, reference, source, created_at, pockets!inner(plan_id)',
        )
        .eq('pockets.plan_id', planId)
        .eq('type', 'credit')
        .not('reference', 'is', null)
        .order('created_at', ascending: false)
        .limit(120);

    final txs = <_CreditTx>[];
    for (final raw in (res as List)) {
      if (raw is! Map<String, dynamic>) continue;
      final pocketId = raw['pocket_id'] as String?;
      final reference = (raw['reference'] as String?)?.trim();
      final createdAt = DateTime.tryParse(raw['created_at'] as String? ?? '');
      final amount = (raw['amount'] as num?)?.toInt() ?? 0;
      if (pocketId == null || pocketId.isEmpty) continue;
      if (reference == null || reference.isEmpty) continue;
      if (createdAt == null || amount <= 0) continue;
      txs.add(
        _CreditTx(
          pocketId: pocketId,
          amount: amount,
          reference: reference,
          source: raw['source'] as String?,
          createdAt: createdAt,
        ),
      );
    }

    if (txs.isEmpty) return null;

    final latest = txs.first;
    final windowStart = latest.createdAt.subtract(const Duration(minutes: 2));
    final windowEnd = latest.createdAt.add(const Duration(minutes: 2));
    final batch = txs
        .where(
          (tx) =>
              tx.reference == latest.reference &&
              !tx.createdAt.isBefore(windowStart) &&
              !tx.createdAt.isAfter(windowEnd),
        )
        .toList();
    if (batch.isEmpty) return null;

    final breakdownByPocketId = <String, int>{};
    var receivedAmount = 0;
    for (final tx in batch) {
      breakdownByPocketId[tx.pocketId] =
          (breakdownByPocketId[tx.pocketId] ?? 0) + tx.amount;
      receivedAmount += tx.amount;
    }

    return LatestAllocationSnapshot(
      reference: latest.reference,
      createdAt: latest.createdAt,
      receivedAmount: receivedAmount,
      breakdownByPocketId: breakdownByPocketId,
      source: batch
          .firstWhere(
            (tx) => tx.source != null && tx.source!.isNotEmpty,
            orElse: () => latest,
          )
          .source,
    );
  }

  Future<Map<String, int>> getSpentByPocketSince({
    required String planId,
    required DateTime startInclusive,
  }) async {
    final res = await supabase
        .from('transactions')
        .select('pocket_id, amount, created_at, pockets!inner(plan_id)')
        .eq('pockets.plan_id', planId)
        .eq('type', 'debit')
        .lt('amount', 0)
        .gte('created_at', startInclusive.toUtc().toIso8601String());

    final spentByPocketId = <String, int>{};
    for (final raw in (res as List)) {
      if (raw is! Map<String, dynamic>) continue;
      final pocketId = raw['pocket_id'] as String?;
      final amount = (raw['amount'] as num?)?.toInt() ?? 0;
      if (pocketId == null || pocketId.isEmpty) continue;
      if (amount >= 0) continue;
      spentByPocketId[pocketId] = (spentByPocketId[pocketId] ?? 0) + (-amount);
    }
    return spentByPocketId;
  }
}

class _CreditTx {
  const _CreditTx({
    required this.pocketId,
    required this.amount,
    required this.reference,
    required this.createdAt,
    this.source,
  });

  final String pocketId;
  final int amount;
  final String reference;
  final String? source;
  final DateTime createdAt;
}
