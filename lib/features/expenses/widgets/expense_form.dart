import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:voyage_flutter/features/collaboration/services/collaboration_service.dart';
import 'package:voyage_flutter/features/expenses/services/expense_validators.dart';
import 'package:voyage_flutter/models/expense.dart';
import 'package:voyage_flutter/models/trip_member.dart';

typedef ExpenseSubmitCallback =
    Future<void> Function({
      required String description,
      required double amount,
      required List<String> splitMemberIds,
    });

class ExpenseForm extends StatefulWidget {
  const ExpenseForm({
    required this.tripId,
    required this.submitLabel,
    required this.onSubmit,
    this.initialExpense,
    super.key,
  });

  final String tripId;
  final String submitLabel;
  final Expense? initialExpense;
  final ExpenseSubmitCallback onSubmit;

  @override
  State<ExpenseForm> createState() => _ExpenseFormState();
}

class _ExpenseFormState extends State<ExpenseForm> {
  final _formKey = GlobalKey<FormState>();
  final _collaborationService = CollaborationService();
  late final TextEditingController _descriptionController;
  late final TextEditingController _amountController;
  late Future<List<TripMember>> _membersFuture;
  late List<String> _selectedMemberIds;
  late bool _splitEnabled;
  String? _splitError;
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
    _selectedMemberIds = List<String>.of(
      widget.initialExpense?.splitMemberIds ?? const [],
    );
    _splitEnabled = _selectedMemberIds.isNotEmpty;
    _membersFuture = _collaborationService.getMembers(tripId: widget.tripId);
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit(List<TripMember> members) async {
    if (_isSubmitting || !_formKey.currentState!.validate()) {
      return;
    }
    if (_splitEnabled) {
      final splitError = ExpenseValidators.validateSplitMemberIds(
        _selectedMemberIds,
        tripMemberIds: members.map((member) => member.userId).toSet(),
      );
      if (splitError != null) {
        setState(() => _splitError = splitError);
        return;
      }
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
        splitMemberIds: _splitEnabled
            ? List.unmodifiable(_selectedMemberIds)
            : const [],
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<TripMember>>(
      future: _membersFuture,
      builder: (context, snapshot) {
        final members = snapshot.data;
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
                  onFieldSubmitted: (_) {
                    if (members != null) {
                      _submit(members);
                    }
                  },
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    helperText: 'Use up to 2 decimal places.',
                    border: OutlineInputBorder(),
                  ),
                  validator: ExpenseValidators.validateAmount,
                ),
                const SizedBox(height: 16),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const Center(child: CircularProgressIndicator())
                else if (snapshot.hasError)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        CollaborationService.userMessage(snapshot.error!),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _membersFuture = _collaborationService.getMembers(
                              tripId: widget.tripId,
                            );
                          });
                        },
                        child: const Text('Retry loading members'),
                      ),
                    ],
                  )
                else if (members != null) ...[
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Split this expense equally'),
                    subtitle: const Text('Choose the trip members sharing it.'),
                    value: _splitEnabled,
                    onChanged: (enabled) {
                      setState(() {
                        _splitEnabled = enabled;
                        _splitError = null;
                        if (!enabled) {
                          _selectedMemberIds.clear();
                        }
                      });
                    },
                  ),
                  if (_splitEnabled) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Split between',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    for (final member in members)
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          member.name.isEmpty ? 'Trip member' : member.name,
                        ),
                        subtitle: member.email == null
                            ? null
                            : Text(member.email!),
                        value: _selectedMemberIds.contains(member.userId),
                        onChanged: _isSubmitting
                            ? null
                            : (selected) {
                                setState(() {
                                  if (selected == true) {
                                    _selectedMemberIds.add(member.userId);
                                  } else {
                                    _selectedMemberIds.remove(member.userId);
                                  }
                                  _splitError = null;
                                });
                              },
                      ),
                    for (final unavailableId in _unavailableSelectedIds(
                      members,
                    ))
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('No longer a trip member'),
                        subtitle: const Text(
                          'Remove this person from the split.',
                        ),
                        value: true,
                        onChanged: _isSubmitting
                            ? null
                            : (_) {
                                setState(() {
                                  _selectedMemberIds.remove(unavailableId);
                                  _splitError = null;
                                });
                              },
                      ),
                    if (_splitError != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          _splitError!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                  ],
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _isSubmitting || members == null
                      ? null
                      : () => _submit(members),
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
      },
    );
  }

  List<String> _unavailableSelectedIds(List<TripMember> members) {
    final availableIds = members.map((member) => member.userId).toSet();
    return _selectedMemberIds
        .where((userId) => !availableIds.contains(userId))
        .toList();
  }
}
