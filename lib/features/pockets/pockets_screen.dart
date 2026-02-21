import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:financial_hub/core/sms_income_listener.dart';
import 'package:financial_hub/core/sms_parser.dart';
import 'package:financial_hub/core/sms_permission.dart';
import 'package:financial_hub/core/supabase_client.dart';
import 'package:financial_hub/features/allocation/allocation_service.dart';
import 'package:financial_hub/features/allocation/simulate_income_sheet.dart';
import 'package:financial_hub/features/behavior/behavior_report_screen.dart';
import 'package:financial_hub/features/money_plan/money_plan_screen.dart';
import 'package:financial_hub/features/pockets/pockets_repository.dart';
import 'package:financial_hub/features/reallocation/reallocate_sheet.dart';
import 'package:financial_hub/features/spending/spend_sheet.dart';
import 'package:financial_hub/shared/models/pocket.dart';
import 'package:financial_hub/shared/theme/app_colors.dart';
import 'package:financial_hub/shared/theme/app_spacing.dart';
import 'package:financial_hub/shared/widgets/app_bottom_nav.dart';
import 'package:financial_hub/shared/widgets/app_card.dart';
import 'package:financial_hub/shared/widgets/app_scaffold.dart';
import 'package:financial_hub/shared/widgets/pocket_card.dart';
import 'package:financial_hub/shared/widgets/primary_button.dart';
import 'package:financial_hub/shared/widgets/secondary_button.dart';
import 'package:financial_hub/shared/widgets/warning_card.dart';

class PocketsScreen extends StatefulWidget {
  const PocketsScreen({super.key, this.onLogout});

  final Future<void> Function()? onLogout;

  @override
  State<PocketsScreen> createState() => _PocketsScreenState();
}

class _PocketsScreenState extends State<PocketsScreen> {
  final _repo = PocketsRepository();
  final _allocationService = AllocationService();
  final _smsListener = SmsIncomeListener();

  List<Pocket> _pockets = [];
  String? _planId;
  String? _profileId;
  bool _loading = true;
  bool _smsPermissionAsked = false;

  @override
  void initState() {
    super.initState();
    _loadPockets();
    _maybeRequestSmsPermission();
  }

  @override
  void dispose() {
    _smsListener.stop();
    super.dispose();
  }

