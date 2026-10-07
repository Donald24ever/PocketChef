import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/config/app_config.dart';
import '../services/security_service.dart';
import 'auth_repository.dart';

/// [AuthRepository] backed by Firebase Authentication.
///
/// Used only when the app was built with Firebase options (see
/// [FirebaseBootstrap]). Email/password, Google and anonymous (guest) are
/// supported; Apple reports a clear, actionable error until its OAuth client
/// is configured in the Firebase console.
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuth get _auth => FirebaseAuth.instance;

  static bool _googleInitialized = false;

  /// [GoogleSignIn.instance.initialize] may only run once per process.
  Future<GoogleSignIn> _google() async {
    final instance = GoogleSignIn.instance;
    if (!_googleInitialized) {
      // serverClientId sets the ID-token audience; without it the platform
      // cannot mint a token Firebase will accept.
      await instance.initialize(
        serverClientId: AppConfig.googleWebClientId.isEmpty
            ? null
            : AppConfig.googleWebClientId,
      );
      _googleInitialized = true;
    }
    return instance;
  }

  @override
  Future<AuthResult> signInWithEmail(String email, String password) async {
    final policy = PasswordPolicy.firstIssueMessage(password, email: email);
    if (policy != null) {
      throw const AuthException(
        AuthException.invalidCredentials,
        'Email or password is incorrect.',
      );
    }
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return _result(cred.user, 'email');
    } on FirebaseAuthException catch (error) {
      if (error.code == 'user-not-found') {
        final cred = await _auth.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
        return _result(cred.user, 'email');
      }
      throw _map(error);
    }
  }

  /// Real Google sign-in.
  ///
  /// Flow: silent sign-in for a returning account (session restore), otherwise
  /// the interactive account picker. The resulting Google ID token is exchanged
  /// for a Firebase credential, which creates the account on first sign-in and
  /// re-authenticates on every visit afterwards. Firebase persists the session
  /// across app restarts.
  @override
  Future<AuthResult> signInWithGoogle() async {
    try {
      final google = await _google();

      var account = await google.attemptLightweightAuthentication();
      if (account == null) {
        if (!google.supportsAuthenticate()) {
          throw const AuthException(
            'unsupported',
            'Google sign-in is not available on this device. '
                'Use email or continue as guest.',
          );
        }
        account = await google.authenticate();
      }

      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw const AuthException(
          'google-token',
          'Google did not return a sign-in token. Please try again.',
        );
      }

      final credential = GoogleAuthProvider.credential(idToken: idToken);
      final cred = await _auth.signInWithCredential(credential);
      return _result(
        cred.user,
        'google',
        fallbackName: account.displayName,
        fallbackPhoto: account.photoUrl,
      );
    } on AuthException {
      rethrow;
    } on GoogleSignInException catch (error) {
      throw _mapGoogle(error);
    } on FirebaseAuthException catch (error) {
      throw _map(error);
    } catch (error) {
      throw AuthException(
        'google',
        'Google sign-in failed. Check your connection and try again.',
      );
    }
  }

  @override
  Future<AuthResult> signInWithApple() async {
    throw const AuthException(
      'unsupported',
      'Apple sign-in is not configured for this build. Use email or continue as guest.',
    );
  }

  @override
  Future<AuthResult> continueAsGuest() async {
    final cred = await _auth.signInAnonymously();
    return _result(cred.user, 'guest');
  }

  @override
  Future<String> requestEmailVerification(String email) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthException(
        AuthException.invalidVerificationCode,
        'Sign in before requesting a verification email.',
      );
    }
    await user.sendEmailVerification();
    return 'sent';
  }

  @override
  Future<bool> confirmEmailVerification(String email, String code) async {
    final user = _auth.currentUser;
    if (user == null) return false;
    await user.reload();
    return _auth.currentUser?.emailVerified ?? false;
  }

  @override
  Future<void> changePassword(String current, String next) async {
    final user = _auth.currentUser;
    final email = user?.email;
    if (user == null || email == null) {
      throw const AuthException(
        AuthException.wrongPassword,
        'Your current password is incorrect.',
      );
    }
    try {
      await user.reauthenticateWithCredential(
        EmailAuthProvider.credential(email: email, password: current),
      );
      await user.updatePassword(next);
    } on FirebaseAuthException {
      throw const AuthException(
        AuthException.wrongPassword,
        'Your current password is incorrect.',
      );
    }
  }

  @override
  Future<DateTime> refreshSession() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthException(
        AuthException.invalidCredentials,
        'No active session.',
      );
    }
    await user.getIdToken(true);
    return DateTime.now();
  }

  @override
  Future<void> deleteAccount(String email) async {
    await _auth.currentUser?.delete();
  }

  @override
  Future<void> signOut() async {
    if (_googleInitialized) {
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {
        // Google session cleanup is best-effort; Firebase sign-out must run.
      }
    }
    await _auth.signOut();
  }

  /// Restores the Firebase session persisted by the SDK (if any) so an
  /// app restart lands the user straight back in their account.
  @override
  Future<AuthResult?> restoreSession() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return _result(user, _providerFor(user));
  }

  String _providerFor(User user) {
    for (final info in user.providerData) {
      if (info.providerId == 'google.com') return 'google';
      if (info.providerId == 'apple.com') return 'apple';
      if (info.providerId == 'password') return 'email';
    }
    return user.isAnonymous ? 'guest' : 'email';
  }

  AuthResult _result(
    User? user,
    String provider, {
    String? fallbackName,
    String? fallbackPhoto,
  }) {
    if (user == null) {
      throw const AuthException(
        AuthException.invalidCredentials,
        'Sign-in failed. Please try again.',
      );
    }
    final display = user.displayName?.trim() ?? '';
    final name = display.isNotEmpty
        ? display
        : (fallbackName?.trim().isNotEmpty ?? false)
        ? fallbackName!.trim()
        : _nameFromEmail(user.email ?? '');
    final photo = user.photoURL ?? fallbackPhoto;
    return AuthResult(
      name: name,
      email: user.email ?? '',
      provider: provider,
      uid: user.uid,
      photoUrl: (photo != null && photo.isNotEmpty) ? photo : null,
      createdAt: user.metadata.creationTime,
    );
  }

  String _nameFromEmail(String email) {
    final raw = email
        .split('@')
        .first
        .replaceAll(RegExp(r'[._-]+'), ' ')
        .trim();
    if (raw.isEmpty) return 'PocketChef user';
    return raw
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase() + part.substring(1))
        .join(' ');
  }

  AuthException _mapGoogle(GoogleSignInException error) {
    switch (error.code) {
      case GoogleSignInExceptionCode.canceled:
        return const AuthException(
          'google-canceled',
          'Google sign-in was cancelled.',
        );
      case GoogleSignInExceptionCode.clientConfigurationError:
      case GoogleSignInExceptionCode.providerConfigurationError:
        return const AuthException(
          'unsupported',
          'Google sign-in is not configured for this build. '
              'Add the SHA-1 fingerprint in the Firebase console, or use email.',
        );
      case GoogleSignInExceptionCode.uiUnavailable:
        return const AuthException(
          'google',
          'Google sign-in could not open a window. Try again.',
        );
      default:
        return AuthException(
          'google',
          error.description ?? 'Google sign-in failed. Please try again.',
        );
    }
  }

  AuthException _map(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return const AuthException(
          AuthException.invalidCredentials,
          'That email address looks incomplete.',
        );
      case 'wrong-password':
      case 'invalid-credential':
      case 'invalid-login-credentials':
        return const AuthException(
          AuthException.invalidCredentials,
          'Email or password is incorrect.',
        );
      case 'too-many-requests':
        return const AuthException(
          AuthException.accountLocked,
          'Too many attempts. Try again in a few minutes.',
        );
      case 'weak-password':
        return const AuthException(
          AuthException.invalidCredentials,
          'Choose a stronger password.',
        );
      case 'network-request-failed':
        return const AuthException(
          'network',
          'You appear to be offline. Check your connection and retry.',
        );
      case 'email-already-in-use':
        return const AuthException(
          AuthException.invalidCredentials,
          'That email is already registered. Sign in instead.',
        );
      default:
        return AuthException(
          error.code,
          error.message ?? 'Authentication failed. Please try again.',
        );
    }
  }
}