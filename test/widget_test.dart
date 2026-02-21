import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App title smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(appBar: AppBar(title: const Text('Financial Hub'))),
      ),
    );
    expect(find.text('Financial Hub'), findsOneWidget);
  });
}
