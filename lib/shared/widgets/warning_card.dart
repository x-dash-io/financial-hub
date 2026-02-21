import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:financial_hub/shared/theme/app_radius.dart';
import 'package:financial_hub/shared/theme/app_spacing.dart';

enum WarningCardType { warning, error, info }

class WarningCard extends StatelessWidget {
  const WarningCard({
    super.key,
    required this.message,
    this.title,
    this.type = WarningCardType.warning,
    this.trailing,
  });

  final String message;
  final String? title;
  final WarningCardType type;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (bg, fg, icon) = switch (type) {
      WarningCardType.warning => (
        theme.colorScheme.errorContainer.withValues(alpha: 0.42),
        const Color(0xFF8C5A00),
        LucideIcons.alertTriangle,
      ),
      WarningCardType.error => (
        theme.colorScheme.errorContainer.withValues(alpha: 0.55),
        theme.colorScheme.error,
        LucideIcons.shieldAlert,
      ),
      WarningCardType.info => (
        theme.colorScheme.primaryContainer.withValues(alpha: 0.42),
        theme.colorScheme.primary,
        LucideIcons.info,
      ),
    };

    return Container(
      padding: AppSpacing.card,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: fg),
          const SizedBox(width: AppSpacing.x1),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null) ...[
                  Text(
                    title!,
                    style: theme.textTheme.titleMedium?.copyWith(color: fg),
                  ),
                  const SizedBox(height: AppSpacing.x0_5),
                ],
                Text(
                  message,
                  style: theme.textTheme.bodyMedium?.copyWith(color: fg),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.x1),
            trailing!,
          ],
        ],
      ),
    );
  }
}
