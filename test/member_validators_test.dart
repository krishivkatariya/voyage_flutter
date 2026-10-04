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

  group('MemberValidators.normalizeEmail', () {
    test('lowercases an email address for directory lookup', () {
      expect(
        MemberValidators.normalizeEmail('Test@Example.com'),
        'test@example.com',
      );
    });

    test('removes leading and trailing whitespace', () {
      expect(
        MemberValidators.normalizeEmail('  member@example.com  '),
        'member@example.com',
      );
      expect(
        MemberValidators.normalizeEmail('  Test@Example.com '),
        'test@example.com',
      );
    });

    test('rejects an empty email', () {
      expect(MemberValidators.normalizeEmail(''), '');
      expect(MemberValidators.normalizeEmail('   '), '');
      expect(
        MemberValidators.validateEmail(MemberValidators.normalizeEmail('   ')),
        isNotNull,
      );
      expect(
        MemberValidators.validateEmail(MemberValidators.normalizeEmail(null)),
        isNotNull,
      );
    });

    test('produces a normalized email that can be used for lookup', () {
      final normalized =
          MemberValidators.normalizeEmail('  USER@Example.COM  ');
      expect(normalized, 'user@example.com');
      // The value a directory document stores and the value a lookup queries
      // both come from this helper, so they always match exactly.
      expect(MemberValidators.validateEmail(normalized), isNull);
      expect(
        MemberValidators.normalizeEmail(normalized),
        normalized,
      );
    });
  });
}
