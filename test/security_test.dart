import 'package:flutter_test/flutter_test.dart';
import 'package:pocketchef_ai/data/repositories/auth_repository.dart';
import 'package:pocketchef_ai/data/services/security_service.dart';

void main() {
  group('PasswordPolicy', () {
    test('rejects weak passwords with clear guidance', () {
      expect(PasswordPolicy.firstIssueMessage('short'), 'Use at least 8 characters');
      expect(PasswordPolicy.firstIssueMessage('password1'), isNotNull);
      expect(PasswordPolicy.firstIssueMessage('onlylowercase1'),
          'Add an uppercase letter');
      expect(PasswordPolicy.firstIssueMessage('ONLYUPPERCASE1'),
          'Add a lowercase letter');
      expect(PasswordPolicy.firstIssueMessage('NoDigitsHere'),
          'Add a number');
    });

    test('accepts a strong password', () {
      expect(PasswordPolicy.firstIssueMessage('YamAndEgusi42'), isNull);
    });

    test('rejects passwords that reuse the email prefix', () {
      expect(
        PasswordPolicy.firstIssueMessage(
          'samrivera99',
          email: 'sam.rivera@gmail.com',
        ),
        isNotNull,
      );
    });
  });

  group('AuthRepository lockout', () {
    test('locks an account after five failed attempts', () async {
      final repo = DemoAuthRepository();
      for (var i = 0; i < 5; i++) {
        try {
          await repo.signInWithEmail('lock@example.com', 'wrongpassword');
          fail('expected invalid credentials');
        } on AuthException catch (e) {
          expect(e.code, AuthException.invalidCredentials);
        }
      }
      await expectLater(
        repo.signInWithEmail('lock@example.com', 'Password123'),
        throwsA(
          isA<AuthException>().having((e) => e.code, 'code', AuthException.accountLocked),
        ),
      );
    });

    test('succeeds with the demo strong credential', () async {
      final repo = DemoAuthRepository();
      final result = await repo.signInWithEmail('ada@example.com', 'YamAndEgusi42');
      expect(result.email, 'ada@example.com');
      expect(result.provider, 'email');
    });
  });
}