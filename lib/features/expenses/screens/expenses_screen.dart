import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:voyage_flutter/features/collaboration/services/collaboration_service.dart';
import 'package:voyage_flutter/features/expenses/screens/add_expense_screen.dart';
import 'package:voyage_flutter/features/expenses/screens/edit_expense_screen.dart';
import 'package:voyage_flutter/features/expenses/services/expense_service.dart';
import 'package:voyage_flutter/features/expenses/widgets/expense_card.dart';
import 'package:voyage_flutter/models/expense.dart';
import 'package:voyage_flutter/models/trip_member.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({required this.tripId, super.key});

  final String tripId;

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final _expenseService = ExpenseService();
  final _collaborationService = CollaborationService();
  final Set<String> _busyExpenseIds = {};
  late Stream<List<Expense>> _expensesStream;
  late Future<List<TripMember>> _membersFuture;

  @override
  void initState() {
    super.initState();
    _expensesStream = _expenseService.watchExpenses(widget.tripId);
    _membersFuture = _collaborationService.getMembers(tripId: widget.tripId);
  }

  void _retry() {
    setState(() {
      _expensesStream = _expenseService.watchExpenses(widget.tripId);
      _membersFuture = _collaborationService.getMembers(tripId: widget.tripId);
    });
  }

  Future<void> _addExpense() async {
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => AddExpenseScreen(tripId: widget.tripId),
      ),
    );
    if (added == true && mounted) {
      _showMessage('Expense added.');
    }
  }

  Future<void> _editExpense(Expense expense) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => EditExpenseScreen(expense: expense),
      ),
    );
    if (updated == true && mounted) {
      _showMessage('Expense updated.');
    }
  }

  Future<void> _deleteExpense(Expense expense) async {
    if (_busyExpenseIds.contains(expense.id)) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete expense?'),
        content: Text('Delete "${expense.description}" from this trip?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }

    setState(() => _busyExpenseIds.add(expense.id));
    try {
      await _expenseService.deleteExpense(
        tripId: widget.tripId,
        expenseId: expense.id,
      );
      if (mounted) {
        _showMessage('Expense deleted.');
      }
    } on ExpenseServiceException catch (error) {
      _showMessage(error.message);
    } on FirebaseException catch (error) {
      _showMessage(ExpenseService.userMessage(error));
    } finally {
      if (mounted) {
        setState(() => _busyExpenseIds.remove(expense.id));
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = firebase_auth.FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      appBar: AppBar(title: const Text('Expenses')),
      body: currentUserId == null
          ? const _ExpensesMessage(message: 'Sign in to view trip expenses.')
          : FutureBuilder<List<TripMember>>(
              future: _membersFuture,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _ExpensesMessage(
                    message: CollaborationService.userMessage(snapshot.error!),
                    buttonLabel: 'Retry',
                    onPressed: _retry,
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final memberNames = {
                  for (final member in snapshot.data!)
                    member.userId: member.name,
                };
                return StreamBuilder<List<Expense>>(
                  stream: _expensesStream,
                  builder: (context, expenseSnapshot) {
                    if (expenseSnapshot.hasError) {
                      return _ExpensesMessage(
                        message: ExpenseService.userMessage(
                          expenseSnapshot.error!,
                        ),
                        buttonLabel: 'Retry',
                        onPressed: _retry,
                      );
                    }
                    if (!expenseSnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final expenses = expenseSnapshot.data!;
                    if (expenses.isEmpty) {
                      return _ExpensesMessage(
                        message: 'No expenses have been added yet.',
                        buttonLabel: 'Add Expense',
                        onPressed: _addExpense,
                      );
                    }

                    return ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        for (final expense in expenses)
                          ExpenseCard(
                            expense: expense,
                            currentUserId: currentUserId,
                            memberNames: memberNames,
                            onEdit: () => _editExpense(expense),
                            onDelete: () => _deleteExpense(expense),
                          ),
                      ],
                    );
                  },
                );
              },
            ),
      floatingActionButton: currentUserId == null
          ? null
          : FloatingActionButton.extended(
              onPressed: _addExpense,
              icon: const Icon(Icons.add),
              label: const Text('Add Expense'),
            ),
    );
  }
}

class _ExpensesMessage extends StatelessWidget {
  const _ExpensesMessage({
    required this.message,
    this.buttonLabel,
    this.onPressed,
  });

  final String message;
  final String? buttonLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            if (buttonLabel != null) ...[
              const SizedBox(height: 16),
              OutlinedButton(onPressed: onPressed, child: Text(buttonLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
