import 'package:flutter/material.dart';
import 'package:financial_hub/features/behavior/behavior_report_screen.dart';
import 'package:financial_hub/features/money_plan/money_plan_screen.dart';
import 'package:financial_hub/features/pockets/pockets_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, this.onLogout});

  final Future<void> Function()? onLogout;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selectedIndex = 0;

  void _onTabSelected(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: _selectedIndex,
      children: [
        PocketsScreen(
          key: const PageStorageKey('tab-pockets'),
          onLogout: widget.onLogout,
          onTabSelected: _onTabSelected,
        ),
        MoneyPlanScreen(
          key: const PageStorageKey('tab-plan'),
          onTabSelected: _onTabSelected,
        ),
        BehaviorReportScreen(
          key: const PageStorageKey('tab-insights'),
          onTabSelected: _onTabSelected,
        ),
      ],
    );
  }
}
