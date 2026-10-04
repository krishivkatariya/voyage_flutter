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
}
