import 'package:financial_hub/features/reallocation/reallocate_sheet.dart';
import 'package:financial_hub/shared/models/pocket.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders reallocate sheet without duplicate key exception', (
    tester,
  ) async {
    final pockets = [
      Pocket(
        id: 'savings',
        profileId: 'profile-1',
        planId: 'plan-1',
        name: 'Savings',
        balance: 2000,
        isSavings: true,
      ),
      Pocket(
        id: 'transport',
        profileId: 'profile-1',
        planId: 'plan-1',
        name: 'Transport',
        balance: 1000,
        isSavings: false,
      ),
      Pocket(
        id: 'food',
        profileId: 'profile-1',
        planId: 'plan-1',
        name: 'Food',
        balance: 1000,
        isSavings: false,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReallocateSheet(
            pockets: pockets,
            profileId: 'profile-1',
            onReallocated: () {},
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Reallocate'), findsOneWidget);
  });
}
