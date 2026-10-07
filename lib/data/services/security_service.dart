enum PasswordIssue { tooShort, needsUpper, needsLower, needsDigit, resemblesEmail, common }

class PasswordPolicy {
  static const int minLength = 8;

  static const Set<String> _common = {
    'password',
    'password1',
    'password123',
    '12345678',
    '123456789',
    'qwertyui',
    'qwerty123',
    'iloveyou',
    'letmein',
    'football',
    'abc12345',
    'monkey123',
    'dragon123',
    'trustno1',
    'pocketchef',
    'chef1234',
    'admin123',
    'welcome1',
    'sunshine',
    'password!',
  };

  static List<PasswordIssue> issues(String password, {String? email}) {
    final issues = <PasswordIssue>[];
    if (password.length < minLength) issues.add(PasswordIssue.tooShort);
    if (!RegExp(r'[A-Z]').hasMatch(password)) issues.add(PasswordIssue.needsUpper);
    if (!RegExp(r'[a-z]').hasMatch(password)) issues.add(PasswordIssue.needsLower);
    if (!RegExp(r'\d').hasMatch(password)) issues.add(PasswordIssue.needsDigit);
    if (_common.contains(password.toLowerCase())) {
      issues.add(PasswordIssue.common);
    }
    if (email != null) {
      final local = email.split('@').first.toLowerCase();
      final normalized = password.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
      if (normalized.isNotEmpty &&
          (normalized == local ||
              (local.length >= 3 && normalized.contains(local)))) {
        issues.add(PasswordIssue.resemblesEmail);
      }
    }
    return issues;
  }

  static String? firstIssueMessage(String password, {String? email}) {
    final result = issues(password, email: email);
    if (result.isEmpty) return null;
    final first = result.first;
    return switch (first) {
      PasswordIssue.tooShort => 'Use at least $minLength characters',
      PasswordIssue.needsUpper => 'Add an uppercase letter',
      PasswordIssue.needsLower => 'Add a lowercase letter',
      PasswordIssue.needsDigit => 'Add a number',
      PasswordIssue.resemblesEmail => 'Do not reuse your email address',
      PasswordIssue.common => 'This password is too easy to guess',
    };
  }

  static List<String> helpTexts(
    String password, {
    String? email,
    bool complianceRequired = false,
  }) {
    final result = issues(password, email: email);
    if (result.isEmpty) return const [];
    const guidance = <PasswordIssue, String>{
      PasswordIssue.tooShort: 'At least $minLength characters',
      PasswordIssue.needsUpper: 'One uppercase letter',
      PasswordIssue.needsLower: 'One lowercase letter',
      PasswordIssue.needsDigit: 'One number',
      PasswordIssue.resemblesEmail: 'Different from your email',
      PasswordIssue.common: 'Not a common password',
    };
    if (complianceRequired) {
      return [
        for (final issue in result) guidance[issue]!,
      ];
    }
    final first = result.first;
    return [guidance[first]!];
  }
}

class AuthException implements Exception {
  const AuthException(this.code, this.message);

  final String code;
  final String message;

  static const invalidCredentials = 'invalid-credentials';
  static const accountLocked = 'account-locked';
  static const invalidVerificationCode = 'invalid-verification-code';
  static const wrongPassword = 'wrong-password';

  @override
  String toString() => message;
}

class SecurityAuditEntry {
  const SecurityAuditEntry({
    required this.id,
    required this.action,
    required this.detail,
    required this.at,
  });

  final String id;
  final String action;
  final String detail;
  final DateTime at;
}

class ActiveSession {
  const ActiveSession({
    required this.device,
    required this.location,
    required this.signedInAt,
    required this.refreshedAt,
  });

  final String device;
  final String location;
  final DateTime signedInAt;
  final DateTime refreshedAt;
}