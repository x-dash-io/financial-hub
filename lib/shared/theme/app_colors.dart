import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFFF4F7FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFEEF3F7);
  static const Color border = Color(0xFFD7E0E8);

  static const Color primary = Color(0xFF0E7A66);
  static const Color primaryDeep = Color(0xFF0C6655);
  static const Color primarySoft = Color(0xFFDDF4EE);

  static const Color textPrimary = Color(0xFF132031);
  static const Color textSecondary = Color(0xFF5E6E80);

  static const Color success = Color(0xFF24895C);
  static const Color warning = Color(0xFFB0822A);
  static const Color danger = Color(0xFFBF3F52);

  static const Color accentBlue = Color(0xFF2563EB);
  static const Color accentPurple = Color(0xFF9333EA);
  static const Color accentRed = Color(0xFFDC2626);
  static const Color accentAmber = Color(0xFFD97706);
  static const Color accentSlate = Color(0xFF64748B);
  static const Color accentViolet = Color(0xFF7C3AED);

  static const LinearGradient primaryButtonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF13997A), Color(0xFF0E7A66)],
  );
}
