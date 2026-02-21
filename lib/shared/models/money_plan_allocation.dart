class MoneyPlanAllocation {
  final String id;
  final String planId;
  final String pocketId;
  final int percentage;

  MoneyPlanAllocation({
    required this.id,
    required this.planId,
    required this.pocketId,
    required this.percentage,
  });

  factory MoneyPlanAllocation.fromJson(Map<String, dynamic> json) {
    return MoneyPlanAllocation(
      id: json['id'] as String,
      planId: json['plan_id'] as String,
      pocketId: json['pocket_id'] as String,
      percentage: (json['percentage'] as num).toInt(),
    );
  }
}
