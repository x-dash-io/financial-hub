import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:financial_hub/core/app_logger.dart';
import 'package:financial_hub/core/supabase_client.dart';
import 'package:financial_hub/features/money_plan/money_plan_screen.dart';
import 'package:financial_hub/shared/theme/app_colors.dart';
import 'package:financial_hub/shared/theme/app_spacing.dart';
import 'package:financial_hub/shared/widgets/app_bottom_nav.dart';
import 'package:financial_hub/shared/widgets/app_card.dart';
import 'package:financial_hub/shared/widgets/app_scaffold.dart';
import 'package:financial_hub/shared/widgets/warning_card.dart';

class BehaviorReportScreen extends StatefulWidget {
  const BehaviorReportScreen({super.key, this.onTabSelected});

  final ValueChanged<int>? onTabSelected;

  @override
  State<BehaviorReportScreen> createState() => _BehaviorReportScreenState();
}

class _BehaviorReportScreenState extends State<BehaviorReportScreen> {
  Map<String, int>? _counts;
  Map<String, int> _previousCounts = const {};
  _ReportRange _range = _ReportRange.days7;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() => _loading = true);
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        if (!mounted) return;
        setState(() {
          _counts = const {};
          _previousCounts = const {};
          _loading = false;
          _error = null;
        });
        return;
      }

      final profile = await supabase
          .from('profiles')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();
      if (profile == null) {
        if (!mounted) return;
        setState(() {
          _counts = const {};
          _previousCounts = const {};
          _loading = false;
          _error = null;
        });
        return;
      }

      final profileId = profile['id'] as String;
      final currentWindowStart = _range.windowStart;
      final previousWindowStart = _range.previousWindowStart;

      var currentQuery = supabase
          .from('behavioral_events')
          .select('event_type, created_at')
          .eq('profile_id', profileId);
      if (currentWindowStart != null) {
        currentQuery = currentQuery.gte(
          'created_at',
          currentWindowStart.toIso8601String(),
        );
      }
      final currentEvents = await currentQuery;
      final currentCounts = _countByType(currentEvents as List);

      Map<String, int> previousCounts = const {};
      if (currentWindowStart != null && previousWindowStart != null) {
        final previousEvents = await supabase
            .from('behavioral_events')
            .select('event_type, created_at')
            .eq('profile_id', profileId)
            .gte('created_at', previousWindowStart.toIso8601String())
            .lt('created_at', currentWindowStart.toIso8601String());
        previousCounts = _countByType(previousEvents as List);
      }

      if (!mounted) return;
      setState(() {
        _counts = currentCounts;
        _previousCounts = previousCounts;
        _loading = false;
        _error = null;
      });
    } catch (e, st) {
      AppLogger.error('Failed to load behavior report', e, st);
      if (!mounted) return;
      setState(() {
        _counts = const {};
        _previousCounts = const {};
        _loading = false;
        _error =
            'Could not load behavior insights right now. Pull to refresh and retry.';
      });
    }
  }

  Map<String, int> _countByType(List rows) {
    final counts = <String, int>{};
    for (final row in rows) {
      if (row is! Map<String, dynamic>) continue;
      final type = row['event_type'] as String? ?? 'unknown';
      counts[type] = (counts[type] ?? 0) + 1;
    }
    return counts;
  }

  void _onRangeChanged(_ReportRange range) {
    if (_range == range) return;
    setState(() => _range = range);
    _loadReport();
  }

  void _onNavTap(int index) {
    if (widget.onTabSelected != null) {
      widget.onTabSelected!(index);
      return;
    }
    switch (index) {
      case 0:
        Navigator.of(context).popUntil((route) => route.isFirst);
        return;
      case 1:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MoneyPlanScreen()),
        );
        return;
      case 2:
        return;
    }
  }

  _TrendDirection _trendFor(String eventType, int currentCount) {
    if (_range == _ReportRange.all) return _TrendDirection.flat;
    final previousCount = _previousCounts[eventType] ?? 0;
    if (currentCount > previousCount) return _TrendDirection.up;
    if (currentCount < previousCount) return _TrendDirection.down;
    return _TrendDirection.flat;
  }

  @override
  Widget build(BuildContext context) {
    final body = _loading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _loadReport,
            child: ListView(
              padding: AppSpacing.page,
              children: [
                AppCard(
                  child: Wrap(
                    spacing: AppSpacing.x1,
                    runSpacing: AppSpacing.x1,
                    children: [
                      _RangeChip(
                        label: '7d',
                        selected: _range == _ReportRange.days7,
                        onTap: () => _onRangeChanged(_ReportRange.days7),
                      ),
                      _RangeChip(
                        label: '30d',
                        selected: _range == _ReportRange.days30,
                        onTap: () => _onRangeChanged(_ReportRange.days30),
                      ),
                      _RangeChip(
                        label: 'All',
                        selected: _range == _ReportRange.all,
                        onTap: () => _onRangeChanged(_ReportRange.all),
                      ),
                    ],
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: AppSpacing.x2),
                  WarningCard(message: _error!, type: WarningCardType.error),
                ],
                const SizedBox(height: AppSpacing.x2),
                if (_counts == null || _counts!.isEmpty)
                  const WarningCard(
                    title: 'No events yet',
                    message:
                        'Behavioral insights will appear after spend, reallocation, and plan actions.',
                    type: WarningCardType.info,
                  )
                else
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Behavior Insights',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: AppSpacing.x2),
                        ...(_counts!.entries.toList()
                              ..sort((a, b) => b.value.compareTo(a.value)))
                            .map((entry) {
                              final meta = _eventMeta(entry.key);
                              final trend = _trendFor(entry.key, entry.value);
                              return Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppSpacing.x2,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(
                                        AppSpacing.x1,
                                      ),
                                      decoration: BoxDecoration(
                                        color: meta.color.withValues(
                                          alpha: 0.14,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        meta.icon,
                                        size: 16,
                                        color: meta.color,
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.x1),
                                    Expanded(child: Text(meta.label)),
                                    _TrendBadge(trend: trend),
                                    const SizedBox(width: AppSpacing.x1),
                                    Text(
                                      '${entry.value}',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium,
                                    ),
                                  ],
                                ),
                              );
                            }),
                      ],
                    ),
                  ),
              ],
            ),
          );

    return AppScaffold(
      title: 'Behavior Report',
      body: body,
      bottomNavigation: BottomNav(
        selectedIndex: 2,
        onSelected: _onNavTap,
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

  _EventMeta _eventMeta(String type) {
    switch (type) {
      case 'overspend_attempt':
        return const _EventMeta(
          'Overspend attempts',
          LucideIcons.alertTriangle,
          AppColors.accentAmber,
        );
      case 'savings_withdrawal_attempt':
        return const _EventMeta(
          'Savings withdrawal attempts',
          LucideIcons.shieldAlert,
          AppColors.accentRed,
        );
      case 'reallocation':
        return const _EventMeta(
          'Reallocations',
          LucideIcons.arrowLeftRight,
          AppColors.accentBlue,
        );
      case 'spend_within_budget':
        return const _EventMeta(
          'Spend within budget',
          LucideIcons.badgeCheck,
          AppColors.primary,
        );
      case 'plan_modification':
        return const _EventMeta(
          'Plan modifications',
          LucideIcons.settings2,
          AppColors.accentPurple,
        );
      default:
        return _EventMeta(type, LucideIcons.info, AppColors.accentSlate);
    }
  }
}

enum _ReportRange {
  days7,
  days30,
  all;

  DateTime? get windowStart {
    final now = DateTime.now().toUtc();
    return switch (this) {
      _ReportRange.days7 => now.subtract(const Duration(days: 7)),
      _ReportRange.days30 => now.subtract(const Duration(days: 30)),
      _ReportRange.all => null,
    };
  }

  DateTime? get previousWindowStart {
    final start = windowStart;
    if (start == null) return null;
    final now = DateTime.now().toUtc();
    final window = now.difference(start);
    return start.subtract(window);
  }
}

class _RangeChip extends StatelessWidget {
  const _RangeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primarySoft,
      side: const BorderSide(color: AppColors.border),
      labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: selected ? AppColors.primaryDeep : AppColors.textPrimary,
      ),
    );
  }
}

enum _TrendDirection { up, down, flat }

class _TrendBadge extends StatelessWidget {
  const _TrendBadge({required this.trend});

  final _TrendDirection trend;

  @override
  Widget build(BuildContext context) {
    final (icon, color, label) = switch (trend) {
      _TrendDirection.up => (LucideIcons.trendingUp, AppColors.success, 'Up'),
      _TrendDirection.down => (
        LucideIcons.trendingDown,
        AppColors.accentRed,
        'Down',
      ),
      _TrendDirection.flat => (
        LucideIcons.minus,
        AppColors.accentSlate,
        'No change',
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x1,
        vertical: AppSpacing.x0_5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: AppSpacing.x0_5),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _EventMeta {
  const _EventMeta(this.label, this.icon, this.color);

  final String label;
  final IconData icon;
  final Color color;
}
