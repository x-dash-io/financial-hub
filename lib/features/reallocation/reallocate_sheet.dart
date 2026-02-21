import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:financial_hub/features/reallocation/reallocation_service.dart';
import 'package:financial_hub/shared/models/pocket.dart';
import 'package:financial_hub/shared/theme/app_spacing.dart';
import 'package:financial_hub/shared/theme/app_colors.dart';
import 'package:financial_hub/shared/widgets/app_card.dart';
import 'package:financial_hub/shared/widgets/amount_keypad_input.dart';
import 'package:financial_hub/shared/widgets/pocket_selector_strip.dart';
import 'package:financial_hub/shared/widgets/primary_button.dart';
import 'package:financial_hub/shared/widgets/secondary_button.dart';
import 'package:financial_hub/shared/widgets/warning_card.dart';

class ReallocateSheet extends StatefulWidget {
  const ReallocateSheet({
    super.key,
    required this.pockets,
    required this.profileId,
    required this.onReallocated,
  });

  final List<Pocket> pockets;
  final String profileId;
  final VoidCallback onReallocated;

  @override
  State<ReallocateSheet> createState() => _ReallocateSheetState();
}

class _ReallocateSheetState extends State<ReallocateSheet> {
  static const int _frictionSeconds = 7;

  final _amountController = TextEditingController();
  final _service = ReallocationService();

  Pocket? _source;
  Pocket? _dest;
  bool _loading = false;
  String? _error;
  int _countdown = -1;
  Timer? _timer;

  List<Pocket> get _spendablePockets =>
      widget.pockets.where((p) => !p.isSavings).toList();
  Pocket? get _savingsPocket =>
      widget.pockets.where((p) => p.isSavings).firstOrNull;
  bool get _countdownComplete => _countdown == 0;
  bool get _countdownRunning => _countdown > 0;
  double get _countdownProgress {
    if (_countdown < 0) return 0;
    return ((_frictionSeconds - _countdown) / _frictionSeconds).clamp(0.0, 1.0);
  }

  @override
  void initState() {
    super.initState();
    final spendables = _spendablePockets;
    if (spendables.isNotEmpty) {
      _source = spendables.first;
    }
    if (spendables.length > 1) {
      _dest = spendables[1];
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _resetFriction() {
    _timer?.cancel();
    _countdown = -1;
  }

  void _startCountdown() {
    if (_countdownRunning || _countdownComplete) return;
    setState(() => _countdown = _frictionSeconds);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_countdown <= 1) {
          _countdown = 0;
          _timer?.cancel();
        } else {
          _countdown--;
        }
      });
    });
  }

  Future<void> _confirm() async {
    if (!_countdownComplete) {
      setState(
        () => _error = 'Complete the friction countdown before confirm.',
      );
      return;
    }

    if (_source == null || _dest == null) return;

    if (_source!.id == _dest!.id) {
      setState(() => _error = 'Select different pockets for from/to.');
      return;
    }

    final amount = int.tryParse(_amountController.text.replaceAll(',', ''));
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Enter a valid amount to move.');
      return;
    }

    if (amount > _source!.balance) {
      setState(() => _error = 'Amount exceeds available balance.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final ok = await _service.reallocate(
      sourcePocketId: _source!.id,
      destPocketId: _dest!.id,
      amount: amount,
      profileId: widget.profileId,
      sourceIsSavings: _source!.isSavings,
      sourceBalance: _source!.balance,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (ok) {
      widget.onReallocated();
      Navigator.of(context).pop();
    } else {
      setState(() => _error = 'Could not reallocate now. Try again.');
    }
  }

  String _savingsImpactMessage() {
    final savings = _savingsPocket;
    if (savings == null) {
      return 'Savings pocket is not configured.';
    }
    return 'Savings remains protected at KES ${savings.balance}. Savings stays locked (no time expiry); keep at least 10% in Money Plan and adjust that percentage there anytime.';
  }

  @override
  Widget build(BuildContext context) {
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
                  const Icon(
                    LucideIcons.arrowLeftRight,
                    color: AppColors.accentBlue,
                  ),
                  const SizedBox(width: AppSpacing.x1),
                  Text(
                    'Reallocate',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.x1),
              Text(
                'Move money between spendable pockets. Savings remains locked.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.x2),
              Text(
                'From pocket',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.x1),
              PocketSelectorStrip(
                pockets: _spendablePockets,
                selectedPocketId: _source?.id,
                variant: PocketSelectorVariant.card,
                onSelected: (p) {
                  setState(() {
                    _source = p;
                    if (_dest?.id == p.id) {
                      _dest = null;
                    }
                    _resetFriction();
                  });
                },
              ),
              const SizedBox(height: AppSpacing.x2),
              Text('To pocket', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.x1),
              PocketSelectorStrip(
                pockets: _spendablePockets,
                selectedPocketId: _dest?.id,
                variant: PocketSelectorVariant.card,
                disabledPocketIds: _source == null ? const {} : {_source!.id},
                onSelected: (p) {
                  if (p.id == _source?.id) return;
                  setState(() {
                    _dest = p;
                    _resetFriction();
                  });
                },
              ),
              const SizedBox(height: AppSpacing.x2),
              AmountKeypadInput(
                controller: _amountController,
                label: 'Amount (KES)',
                hint: '500',
                prefixIcon: LucideIcons.coins,
                iconColor: AppColors.accentPurple,
                enabled: !_loading,
                onChanged: (_) {
                  if (_countdownComplete) {
                    setState(() => _countdown = -1);
                  }
                  if (_error != null) {
                    setState(() => _error = null);
                  }
                },
              ),
              const SizedBox(height: AppSpacing.x2),
              WarningCard(
                title: 'Savings impact',
                message: _savingsImpactMessage(),
                type: WarningCardType.info,
              ),
              const SizedBox(height: AppSpacing.x2),
              AppCard(
                padding: AppSpacing.card,
                softShadow: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          LucideIcons.timerReset,
                          size: 18,
                          color: AppColors.accentBlue,
                        ),
                        const SizedBox(width: AppSpacing.x1),
                        Expanded(
                          child: Text(
                            'Behavioral friction',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.x1),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: _countdownProgress,
                        minHeight: AppSpacing.x1,
                        backgroundColor: AppColors.surfaceMuted,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.accentBlue,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.x1),
                    Text(
                      _countdown < 0
                          ? 'Start a ${_frictionSeconds}s countdown before confirm.'
                          : _countdownComplete
                          ? 'Countdown complete. Confirm is unlocked.'
                          : 'Confirm unlocks in ${_countdown}s.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.x2),
                    SecondaryButton(
                      label: _countdownComplete
                          ? 'Countdown complete'
                          : _countdownRunning
                          ? 'Countdown running'
                          : 'Start ${_frictionSeconds}s countdown',
                      icon: LucideIcons.play,
                      onPressed: _countdownRunning || _countdownComplete
                          ? null
                          : _startCountdown,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.x3),
              PrimaryButton(
                label: 'Confirm reallocation',
                icon: LucideIcons.check,
                loading: _loading,
                onPressed: _countdownComplete ? _confirm : null,
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.x2),
                WarningCard(message: _error!, type: WarningCardType.warning),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
