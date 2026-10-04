import 'package:flutter_test/flutter_test.dart';
import 'package:voyage_flutter/features/collaboration/services/member_validators.dart';

void main() {
  group('MemberValidators', () {
    test('requires an email', () {
      expect(MemberValidators.validateEmail(' '), isNotNull);
    });

    test('rejects invalid email addresses', () {
      expect(MemberValidators.validateEmail('not-an-email'), isNotNull);
      expect(MemberValidators.validateEmail('missing-domain@'), isNotNull);
    });

    test('accepts a valid email address with surrounding whitespace', () {
      expect(MemberValidators.validateEmail('  member@example.com  '), isNull);
    });
  });
}
