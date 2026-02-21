import 'package:flutter_test/flutter_test.dart';
import 'package:financial_hub/features/money_plan/money_plan_service.dart';

void main() {
  group('MoneyPlanService.validatePockets', () {
    test('accepts valid pockets', () {
      final pockets = [
        EditablePocketDraft(name: 'Savings', percentage: 40, isSavings: true),
        EditablePocketDraft(name: 'Food', percentage: 30, isSavings: false),
        EditablePocketDraft(
          name: 'Transport',
          percentage: 30,
          isSavings: false,
        ),
      ];

      final result = MoneyPlanService.validatePockets(pockets);
      expect(result, isNull);
    });

    test('rejects total percentage not equal to 100', () {
      final pockets = [
        EditablePocketDraft(name: 'Savings', percentage: 30, isSavings: true),
        EditablePocketDraft(name: 'Food', percentage: 20, isSavings: false),
      ];

      final result = MoneyPlanService.validatePockets(pockets);
      expect(result, contains('Total percentage'));
    });

    test('rejects savings lower than 10 percent', () {
      final pockets = [
        EditablePocketDraft(name: 'Savings', percentage: 5, isSavings: true),
        EditablePocketDraft(name: 'Food', percentage: 95, isSavings: false),
      ];

      final result = MoneyPlanService.validatePockets(pockets);
      expect(result, contains('Savings'));
    });

    test('rejects multiple savings pockets', () {
      final pockets = [
        EditablePocketDraft(name: 'Savings', percentage: 20, isSavings: true),
        EditablePocketDraft(name: 'Emergency', percentage: 20, isSavings: true),
        EditablePocketDraft(name: 'Food', percentage: 60, isSavings: false),
      ];

      final result = MoneyPlanService.validatePockets(pockets);
      expect(result, contains('Exactly one Savings'));
    });

    test('rejects duplicate pocket names', () {
      final pockets = [
        EditablePocketDraft(name: 'Savings', percentage: 20, isSavings: true),
        EditablePocketDraft(name: 'Food', percentage: 40, isSavings: false),
        EditablePocketDraft(name: 'food', percentage: 40, isSavings: false),
      ];

      final result = MoneyPlanService.validatePockets(pockets);
      expect(result, contains('unique'));
    });
  });
}
