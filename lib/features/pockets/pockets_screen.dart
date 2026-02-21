import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:financial_hub/core/app_logger.dart';
import 'package:financial_hub/core/sms_income_listener.dart';
import 'package:financial_hub/core/sms_parser.dart';
import 'package:financial_hub/core/sms_permission.dart';
import 'package:financial_hub/core/supabase_client.dart';
import 'package:financial_hub/features/allocation/allocation_result_sheet.dart';
import 'package:financial_hub/features/allocation/allocation_service.dart';
import 'package:financial_hub/features/allocation/simulate_income_sheet.dart';
import 'package:financial_hub/features/behavior/behavior_report_screen.dart';
import 'package:financial_hub/features/money_plan/money_plan_screen.dart';
import 'package:financial_hub/features/pockets/pockets_repository.dart';
import 'package:financial_hub/features/reallocation/reallocate_sheet.dart';
import 'package:financial_hub/features/spending/spend_sheet.dart';
import 'package:financial_hub/shared/models/app_state.dart';
import 'package:financial_hub/shared/models/latest_allocation_snapshot.dart';
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
  const PocketsScreen({super.key, this.onLogout, this.onTabSelected});

  final Future<void> Function()? onLogout;
  final ValueChanged<int>? onTabSelected;

  @override
  State<PocketsScreen> createState() => _PocketsScreenState();
}

class _PocketsScreenState extends State<PocketsScreen> {
  final _repo = PocketsRepository();
  final _allocationService = AllocationService();
  final _smsListener = SmsIncomeListener();

