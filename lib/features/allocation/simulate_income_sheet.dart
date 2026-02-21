import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:financial_hub/core/app_logger.dart';
import 'package:financial_hub/features/allocation/allocation_service.dart';
import 'package:financial_hub/shared/models/pocket.dart';
import 'package:financial_hub/shared/pockets/pocket_icon_catalog.dart';
import 'package:financial_hub/shared/theme/app_radius.dart';
import 'package:financial_hub/shared/theme/app_spacing.dart';
import 'package:financial_hub/shared/theme/app_colors.dart';
import 'package:financial_hub/shared/widgets/app_card.dart';
import 'package:financial_hub/shared/widgets/amount_keypad_input.dart';
import 'package:financial_hub/shared/widgets/primary_button.dart';
import 'package:financial_hub/shared/widgets/warning_card.dart';

class SimulateIncomeSheet extends StatefulWidget {
  const SimulateIncomeSheet({
    super.key,
    required this.planId,
    required this.pockets,
    required this.onAllocated,
    this.allocationService,
  });

  final String planId;
  final List<Pocket> pockets;
  final Future<void> Function() onAllocated;
  final AllocationService? allocationService;

  @override
  State<SimulateIncomeSheet> createState() => _SimulateIncomeSheetState();
}

class _SimulateIncomeSheetState extends State<SimulateIncomeSheet>
    with SingleTickerProviderStateMixin {
  final _amountController = TextEditingController();
  late final AllocationService _service;
  late final AnimationController _resultController;
  bool _loading = false;
  String? _error;
  Map<String, int>? _breakdown;
  int? _receivedAmount;

  @override
  void initState() {
    super.initState();
    _service = widget.allocationService ?? AllocationService();
    _resultController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _resultController.dispose();
    super.dispose();
  }

  Future<void> _simulate() async {
    final amount = int.tryParse(_amountController.text.replaceAll(',', ''));
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Enter a valid amount');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final reference = 'simulate_${DateTime.now().microsecondsSinceEpoch}';
      final result = await _service.allocate(
        planId: widget.planId,
        income: amount,
        reference: reference,
      );
      if (!mounted) return;
      setState(() {
        _loading = false;
        _breakdown = result;
        _receivedAmount = amount;
      });
      _resultController.forward(from: 0);
    } catch (e, st) {
      AppLogger.error('Simulated allocation failed', e, st);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceAll(RegExp(r'Exception:?'), '').trim();
      });
    }
  }

  Future<void> _viewPockets() async {
    await widget.onAllocated();
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  List<_AllocationRow> _rowsFor(Map<String, int> breakdown) {
    final rows = <_AllocationRow>[];
    for (final pocket in widget.pockets) {
      final amount = breakdown[pocket.id];
      if (amount == null || amount <= 0) continue;
      rows.add(_AllocationRow(pocket: pocket, amount: amount));
    }
    return rows;
  }

  Widget _resultHeader(BuildContext context) {
    final amount =
        _receivedAmount ??
        _breakdown?.values.fold<int>(0, (sum, value) => sum + value) ??
        0;
    return Container(
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
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.primaryDeep,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.x0_5),
                Text(
                  'KES $amount',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.x0_5),
                Text(
                  'Received amount distributed across pockets.',
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
              border: Border.all(color: AppColors.primarySoftBorder),
            ),
            child: const Icon(
              LucideIcons.check,
              size: 18,
              color: AppColors.primaryDeep,
            ),
          ),
        ],
      ),
    );
  }

  Widget _animatedRow({
    required BuildContext context,
    required _AllocationRow row,
    required int index,
  }) {
    final start = (index * 0.12).clamp(0.0, 0.72).toDouble();
    final end = (start + 0.36).clamp(start + 0.08, 1.0).toDouble();
    final curve = CurvedAnimation(
      parent: _resultController,
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
    final breakdown = _breakdown;
    final rows = breakdown == null
        ? const <_AllocationRow>[]
        : _rowsFor(breakdown);

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
                  Row(
                    children: [
                      const Icon(
                        LucideIcons.banknote,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: AppSpacing.x1),
                      Text(
                        breakdown == null
                            ? 'Simulate income'
                            : 'Allocation complete',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.x1),
                  if (breakdown == null) ...[
                    Text(
                      'Enter amount to allocate to your pockets. Remainder goes to Savings (locked).',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.x2),
                    AmountKeypadInput(
                      controller: _amountController,
                      label: 'Amount (KES)',
                      hint: '5000',
                      prefixIcon: LucideIcons.coins,
                      iconColor: AppColors.accentBlue,
                      enabled: !_loading,
                      onChanged: (_) {
                        if (_error != null) setState(() => _error = null);
                      },
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: AppSpacing.x2),
                      WarningCard(
                        message: _error!,
                        type: WarningCardType.error,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.x3),
                    PrimaryButton(
                      label: 'Allocate',
                      icon: LucideIcons.sparkles,
                      loading: _loading,
                      onPressed: _simulate,
                    ),
                  ] else ...[
                    _resultHeader(context),
                    const SizedBox(height: AppSpacing.x2),
                    if (rows.isEmpty)
                      const WarningCard(
                        title: 'No pocket distribution',
                        message:
                            'No positive allocations were created for this income.',
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
                      onPressed: _viewPockets,
                    ),
                  ],
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
