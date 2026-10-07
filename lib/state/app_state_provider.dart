import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/firebase/firebase_bootstrap.dart';
import '../data/models/recipe.dart';
import '../data/models/user.dart';
import '../data/repositories/auth_repository.dart';
import '../data/services/local_store.dart';
import 'auth_providers.dart';
import 'cloud_providers.dart';
import 'security_providers.dart';

class AppState {
  const AppState({
    required this.onboarded,
    required this.authed,
    required this.theme,
    required this.profile,
  });

  final bool onboarded;
  final bool authed;
  final ThemePreference theme;
  final UserProfile profile;

  AppState copyWith({
    bool? onboarded,
    bool? authed,
    ThemePreference? theme,
    UserProfile? profile,
  }) {
    return AppState(
      onboarded: onboarded ?? this.onboarded,
      authed: authed ?? this.authed,
      theme: theme ?? this.theme,
      profile: profile ?? this.profile,
    );
  }
}

class AppStateNotifier extends AsyncNotifier<AppState> {
  @override
  Future<AppState> build() async {
    final sp = await SharedPreferences.getInstance();
    final authed = sp.getBool('authed') ?? false;
    var profile = _readProfile(sp, authed);

    // Firebase restores its own session asynchronously; refresh the profile
    // from it when possible so uid / photo / provider stay accurate across
    // restarts. A null result never signs anyone out — the local session
    // stays valid until the user signs out explicitly.
    if (authed && profile.uid.isNotEmpty && FirebaseBootstrap.isReady) {
      try {
        final session = await ref.read(authRepositoryProvider).restoreSession();
        if (session != null) {
          profile = profile.copyWith(
            uid: session.uid.isNotEmpty ? session.uid : profile.uid,
            photoUrl: session.photoUrl ?? profile.photoUrl,
            lastLoginAt: DateTime.now(),
          );
        }
      } catch (_) {
        // Offline cold start: keep the locally persisted session.
      }
    }

    return AppState(
      onboarded: sp.getBool('onboarded') ?? false,
      authed: authed,
      theme: ThemePreference.values[sp.getInt('theme') ?? 0],
      profile: profile,
    );
  }

