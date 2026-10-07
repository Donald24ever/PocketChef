import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/firebase/firebase_bootstrap.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/firebase_auth_repository.dart';

/// Uses Firebase Authentication when Firebase is configured; otherwise the
/// offline demo repository so the app always works.
///
/// Lives in its own file so both the app session state and the feature layer
/// can depend on it without import cycles.
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => FirebaseBootstrap.isReady
      ? FirebaseAuthRepository()
      : DemoAuthRepository(),
);
