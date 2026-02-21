import 'package:flutter/material.dart';

class AppColors {
  static const Color transparent = Color(0x00000000);
  static const Color white = Color(0xFFFFFFFF);

  static const Color background = Color(0xFFF4F7FA);
  static const Color backgroundTop = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFEEF3F7);
  static const Color border = Color(0xFFD7E0E8);
  static const Color borderMuted = Color(0xFFDFE9F2);

  static const Color onboardingGradientStart = Color(0xFFF9FBFF);
  static const Color onboardingGradientEnd = Color(0xFFF1F6FB);
  static const Color onboardingIndicatorInactive = Color(0xFFC9D5E3);
  static const Color helperTextMuted = Color(0xFF7B8BA0);

  static const Color primary = Color(0xFF0E7A66);
  static const Color primaryBright = Color(0xFF13997A);
  static const Color primaryDeep = Color(0xFF0C6655);
  static const Color primarySoft = Color(0xFFDDF4EE);
  static const Color primarySoftTint = Color(0xFFE8F8F1);
  static const Color primarySoftBorder = Color(0xFFBEE6D3);

  static const Color textPrimary = Color(0xFF132031);
  static const Color textSecondary = Color(0xFF5E6E80);
  static const Color onPrimary = Color(0xFFFFFFFF);

  static const Color success = Color(0xFF24895C);
  static const Color warning = Color(0xFFB0822A);
  static const Color warningDeep = Color(0xFF8C5A00);
  static const Color danger = Color(0xFFBF3F52);

  static const Color accentBlue = Color(0xFF2563EB);
  static const Color accentPurple = Color(0xFF9333EA);
  static const Color accentRed = Color(0xFFDC2626);
  static const Color accentAmber = Color(0xFFD97706);
  static const Color accentSlate = Color(0xFF64748B);
  static const Color accentViolet = Color(0xFF7C3AED);
  static const Color accentTeal = Color(0xFF0F766E);

  static const Color savingsCardTint = Color(0xFFF2FAF7);
  static const Color savingsCardBorder = Color(0xFFC8EAD8);
  static const Color pocketCardBorder = Color(0xFFDEE8F1);
  static const Color savingsBadge = Color(0xFFCFF0E3);

  static const Color shadowStrong = Color(0x1A0F1C2C);
  static const Color shadowTiny = Color(0x0D0F1C2C);
  static const Color shadowSoft = Color(0x120F1C2C);
  static const Color shadowNavStrong = Color(0x1F0F1C2C);
  static const Color shadowNavSoft = Color(0x140F1C2C);
  static const Color shadowSelected = Color(0x12000000);
  static const Color themeShadow = Color(0x190F1C2C);
  static const Color scrim = Color(0x4D0F1C2C);

  static const Color disabledGradientStart = Color(0xFFB5BFC8);
  static const Color disabledGradientEnd = Color(0xFFA3AFBA);

  static const LinearGradient primaryButtonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryBright, primary],
  );
}
