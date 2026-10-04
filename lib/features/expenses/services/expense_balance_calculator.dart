import 'package:voyage_flutter/features/expenses/models/expense_balance.dart';
import 'package:voyage_flutter/models/expense.dart';
import 'package:voyage_flutter/models/trip_member.dart';

class ExpenseBalanceCalculator {
  static List<ExpenseBalance> calculate({
    required List<Expense> expenses,
    required List<TripMember> members,
  }) {
    final memberById = <String, TripMember>{};
    for (final member in members) {
      memberById.putIfAbsent(member.userId, () => member);
    }

    final paidCents = {for (final id in memberById.keys) id: 0};
    final owedCents = {for (final id in memberById.keys) id: 0};

    for (final expense in expenses) {
      if (!expense.amount.isFinite || expense.amount < 0) {
        throw FormatException('Invalid amount for expense ${expense.id}.');
      }
      if (expense.amount == 0) {
        continue;
      }
      if (!memberById.containsKey(expense.paidById)) {
        throw FormatException(
          'The payer for expense ${expense.id} is not a current trip member.',
        );
      }

      final amountCents = (expense.amount * 100).round();
      paidCents[expense.paidById] = paidCents[expense.paidById]! + amountCents;

      final participantIds =
          expense.splitMemberIds
              .where((id) => id.trim().isNotEmpty)
              .toSet()
              .toList()
            ..sort();
      if (participantIds.isEmpty) {
        // Legacy and explicitly unsplit expenses are assigned to the payer.
        owedCents[expense.paidById] =
            owedCents[expense.paidById]! + amountCents;
        continue;
      }

      final baseShareCents = amountCents ~/ participantIds.length;
      final remainderCents = amountCents % participantIds.length;
      for (var index = 0; index < participantIds.length; index++) {
        final participantId = participantIds[index];
        if (!owedCents.containsKey(participantId)) {
          continue;
        }
        owedCents[participantId] =
            owedCents[participantId]! +
            baseShareCents +
            (index < remainderCents ? 1 : 0);
      }
    }

    return [
      for (final member in memberById.values)
        ExpenseBalance(
          userId: member.userId,
          displayName: _displayName(member),
          totalPaid: paidCents[member.userId]! / 100,
          totalOwed: owedCents[member.userId]! / 100,
          balance:
              (paidCents[member.userId]! - owedCents[member.userId]!) / 100,
        ),
    ];
  }

  static String _displayName(TripMember member) {
    final name = member.name.trim();
    if (name.isNotEmpty) {
      return name;
    }
    final email = member.email?.trim();
    if (email != null && email.isNotEmpty) {
      return email;
    }
    return 'Trip member';
  }
}
