import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Namespaced, per-account persistence on top of SharedPreferences.
///
/// Every key is prefixed with the signed-in uid (`guest` for the offline
/// demo session) so two accounts on the same device never read each other's
/// planner, shopping list or favourites.
class LocalStore {
  const LocalStore();

  static const LocalStore instance = LocalStore();

  /// Document names that belong to a user scope, used by [clear].
  static const List<String> userDocuments = [
    'profile',
    'favorites',
    'planner',
    'shopping',
    'pantry',
    'scanHistory',
    'generatedRecipes',
  ];

  static String namespace(String uid) =>
      uid.trim().isEmpty ? 'guest' : uid.trim();

  String keyFor(String uid, String document) =>
      'u.${namespace(uid)}.$document';

  Future<void> writeJson(String uid, String document, Object? value) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(keyFor(uid, document), jsonEncode(value ?? const {}));
  }

  Future<Object?> readJson(String uid, String document) async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(keyFor(uid, document));
    if (raw == null || raw.isEmpty) return null;
    try {
      return jsonDecode(raw);
    } catch (_) {
      return null;
    }
  }

  Future<void> remove(String uid, String document) async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(keyFor(uid, document));
  }

  /// Drops every document belonging to [uid] (used when a session ends).
  Future<void> clear(String uid) async {
    final sp = await SharedPreferences.getInstance();
    for (final document in userDocuments) {
      await sp.remove(keyFor(uid, document));
    }
  }
}
