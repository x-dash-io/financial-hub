class Pocket {
  final String id;
  final String profileId;
  final String planId;
  final String name;
  final int balance;
  final bool isSavings;

  Pocket({
    required this.id,
    required this.profileId,
    required this.planId,
    required this.name,
    required this.balance,
    required this.isSavings,
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
    );
  }
}
