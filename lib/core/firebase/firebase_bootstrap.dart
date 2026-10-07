import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';

/// Initialises Firebase when the app was built with Firebase options supplied
/// via `--dart-define`. When it wasn't, every method is a safe no-op, which is
/// what lets the release APK build and run without a `google-services.json`.
class FirebaseBootstrap {
  const FirebaseBootstrap._();

  static bool _ready = false;

  static bool get isReady => _ready;

  static Future<void> init() async {
    if (!AppConfig.hasFirebase) return;
    try {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: AppConfig.firebaseApiKey,
          appId: AppConfig.firebaseAppId,
          messagingSenderId: AppConfig.firebaseMessagingSenderId,
          projectId: AppConfig.firebaseProjectId,
          storageBucket: AppConfig.firebaseStorageBucket,
          authDomain: AppConfig.firebaseAuthDomain,
        ),
      );
      _ready = true;
    } catch (error) {
      _ready = false;
      if (kDebugMode) debugPrint('Firebase not initialised: $error');
    }
  }

  static void reportError(Object error, StackTrace? stack) {
    if (!_ready) return;
    try {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: false);
    } catch (_) {
      // Never let telemetry throw.
    }
  }

  static Future<void> logEvent(String name, [Map<String, Object>? params]) async {
    if (!_ready) return;
    try {
      await FirebaseAnalytics.instance.logEvent(name: name, parameters: params);
    } catch (_) {
      // Never let analytics throw.
    }
  }
}