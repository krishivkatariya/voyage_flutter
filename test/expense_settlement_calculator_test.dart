import 'package:flutter_test/flutter_test.dart';
import 'package:voyage_flutter/features/expenses/models/expense_balance.dart';
import 'package:voyage_flutter/features/expenses/services/expense_settlement_calculator.dart';

void main() {
  ExpenseBalance balance(String id, double amount) => ExpenseBalance(
    userId: id,
    displayName: id,
    totalPaid: 0,
    totalOwed: 0,
    balance: amount,
  );

  group('ExpenseSettlementCalculator', () {
    test('suggests transfers for a debtor and two equal creditors', () {
      final settlements = ExpenseSettlementCalculator.calculate([
        balance('a', 1000),
        balance('b', -500),
        balance('c', -500),
      ]);

      expect(settlements, hasLength(2));
      expect(settlements.map((settlement) => settlement.fromUserId).toSet(), {
        'b',
        'c',
      });
      expect(
        settlements.every((settlement) => settlement.toUserId == 'a'),
        isTrue,
      );
      expect(
        settlements.fold<double>(
          0,
          (sum, settlement) => sum + settlement.amount,
        ),
        1000,
      );
    });

    test(
      'matches multiple debtors and creditors using largest balances first',
      () {
        final startingBalances = [
          balance('a', 600),
          balance('b', 400),
          balance('c', -400),
          balance('d', -200),
          balance('e', -400),
        ];
        final settlements = ExpenseSettlementCalculator.calculate(
          startingBalances,
        );

        final incoming = <String, double>{};
        final outgoing = <String, double>{};
        final finalBalances = {
          for (final balance in startingBalances)
            balance.userId: balance.balance,
        };
        for (final settlement in settlements) {
          incoming.update(
            settlement.toUserId,
            (amount) => amount + settlement.amount,
            ifAbsent: () => settlement.amount,
          );
          outgoing.update(
            settlement.fromUserId,
            (amount) => amount + settlement.amount,
            ifAbsent: () => settlement.amount,
          );
          finalBalances[settlement.fromUserId] =
              finalBalances[settlement.fromUserId]! + settlement.amount;
          finalBalances[settlement.toUserId] =
              finalBalances[settlement.toUserId]! - settlement.amount;
        }
        expect(incoming, {'a': 600, 'b': 400});
        expect(outgoing, {'c': 400, 'd': 200, 'e': 400});
        expect(finalBalances.values.every((amount) => amount == 0), isTrue);
      },
    );

    test('does not create a transfer for a sub-cent balance', () {
      expect(
        ExpenseSettlementCalculator.calculate([balance('a', 0.004)]),
        isEmpty,
      );
    });

    test('returns no settlements when all balances are zero', () {
      expect(
        ExpenseSettlementCalculator.calculate([
          balance('a', 0),
          balance('b', 0),
        ]),
        isEmpty,
      );
    });
  });
}