  Future<void> _maybeRequestSmsPermission() async {
    if (_smsPermissionAsked) return;
    _smsPermissionAsked = true;
    final granted = await requestSmsPermission();
    if (granted) {
      _smsListener.start(_onSmsIncomeParsed);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'SMS permission helps detect MPESA income. Enable it in Settings.',
          ),
        ),
      );
    }
  }

  Future<void> _onSmsIncomeParsed(ParsedIncome parsed) async {
    if (_planId == null) return;
    try {
      await _allocationService.allocate(
        planId: _planId!,
        income: parsed.amount,
        reference: parsed.reference,
        source: parsed.sender,
      );
      if (!mounted) return;
      await _loadPockets();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Income received and allocated across your pockets.'),
        ),
      );
    } catch (_) {}
  }

  Future<void> _openMoneyPlan() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MoneyPlanScreen(
          onPlanChanged: () {
            _loadPockets();
          },
        ),
      ),
    );
    if (!mounted) return;
    await _loadPockets();
  }

  Future<void> _openBehaviorReport() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const BehaviorReportScreen()));
    if (!mounted) return;
    await _loadPockets();
  }

  void _openSimulateIncome() {
    if (_planId == null || _pockets.isEmpty) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => SimulateIncomeSheet(
        planId: _planId!,
        pockets: _pockets,
        onAllocated: _loadPockets,
      ),
    );
  }

  Future<void> _loadPockets() async {
    if (mounted) {
      setState(() => _loading = true);
    }
    try {
      final profile = await _repo.getProfile();
      if (!mounted) return;
      if (profile == null) {
        setState(() {
          _loading = false;
          _planId = null;
          _profileId = null;
          _pockets = [];
        });
        return;
      }

      final planId = profile['default_plan_id'] as String?;
      final profileId = profile['id'] as String?;
      if (planId == null) {
        setState(() {
          _loading = false;
          _planId = null;
          _profileId = profileId;
          _pockets = [];
        });
        return;
      }

      final pockets = await _repo.getPockets(planId);
      if (!mounted) return;
      setState(() {
        _planId = planId;
        _profileId = profileId;
        _pockets = pockets;
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _planId = null;
          _profileId = null;
          _pockets = [];
        });
      }
    }
  }

  Future<void> _logout() async {
    if (widget.onLogout != null) {
      await widget.onLogout!();
    } else {
      await supabase.auth.signOut();
      if (mounted) setState(() {});
    }
  }

  void _onBottomNavTap(int index) {
    switch (index) {
      case 0:
        return;
      case 1:
        _openMoneyPlan();
        return;
      case 2:
        _openBehaviorReport();
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasSpendable = _pockets.any((p) => !p.isSavings);
    final totalBalance = _pockets.fold<int>(
      0,
      (sum, pocket) => sum + pocket.balance,
    );

    final body = _loading
        ? const Center(child: CircularProgressIndicator())
        : _pockets.isEmpty
        ? Center(
            child: Padding(
              padding: AppSpacing.page,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const WarningCard(
                    title: 'No pockets yet',
                    message:
                        'Set up or edit your money plan, then come back to your pockets.',
                    type: WarningCardType.info,
                  ),
                  const SizedBox(height: AppSpacing.x2),
                  PrimaryButton(
                    label: 'Open Money Plan',
                    icon: LucideIcons.settings2,
                    onPressed: _openMoneyPlan,
                  ),
                ],
              ),
            ),
          )
        : Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadPockets,
                  child: ListView(
                    padding: AppSpacing.page,
                    children: [
                      const WarningCard(
                        title: 'Simple flow',
                        message:
                            'Tap a pocket to spend, use Reallocate for transfers, and Simulate to test income. Savings stays locked and must remain at least 10%.',
                        type: WarningCardType.info,
                      ),
                      const SizedBox(height: AppSpacing.x2),
                      ..._pockets.map((pocket) {
                        final progress = totalBalance <= 0
                            ? 0.0
                            : pocket.balance / totalBalance;
                        return PocketCard(
                          name: pocket.name,
                          balance: pocket.balance,
                          progress: progress,
                          locked: pocket.isSavings,
                          onTap: _profileId == null
                              ? null
                              : () => showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  builder: (_) => SpendSheet(
                                    pockets: _pockets,
                                    initialPocketId: pocket.id,
                                    profileId: _profileId!,
                                    onSpent: _loadPockets,
                                  ),
                                ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.x3,
                  0,
                  AppSpacing.x3,
                  AppSpacing.x2,
                ),
                child: AppCard(
                  softShadow: true,
                  child: Row(
                    children: [
                      Expanded(
                        child: SecondaryButton(
                          label: 'Reallocate',
                          icon: LucideIcons.arrowLeftRight,
                          onPressed: _profileId != null && hasSpendable
                              ? () => showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  builder: (_) => ReallocateSheet(
                                    pockets: _pockets,
                                    profileId: _profileId!,
                                    onReallocated: _loadPockets,
                                  ),
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.x1),
                      Expanded(
                        child: PrimaryButton(
                          label: 'Simulate',
                          icon: LucideIcons.banknote,
                          onPressed: _openSimulateIncome,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );

    return AppScaffold(
      title: 'Pockets',
      actions: [
        IconButton(
          icon: const Icon(LucideIcons.settings2, color: AppColors.accentBlue),
          tooltip: 'Money plan',
          onPressed: _openMoneyPlan,
        ),
        IconButton(
          icon: const Icon(
            LucideIcons.barChart3,
            color: AppColors.accentPurple,
          ),
          tooltip: 'Behavior report',
          onPressed: _openBehaviorReport,
        ),
        IconButton(
          icon: const Icon(LucideIcons.logOut, color: AppColors.accentRed),
          tooltip: 'Logout',
          onPressed: _logout,
        ),
      ],
      body: body,
      bottomNavigation: BottomNav(
        selectedIndex: 0,
        onSelected: _onBottomNavTap,
        items: const [
          BottomNavItem(
            label: 'Pockets',
            icon: LucideIcons.wallet2,
            color: AppColors.primary,
          ),
          BottomNavItem(
            label: 'Plan',
            icon: LucideIcons.settings2,
            color: AppColors.accentBlue,
          ),
          BottomNavItem(
            label: 'Insights',
            icon: LucideIcons.barChart3,
            color: AppColors.accentPurple,
          ),
        ],
      ),
    );
  }
}
