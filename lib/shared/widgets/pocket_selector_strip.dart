import 'package:flutter/material.dart';
import 'package:financial_hub/shared/pockets/pocket_icon_catalog.dart';
import 'package:financial_hub/shared/models/pocket.dart';
import 'package:financial_hub/shared/theme/app_colors.dart';
import 'package:financial_hub/shared/theme/app_radius.dart';
import 'package:financial_hub/shared/theme/app_shadows.dart';
import 'package:financial_hub/shared/theme/app_spacing.dart';

enum PocketSelectorVariant { chip, card }

class PocketSelectorStrip extends StatelessWidget {
  const PocketSelectorStrip({
    super.key,
    required this.pockets,
    required this.selectedPocketId,
    required this.onSelected,
    this.disabledPocketIds = const {},
    this.showBalance = true,
    this.variant = PocketSelectorVariant.chip,
    this.emptyLabel = 'No pockets available',
  });

  final List<Pocket> pockets;
  final String? selectedPocketId;
  final ValueChanged<Pocket> onSelected;
  final Set<String> disabledPocketIds;
  final bool showBalance;
  final PocketSelectorVariant variant;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    if (pockets.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.x1),
        child: Text(emptyLabel, style: Theme.of(context).textTheme.bodyMedium),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < pockets.length; i++)
            Padding(
              padding: EdgeInsets.only(
                right: i == pockets.length - 1 ? 0 : AppSpacing.x1,
              ),
              child: _PocketSelectorTile(
                pocket: pockets[i],
                selected: pockets[i].id == selectedPocketId,
                disabled: disabledPocketIds.contains(pockets[i].id),
                showBalance: showBalance,
                variant: variant,
                onTap: () => onSelected(pockets[i]),
              ),
            ),
        ],
      ),
    );
  }
}

class _PocketSelectorTile extends StatelessWidget {
  const _PocketSelectorTile({
    required this.pocket,
    required this.selected,
    required this.disabled,
    required this.showBalance,
    required this.variant,
    required this.onTap,
  });

  final Pocket pocket;
  final bool selected;
  final bool disabled;
  final bool showBalance;
  final PocketSelectorVariant variant;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final iconMeta = PocketIconCatalog.resolve(
      isSavings: pocket.isSavings,
      iconKey: pocket.iconKey,
      name: pocket.name,
    );
    final accent = iconMeta.color;
    final disabledColor = AppColors.accentSlate.withValues(alpha: 0.7);
    final fg = disabled
        ? disabledColor
        : selected
        ? accent
        : AppColors.textPrimary;

    final bg = disabled
        ? AppColors.surfaceMuted
        : selected
        ? accent.withValues(alpha: 0.12)
        : AppColors.surface;
    final border = disabled
        ? AppColors.border
        : selected
        ? accent.withValues(alpha: 0.48)
        : AppColors.border;
    final radius = variant == PocketSelectorVariant.card
        ? AppRadius.card
        : AppRadius.button;
    final minWidth = variant == PocketSelectorVariant.card
        ? AppSpacing.x8 + AppSpacing.x6 + AppSpacing.x2
        : AppSpacing.x8 + AppSpacing.x6;

    return Opacity(
      opacity: disabled ? 0.72 : 1,
      child: Material(
        color: AppColors.transparent,
        child: InkWell(
          onTap: disabled ? null : onTap,
          borderRadius: BorderRadius.circular(radius),
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: minWidth),
            child: Ink(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.x2,
                vertical: AppSpacing.x1,
              ),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(radius),
                border: Border.all(color: border),
                boxShadow: selected ? AppShadows.soft : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(iconMeta.icon, size: 16, color: fg),
                      const SizedBox(width: AppSpacing.x0_5),
                      if (pocket.isSavings)
                        Text(
                          'Locked',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: fg,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.x0_5),
                  Text(
                    pocket.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: fg,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (showBalance) ...[
                    const SizedBox(height: AppSpacing.x0_5),
                    Text(
                      'KES ${pocket.balance}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: fg.withValues(alpha: 0.82),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
