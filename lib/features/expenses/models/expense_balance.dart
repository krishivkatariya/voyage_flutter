class ExpenseBalance {
  const ExpenseBalance({
    required this.userId,
    required this.displayName,
    required this.totalPaid,
    required this.totalOwed,
    required this.balance,
  });

  final String userId;
  final String displayName;
  final double totalPaid;
  final double totalOwed;
  final double balance;
}
