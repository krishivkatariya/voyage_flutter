import 'package:flutter_test/flutter_test.dart';
import 'package:voyage_flutter/features/expenses/models/expense_balance.dart';
import 'package:voyage_flutter/features/expenses/services/expense_balance_calculator.dart';
import 'package:voyage_flutter/models/expense.dart';
import 'package:voyage_flutter/models/trip_member.dart';

void main() {
  const members = [
    TripMember(userId: 'a', name: 'A'),
    TripMember(userId: 'b', name: 'B'),
    TripMember(userId: 'c', name: 'C'),
  ];

  Expense expense({
    required String id,
    required double amount,
    required String payer,
    List<String> split = const [],
  }) => Expense(
    id: id,
    tripId: 'trip',
    description: id,
    amount: amount,
    paidById: payer,
    splitMemberIds: split,
  );

  Map<String, ExpenseBalance> byId(List<ExpenseBalance> balances) => {
    for (final balance in balances) balance.userId: balance,
  };

  group('ExpenseBalanceCalculator', () {
    test('calculates an equal split including the payer', () {
      final balances = byId(
        ExpenseBalanceCalculator.calculate(
          expenses: [
            expense(
              id: 'dinner',
              amount: 1500,
              payer: 'a',
              split: ['a', 'b', 'c'],
            ),
          ],
          members: members,
        ),
      );

      expect(balances['a']!.totalPaid, 1500);
      expect(balances['a']!.totalOwed, 500);
      expect(balances['a']!.balance, 1000);
      expect(balances['b']!.balance, -500);
      expect(balances['c']!.balance, -500);
    });

    test('supports a payer who is not a participant', () {
      final balances = byId(
        ExpenseBalanceCalculator.calculate(
          expenses: [
            expense(id: 'dinner', amount: 1500, payer: 'a', split: ['b', 'c']),
          ],
          members: members,
        ),
      );

      expect(balances['a']!.balance, 1500);
      expect(balances['b']!.balance, -750);
      expect(balances['c']!.balance, -750);
    });

    test('nets a single-member expense to zero', () {
      final balances = byId(
        ExpenseBalanceCalculator.calculate(
          expenses: [
            expense(id: 'snack', amount: 100, payer: 'a', split: ['a']),
          ],
          members: members,
        ),
      );

      expect(balances['a']!.balance, 0);
    });

    test('aggregates multiple expenses and payers', () {
      final balances = byId(
        ExpenseBalanceCalculator.calculate(
          expenses: [
            expense(id: 'dinner', amount: 120, payer: 'a', split: ['a', 'b']),
            expense(id: 'taxi', amount: 60, payer: 'b', split: ['a', 'b', 'c']),
          ],
          members: members,
        ),
      );

      expect(balances['a']!.balance, 40);
      expect(balances['b']!.balance, -20);
      expect(balances['c']!.balance, -20);
    });

    test('returns zero balances for members when there are no expenses', () {
      final balances = ExpenseBalanceCalculator.calculate(
        expenses: const [],
        members: members,
      );

      expect(balances, hasLength(3));
      expect(balances.every((balance) => balance.balance == 0), isTrue);
      expect(balances.every((balance) => balance.totalPaid == 0), isTrue);
      expect(balances.every((balance) => balance.totalOwed == 0), isTrue);
    });

    test('treats a legacy expense without split IDs as payer-only', () {
      final balances = byId(
        ExpenseBalanceCalculator.calculate(
          expenses: [expense(id: 'legacy', amount: 50, payer: 'a')],
          members: members,
        ),
      );

      expect(balances['a']!.totalPaid, 50);
      expect(balances['a']!.totalOwed, 50);
      expect(balances['a']!.balance, 0);
    });

    test('ignores split participants who are no longer trip members', () {
      final balances = byId(
        ExpenseBalanceCalculator.calculate(
          expenses: [
            expense(
              id: 'old-split',
              amount: 100,
              payer: 'a',
              split: ['a', 'removed-user'],
            ),
          ],
          members: members,
        ),
      );

      expect(balances['a']!.balance, 50);
    });

    test('does not double-count duplicate participants', () {
      final balances = byId(
        ExpenseBalanceCalculator.calculate(
          expenses: [
            expense(
              id: 'duplicate-split',
              amount: 100,
              payer: 'a',
              split: ['a', 'b', 'b'],
            ),
          ],
          members: members,
        ),
      );

      expect(balances['a']!.totalOwed, 50);
      expect(balances['b']!.totalOwed, 50);
    });

    test('settles a penny remainder consistently', () {
      final balances = byId(
        ExpenseBalanceCalculator.calculate(
          expenses: [
            expense(
              id: 'uneven',
              amount: 10,
              payer: 'a',
              split: ['a', 'b', 'c'],
            ),
          ],
          members: members,
        ),
      );

      expect(balances['a']!.balance, 6.66);
      expect(balances['b']!.balance, -3.33);
      expect(balances['c']!.balance, -3.33);
    });

    test('rejects an invalid negative amount', () {
      expect(
        () => ExpenseBalanceCalculator.calculate(
          expenses: [expense(id: 'invalid', amount: -1, payer: 'a')],
          members: members,
        ),
        throwsFormatException,
      );
    });

    test('ignores a zero-value expense', () {
      final balances = ExpenseBalanceCalculator.calculate(
        expenses: [expense(id: 'zero', amount: 0, payer: 'a')],
        members: members,
      );

      expect(balances.every((balance) => balance.balance == 0), isTrue);
    });
  });
}
