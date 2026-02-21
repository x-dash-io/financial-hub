class LatestAllocationSnapshot {
  const LatestAllocationSnapshot({
    required this.reference,
    required this.createdAt,
    required this.receivedAmount,
    required this.breakdownByPocketId,
    this.source,
  });

  final String reference;
  final DateTime createdAt;
  final int receivedAmount;
  final Map<String, int> breakdownByPocketId;
  final String? source;
}