  List<Pocket> _pockets = [];
  Map<String, int> _spentByPocketId = const {};
  String? _planId;
  String? _profileId;
  LatestAllocationSnapshot? _latestAllocation;
  bool _loading = true;
  bool _smsPermissionAsked = false;
  bool _navigating = false;
  String? _loadError;

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
      final started = await _smsListener.start(_onSmsIncomeParsed);
      if (!started && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'SMS auto-detection is unavailable on this runtime. A full app restart usually resolves it.',
            ),
          ),
        );
      }
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
    } catch (e, st) {
      AppLogger.error('Automatic SMS allocation failed', e, st);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not auto-allocate this SMS income. Try Simulate income.',
          ),
        ),
      );
    }
  }

  Future<void> _openMoneyPlan() async {
    if (widget.onTabSelected != null) {
      widget.onTabSelected!(1);
      return;
    }
    if (_navigating) return;
    _navigating = true;
    try {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => MoneyPlanScreen(
            onPlanChanged: () {
              _loadPockets();
            },
          ),
        ),
      );
    } finally {
      _navigating = false;
    }
    if (!mounted) return;
    await _loadPockets();
  }

  Future<void> _openBehaviorReport() async {
    if (widget.onTabSelected != null) {
      widget.onTabSelected!(2);
      return;
    }
    if (_navigating) return;
    _navigating = true;
    try {
      await Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const BehaviorReportScreen()));
    } finally {
      _navigating = false;
    }
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
          _spentByPocketId = const {};
          _latestAllocation = null;
          _loadError = 'Profile not found. Register again to continue.';
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
          _spentByPocketId = const {};
          _latestAllocation = null;
          _loadError = 'No active plan found. Open Money Plan to set one.';
        });
        return;
      }

      final startOfMonth = _startOfMonthLocal();
      final pocketsFuture = _repo.getPockets(planId);
      final latestAllocationFuture = _repo.getLatestAllocation(planId);
      final spentByPocketFuture = _repo.getSpentByPocketSince(
        planId: planId,
        startInclusive: startOfMonth,
      );
      final pockets = await pocketsFuture;
      final latestAllocation = await latestAllocationFuture;
      final spentByPocket = await spentByPocketFuture;
      if (!mounted) return;
      setState(() {
        _planId = planId;
        _profileId = profileId;
        _pockets = pockets;
        _spentByPocketId = spentByPocket;
        _latestAllocation = latestAllocation;
        _loading = false;
        _loadError = null;
      });
    } catch (e, st) {
      AppLogger.error('Failed to load pockets dashboard', e, st);
      if (mounted) {
        setState(() {
          _loading = false;
          _planId = null;
          _profileId = null;
          _pockets = [];
          _spentByPocketId = const {};
          _latestAllocation = null;
          _loadError =
              'Could not load pockets right now. Pull to refresh and try again.';
        });
      }
    }
  }

  Future<void> _logout() async {
    if (widget.onLogout != null) {
      await widget.onLogout!();
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppStateKeys.phone);
      await supabase.auth.signOut();
      if (mounted) setState(() {});
    }
  }

  void _onBottomNavTap(int index) {
    if (widget.onTabSelected != null) {
      widget.onTabSelected!(index);
      return;
    }
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

  int get _spendableBalance => _pockets
      .where((p) => !p.isSavings)
      .fold<int>(0, (sum, p) => sum + p.balance);

  int get _savingsBalance => _pockets
      .where((p) => p.isSavings)
      .fold<int>(0, (sum, p) => sum + p.balance);

  int get _spentThisMonth =>
      _spentByPocketId.values.fold<int>(0, (sum, value) => sum + value);

  DateTime _startOfMonthLocal() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  }

  String _formatLastAllocation(DateTime? value) {
    if (value == null) return 'No allocations yet';
    final now = DateTime.now();
    final local = value.toLocal();
    final diff = now.difference(local);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';
    return '${local.day}/${local.month} $hour:$minute $period';
  }

  void _openLatestAllocationBreakdown() {
    final latest = _latestAllocation;
    if (latest == null || _pockets.isEmpty) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => AllocationResultSheet(
        receivedAmount: latest.receivedAmount,
        breakdownByPocketId: latest.breakdownByPocketId,
        pockets: _pockets,
        allocatedAt: latest.createdAt,
      ),
    );
  }

  Widget _buildTodaySummary() {
    return AppCard(
      softShadow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Today', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.x2),
          Row(
            children: [
              Expanded(
                child: _SummaryMetric(
                  label: 'Spendable',
                  value: 'KES $_spendableBalance',
                  accent: AppColors.accentBlue,
                ),
              ),
              const SizedBox(width: AppSpacing.x1),
              Expanded(
                child: _SummaryMetric(
                  label: 'Savings (locked)',
                  value: 'KES $_savingsBalance',
                  accent: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x1),
          _SummaryMetric(
            label: 'Spent this month',
            value: 'KES $_spentThisMonth',
            accent: AppColors.accentRed,
            compact: true,
          ),
          const SizedBox(height: AppSpacing.x1),
          _SummaryMetric(
            label: 'Last allocation',
            value: _formatLastAllocation(_latestAllocation?.createdAt),
            accent: AppColors.accentPurple,
            compact: true,
          ),
        ],
      ),
    );
  }

  Widget _buildLatestAllocationCard() {
    final latest = _latestAllocation;
    if (latest == null) {
      return const WarningCard(
        title: 'Latest allocation',
        message:
            'No allocation history yet. Simulate or detect incoming income.',
        type: WarningCardType.info,
      );
    }
    return AppCard(
      softShadow: true,
      child: Row(
        children: [
          Container(
            width: AppSpacing.x5,
            height: AppSpacing.x5,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              LucideIcons.badgeCheck,
              size: 18,
              color: AppColors.primaryDeep,
            ),
          ),
          const SizedBox(width: AppSpacing.x2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Latest allocation',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.x0_5),
                Text('KES ${latest.receivedAmount}'),
                Text(
                  _formatLastAllocation(latest.createdAt),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: _openLatestAllocationBreakdown,
            icon: const Icon(LucideIcons.list, size: 16),
            label: const Text('View breakdown'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView(
      padding: AppSpacing.page,
      children: const [
        _SkeletonBlock(height: 128),
        SizedBox(height: AppSpacing.x2),
        _SkeletonBlock(height: 94),
        SizedBox(height: AppSpacing.x2),
        _SkeletonBlock(height: 110),
        SizedBox(height: AppSpacing.x2),
        _SkeletonBlock(height: 110),
        SizedBox(height: AppSpacing.x2),
        _SkeletonBlock(height: 110),
        SizedBox(height: AppSpacing.x2),
        _SkeletonBlock(height: 64),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasSpendable = _pockets.any((p) => !p.isSavings);
    final totalBalance = _pockets.fold<int>(
      0,
      (sum, pocket) => sum + pocket.balance,
    );

    final body = _loading
        ? _buildLoadingSkeleton()
        : _pockets.isEmpty
        ? Center(
            child: Padding(
              padding: AppSpacing.page,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_loadError != null) ...[
                    WarningCard(
                      message: _loadError!,
                      type: WarningCardType.error,
                    ),
                    const SizedBox(height: AppSpacing.x2),
                  ],
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
                      if (_loadError != null) ...[
                        WarningCard(
                          message: _loadError!,
                          type: WarningCardType.error,
                        ),
                        const SizedBox(height: AppSpacing.x2),
                      ],
                      const WarningCard(
                        title: 'Simple flow',
                        message:
                            'Tap a pocket to spend, use Reallocate for transfers, and Simulate to test income. Savings stays locked and must remain at least 10%.',
                        type: WarningCardType.info,
                      ),
                      const SizedBox(height: AppSpacing.x2),
                      _buildTodaySummary(),
                      const SizedBox(height: AppSpacing.x2),
                      _buildLatestAllocationCard(),
                      const SizedBox(height: AppSpacing.x2),
                      ..._pockets.map((pocket) {
                        final progress = totalBalance <= 0
                            ? 0.0
                            : pocket.balance / totalBalance;
                        final spentAmount = _spentByPocketId[pocket.id] ?? 0;
                        return PocketCard(
                          name: pocket.name,
                          balance: pocket.balance,
                          progress: progress,
                          locked: pocket.isSavings,
                          iconKey: pocket.iconKey,
                          spentAmount: pocket.isSavings ? null : spentAmount,
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

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.label,
    required this.value,
    required this.accent,
    this.compact = false,
  });

  final String label;
  final String value;
  final Color accent;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.x2,
        vertical: compact ? AppSpacing.x1 : AppSpacing.x2,
      ),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.x0_5),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _SkeletonBlock extends StatelessWidget {
  const _SkeletonBlock({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Container(
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: AppColors.surfaceMuted,
        ),
      ),
    );
  }
}
