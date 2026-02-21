/// Allocation engine: integer math only, remainder to Savings.
/// floor(income × percentage / 100), remainder assigned to Savings.
class AllocationEngine {
  /// Allocates [income] according to [allocations] (list of (pocketId, percentage)).
  /// Returns map of pocketId -> allocated amount.
  /// Remainder goes to the savings pocket (last entry with isSavings or first).
  static Map<String, int> allocate({
    required int income,
    required List<AllocationRule> allocations,
    required String savingsPocketId,
  }) {
    final result = <String, int>{};
    var remaining = income;

    for (final rule in allocations) {
      if (rule.pocketId == savingsPocketId) continue;
      final amount = (income * rule.percentage) ~/ 100;
      result[rule.pocketId] = amount;
      remaining -= amount;
    }

    result[savingsPocketId] = (result[savingsPocketId] ?? 0) + remaining;
    return result;
  }
}

class AllocationRule {
  final String pocketId;
  final int percentage;

  AllocationRule({required this.pocketId, required this.percentage});
}
