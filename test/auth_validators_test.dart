import 'package:flutter_test/flutter_test.dart';
import 'package:voyage_flutter/features/auth/services/auth_validators.dart';

void main() {
  group('AuthValidators', () {
    test('requires a non-blank name', () {
      expect(AuthValidators.validateName('  '), isNotNull);
      expect(AuthValidators.validateName('Voyager'), isNull);
    });

    test('validates required email and basic email format', () {
      expect(AuthValidators.validateEmail(' '), isNotNull);
      expect(AuthValidators.validateEmail('not-an-email'), isNotNull);
      expect(AuthValidators.validateEmail('person@example.com'), isNull);
    });

    test('requires a password of at least six characters', () {
      expect(AuthValidators.validatePassword(''), isNotNull);
      expect(AuthValidators.validatePassword('12345'), isNotNull);
      expect(AuthValidators.validatePassword('123456'), isNull);
    });

    test('requires matching confirmation password', () {
      expect(
        AuthValidators.validateConfirmPassword('', password: 'secret1'),
        isNotNull,
      );
      expect(
        AuthValidators.validateConfirmPassword('secret2', password: 'secret1'),
        isNotNull,
      );
      expect(
        AuthValidators.validateConfirmPassword('secret1', password: 'secret1'),
        isNull,
      );
    });
  });
}
