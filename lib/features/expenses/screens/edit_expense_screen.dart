import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:voyage_flutter/features/expenses/services/expense_service.dart';
import 'package:voyage_flutter/features/expenses/widgets/expense_form.dart';
import 'package:voyage_flutter/models/expense.dart';

class EditExpenseScreen extends StatefulWidget {
  const EditExpenseScreen({required this.expense, super.key});

  final Expense expense;

  @override
  State<EditExpenseScreen> createState() => _EditExpenseScreenState();
}

class _EditExpenseScreenState extends State<EditExpenseScreen> {
  final _expenseService = ExpenseService();

  Future<void> _updateExpense({
    required String description,
    required double amount,
    required List<String> splitMemberIds,
  }) async {
    try {
      await _expenseService.updateExpense(
        expense: Expense(
          id: widget.expense.id,
          tripId: widget.expense.tripId,
          description: description,
          amount: amount,
          paidById: widget.expense.paidById,
          splitMemberIds: splitMemberIds,
        ),
      );
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } on ExpenseServiceException catch (error) {
      _showError(error.message);
    } on FirebaseException catch (error) {
      _showError(ExpenseService.userMessage(error));
    }
  }

  void _showError(String message) {
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
    if (currentUserId != widget.expense.paidById) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Expense')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text('Only the original payer can edit this expense.'),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Expense')),
      body: ExpenseForm(
        tripId: widget.expense.tripId,
        initialExpense: widget.expense,
        submitLabel: 'Save changes',
        onSubmit: _updateExpense,
      ),
    );
  }
}
