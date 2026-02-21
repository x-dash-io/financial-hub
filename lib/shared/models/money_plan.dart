class MoneyPlan {
  final String id;
  final String profileId;
  final String name;
  final bool isActive;

  const MoneyPlan({
    required this.id,
    required this.profileId,
    required this.name,
    required this.isActive,
  });

  factory MoneyPlan.fromJson(Map<String, dynamic> json) {
    return MoneyPlan(
      id: json['id'] as String,
      profileId: json['profile_id'] as String,
      name: json['name'] as String? ?? 'Unnamed Plan',
      isActive: json['is_active'] as bool? ?? false,
    );
  }
}
