import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../core/firebase/firebase_bootstrap.dart';
import '../models/recipe.dart';
import '../models/shopping_item.dart';
import '../models/user.dart';

/// Best-effort mirror of the user's local data into Cloud Firestore, namespaced
/// under their own uid (`users/{uid}` + `users/{uid}/meta/{doc}`). Every
/// write is a no-op unless Firebase is configured *and* a user is signed in,
/// and every failure is swallowed — local state remains the source of truth so
/// the app never blocks on the network.
///
/// Reads return `null` whenever the backend is unavailable so callers can
/// fall back to the local copy instead of losing data.
class CloudStore {
  const CloudStore();

  String? _guard() {
    if (!FirebaseBootstrap.isReady) return null;
    return FirebaseAuth.instance.currentUser?.uid;
  }

  // ---------------------------------------------------------------- writes

  Future<void> saveProfile(UserProfile profile) async {
    final uid = _guard();
    if (uid == null) return;
    await _write(
      () => _users(uid).set({
        'uid': uid,
        'name': profile.name,
        'email': profile.email,
        'provider': profile.provider,
        'diets': profile.diets.map((d) => d.name).toList(growable: false),
        'allergies': profile.allergies,
        'goal': profile.goal,
        'familySize': profile.familySize,
        'notifications': profile.notifications,
        'photoUrl': profile.photoUrl ?? '',
        if (profile.createdAt != null)
          'createdAt': profile.createdAt!.toIso8601String(),
        if (profile.lastLoginAt != null)
          'lastLoginAt': profile.lastLoginAt!.toIso8601String(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)),
    );
  }

  Future<void> saveFavorites(Set<String> recipeIds) => _saveMeta(
    'favourites',
    {'recipeIds': recipeIds.toList(growable: false)},
  );

  Future<void> saveCollections(List<RecipeCollection> collections) =>
      _saveMeta('collections', {
        'collections': collections.map((c) => c.toJson()).toList(growable: false),
      });

  Future<void> savePlanner(List<PlannedMeal> meals) => _saveMeta('planner', {
    'meals': meals.map((m) => m.toJson()).toList(growable: false),
  });

  Future<void> saveShopping(List<ShoppingItem> items) => _saveMeta('shopping', {
    'items': items.map((i) => i.toJson()).toList(growable: false),
  });

  Future<void> savePantry(List<PantryItem> items) => _saveMeta('pantry', {
    'items': items.map((i) => i.toJson()).toList(growable: false),
  });

  Future<void> saveScanHistory(List<ScanRecord> records) => _saveMeta(
    'scanHistory',
    {'records': records.map((r) => r.toJson()).toList(growable: false)},
  );

  Future<void> saveGeneratedRecipes(List<Recipe> recipes) => _saveMeta(
    'generatedRecipes',
    {'recipes': recipes.map((r) => r.toJson()).toList(growable: false)},
  );

  Future<void> _saveMeta(String document, Map<String, Object?> data) async {
    final uid = _guard();
    if (uid == null) return;
    await _write(
      () => _meta(uid, document).set(
        {...data, 'updatedAt': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      ),
    );
  }

  // ----------------------------------------------------------------- reads

  Future<UserProfile?> loadProfile() async {
    final uid = _guard();
    if (uid == null) return null;
    final data = await _read<Map<String, Object?>?>(() async {
      final snapshot = await _users(uid).get();
      return snapshot.data() as Map<String, Object?>?;
    });
    if (data == null) return null;
    return UserProfile.fromJson(data);
  }

  Future<Set<String>?> loadFavorites() async {
    final data = await _loadMeta('favourites');
    if (data == null) return null;
    return {
      for (final id in data['recipeIds'] as List<Object?>? ?? const [])
        id.toString(),
    };
  }

  Future<List<RecipeCollection>?> loadCollections() async {
    final data = await _loadMeta('collections');
    if (data == null) return null;
    return [
      for (final raw in data['collections'] as List<Object?>? ?? const [])
        RecipeCollection.fromJson(raw! as Map<String, Object?>),
    ];
  }

  Future<List<PlannedMeal>?> loadPlanner() async {
    final data = await _loadMeta('planner');
    if (data == null) return null;
    return [
      for (final raw in data['meals'] as List<Object?>? ?? const [])
        PlannedMeal.fromJson(raw! as Map<String, Object?>),
    ];
  }

  Future<List<ShoppingItem>?> loadShopping() async {
    final data = await _loadMeta('shopping');
    if (data == null) return null;
    return [
      for (final raw in data['items'] as List<Object?>? ?? const [])
        ShoppingItem.fromJson(raw! as Map<String, Object?>),
    ];
  }

  Future<List<PantryItem>?> loadPantry() async {
    final data = await _loadMeta('pantry');
    if (data == null) return null;
    return [
      for (final raw in data['items'] as List<Object?>? ?? const [])
        PantryItem.fromJson(raw! as Map<String, Object?>),
    ];
  }

  Future<List<ScanRecord>?> loadScanHistory() async {
    final data = await _loadMeta('scanHistory');
    if (data == null) return null;
    return [
      for (final raw in data['records'] as List<Object?>? ?? const [])
        ScanRecord.fromJson(raw! as Map<String, Object?>),
    ];
  }

  Future<List<Recipe>?> loadGeneratedRecipes() async {
    final data = await _loadMeta('generatedRecipes');
    if (data == null) return null;
    return [
      for (final raw in data['recipes'] as List<Object?>? ?? const [])
        Recipe.fromJson(raw! as Map<String, Object?>),
    ];
  }

  Future<Map<String, Object?>?> _loadMeta(String document) async {
    final uid = _guard();
    if (uid == null) return null;
    return _read<Map<String, Object?>?>(() async {
      final snapshot = await _meta(uid, document).get();
      return snapshot.data() as Map<String, Object?>?;
    });
  }

  // --------------------------------------------------------------- helpers

  DocumentReference<Map<String, dynamic>> _users(String uid) =>
      FirebaseFirestore.instance.collection('users').doc(uid);

  DocumentReference<Map<String, dynamic>> _meta(String uid, String doc) =>
      _users(uid).collection('meta').doc(doc);

  Future<T?> _read<T>(Future<T> Function() action) async {
    try {
      final value = await action().timeout(const Duration(seconds: 6));
      return value;
    } catch (error) {
      if (kDebugMode) debugPrint('CloudStore read skipped: $error');
      return null;
    }
  }

  Future<void> _write(Future<void> Function() action) async {
    try {
      await action();
    } catch (error) {
      if (kDebugMode) debugPrint('CloudStore write skipped: $error');
    }
  }
}
