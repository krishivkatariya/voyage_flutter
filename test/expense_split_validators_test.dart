import 'package:flutter_test/flutter_test.dart';
import 'package:voyage_flutter/features/expenses/services/expense_validators.dart';

void main() {
  group('ExpenseValidators.validateSplitMemberIds', () {
    const tripMemberIds = {'payer-uid', 'member-a', 'member-b'};

    test('accepts selected trip members including the payer', () {
      expect(
        ExpenseValidators.validateSplitMemberIds([
          'payer-uid',
          'member-a',
        ], tripMemberIds: tripMemberIds),
        isNull,
      );
    });

    test('rejects an empty split member list', () {
      expect(
        ExpenseValidators.validateSplitMemberIds(
          const [],
          tripMemberIds: tripMemberIds,
        ),
        isNotNull,
      );
    });

    test('rejects duplicate member IDs', () {
      expect(
        ExpenseValidators.validateSplitMemberIds([
          'member-a',
          'member-a',
        ], tripMemberIds: tripMemberIds),
        isNotNull,
      );
    });

    test('rejects IDs that are not trip members', () {
      expect(
        ExpenseValidators.validateSplitMemberIds([
          'outside-user',
        ], tripMemberIds: tripMemberIds),
        isNotNull,
      );
    });
  });
}
