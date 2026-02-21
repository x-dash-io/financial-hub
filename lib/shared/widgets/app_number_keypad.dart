import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:financial_hub/shared/theme/app_colors.dart';
import 'package:financial_hub/shared/theme/app_radius.dart';
import 'package:financial_hub/shared/theme/app_spacing.dart';

class AppNumberKeypad extends StatelessWidget {
  const AppNumberKeypad({
    super.key,
    required this.onDigit,
    required this.onBackspace,
    this.onClear,
    this.clearLabel = 'C',
    this.enabled = true,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final VoidCallback? onClear;
  final String clearLabel;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
                    child: _NumberKeyButton(
                      label: key,
                      enabled: enabled,
                      onTap: () => onDigit(key),
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
                child: _NumberKeyButton(
                  label: clearLabel,
                  enabled: enabled,
                  destructive: true,
                  onTap: onClear ?? () {},
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.x0_5),
                child: _NumberKeyButton(
                  label: '0',
                  enabled: enabled,
                  onTap: () => onDigit('0'),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.x0_5),
                child: _NumberKeyButton(
                  icon: LucideIcons.delete,
                  enabled: enabled,
                  onTap: onBackspace,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _NumberKeyButton extends StatelessWidget {
  const _NumberKeyButton({
    this.label,
    this.icon,
    required this.onTap,
    required this.enabled,
    this.destructive = false,
  });

  final String? label;
  final IconData? icon;
  final VoidCallback onTap;
  final bool enabled;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final fg = destructive ? AppColors.accentRed : AppColors.textPrimary;
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.button),
        onTap: enabled ? onTap : null,
        child: Ink(
          height: 52,
          decoration: BoxDecoration(
            color: enabled ? AppColors.surface : AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(AppRadius.button),
            border: Border.all(color: AppColors.borderMuted),
          ),
          child: Center(
            child: label != null
                ? Text(
                    label!,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: enabled ? fg : AppColors.textSecondary,
                    ),
                  )
                : Icon(
                    icon,
                    color: enabled ? fg : AppColors.textSecondary,
                    size: 20,
                  ),
          ),
        ),
      ),
    );
  }
}
