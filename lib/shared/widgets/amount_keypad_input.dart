import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:financial_hub/shared/theme/app_colors.dart';
import 'package:financial_hub/shared/theme/app_radius.dart';
import 'package:financial_hub/shared/theme/app_spacing.dart';
import 'package:financial_hub/shared/widgets/app_card.dart';
import 'package:financial_hub/shared/widgets/app_text_field.dart';

class AmountKeypadInput extends StatelessWidget {
  const AmountKeypadInput({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.prefixIcon,
    this.iconColor = AppColors.accentBlue,
    this.textStyle,
    this.enabled = true,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData? prefixIcon;
  final Color iconColor;
  final TextStyle? textStyle;
  final bool enabled;
  final ValueChanged<String>? onChanged;

  static const int _maxLength = 9;
  static const List<_QuickAmount> _quickAmounts = [
    _QuickAmount(label: '+100', amount: 100),
    _QuickAmount(label: '+500', amount: 500),
    _QuickAmount(label: '+1k', amount: 1000),
  ];

  void _setText(String value) {
    controller.value = controller.value.copyWith(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
      composing: TextRange.empty,
    );
    onChanged?.call(value);
  }

  void _appendDigit(String digit) {
    final current = controller.text.trim();
    if (current.length >= _maxLength) return;
    final next = current == '0' ? digit : '$current$digit';
    _setText(next);
  }

  void _backspace() {
    final current = controller.text.trim();
    if (current.isEmpty) return;
    _setText(current.substring(0, current.length - 1));
  }

  void _clear() {
    if (controller.text.isEmpty) return;
    _setText('');
  }

  void _addQuick(int amount) {
    final current = int.tryParse(controller.text.trim()) ?? 0;
    final next = current + amount;
    final text = next.toString();
    if (text.length > _maxLength) return;
    _setText(text);
  }

  void _onKeyTap(VoidCallback action) {
    if (!enabled) return;
    HapticFeedback.selectionClick();
    action();
  }

  @override
  Widget build(BuildContext context) {
    final fieldStyle =
        textStyle ??
        Theme.of(context).textTheme.headlineLarge?.copyWith(
          fontWeight: FontWeight.w800,
          fontSize: 38,
          letterSpacing: -0.8,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          padding: AppSpacing.card,
          softShadow: true,
          child: AppTextField(
            controller: controller,
            readOnly: true,
            showCursor: false,
            enableInteractiveSelection: false,
            label: label,
            hint: hint,
            textAlign: TextAlign.center,
            style: fieldStyle,
            prefixIcon: Icon(
              prefixIcon ?? LucideIcons.banknote,
              size: 20,
              color: iconColor,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.x1),
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.x1),
          radius: AppRadius.sheet,
          softShadow: true,
          child: Column(
            children: [
              Row(
                children: [
                  for (final quick in _quickAmounts)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.x0_5,
                        ),
                        child: _KeyButton(
                          label: quick.label,
                          muted: true,
                          enabled: enabled,
                          onTap: () => _onKeyTap(() => _addQuick(quick.amount)),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.x1),
              for (final row in const [
                ['1', '2', '3'],
                ['4', '5', '6'],
                ['7', '8', '9'],
              ]) ...[
                Row(
                  children: [
                    for (final key in row)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.x0_5),
                          child: _KeyButton(
                            label: key,
                            enabled: enabled,
                            onTap: () => _onKeyTap(() => _appendDigit(key)),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
              Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.x0_5),
                      child: _KeyButton(
                        label: 'C',
                        enabled: enabled,
                        destructive: true,
                        onTap: () => _onKeyTap(_clear),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.x0_5),
                      child: _KeyButton(
                        label: '0',
                        enabled: enabled,
                        onTap: () => _onKeyTap(() => _appendDigit('0')),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.x0_5),
                      child: _KeyButton(
                        icon: LucideIcons.delete,
                        enabled: enabled,
                        onTap: () => _onKeyTap(_backspace),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuickAmount {
  const _QuickAmount({required this.label, required this.amount});

  final String label;
  final int amount;
}

class _KeyButton extends StatelessWidget {
  const _KeyButton({
    this.label,
    this.icon,
    required this.onTap,
    this.enabled = true,
    this.muted = false,
    this.destructive = false,
  });

  final String? label;
  final IconData? icon;
  final VoidCallback onTap;
  final bool enabled;
  final bool muted;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final bg = !enabled
        ? AppColors.surfaceMuted
        : muted
        ? AppColors.primarySoft
        : AppColors.surface;
    final fg = !enabled
        ? AppColors.textSecondary.withValues(alpha: 0.7)
        : destructive
        ? AppColors.accentRed
        : AppColors.textPrimary;
    final border = muted ? AppColors.primarySoftBorder : AppColors.borderMuted;

    return Material(
      color: AppColors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.button),
        onTap: enabled ? onTap : null,
        child: Ink(
          height: 52,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AppRadius.button),
            border: Border.all(color: border),
          ),
          child: Center(
            child: label != null
                ? Text(
                    label!,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: fg,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                : Icon(icon, color: fg, size: 20),
          ),
        ),
      ),
    );
  }
}
