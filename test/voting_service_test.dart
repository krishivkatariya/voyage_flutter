import 'package:flutter_test/flutter_test.dart';
import 'package:voyage_flutter/features/collaboration/services/voting_service.dart';

void main() {
  group('VoteStatus', () {
    test('counts voter documents and identifies the current user', () {
      final status = VoteStatus.fromVoterIds([
        'uid-one',
        'uid-two',
        'current-uid',
      ], 'current-uid');

      expect(status.count, 3);
      expect(status.hasVoted, isTrue);
    });

    test('reports no vote for the current user when absent', () {
      final status = VoteStatus.fromVoterIds([
        'uid-one',
        'uid-two',
      ], 'current-uid');

      expect(status.count, 2);
      expect(status.hasVoted, isFalse);
    });

    test('reports an empty vote collection', () {
      final status = VoteStatus.fromVoterIds(const [], 'current-uid');

      expect(status.count, 0);
      expect(status.hasVoted, isFalse);
    });
  });
}
