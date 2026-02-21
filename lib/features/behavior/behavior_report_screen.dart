import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:financial_hub/core/supabase_client.dart';
import 'package:financial_hub/features/money_plan/money_plan_screen.dart';
import 'package:financial_hub/shared/theme/app_spacing.dart';
import 'package:financial_hub/shared/theme/app_colors.dart';
import 'package:financial_hub/shared/widgets/app_bottom_nav.dart';
import 'package:financial_hub/shared/widgets/app_card.dart';
import 'package:financial_hub/shared/widgets/app_scaffold.dart';
import 'package:financial_hub/shared/widgets/warning_card.dart';

class BehaviorReportScreen extends StatefulWidget {
  const BehaviorReportScreen({super.key});

  @override
  State<BehaviorReportScreen> createState() => _BehaviorReportScreenState();
}

class _BehaviorReportScreenState extends State<BehaviorReportScreen> {
  Map<String, int>? _counts;
  bool _loading = true;

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
          _loading = false;
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
          _loading = false;
        });
        return;
      }

      final profileId = profile['id'] as String;
      final events = await supabase
          .from('behavioral_events')
          .select('event_type')
          .eq('profile_id', profileId);
      final counts = <String, int>{};
      for (final e in events as List) {
        final t = e['event_type'] as String? ?? 'unknown';
        counts[t] = (counts[t] ?? 0) + 1;
      }

      if (!mounted) return;
      setState(() {
        _counts = counts;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _counts = const {};
        _loading = false;
      });
    }
  }

  void _onNavTap(int index) {
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

  @override
  Widget build(BuildContext context) {
    final body = _loading
        ? const Center(child: CircularProgressIndicator())
        : _counts == null || _counts!.isEmpty
        ? Center(
            child: Padding(
              padding: AppSpacing.page,
              child: const WarningCard(
                title: 'No events yet',
                message:
                    'Behavioral insights will appear after spend, reallocation, and plan actions.',
                type: WarningCardType.info,
              ),
            ),
          )
        : ListView(
            padding: AppSpacing.page,
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Behavior Insights',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.x2),
                    ..._counts!.entries.map((entry) {
                      final meta = _eventMeta(entry.key);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.x2),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.x1),
                              decoration: BoxDecoration(
                                color: meta.color.withValues(alpha: 0.14),
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
                            Text(
                              '${entry.value}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
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

class _EventMeta {
  const _EventMeta(this.label, this.icon, this.color);

  final String label;
  final IconData icon;
  final Color color;
}
