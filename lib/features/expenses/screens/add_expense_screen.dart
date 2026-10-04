import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:voyage_flutter/features/expenses/services/expense_service.dart';
import 'package:voyage_flutter/features/expenses/widgets/expense_form.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({required this.tripId, super.key});

  final String tripId;

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _expenseService = ExpenseService();

  Future<void> _addExpense({
    required String description,
    required double amount,
  }) async {
    try {
      await _expenseService.addExpense(
        tripId: widget.tripId,
        description: description,
        amount: amount,
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
    return Scaffold(
      appBar: AppBar(title: const Text('Add Expense')),
      body: ExpenseForm(submitLabel: 'Add expense', onSubmit: _addExpense),
    );
  }
}
