import 'package:flutter/material.dart';
import 'package:financial_hub/shared/theme/app_colors.dart';

class AppShadows {
  static const List<BoxShadow> card = [
    BoxShadow(
      color: AppColors.shadowStrong,
      blurRadius: 24,
      offset: Offset(0, 10),
    ),
    BoxShadow(color: AppColors.shadowTiny, blurRadius: 6, offset: Offset(0, 2)),
  ];

  static const List<BoxShadow> soft = [
    BoxShadow(
      color: AppColors.shadowSoft,
      blurRadius: 14,
      offset: Offset(0, 6),
    ),
  ];
}
