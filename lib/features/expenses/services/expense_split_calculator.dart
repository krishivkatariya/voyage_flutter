class ExpenseSplitCalculator {
  static double calculateEqualShare(double amount, int memberCount) {
    if (!amount.isFinite || amount < 0) {
      throw ArgumentError.value(
        amount,
        'amount',
        'Must be finite and nonnegative.',
      );
    }
    if (memberCount < 1) {
      throw ArgumentError.value(
        memberCount,
        'memberCount',
        'Must be at least 1.',
      );
    }
    return amount / memberCount;
  }
}
