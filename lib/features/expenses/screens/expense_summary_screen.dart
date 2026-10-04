import 'package:flutter/material.dart';
import 'package:voyage_flutter/features/collaboration/services/collaboration_service.dart';
import 'package:voyage_flutter/features/expenses/models/expense_balance.dart';
import 'package:voyage_flutter/features/expenses/models/expense_settlement.dart';
import 'package:voyage_flutter/features/expenses/services/expense_balance_calculator.dart';
import 'package:voyage_flutter/features/expenses/services/expense_service.dart';
import 'package:voyage_flutter/features/expenses/services/expense_settlement_calculator.dart';
import 'package:voyage_flutter/models/expense.dart';
import 'package:voyage_flutter/models/trip_member.dart';

class ExpenseSummaryScreen extends StatefulWidget {
  const ExpenseSummaryScreen({required this.tripId, super.key});

  final String tripId;

  @override
  State<ExpenseSummaryScreen> createState() => _ExpenseSummaryScreenState();
}

class _ExpenseSummaryScreenState extends State<ExpenseSummaryScreen> {
  final _expenseService = ExpenseService();
  final _collaborationService = CollaborationService();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Expense Summary')),
      body: FutureBuilder<List<TripMember>>(
        future: _membersFuture,
        builder: (context, memberSnapshot) {
          if (memberSnapshot.hasError) {
            return _SummaryMessage(
              message: CollaborationService.userMessage(memberSnapshot.error!),
              onRetry: _retry,
            );
          }
          if (!memberSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          return StreamBuilder<List<Expense>>(
            stream: _expensesStream,
            builder: (context, expenseSnapshot) {
              if (expenseSnapshot.hasError) {
                return _SummaryMessage(
                  message: ExpenseService.userMessage(expenseSnapshot.error!),
                  onRetry: _retry,
                );
              }
              if (!expenseSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final expenses = expenseSnapshot.data!;
              final members = memberSnapshot.data!;
              late final List<ExpenseBalance> balances;
              late final List<ExpenseSettlement> settlements;
              try {
                balances = ExpenseBalanceCalculator.calculate(
                  expenses: expenses,
                  members: members,
                );
                settlements = ExpenseSettlementCalculator.calculate(balances);
              } on FormatException {
                return const _SummaryMessage(
                  message:
                      'Expense data could not be summarized. Check that each '
                      'payer is still a trip member and the amounts are valid.',
                );
              }

              final memberIds = members.map((member) => member.userId).toSet();
              final hasUnavailableParticipants = expenses.any(
                (expense) => expense.splitMemberIds.any(
                  (memberId) =>
                      memberId.trim().isEmpty || !memberIds.contains(memberId),
                ),
              );
              final totalCents = expenses.fold<int>(
                0,
                (total, expense) =>
                    total +
                    (expense.amount.isFinite ? expense.amount * 100 : 0)
                        .round(),
              );
              final memberNames = {
                for (final balance in balances)
                  balance.userId: balance.displayName,
              };

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: ListTile(
                      title: const Text('Total Expenses'),
                      trailing: Text(
                        _formatMoney(totalCents / 100),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                  ),
                  if (expenses.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'No expenses recorded yet.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  if (hasUnavailableParticipants)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Some split participants are no longer trip members. '
                          'Their shares are excluded from member balances, so '
                          'these suggestions may be incomplete.',
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  Text(
                    'Member Balances',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  if (balances.isEmpty)
                    const _InlineMessage(message: 'No trip members found.')
                  else
                    for (final balance in balances)
                      _BalanceCard(balance: balance),
                  const SizedBox(height: 20),
                  Text(
                    'Settlement Suggestions',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  if (settlements.isEmpty)
                    _InlineMessage(
                      message: expenses.isEmpty
                          ? 'No settlement required.'
                          : balances.every((balance) => balance.balance == 0)
                          ? 'Everyone is settled.'
                          : 'No complete settlement suggestions are available.',
                    )
                  else
                    for (final settlement in settlements)
                      _SettlementCard(
                        settlement: settlement,
                        memberNames: memberNames,
                      ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  static String _formatMoney(double amount) => _formatRupees(amount);
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.balance});

  final ExpenseBalance balance;

  @override
  Widget build(BuildContext context) {
    final status = balance.balance > 0
        ? 'Should receive ${_formatRupees(balance.balance)}'
        : balance.balance < 0
        ? 'Owes ${_formatRupees(-balance.balance)}'
        : 'Settled';

    return Card(
      child: ListTile(
        title: Text(balance.displayName),
        subtitle: Text(
          'Paid: ${_formatRupees(balance.totalPaid)}\n'
          'Share: ${_formatRupees(balance.totalOwed)}',
        ),
        isThreeLine: true,
        trailing: SizedBox(
          width: 150,
          child: Text(status, textAlign: TextAlign.end),
        ),
      ),
    );
  }
}

class _SettlementCard extends StatelessWidget {
  const _SettlementCard({required this.settlement, required this.memberNames});

  final ExpenseSettlement settlement;
  final Map<String, String> memberNames;

  @override
  Widget build(BuildContext context) {
    final fromName = memberNames[settlement.fromUserId] ?? 'Trip member';
    final toName = memberNames[settlement.toUserId] ?? 'Trip member';

    return Card(
      child: ListTile(
        leading: const Icon(Icons.compare_arrows),
        title: Text(
          '$fromName pays $toName ${_formatRupees(settlement.amount)}',
        ),
      ),
    );
  }
}

class _InlineMessage extends StatelessWidget {
  const _InlineMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(message, textAlign: TextAlign.center),
    );
  }
}

String _formatRupees(double amount) => '₹${amount.toStringAsFixed(2)}';

class _SummaryMessage extends StatelessWidget {
  const _SummaryMessage({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ],
        ),
      ),
    );
  }
}
