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
      backgroundColor: const Color(0xFFF7F6FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F6FC),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Expense Summary',
          style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.4),
        ),
      ),
      body: FutureBuilder<List<TripMember>>(
        future: _membersFuture,
        builder: (context, memberSnapshot) {
          if (memberSnapshot.hasError) {
            return _SummaryMessage(
              icon: Icons.cloud_off_rounded,
              title: 'Unable to load members',
              message: CollaborationService.userMessage(memberSnapshot.error!),
              onRetry: _retry,
            );
          }

          if (!memberSnapshot.hasData) {
            return _LoadingSummary();
          }

          return StreamBuilder<List<Expense>>(
            stream: _expensesStream,
            builder: (context, expenseSnapshot) {
              if (expenseSnapshot.hasError) {
                return _SummaryMessage(
                  icon: Icons.cloud_off_rounded,
                  title: 'Unable to load expenses',
                  message: ExpenseService.userMessage(expenseSnapshot.error!),
                  onRetry: _retry,
                );
              }

              if (!expenseSnapshot.hasData) {
                return _LoadingSummary();
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
                  icon: Icons.warning_amber_rounded,
                  title: 'Unable to calculate balances',
                  message:
                      'Expense data could not be summarized. Check that '
                      'each payer is still a trip member and the amounts '
                      'are valid.',
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
                          36,
                        ),
                        children: [
                          _TotalExpensesCard(
                            total: totalCents / 100,
                            expenseCount: expenses.length,
                            memberCount: members.length,
                          ),
                          const SizedBox(height: 28),

                          if (hasUnavailableParticipants) ...[
                            const _ParticipantWarning(),
                            const SizedBox(height: 20),
                          ],

                          _SectionHeading(
                            icon: Icons.people_alt_rounded,
                            title: 'Member balances',
                            subtitle:
                                'See who owes money and who should '
                                'receive it.',
                            count: balances.length,
                          ),
                          const SizedBox(height: 14),

                          if (balances.isEmpty)
                            const _InlineMessage(
                              icon: Icons.people_outline_rounded,
                              message: 'No trip members found.',
                            )
                          else
                            for (final balance in balances)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _BalanceCard(balance: balance),
                              ),

                          const SizedBox(height: 22),

                          _SectionHeading(
                            icon: Icons.swap_horiz_rounded,
                            title: 'Settlement suggestions',
                            subtitle:
                                'Suggested payments to settle up '
                                'between trip members.',
                            count: settlements.length,
                          ),
                          const SizedBox(height: 14),

                          if (settlements.isEmpty)
                            _InlineMessage(
                              icon: expenses.isEmpty
                                  ? Icons.receipt_long_outlined
                                  : Icons.check_circle_outline_rounded,
                              message: expenses.isEmpty
                                  ? 'No expenses yet. Add an expense to '
                                        'start tracking shared costs.'
                                  : balances.every(
                                      (balance) => balance.balance == 0,
                                    )
                                  ? 'Everyone is settled. No payments '
                                        'are needed.'
                                  : 'No complete settlement suggestions '
                                        'are available.',
                            )
                          else
                            for (int i = 0; i < settlements.length; i++)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _SettlementCard(
                                  settlement: settlements[i],
                                  memberNames: memberNames,
                                  number: i + 1,
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
    );
  }
}

class _TotalExpensesCard extends StatelessWidget {
  const _TotalExpensesCard({
    required this.total,
    required this.expenseCount,
    required this.memberCount,
  });

  final double total;
  final int expenseCount;
  final int memberCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
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
          Row(
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
                  size: 27,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Total trip expenses',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.92),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            _formatRupees(total),
            style: theme.textTheme.headlineLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Keep track of every shared cost.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _TotalStat(
                  icon: Icons.receipt_long_rounded,
                  value: '$expenseCount',
                  label: expenseCount == 1 ? 'Expense' : 'Expenses',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TotalStat(
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

class _TotalStat extends StatelessWidget {
  const _TotalStat({
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

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.count,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(icon, color: colors.onPrimaryContainer, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        if (count != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.balance});

  final ExpenseBalance balance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final isReceiving = balance.balance > 0;
    final isOwing = balance.balance < 0;

    final Color statusColor;
    final Color statusBackground;
    final IconData statusIcon;
    final String status;

    if (isReceiving) {
      statusColor = const Color(0xFF16845B);
      statusBackground = const Color(0xFFE3F6ED);
      statusIcon = Icons.south_west_rounded;
      status = 'Gets back';
    } else if (isOwing) {
      statusColor = const Color(0xFFD34C4C);
      statusBackground = const Color(0xFFFFE9E7);
      statusIcon = Icons.north_east_rounded;
      status = 'Owes';
    } else {
      statusColor = const Color(0xFF64748B);
      statusBackground = const Color(0xFFF0F1F5);
      statusIcon = Icons.check_circle_outline_rounded;
      status = 'Settled';
    }

    final balanceAmount = balance.balance.abs();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: colors.primaryContainer,
                child: Text(
                  balance.displayName.trim().isEmpty
                      ? '?'
                      : balance.displayName.trim()[0].toUpperCase(),
                  style: TextStyle(
                    color: colors.onPrimaryContainer,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  balance.displayName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: statusBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, color: statusColor, size: 16),
                    const SizedBox(width: 5),
                    Text(
                      status,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Divider(
            color: colors.outlineVariant.withValues(alpha: 0.6),
            height: 1,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _BalanceDetail(
                  label: 'Total paid',
                  amount: balance.totalPaid,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _BalanceDetail(
                  label: 'Share of costs',
                  amount: balance.totalOwed,
                ),
              ),
            ],
          ),
          if (balance.balance != 0) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: statusBackground,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                '${isReceiving ? 'Should receive' : 'Needs to pay'} '
                '${_formatRupees(balanceAmount)}',
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BalanceDetail extends StatelessWidget {
  const _BalanceDetail({required this.label, required this.amount});

  final String label;
  final double amount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          _formatRupees(amount),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _SettlementCard extends StatelessWidget {
  const _SettlementCard({
    required this.settlement,
    required this.memberNames,
    required this.number,
  });

  final ExpenseSettlement settlement;
  final Map<String, String> memberNames;
  final int number;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final fromName = memberNames[settlement.fromUserId] ?? 'Trip member';
    final toName = memberNames[settlement.toUserId] ?? 'Trip member';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$number',
                  style: TextStyle(
                    color: colors.onPrimaryContainer,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Suggested payment',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.check_circle_outline_rounded,
                color: colors.primary,
                size: 21,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _SettlementPerson(
                  name: fromName,
                  caption: 'Pays',
                  icon: Icons.north_east_rounded,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: colors.primary,
                  size: 23,
                ),
              ),
              Expanded(
                child: _SettlementPerson(
                  name: toName,
                  caption: 'Receives',
                  icon: Icons.south_west_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            decoration: BoxDecoration(
              color: colors.primaryContainer.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: [
                Icon(Icons.payments_outlined, color: colors.onPrimaryContainer),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Settlement amount',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  _formatRupees(settlement.amount),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colors.onPrimaryContainer,
                    fontWeight: FontWeight.w800,
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

class _SettlementPerson extends StatelessWidget {
  const _SettlementPerson({
    required this.name,
    required this.caption,
    required this.icon,
  });

  final String name;
  final String caption;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Row(
      children: [
        CircleAvatar(
          radius: 19,
          backgroundColor: colors.surfaceContainerHighest,
          child: Icon(icon, color: colors.primary, size: 20),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                caption,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ParticipantWarning extends StatelessWidget {
  const _ParticipantWarning();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4DF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF3D8A2)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: Color(0xFF9A6700), size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Some split participants are no longer trip members. '
              'Their shares are excluded from member balances, so '
              'these suggestions may be incomplete.',
              style: TextStyle(color: Color(0xFF7A5200), height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineMessage extends StatelessWidget {
  const _InlineMessage({required this.message, required this.icon});

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        children: [
          Icon(icon, size: 38, color: colors.primary),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingSummary extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: colors.primary),
          const SizedBox(height: 16),
          const Text('Calculating trip expenses...'),
        ],
      ),
    );
  }
}

class _SummaryMessage extends StatelessWidget {
  const _SummaryMessage({
    required this.title,
    required this.message,
    required this.icon,
    this.onRetry,
  });

  final String title;
  final String message;
  final IconData icon;
  final VoidCallback? onRetry;

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
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Icon(icon, color: colors.onPrimaryContainer, size: 35),
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
                if (onRetry != null) ...[
                  const SizedBox(height: 22),
                  FilledButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Try again'),
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

String _formatRupees(double amount) => '₹${amount.toStringAsFixed(2)}';
