import 'package:flutter_test/flutter_test.dart';
import 'package:financial_hub/core/allocation_engine.dart';

void main() {
  group('AllocationEngine', () {
    test('allocates income with integer math, remainder to savings', () {
      final allocations = [
        AllocationRule(pocketId: 'p1', percentage: 30),
        AllocationRule(pocketId: 'p2', percentage: 20),
        AllocationRule(pocketId: 'savings', percentage: 50),
      ];
      final result = AllocationEngine.allocate(
        income: 1000,
        allocations: allocations,
        savingsPocketId: 'savings',
      );
      expect(result['p1'], 300);
      expect(result['p2'], 200);
      expect(result['savings'], 500);
    });

    test('remainder from floor goes to savings', () {
      final allocations = [
        AllocationRule(pocketId: 'p1', percentage: 33),
        AllocationRule(pocketId: 'savings', percentage: 67),
      ];
      final result = AllocationEngine.allocate(
        income: 100,
        allocations: allocations,
        savingsPocketId: 'savings',
      );
      expect(result['p1'], 33);
      expect(result['savings'], 67);
    });
  });
}
