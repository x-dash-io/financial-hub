import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:financial_hub/shared/theme/app_colors.dart';

class PocketIconMeta {
  const PocketIconMeta({
    required this.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.keywords,
  });

  final String key;
  final String label;
  final IconData icon;
  final Color color;
  final List<String> keywords;
}

class PocketIconCatalog {
  static const String savingsKey = 'savings';
  static const String defaultKey = 'other';

  static const List<PocketIconMeta> _all = [
    PocketIconMeta(
      key: 'savings',
      label: 'Savings',
      icon: LucideIcons.piggyBank,
      color: AppColors.primary,
      keywords: ['savings', 'save', 'reserve'],
    ),
    PocketIconMeta(
      key: 'food',
      label: 'Food',
      icon: LucideIcons.utensils,
      color: AppColors.accentAmber,
      keywords: ['food', 'meal', 'restaurant', 'grocery', 'grocer', 'lunch'],
    ),
    PocketIconMeta(
      key: 'transport',
      label: 'Transport',
      icon: LucideIcons.car,
      color: AppColors.accentBlue,
      keywords: [
        'transport',
        'travel',
        'bus',
        'matatu',
        'fare',
        'fuel',
        'uber',
        'taxi',
      ],
    ),
    PocketIconMeta(
      key: 'housing',
      label: 'Housing',
      icon: LucideIcons.home,
      color: AppColors.accentViolet,
      keywords: ['home', 'house', 'rent', 'mortgage', 'housing'],
    ),
    PocketIconMeta(
      key: 'utilities',
      label: 'Utilities',
      icon: LucideIcons.wifi,
      color: AppColors.accentSlate,
      keywords: [
        'utility',
        'utilities',
        'internet',
        'water',
        'power',
        'airtime',
      ],
    ),
    PocketIconMeta(
      key: 'shopping',
      label: 'Shopping',
      icon: LucideIcons.shoppingBag,
      color: AppColors.accentRed,
      keywords: ['shopping', 'shop', 'market', 'clothes', 'fashion'],
    ),
    PocketIconMeta(
      key: 'health',
      label: 'Health',
      icon: LucideIcons.heartPulse,
      color: AppColors.primary,
      keywords: ['health', 'medical', 'clinic', 'hospital', 'medicine'],
    ),
    PocketIconMeta(
      key: 'education',
      label: 'Education',
      icon: LucideIcons.graduationCap,
      color: AppColors.accentBlue,
      keywords: ['school', 'education', 'tuition', 'books', 'learning'],
    ),
    PocketIconMeta(
      key: 'entertainment',
      label: 'Entertainment',
      icon: LucideIcons.gamepad2,
      color: AppColors.accentPurple,
      keywords: ['entertainment', 'fun', 'games', 'movie', 'leisure'],
    ),
    PocketIconMeta(
      key: 'family',
      label: 'Family',
      icon: LucideIcons.users,
      color: AppColors.accentPurple,
      keywords: ['family', 'kids', 'children', 'parent', 'baby'],
    ),
    PocketIconMeta(
      key: 'business',
      label: 'Business',
      icon: LucideIcons.briefcase,
      color: AppColors.accentBlue,
      keywords: ['business', 'work', 'office', 'project'],
    ),
    PocketIconMeta(
      key: 'debt',
      label: 'Debt',
      icon: LucideIcons.receipt,
      color: AppColors.accentRed,
      keywords: ['debt', 'loan', 'credit'],
    ),
    PocketIconMeta(
      key: 'investment',
      label: 'Investment',
      icon: LucideIcons.landmark,
      color: AppColors.primaryDeep,
      keywords: ['invest', 'investment', 'stocks', 'crypto', 'mmf'],
    ),
    PocketIconMeta(
      key: 'gift',
      label: 'Gift',
      icon: LucideIcons.gift,
      color: AppColors.accentViolet,
      keywords: ['gift', 'present', 'birthday', 'wedding'],
    ),
    PocketIconMeta(
      key: 'emergency',
      label: 'Emergency',
      icon: LucideIcons.shieldAlert,
      color: AppColors.accentRed,
      keywords: ['emergency', 'urgent', 'buffer', 'rainy'],
    ),
    PocketIconMeta(
      key: 'cash',
      label: 'Cash',
      icon: LucideIcons.banknote,
      color: AppColors.accentTeal,
      keywords: ['cash', 'allowance', 'daily', 'wallet', 'spending'],
    ),
    PocketIconMeta(
      key: 'other',
      label: 'Other',
      icon: LucideIcons.wallet2,
      color: AppColors.accentSlate,
      keywords: ['other', 'misc', 'general'],
    ),
  ];

  static PocketIconMeta resolve({
    required bool isSavings,
    String? iconKey,
    required String name,
  }) {
    if (isSavings) {
      return byKey(savingsKey);
    }
    if (iconKey != null && iconKey.trim().isNotEmpty) {
      return byKey(iconKey);
    }
    return byKey(inferKey(name: name, isSavings: isSavings));
  }

  static PocketIconMeta byKey(String key) {
    for (final entry in _all) {
      if (entry.key == key) return entry;
    }
    return _all.last;
  }

  static String inferKey({required String name, required bool isSavings}) {
    if (isSavings) return savingsKey;
    final lower = name.toLowerCase();
    for (final entry in _all) {
      if (entry.key == savingsKey) continue;
      for (final keyword in entry.keywords) {
        if (lower.contains(keyword)) return entry.key;
      }
    }
    return defaultKey;
  }

  static List<PocketIconMeta> optionsForPicker({required bool isSavings}) {
    if (isSavings) return [byKey(savingsKey)];
    return _all.where((e) => e.key != savingsKey).toList();
  }
}
