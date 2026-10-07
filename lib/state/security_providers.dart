import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/services/security_service.dart';

class SecuritySettings {
  const SecuritySettings({
    this.emailVerified = false,
    this.faceUnlock = false,
    this.mfaEnabled = false,
    this.lastRefresh,
  });

  final bool emailVerified;
  final bool faceUnlock;
  final bool mfaEnabled;
  final DateTime? lastRefresh;

  SecuritySettings copyWith({
    bool? emailVerified,
    bool? faceUnlock,
    bool? mfaEnabled,
    DateTime? lastRefresh,
    bool clearRefresh = false,
  }) {
    return SecuritySettings(
      emailVerified: emailVerified ?? this.emailVerified,
      faceUnlock: faceUnlock ?? this.faceUnlock,
      mfaEnabled: mfaEnabled ?? this.mfaEnabled,
      lastRefresh: clearRefresh ? null : (lastRefresh ?? this.lastRefresh),
    );
  }
}

class SecuritySettingsNotifier extends AsyncNotifier<SecuritySettings> {
  @override
  Future<SecuritySettings> build() async {
    final sp = await SharedPreferences.getInstance();
    return SecuritySettings(
      emailVerified: sp.getBool('sec.emailVerified') ?? false,
      faceUnlock: sp.getBool('sec.faceUnlock') ?? false,
      mfaEnabled: sp.getBool('sec.mfaEnabled') ?? false,
      lastRefresh: _readRefresh(sp),
    );
  }

  DateTime? _readRefresh(SharedPreferences sp) {
    final ms = sp.getInt('sec.lastRefresh');
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<void> _persist(SecuritySettings s) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool('sec.emailVerified', s.emailVerified);
    await sp.setBool('sec.faceUnlock', s.faceUnlock);
    await sp.setBool('sec.mfaEnabled', s.mfaEnabled);
    final refresh = s.lastRefresh;
    if (refresh == null) {
      await sp.remove('sec.lastRefresh');
    } else {
      await sp.setInt('sec.lastRefresh', refresh.millisecondsSinceEpoch);
    }
  }

  Future<void> _update(SecuritySettings Function(SecuritySettings) f) async {
    final current = state.value ?? await future;
    final next = f(current);
    state = AsyncData(next);
    await _persist(next);
  }

  Future<void> setEmailVerified(bool value) =>
      _update((s) => s.copyWith(emailVerified: value));

  Future<void> setFaceUnlock(bool value) =>
      _update((s) => s.copyWith(faceUnlock: value));

  Future<void> setMfaEnabled(bool value) =>
      _update((s) => s.copyWith(mfaEnabled: value));

  Future<void> recordRefresh(DateTime at) =>
      _update((s) => s.copyWith(lastRefresh: at));
}

final securitySettingsProvider =
    AsyncNotifierProvider<SecuritySettingsNotifier, SecuritySettings>(
      SecuritySettingsNotifier.new,
    );

class SecurityAuditNotifier extends Notifier<List<SecurityAuditEntry>> {
  static int _sequence = 0;

  @override
  List<SecurityAuditEntry> build() => const [];

  void record(String action, String detail) {
    _sequence++;
    state = [
      ...state,
      SecurityAuditEntry(
        id: 'audit$_sequence',
        action: action,
        detail: detail,
        at: DateTime.now(),
      ),
    ];
  }
}

final securityAuditProvider =
    NotifierProvider<SecurityAuditNotifier, List<SecurityAuditEntry>>(
      SecurityAuditNotifier.new,
    );