  UserProfile _readProfile(SharedPreferences sp, bool authed) {
    if (!authed) return UserProfile.guest;
    final raw = sp.getString('profile.json');
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, Object?>) {
          return UserProfile.fromJson(decoded);
        }
      } catch (_) {
        // Fall through to the legacy flat keys below.
      }
    }
    final dietNames = sp.getStringList('diets') ?? const [];
    final diets = DietTag.values
        .where((d) => dietNames.contains(d.name))
        .toList(growable: false);
    return UserProfile(
      name: sp.getString('name') ?? 'Guest chef',
      email: sp.getString('email') ?? '',
      provider: sp.getString('provider') ?? 'email',
      diets: diets,
      allergies: sp.getStringList('allergies') ?? const [],
      goal: sp.getString('goal') ?? 'Balanced plates',
      familySize: sp.getInt('familySize') ?? 2,
      notifications: sp.getBool('notifications') ?? true,
    );
  }

  Future<void> _persist(AppState s) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool('onboarded', s.onboarded);
    await sp.setBool('authed', s.authed);
    await sp.setInt('theme', s.theme.index);
    await LocalStore.instance.writeJson(s.profile.uid, 'profile', s.profile.toJson());
    // Legacy flat keys keep the profile readable for installs that predate
    // the uid-namespaced bucket.
    await sp.setString('name', s.profile.name);
    await sp.setString('email', s.profile.email);
    await sp.setString('provider', s.profile.provider);
    await sp.setStringList(
      'diets',
      s.profile.diets.map((d) => d.name).toList(growable: false),
    );
    await sp.setStringList('allergies', s.profile.allergies);
    await sp.setString('goal', s.profile.goal);
    await sp.setInt('familySize', s.profile.familySize);
    await sp.setBool('notifications', s.profile.notifications);
  }

  Future<void> _update(AppState Function(AppState) transform) async {
    final current = state.value ?? await future;
    final next = transform(current);
    state = AsyncData(next);
    await _persist(next);
  }

  Future<void> completeOnboarding() =>
      _update((s) => s.copyWith(onboarded: true));

  Future<void> signIn(AuthResult result) {
    ref
        .read(securityAuditProvider.notifier)
        .record('Sign-in', '${result.provider} account');
    final now = DateTime.now();
    // Keep the preferences the guest set up on this device; they only get
    // replaced by account data once Firestore read-back confirms it.
    final previous = state.value?.profile;
    final carryOver = previous != null && previous.isGuest ? previous : null;
    final profile = UserProfile(
      uid: result.uid,
      name: result.name,
      email: result.email,
      provider: result.provider,
      photoUrl: result.photoUrl,
      createdAt: result.createdAt,
      lastLoginAt: now,
      diets: carryOver?.diets ?? const [],
      allergies: carryOver?.allergies ?? const [],
      goal: carryOver?.goal ?? 'Balanced plates',
      familySize: carryOver?.familySize ?? 2,
      notifications: carryOver?.notifications ?? true,
    );
    unawaited(ref.read(cloudStoreProvider).saveProfile(profile));
    return _update((s) => s.copyWith(authed: true, profile: profile));
  }

  Future<void> signOut() {
    ref
        .read(securityAuditProvider.notifier)
        .record('Sign-out', 'Session closed on this device');
    unawaited(_signOutRepository());
    return _update(
      (s) => s.copyWith(authed: false, profile: UserProfile.guest),
    );
  }

  Future<void> _signOutRepository() async {
    try {
      await ref.read(authRepositoryProvider).signOut();
    } catch (_) {
      // Best effort — the local session is already closed.
    }
  }

  Future<void> setTheme(ThemePreference theme) =>
      _update((s) => s.copyWith(theme: theme));

  Future<void> updateProfile(UserProfile profile) {
    unawaited(ref.read(cloudStoreProvider).saveProfile(profile));
    return _update((s) => s.copyWith(profile: profile));
  }

  /// Fills the local profile with what Firestore holds for this account
  /// (photo, timestamps, edits made on another device). Called by the user
  /// data coordinator after a successful read-back; never changes the uid.
  Future<void> applyCloudProfile(UserProfile cloud) async {
    final current = state.value;
    if (current == null) return;
    if (cloud.uid.isNotEmpty && cloud.uid != current.profile.uid) return;
    final local = current.profile;
    final merged = cloud.copyWith(
      uid: local.uid,
      provider: local.provider.isNotEmpty ? local.provider : cloud.provider,
      name: cloud.name.isNotEmpty ? cloud.name : local.name,
      photoUrl: cloud.hasPhoto ? cloud.photoUrl : local.photoUrl,
      createdAt: cloud.createdAt ?? local.createdAt,
      lastLoginAt: cloud.lastLoginAt ?? local.lastLoginAt,
      diets: cloud.diets.isNotEmpty ? cloud.diets : local.diets,
      allergies: cloud.allergies.isNotEmpty ? cloud.allergies : local.allergies,
      goal: cloud.goal.isNotEmpty ? cloud.goal : local.goal,
    );
    if (_sameProfile(merged, local)) return;
    await _update((s) => s.copyWith(profile: merged));
  }

  bool _sameProfile(UserProfile a, UserProfile b) =>
      a.name == b.name &&
      a.email == b.email &&
      a.provider == b.provider &&
      a.photoUrl == b.photoUrl &&
      a.goal == b.goal &&
      a.familySize == b.familySize &&
      a.notifications == b.notifications &&
      a.diets.length == b.diets.length &&
      a.allergies.length == b.allergies.length;
}

final appStateProvider = AsyncNotifierProvider<AppStateNotifier, AppState>(
  AppStateNotifier.new,
);

class SessionState {
  const SessionState({
    required this.ready,
    required this.onboarded,
    required this.authed,
  });

  final bool ready;
  final bool onboarded;
  final bool authed;

  static const loading = SessionState(
    ready: false,
    onboarded: false,
    authed: false,
  );
}

final sessionProvider = Provider<SessionState>((ref) {
  final async = ref.watch(appStateProvider);
  return async.when(
    data: (s) =>
        SessionState(ready: true, onboarded: s.onboarded, authed: s.authed),
    loading: () => SessionState.loading,
    error: (_, _) =>
        const SessionState(ready: true, onboarded: false, authed: false),
  );
});

final themeModeProvider = Provider<ThemeMode>((ref) {
  final async = ref.watch(appStateProvider);
  final pref = async.value?.theme ?? ThemePreference.system;
  return switch (pref) {
    ThemePreference.system => ThemeMode.system,
    ThemePreference.light => ThemeMode.light,
    ThemePreference.dark => ThemeMode.dark,
  };
});
