import 'package:flutter_test/flutter_test.dart';
import 'package:voyage_flutter/features/expenses/services/expense_split_calculator.dart';

void main() {
  group('ExpenseSplitCalculator', () {
    test('returns the full amount for one member', () {
      expect(ExpenseSplitCalculator.calculateEqualShare(1500, 1), 1500);
    });

    test('splits equally between two members', () {
      expect(ExpenseSplitCalculator.calculateEqualShare(1500, 2), 750);
    });

    test('splits equally between three members', () {
      expect(ExpenseSplitCalculator.calculateEqualShare(1500, 3), 500);
    });

    test('returns an unrounded share for an uneven split', () {
      expect(
        ExpenseSplitCalculator.calculateEqualShare(1000, 3),
        closeTo(333.333333, 0.000001),
      );
      expect(
        ExpenseSplitCalculator.calculateEqualShare(1000, 3).toStringAsFixed(2),
        '333.33',
      );
    });

    test('rejects an empty split', () {
      expect(
        () => ExpenseSplitCalculator.calculateEqualShare(1000, 0),
        throwsArgumentError,
      );
    });
  });
}
