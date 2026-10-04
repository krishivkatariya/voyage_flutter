import 'package:flutter/material.dart';
import 'package:voyage_flutter/features/expenses/services/expense_split_calculator.dart';
import 'package:voyage_flutter/models/expense.dart';

class ExpenseCard extends StatelessWidget {
  const ExpenseCard({
    required this.expense,
    required this.currentUserId,
    required this.memberNames,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final Expense expense;
  final String currentUserId;
  final Map<String, String> memberNames;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final canManage = expense.paidById == currentUserId;
    final payerName = memberNames[expense.paidById] ?? expense.paidById;
    final payerLabel = canManage ? 'Paid by you' : 'Paid by $payerName';
    final splitCount = expense.splitMemberIds.length;
    final share = splitCount == 0
        ? null
        : ExpenseSplitCalculator.calculateEqualShare(
            expense.amount,
            splitCount,
          );

    return Card(
      child: ListTile(
        title: Text(expense.description),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(payerLabel),
            if (share != null) ...[
              const SizedBox(height: 4),
              Text(
                'Split between $splitCount '
                '${splitCount == 1 ? 'person' : 'people'}',
              ),
              Text(
                '${expense.splitMemberIds.map((id) => memberNames[id] ?? id).join(', ')}'
                ' · ₹${share.toStringAsFixed(2)} each',
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('₹${expense.amount.toStringAsFixed(2)}'),
            if (canManage) ...[
              IconButton(
                tooltip: 'Edit expense',
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                tooltip: 'Delete expense',
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
