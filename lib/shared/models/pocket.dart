class Pocket {
  final String id;
  final String profileId;
  final String planId;
  final String name;
  final int balance;
  final bool isSavings;
  final String? iconKey;
  final bool iconCustom;

  Pocket({
    required this.id,
    required this.profileId,
    required this.planId,
    required this.name,
    required this.balance,
    required this.isSavings,
    this.iconKey,
    this.iconCustom = false,
  });

  factory Pocket.fromJson(Map<String, dynamic> json) {
    final bal = json['cached_balance'] ?? json['balance'];
    return Pocket(
      id: json['id'] as String,
      profileId: json['profile_id'] as String,
      planId: json['plan_id'] as String,
      name: json['name'] as String,
      balance: (bal as num?)?.toInt() ?? 0,
      isSavings: json['is_savings'] as bool? ?? false,
      iconKey: json['icon_key'] as String?,
      iconCustom: json['icon_custom'] as bool? ?? false,
    );
  }
}
