import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:financial_hub/shared/models/pocket.dart';
import 'package:financial_hub/shared/pockets/pocket_icon_catalog.dart';
import 'package:financial_hub/shared/theme/app_colors.dart';
import 'package:financial_hub/shared/theme/app_radius.dart';
import 'package:financial_hub/shared/theme/app_spacing.dart';
import 'package:financial_hub/shared/widgets/app_card.dart';
import 'package:financial_hub/shared/widgets/primary_button.dart';
import 'package:financial_hub/shared/widgets/warning_card.dart';

class AllocationResultSheet extends StatefulWidget {
  const AllocationResultSheet({
    super.key,
    required this.receivedAmount,
    required this.breakdownByPocketId,
    required this.pockets,
    this.allocatedAt,
    this.onViewPockets,
  });

  final int receivedAmount;
  final Map<String, int> breakdownByPocketId;
  final List<Pocket> pockets;
  final DateTime? allocatedAt;
  final VoidCallback? onViewPockets;

  @override
  State<AllocationResultSheet> createState() => _AllocationResultSheetState();
}

class _AllocationResultSheetState extends State<AllocationResultSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<_AllocationRow> _rowsFor() {
    final rows = <_AllocationRow>[];
    for (final pocket in widget.pockets) {
      final amount = widget.breakdownByPocketId[pocket.id];
      if (amount == null || amount <= 0) continue;
      rows.add(_AllocationRow(pocket: pocket, amount: amount));
    }
    return rows;
  }

  String _formatAllocationTime(DateTime? value) {
    if (value == null) return 'Just now';
    final local = value.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '${local.day}/${local.month}/${local.year} $hour:$minute';
  }

  Widget _animatedRow({
    required BuildContext context,
    required _AllocationRow row,
    required int index,
  }) {
    final start = (index * 0.12).clamp(0.0, 0.72).toDouble();
    final end = (start + 0.36).clamp(start + 0.08, 1.0).toDouble();
    final curve = CurvedAnimation(
      parent: _controller,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
    final iconMeta = PocketIconCatalog.resolve(
      isSavings: row.pocket.isSavings,
      iconKey: row.pocket.iconKey,
      name: row.pocket.name,
    );
    final accent = iconMeta.color;
    final icon = iconMeta.icon;

    return AnimatedBuilder(
      animation: curve,
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.x1),
        child: AppCard(
          padding: AppSpacing.card,
          radius: AppRadius.button,
          softShadow: true,
          child: Row(
            children: [
              Container(
                width: AppSpacing.x5,
                height: AppSpacing.x5,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
                child: Icon(icon, size: 20, color: accent),
              ),
              const SizedBox(width: AppSpacing.x2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.pocket.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (row.pocket.isSavings)
                      Text(
                        'Locked',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.primaryDeep,
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                'KES ${row.amount}',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ),
      builder: (context, child) {
        final value = curve.value;
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 18),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final rows = _rowsFor();
    return DraggableScrollableSheet(
      initialChildSize: 0.62,
      minChildSize: 0.42,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: AppSpacing.sheet,
            child: AppCard(
              padding: AppSpacing.page,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: AppSpacing.x5,
                      height: AppSpacing.x1,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.outline,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.x3),
                  Container(
                    padding: AppSpacing.card,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      border: Border.all(color: AppColors.primarySoftBorder),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.primarySoftTint, AppColors.surface],
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Income allocated',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      color: AppColors.primaryDeep,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              const SizedBox(height: AppSpacing.x0_5),
                              Text(
                                'KES ${widget.receivedAmount}',
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: AppSpacing.x0_5),
                              Text(
                                'Allocated on ${_formatAllocationTime(widget.allocatedAt)}.',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primarySoft,
                            border: Border.all(
                              color: AppColors.primarySoftBorder,
                            ),
                          ),
                          child: const Icon(
                            LucideIcons.check,
                            size: 18,
                            color: AppColors.primaryDeep,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.x2),
                  if (rows.isEmpty)
                    const WarningCard(
                      title: 'No pocket distribution',
                      message:
                          'No positive allocations were found for this run.',
                      type: WarningCardType.info,
                    )
                  else
                    ...rows.asMap().entries.map(
                      (entry) => _animatedRow(
                        context: context,
                        row: entry.value,
                        index: entry.key,
                      ),
                    ),
                  const SizedBox(height: AppSpacing.x3),
                  PrimaryButton(
                    label: 'View pockets',
                    icon: LucideIcons.wallet2,
                    onPressed:
                        widget.onViewPockets ?? () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AllocationRow {
  const _AllocationRow({required this.pocket, required this.amount});

  final Pocket pocket;
  final int amount;
}
