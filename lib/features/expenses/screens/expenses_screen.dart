import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:voyage_flutter/features/collaboration/services/collaboration_service.dart';
import 'package:voyage_flutter/features/expenses/screens/add_expense_screen.dart';
import 'package:voyage_flutter/features/expenses/screens/expense_summary_screen.dart';
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
    _loadData();
  }

  void _loadData() {
    _expensesStream = _expenseService.watchExpenses(widget.tripId);
    _membersFuture = _collaborationService.getMembers(tripId: widget.tripId);
  }

  void _retry() {
    setState(_loadData);
  }

  Future<void> _addExpense() async {
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => AddExpenseScreen(tripId: widget.tripId),
      ),
    );

    if (added == true && mounted) {
      _showMessage('Expense added successfully.');
    }
  }

  Future<void> _editExpense(Expense expense) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => EditExpenseScreen(expense: expense),
      ),
    );

    if (updated == true && mounted) {
      _showMessage('Expense updated successfully.');
    }
  }

  Future<void> _deleteExpense(Expense expense) async {
    if (_busyExpenseIds.contains(expense.id)) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(
          Icons.delete_outline_rounded,
          color: Colors.redAccent,
          size: 32,
        ),
        title: const Text('Delete expense?'),
        content: Text(
          'Are you sure you want to delete "${expense.description}" '
          'from this trip?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _busyExpenseIds.add(expense.id));

    try {
      await _expenseService.deleteExpense(
        tripId: widget.tripId,
        expenseId: expense.id,
      );

      if (mounted) {
        _showMessage('Expense deleted successfully.');
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
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }

  void _openSummary() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ExpenseSummaryScreen(tripId: widget.tripId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = firebase_auth.FirebaseAuth.instance.currentUser?.uid;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F6FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F6FC),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Expenses',
          style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.4),
        ),
        actions: [
          IconButton(
            tooltip: 'Expense Summary',
            onPressed: currentUserId == null ? null : _openSummary,
            icon: const Icon(Icons.summarize_outlined),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: currentUserId == null
          ? const _ExpensesMessage(
              icon: Icons.lock_outline_rounded,
              title: 'Sign in required',
              message: 'Sign in to view and manage trip expenses.',
            )
          : FutureBuilder<List<TripMember>>(
              future: _membersFuture,
              builder: (context, memberSnapshot) {
                if (memberSnapshot.hasError) {
                  return _ExpensesMessage(
                    icon: Icons.cloud_off_rounded,
                    title: 'Unable to load trip members',
                    message: CollaborationService.userMessage(
                      memberSnapshot.error!,
                    ),
                    buttonLabel: 'Try again',
                    onPressed: _retry,
                  );
                }

                if (!memberSnapshot.hasData) {
                  return _LoadingExpenses();
                }

                final memberNames = {
                  for (final member in memberSnapshot.data!)
                    member.userId: member.name,
                };

                return StreamBuilder<List<Expense>>(
                  stream: _expensesStream,
                  builder: (context, expenseSnapshot) {
                    if (expenseSnapshot.hasError) {
                      return _ExpensesMessage(
                        icon: Icons.cloud_off_rounded,
                        title: 'Unable to load expenses',
                        message: ExpenseService.userMessage(
                          expenseSnapshot.error!,
                        ),
                        buttonLabel: 'Try again',
                        onPressed: _retry,
                      );
                    }

                    if (!expenseSnapshot.hasData) {
                      return _LoadingExpenses();
                    }

                    final expenses = expenseSnapshot.data!;

                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final horizontalPadding = constraints.maxWidth > 700
                            ? 32.0
                            : 18.0;

                        return Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1000),
                            child: ListView(
                              padding: EdgeInsets.fromLTRB(
                                horizontalPadding,
                                12,
                                horizontalPadding,
                                110,
                              ),
                              children: [
                                _ExpensesHeader(
                                  expenseCount: expenses.length,
                                  memberCount: memberNames.length,
                                ),
                                const SizedBox(height: 28),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.receipt_long_rounded,
                                      color: colors.primary,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'Trip expenses',
                                        style: theme.textTheme.titleLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: -0.5,
                                            ),
                                      ),
                                    ),
                                    if (expenses.isNotEmpty)
                                      Text(
                                        '${expenses.length} '
                                        '${expenses.length == 1 ? 'item' : 'items'}',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: colors.onSurfaceVariant,
                                            ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                if (expenses.isEmpty)
                                  _EmptyExpenses(onAdd: _addExpense)
                                else
                                  for (final expense in expenses)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 12,
                                      ),
                                      child: Stack(
                                        children: [
                                          ExpenseCard(
                                            expense: expense,
                                            currentUserId: currentUserId,
                                            memberNames: memberNames,
                                            onEdit: () => _editExpense(expense),
                                            onDelete: () =>
                                                _deleteExpense(expense),
                                          ),
                                          if (_busyExpenseIds.contains(
                                            expense.id,
                                          ))
                                            Positioned.fill(
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: colors.surface
                                                      .withValues(alpha: 0.7),
                                                  borderRadius:
                                                      BorderRadius.circular(18),
                                                ),
                                                child: Center(
                                                  child:
                                                      CircularProgressIndicator(
                                                        color: colors.primary,
                                                      ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
      floatingActionButton: currentUserId == null
          ? null
          : FloatingActionButton.extended(
              onPressed: _addExpense,
              elevation: 4,
              backgroundColor: colors.primary,
              foregroundColor: colors.onPrimary,
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Add Expense',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
    );
  }
}

class _ExpensesHeader extends StatelessWidget {
  const _ExpensesHeader({
    required this.expenseCount,
    required this.memberCount,
  });

  final int expenseCount;
  final int memberCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6548E8), Color(0xFF8B72F4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6548E8).withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.account_balance_wallet_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Travel together. Spend smarter.',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.7,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Keep shared costs organized and make settling up easier.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.88),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _ExpenseHeaderStat(
                  icon: Icons.receipt_long_rounded,
                  value: '$expenseCount',
                  label: expenseCount == 1 ? 'Expense' : 'Expenses',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ExpenseHeaderStat(
                  icon: Icons.groups_rounded,
                  value: '$memberCount',
                  label: memberCount == 1 ? 'Member' : 'Members',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExpenseHeaderStat extends StatelessWidget {
  const _ExpenseHeaderStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 23),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyExpenses extends StatelessWidget {
  const _EmptyExpenses({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        children: [
          Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              Icons.receipt_long_outlined,
              color: colors.onPrimaryContainer,
              size: 38,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No expenses yet',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Add your first shared expense to start tracking '
            'your trip spending.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 22),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add your first expense'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingExpenses extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: colors.primary),
          const SizedBox(height: 16),
          const Text('Loading trip expenses...'),
        ],
      ),
    );
  }
}

class _ExpensesMessage extends StatelessWidget {
  const _ExpensesMessage({
    required this.message,
    required this.icon,
    required this.title,
    this.buttonLabel,
    this.onPressed,
  });

  final String title;
  final String message;
  final IconData icon;
  final String? buttonLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: colors.outlineVariant),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Icon(icon, size: 38, color: colors.onPrimaryContainer),
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
                if (buttonLabel != null) ...[
                  const SizedBox(height: 22),
                  FilledButton.icon(
                    onPressed: onPressed,
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(buttonLabel!),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
