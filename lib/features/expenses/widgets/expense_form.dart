import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:voyage_flutter/features/expenses/services/expense_validators.dart';
import 'package:voyage_flutter/models/expense.dart';

typedef ExpenseSubmitCallback =
    Future<void> Function({
      required String description,
      required double amount,
    });

class ExpenseForm extends StatefulWidget {
  const ExpenseForm({
    required this.submitLabel,
    required this.onSubmit,
    this.initialExpense,
    super.key,
  });

  final String submitLabel;
  final Expense? initialExpense;
  final ExpenseSubmitCallback onSubmit;

  @override
  State<ExpenseForm> createState() => _ExpenseFormState();
}

class _ExpenseFormState extends State<ExpenseForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _descriptionController;
  late final TextEditingController _amountController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(
      text: widget.initialExpense?.description ?? '',
    );
    _amountController = TextEditingController(
      text: widget.initialExpense?.amount.toStringAsFixed(2) ?? '',
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting || !_formKey.currentState!.validate()) {
      return;
    }
    final amount = ExpenseValidators.parseAmount(_amountController.text);
    if (amount == null) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await widget.onSubmit(
        description: _descriptionController.text.trim(),
        amount: amount,
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _descriptionController,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              maxLength: ExpenseValidators.maximumDescriptionLength,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              validator: ExpenseValidators.validateDescription,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
              ],
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              decoration: const InputDecoration(
                labelText: 'Amount',
                helperText: 'Use up to 2 decimal places.',
                border: OutlineInputBorder(),
              ),
              validator: ExpenseValidators.validateAmount,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(widget.submitLabel),
            ),
          ],
        ),
      ),
    );
  }
}
