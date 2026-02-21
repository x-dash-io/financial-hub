import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:financial_hub/features/spending/spending_service.dart';
import 'package:financial_hub/shared/models/pocket.dart';
import 'package:financial_hub/shared/theme/app_colors.dart';
import 'package:financial_hub/shared/theme/app_spacing.dart';
import 'package:financial_hub/shared/widgets/app_card.dart';
import 'package:financial_hub/shared/widgets/app_text_field.dart';
import 'package:financial_hub/shared/widgets/pocket_selector_strip.dart';
import 'package:financial_hub/shared/widgets/primary_button.dart';
import 'package:financial_hub/shared/widgets/warning_card.dart';

class SpendSheet extends StatefulWidget {
  const SpendSheet({
    super.key,
    required this.pockets,
    required this.initialPocketId,
    required this.profileId,
    required this.onSpent,
  });

  final List<Pocket> pockets;
  final String initialPocketId;
  final String profileId;
  final VoidCallback onSpent;

  @override
  State<SpendSheet> createState() => _SpendSheetState();
}

class _SpendSheetState extends State<SpendSheet> {
  final _amountController = TextEditingController();
  final _service = SpendingService();
  String? _selectedPocketId;
  bool _loading = false;
  String? _error;

  Pocket? get _selectedPocket {
    if (widget.pockets.isEmpty) return null;
    for (final p in widget.pockets) {
      if (p.id == _selectedPocketId) return p;
    }
    return widget.pockets.first;
  }

  @override
  void initState() {
    super.initState();
    _selectedPocketId = widget.initialPocketId;
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _spend() async {
    final selectedPocket = _selectedPocket;
    if (selectedPocket == null) {
      setState(() => _error = 'No pocket selected yet.');
      return;
    }

    final amount = int.tryParse(_amountController.text.replaceAll(',', ''));
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Enter a valid amount to continue.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final ok = await _service.spend(
      pocketId: selectedPocket.id,
      amount: amount,
      profileId: widget.profileId,
      isSavings: selectedPocket.isSavings,
      currentBalance: selectedPocket.balance,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (ok) {
      widget.onSpent();
      Navigator.of(context).pop();
    } else {
      setState(() {
        _error = selectedPocket.isSavings
            ? 'Savings is locked by design. Pick another pocket to spend.'
            : 'This exceeds ${selectedPocket.name}. Available: KES ${selectedPocket.balance}.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedPocket = _selectedPocket;
    final title = selectedPocket == null
        ? 'Spend'
        : 'Spend from ${selectedPocket.name}';
    final titleIcon = selectedPocket?.isSavings == true
        ? LucideIcons.shieldCheck
        : LucideIcons.wallet2;
    final titleColor = selectedPocket?.isSavings == true
        ? AppColors.primary
        : AppColors.accentBlue;

    return Padding(
      padding: AppSpacing.sheet,
      child: SingleChildScrollView(
        child: AppCard(
          padding: AppSpacing.page,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(titleIcon, color: titleColor),
                  const SizedBox(width: AppSpacing.x1),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.x2),
              PocketSelectorStrip(
                pockets: widget.pockets,
                selectedPocketId: _selectedPocketId,
                onSelected: (p) => setState(() => _selectedPocketId = p.id),
                variant: PocketSelectorVariant.chip,
              ),
              if (selectedPocket != null) ...[
                const SizedBox(height: AppSpacing.x2),
                AppCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.x2,
                    vertical: AppSpacing.x1,
                  ),
                  softShadow: true,
                  child: Row(
                    children: [
                      const Icon(
                        LucideIcons.coins,
                        size: 16,
                        color: AppColors.accentPurple,
                      ),
                      const SizedBox(width: AppSpacing.x1),
                      Expanded(
                        child: Text(
                          'Available balance',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      Text(
                        'KES ${selectedPocket.balance}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.x2),
              AppCard(
                padding: AppSpacing.card,
                softShadow: true,
                child: AppTextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  label: 'Amount (KES)',
                  hint: '0',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 38,
                    letterSpacing: -0.8,
                  ),
                  prefixIcon: const Icon(
                    LucideIcons.banknote,
                    size: 20,
                    color: AppColors.accentPurple,
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.x2),
                WarningCard(message: _error!, type: WarningCardType.warning),
              ],
              const SizedBox(height: AppSpacing.x3),
              PrimaryButton(
                label: 'Spend',
                icon: LucideIcons.arrowRight,
                loading: _loading,
                onPressed: _spend,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
