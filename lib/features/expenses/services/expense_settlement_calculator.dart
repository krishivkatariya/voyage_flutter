import 'package:voyage_flutter/features/expenses/models/expense_balance.dart';
import 'package:voyage_flutter/features/expenses/models/expense_settlement.dart';

class ExpenseSettlementCalculator {
  static List<ExpenseSettlement> calculate(List<ExpenseBalance> balances) {
    final creditors = <_BalanceInCents>[];
    final debtors = <_BalanceInCents>[];

    for (final balance in balances) {
      final cents = (balance.balance * 100).round();
      if (cents > 0) {
        creditors.add(_BalanceInCents(balance.userId, cents));
      } else if (cents < 0) {
        debtors.add(_BalanceInCents(balance.userId, -cents));
      }
    }

    creditors.sort(_largestFirst);
    debtors.sort(_largestFirst);

    final settlements = <ExpenseSettlement>[];
    var creditorIndex = 0;
    var debtorIndex = 0;
    while (creditorIndex < creditors.length && debtorIndex < debtors.length) {
      final creditor = creditors[creditorIndex];
      final debtor = debtors[debtorIndex];
      final transferCents = creditor.remainingCents < debtor.remainingCents
          ? creditor.remainingCents
          : debtor.remainingCents;

      if (transferCents > 0) {
        settlements.add(
          ExpenseSettlement(
            fromUserId: debtor.userId,
            toUserId: creditor.userId,
            amount: transferCents / 100,
          ),
        );
        creditor.remainingCents -= transferCents;
        debtor.remainingCents -= transferCents;
      }

      if (creditor.remainingCents == 0) {
        creditorIndex++;
      }
      if (debtor.remainingCents == 0) {
        debtorIndex++;
      }
    }

    return settlements;
  }

  static int _largestFirst(_BalanceInCents first, _BalanceInCents second) {
    final byAmount = second.remainingCents.compareTo(first.remainingCents);
    return byAmount != 0 ? byAmount : first.userId.compareTo(second.userId);
  }
}

class _BalanceInCents {
  _BalanceInCents(this.userId, this.remainingCents);

  final String userId;
  int remainingCents;
}
