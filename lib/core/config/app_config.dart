/// Compile-time configuration.
///
/// Every value is injected with `--dart-define` at build time, so no secret is
/// ever committed to source control. Example:
///
/// ```
/// flutter build apk --release \
///   --dart-define=APP_ENV=production \
///   --dart-define=GEMINI_API_KEY=... \
///   --dart-define=FIREBASE_API_KEY=... \
///   --dart-define=FIREBASE_PROJECT_ID=...
/// ```
class AppConfig {
  const AppConfig._();

  static const String environment =
      String.fromEnvironment('APP_ENV', defaultValue: 'production');

  static const String geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');

  static const String firebaseApiKey =
      String.fromEnvironment('FIREBASE_API_KEY');
  static const String firebaseProjectId =
      String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const String firebaseAppId = String.fromEnvironment('FIREBASE_APP_ID');
  static const String firebaseMessagingSenderId =
      String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
  static const String firebaseStorageBucket =
      String.fromEnvironment('FIREBASE_STORAGE_BUCKET');
  static const String firebaseAuthDomain =
      String.fromEnvironment('FIREBASE_AUTH_DOMAIN');
  static const String firebaseMeasurementId =
      String.fromEnvironment('FIREBASE_MEASUREMENT_ID');

  /// OAuth "Web application" client id used as the audience for the Google
  /// ID token (Google Cloud console → APIs & Services → Credentials, or the
  /// auto-created Web client shown in Firebase Authentication → Sign-in method).
  static const String googleWebClientId =
      String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');

  static const String geminiModel =
      String.fromEnvironment('GEMINI_MODEL', defaultValue: 'gemini-3.1-flash-lite');

  static bool get isProduction => environment == 'production';

  static bool get hasGeminiKey => geminiApiKey.isNotEmpty;

  static bool get hasFirebase =>
      firebaseApiKey.isNotEmpty &&
      firebaseProjectId.isNotEmpty &&
      firebaseAppId.isNotEmpty &&
      firebaseMessagingSenderId.isNotEmpty;

  /// Real Google sign-in needs both Firebase and an OAuth audience.
  static bool get hasGoogleSignIn =>
      hasFirebase && googleWebClientId.isNotEmpty;
}