class Expense {
  final String id;
  final String tripId;
  final String description;
  final double amount;
  final String paidById;

  const Expense({
    required this.id,
    required this.tripId,
    required this.description,
    required this.amount,
    required this.paidById,
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
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tripId': tripId,
      'description': description,
      'amount': amount,
      'paidById': paidById,
    };
  }
}
