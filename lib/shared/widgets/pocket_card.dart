import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:financial_hub/shared/theme/app_radius.dart';
import 'package:financial_hub/shared/theme/app_spacing.dart';
import 'package:financial_hub/shared/theme/app_colors.dart';

class PocketCard extends StatelessWidget {
  const PocketCard({
    super.key,
    required this.name,
    required this.balance,
    required this.progress,
    required this.locked,
    this.onTap,
  });

  final String name;
  final int balance;
  final double progress;
  final bool locked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final icon = _iconForName(name, locked);
    final accent = _iconColorForName(name, locked);
    final progressValue = progress.clamp(0.0, 1.0);
    final cardTint = locked ? const Color(0xFFF2FAF7) : Colors.white;
    final borderColor = locked
        ? const Color(0xFFC8EAD8)
        : const Color(0xFFDEE8F1);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.x2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: Ink(
            decoration: BoxDecoration(
              color: cardTint,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: borderColor),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A0F1C2C),
                  blurRadius: 26,
                  offset: Offset(0, 12),
                ),
                BoxShadow(
                  color: Color(0x120F1C2C),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Padding(
              padding: AppSpacing.card,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: AppSpacing.x6,
                        height: AppSpacing.x6,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(AppRadius.button),
                        ),
                        child: Icon(icon, size: 22, color: accent),
                      ),
                      const SizedBox(width: AppSpacing.x2),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    name,
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                ),
                                if (locked)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.x1,
                                      vertical: AppSpacing.x0_5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFCFF0E3),
                                      borderRadius: BorderRadius.circular(
                                        AppRadius.chip,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          LucideIcons.lock,
                                          size: 12,
                                          color: Color(0xFF0C6655),
                                        ),
                                        const SizedBox(width: AppSpacing.x0_5),
                                        Text(
                                          'Locked',
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                                color: const Color(0xFF0C6655),
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.x1),
                            _AnimatedKesValue(
                              value: balance,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (onTap != null)
                        Icon(
                          LucideIcons.chevronRight,
                          size: 18,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.x2),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.chip),
                    child: SizedBox(
                      height: 6,
                      child: Stack(
                        children: [
                          Container(color: accent.withValues(alpha: 0.16)),
                          FractionallySizedBox(
                            widthFactor: progressValue,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    accent.withValues(alpha: 0.7),
                                    accent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static IconData _iconForName(String name, bool locked) {
    if (locked) return LucideIcons.piggyBank;
    final lower = name.toLowerCase();
    if (lower.contains('food')) return LucideIcons.utensils;
    if (lower.contains('transport') || lower.contains('travel')) {
      return LucideIcons.car;
    }
    if (lower.contains('bills') || lower.contains('home')) {
      return LucideIcons.home;
    }
    if (lower.contains('shopping')) return LucideIcons.shoppingBag;
    return LucideIcons.wallet2;
  }

  static Color _iconColorForName(String name, bool locked) {
    if (locked) return AppColors.primary;
    final lower = name.toLowerCase();
    if (lower.contains('food')) return AppColors.accentAmber;
    if (lower.contains('transport') || lower.contains('travel')) {
      return AppColors.accentBlue;
    }
    if (lower.contains('bills') || lower.contains('home')) {
      return AppColors.accentViolet;
    }
    if (lower.contains('shopping')) return AppColors.accentRed;
    return const Color(0xFF0F766E);
  }
}

class _AnimatedKesValue extends StatefulWidget {
  const _AnimatedKesValue({required this.value, this.style});

  final int value;
  final TextStyle? style;

  @override
  State<_AnimatedKesValue> createState() => _AnimatedKesValueState();
}

class _AnimatedKesValueState extends State<_AnimatedKesValue> {
  late int _from;
  late int _to;

  @override
  void initState() {
    super.initState();
    _from = widget.value;
    _to = widget.value;
  }

  @override
  void didUpdateWidget(covariant _AnimatedKesValue oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value == widget.value) return;
    _from = oldWidget.value;
    _to = widget.value;
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: _from.toDouble(), end: _to.toDouble()),
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
      onEnd: () => _from = _to,
      builder: (context, value, _) {
        return Text('KES ${value.round()}', style: widget.style);
      },
    );
  }
}
