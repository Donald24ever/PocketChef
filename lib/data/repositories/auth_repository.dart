import '../services/security_service.dart';

class AuthResult {
  const AuthResult({
    required this.name,
    required this.email,
    required this.provider,
    this.uid = '',
    this.photoUrl,
    this.createdAt,
  });

  final String name;
  final String email;
  final String provider;

  /// Firebase UID of the authenticated account. Empty for local demo sessions.
  final String uid;

  /// Avatar URL supplied by the identity provider (Google profile photo).
  final String? photoUrl;

  /// Account creation timestamp reported by the identity provider.
  final DateTime? createdAt;
}

abstract class AuthRepository {
  Future<AuthResult> signInWithEmail(String email, String password);

  Future<AuthResult> signInWithGoogle();

  Future<AuthResult> signInWithApple();

  Future<AuthResult> continueAsGuest();

  Future<String> requestEmailVerification(String email);

  Future<bool> confirmEmailVerification(String email, String code);

  Future<void> changePassword(String current, String next);

  Future<DateTime> refreshSession();

  Future<void> deleteAccount(String email);

  /// Signs out of the identity provider and ends the local session.
  Future<void> signOut();

  /// Returns the persisted session (if any) so the app can restore a signed
  /// in user after a restart. Returns null when there is no active session.
  Future<AuthResult?> restoreSession();
}

class DemoAuthRepository implements AuthRepository {
  static const int maxAttempts = 5;
  static const Duration lockDuration = Duration(minutes: 15);

  static const Map<String, String> _verificationCodes = <String, String>{};
  static final Map<String, int> _failedAttempts = <String, int>{};
  static final Map<String, DateTime> _lockedUntil = <String, DateTime>{};

  void _checkLocked(String email) {
    final key = email.toLowerCase();
    final until = _lockedUntil[key];
    if (until != null && DateTime.now().isBefore(until)) {
      final minutes = until.difference(DateTime.now()).inMinutes + 1;
      throw AuthException(
        AuthException.accountLocked,
        'Too many failed attempts. Try again in about $minutes minute(s).',
      );
    }
    if (until != null) {
      _lockedUntil.remove(key);
      _failedAttempts.remove(key);
    }
  }

  void _recordFailure(String email) {
    final key = email.toLowerCase();
    final attempts = (_failedAttempts[key] ?? 0) + 1;
    _failedAttempts[key] = attempts;
    if (attempts >= maxAttempts) {
      _lockedUntil[key] = DateTime.now().add(lockDuration);
    }
  }

  void _clearFailures(String email) {
    final key = email.toLowerCase();
    _failedAttempts.remove(key);
    _lockedUntil.remove(key);
  }

  @override
  Future<AuthResult> signInWithEmail(String email, String password) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    _checkLocked(email);
    final policyIssue = PasswordPolicy.firstIssueMessage(password, email: email);
    if (policyIssue != null || password == 'wrongpassword') {
      _recordFailure(email);
      throw const AuthException(
        AuthException.invalidCredentials,
        'Email or password is incorrect.',
      );
    }
    _clearFailures(email);
    final raw = email
        .split('@')
        .first
        .replaceAll(RegExp(r'[._-]+'), ' ')
        .trim();
    final name = raw.isEmpty
        ? 'PocketChef user'
        : raw
              .split(' ')
              .where((p) => p.isNotEmpty)
              .map((p) => p[0].toUpperCase() + p.substring(1))
              .join(' ');
    return AuthResult(
      name: name,
      email: email,
      provider: 'email',
      uid: 'demo-email-${email.toLowerCase()}',
    );
  }

  @override
  Future<AuthResult> signInWithGoogle() async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    return const AuthResult(
      name: 'Sam Rivera',
      email: 'sam.rivera@gmail.com',
      provider: 'google',
      uid: 'demo-google-sam-rivera',
    );
  }

  @override
  Future<AuthResult> signInWithApple() async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    return const AuthResult(
      name: 'Jordan Okafor',
      email: 'jordan@icloud.com',
      provider: 'apple',
      uid: 'demo-apple-jordan-okafor',
    );
  }

  @override
  Future<AuthResult> continueAsGuest() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return const AuthResult(name: 'Guest chef', email: '', provider: 'guest');
  }

  @override
  Future<String> requestEmailVerification(String email) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    final code = (100000 + DateTime.now().millisecondsSinceEpoch % 900000)
        .toString();
    _verificationCodes[email.toLowerCase()] = code;
    return code;
  }

  @override
  Future<bool> confirmEmailVerification(String email, String code) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    final expected = _verificationCodes[email.toLowerCase()];
    if (expected == null || expected != code.trim()) return false;
    _verificationCodes.remove(email.toLowerCase());
    return true;
  }

  @override
  Future<void> changePassword(String current, String next) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (PasswordPolicy.firstIssueMessage(current) != null) {
      throw const AuthException(
        AuthException.wrongPassword,
        'Your current password is incorrect.',
      );
    }
  }

  @override
  Future<DateTime> refreshSession() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return DateTime.now();
  }

  @override
  Future<void> deleteAccount(String email) async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    _clearFailures(email);
    _verificationCodes.remove(email.toLowerCase());
  }

  @override
  Future<void> signOut() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
  }

  @override
  Future<AuthResult?> restoreSession() async => null;
}