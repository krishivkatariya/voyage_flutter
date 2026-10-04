import 'package:flutter_test/flutter_test.dart';
import 'package:voyage_flutter/features/expenses/services/expense_validators.dart';

void main() {
  group('ExpenseValidators', () {
    test('accepts a non-blank description and valid positive amount', () {
      expect(ExpenseValidators.validateDescription(' Dinner '), isNull);
      expect(ExpenseValidators.validateAmount('1500.50'), isNull);
    });

    test('rejects a blank description', () {
      expect(ExpenseValidators.validateDescription('  '), isNotNull);
    });

    test('rejects descriptions longer than 100 characters', () {
      expect(
        ExpenseValidators.validateDescription(List.filled(101, 'x').join()),
        isNotNull,
      );
    });

    test('rejects zero and negative amounts', () {
      expect(ExpenseValidators.validateAmount('0'), isNotNull);
      expect(ExpenseValidators.validateAmount('-1'), isNotNull);
    });

    test('rejects non-numeric amounts', () {
      expect(ExpenseValidators.validateAmount('abc'), isNotNull);
    });

    test('rejects NaN, infinity, and more than two decimal places', () {
      expect(ExpenseValidators.validateAmount('NaN'), isNotNull);
      expect(ExpenseValidators.validateAmount('Infinity'), isNotNull);
      expect(ExpenseValidators.validateAmount('12.345'), isNotNull);
      expect(ExpenseValidators.validateAmountValue(double.infinity), isNotNull);
    });
  });
}
