import 'package:flutter/material.dart';
import 'package:voyage_flutter/models/expense.dart';

class ExpenseCard extends StatelessWidget {
  const ExpenseCard({
    required this.expense,
    required this.currentUserId,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final Expense expense;
  final String currentUserId;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final canManage = expense.paidById == currentUserId;
    final payerLabel = canManage
        ? 'Paid by you'
        : 'Paid by ${expense.paidById}';

    return Card(
      child: ListTile(
        title: Text(expense.description),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(payerLabel),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(expense.amount.toStringAsFixed(2)),
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
