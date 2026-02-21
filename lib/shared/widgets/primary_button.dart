import 'package:flutter/material.dart';
import 'package:financial_hub/shared/theme/app_colors.dart';
import 'package:financial_hub/shared/theme/app_radius.dart';
import 'package:financial_hub/shared/theme/app_spacing.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.gradient = true,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool gradient;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || loading;

    final child = loading
        ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18),
                const SizedBox(width: AppSpacing.x1),
              ],
              Text(label),
            ],
          );

    final button = FilledButton(
      onPressed: disabled ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: gradient ? AppColors.transparent : AppColors.primary,
        shadowColor: AppColors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
      ),
      child: child,
    );

    if (!gradient) return button;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: disabled
            ? const LinearGradient(
                colors: [
                  AppColors.disabledGradientStart,
                  AppColors.disabledGradientEnd,
                ],
              )
            : AppColors.primaryButtonGradient,
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
      child: button,
    );
  }
}
