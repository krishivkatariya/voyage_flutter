class ExpenseValidators {
  static const int maximumDescriptionLength = 100;

  static String? validateDescription(String? value) {
    final description = value?.trim() ?? '';
    if (description.isEmpty) {
      return 'Enter a description.';
    }
    if (description.length > maximumDescriptionLength) {
      return 'Description cannot exceed $maximumDescriptionLength characters.';
    }
    return null;
  }

  static String? validateAmount(String? value) {
    final amount = parseAmount(value);
    if (amount == null) {
      return 'Enter a valid amount with up to 2 decimal places.';
    }
    return validateAmountValue(amount);
  }

  static String? validateAmountValue(double amount) {
    final cents = amount * 100;
    if (!amount.isFinite || !cents.isFinite) {
      return 'Enter a valid amount with up to 2 decimal places.';
    }
    if (amount <= 0) {
      return 'Amount must be greater than zero.';
    }
    if ((cents - cents.roundToDouble()).abs() > 0.0000001) {
      return 'Enter an amount with no more than 2 decimal places.';
    }
    return null;
  }

  static double? parseAmount(String? value) {
    final input = value?.trim() ?? '';
    if (!RegExp(r'^(?:\d+(?:\.\d{1,2})?|\.\d{1,2})$').hasMatch(input)) {
      return null;
    }
    final amount = double.tryParse(input);
    if (amount == null || !amount.isFinite) {
      return null;
    }
    return amount;
  }
}
