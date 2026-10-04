class Expense {
  final String id;
  final String tripId;
  final String description;
  final double amount;
  final String paidById;
  final List<String> splitMemberIds;

  const Expense({
    required this.id,
    required this.tripId,
    required this.description,
    required this.amount,
    required this.paidById,
    this.splitMemberIds = const [],
  });

  factory Expense.fromMap(
    Map<String, dynamic> map, {
    required String id,
    required String tripId,
  }) {
    final amount = map['amount'];
    if (amount is! num || !amount.toDouble().isFinite) {
      throw FormatException('Invalid expense amount: $amount');
    }
    return Expense(
      id: id,
      tripId: tripId,
      description: map['description'] as String,
      amount: amount.toDouble(),
      paidById: map['paidById'] as String,
      splitMemberIds: _readSplitMemberIds(map['splitMemberIds']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tripId': tripId,
      'description': description,
      'amount': amount,
      'paidById': paidById,
      'splitMemberIds': splitMemberIds,
    };
  }
}

List<String> _readSplitMemberIds(Object? value) {
  if (value == null) {
    return const [];
  }
  if (value is! List || value.any((memberId) => memberId is! String)) {
    throw FormatException('Invalid split member IDs: $value');
  }
  return List<String>.unmodifiable(value.cast<String>());
}
