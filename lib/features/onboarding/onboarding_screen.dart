import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:financial_hub/core/sms_permission.dart';
import 'package:financial_hub/shared/theme/app_colors.dart';
import 'package:financial_hub/shared/theme/app_radius.dart';
import 'package:financial_hub/shared/theme/app_shadows.dart';
import 'package:financial_hub/shared/theme/app_spacing.dart';
import 'package:financial_hub/shared/widgets/app_scaffold.dart';
import 'package:financial_hub/shared/widgets/primary_button.dart';
import 'package:financial_hub/shared/widgets/secondary_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onComplete});

  final VoidCallback onComplete;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();

  int _index = 0;
  bool _requestingSmsPermission = false;

  static const _pages = [
    _OnboardingPage(
      title: 'Plan Money by Pockets',
      description:
          'Turn income into clear categories so daily choices stay within limits.',
      icon: LucideIcons.layoutGrid,
      accent: AppColors.accentBlue,
    ),
    _OnboardingPage(
      title: 'Keep Savings Protected',
      description:
          'Savings stays locked by default while spendable pockets stay flexible.',
      icon: LucideIcons.shieldCheck,
      accent: AppColors.primary,
    ),
    _OnboardingPage(
      title: 'Auto-Detect MPESA Income',
      description:
          'Enable SMS access to detect incoming MPESA payments and allocate instantly.',
      icon: LucideIcons.sparkles,
      accent: AppColors.accentPurple,
      isPermissionStep: true,
    ),
  ];

  bool get _isLastPage => _index == _pages.length - 1;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _goNext() async {
    if (_isLastPage) {
      await _enableSmsAndFinish();
      return;
    }

    await _pageController.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _enableSmsAndFinish() async {
    setState(() => _requestingSmsPermission = true);
    await requestSmsPermission();
    if (!mounted) return;
    setState(() => _requestingSmsPermission = false);
    widget.onComplete();
  }

  void _skip() {
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_index];

    return AppScaffold(
      backgroundGradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFF9FBFF), Color(0xFFF1F6FB)],
      ),
      body: Padding(
        padding: AppSpacing.page,
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _skip,
                icon: const Icon(LucideIcons.chevronsRight, size: 16),
                label: const Text('Skip'),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) {
                  final item = _pages[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.x1,
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: AppSpacing.x1),
                        _IllustrationPlaceholder(
                          icon: item.icon,
                          accent: item.accent,
                        ),
                        const SizedBox(height: AppSpacing.x3),
                        Text(
                          item.title,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: AppSpacing.x2),
                        Text(
                          item.description,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        if (item.isPermissionStep) ...[
                          const SizedBox(height: AppSpacing.x3),
                          _PrivacyNoteCard(accent: item.accent),
                        ],
                        const Spacer(),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (i) {
                final selected = i == _index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: selected ? 22 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: selected ? page.accent : const Color(0xFFC9D5E3),
                  ),
                );
              }),
            ),
            const SizedBox(height: AppSpacing.x2),
            PrimaryButton(
              label: _isLastPage ? 'Enable & Continue' : 'Continue',
              icon: _isLastPage
                  ? LucideIcons.shieldCheck
                  : LucideIcons.arrowRight,
              loading: _requestingSmsPermission,
              onPressed: _requestingSmsPermission ? null : _goNext,
            ),
            if (_isLastPage) ...[
              const SizedBox(height: AppSpacing.x1),
              SecondaryButton(
                label: 'Not now',
                icon: LucideIcons.clock3,
                onPressed: _requestingSmsPermission ? null : _skip,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage {
  const _OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.accent,
    this.isPermissionStep = false,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color accent;
  final bool isPermissionStep;
}

class _IllustrationPlaceholder extends StatelessWidget {
  const _IllustrationPlaceholder({required this.icon, required this.accent});

  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.sheet),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accent.withValues(alpha: 0.14), Colors.white],
        ),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
        boxShadow: AppShadows.card,
      ),
      child: SizedBox(
        width: double.infinity,
        height: 250,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: 26,
              left: 28,
              child: _ShapeBubble(
                size: 48,
                color: accent.withValues(alpha: 0.14),
              ),
            ),
            Positioned(
              bottom: 30,
              right: 34,
              child: _ShapeBubble(
                size: 64,
                color: accent.withValues(alpha: 0.1),
              ),
            ),
            Positioned(
              bottom: 72,
              left: 44,
              child: _ShapeBubble(
                size: 22,
                color: accent.withValues(alpha: 0.2),
              ),
            ),
            Container(
              width: 112,
              height: 112,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: accent.withValues(alpha: 0.3)),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.2),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Icon(icon, size: 48, color: accent),
            ),
            Positioned(
              top: 22,
              right: 22,
              child: Text(
                'Vector\nPlaceholder',
                textAlign: TextAlign.right,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF7B8BA0),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShapeBubble extends StatelessWidget {
  const _ShapeBubble({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size / 2),
      ),
    );
  }
}

class _PrivacyNoteCard extends StatelessWidget {
  const _PrivacyNoteCard({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: AppSpacing.card,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.button),
        border: Border.all(color: accent.withValues(alpha: 0.26)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Icon(LucideIcons.lock, size: 14, color: accent),
          ),
          const SizedBox(width: AppSpacing.x1),
          Expanded(
            child: Text(
              'Privacy note: We only check incoming SMS from sender "MPESA" to detect income amounts. We do not upload personal SMS conversations.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
