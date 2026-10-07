import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_config.dart';
import '../data/models/plan_preferences.dart';
import '../data/models/recipe.dart';
import '../data/models/scan.dart';
import '../data/models/shopping_item.dart';
import '../data/models/user.dart';
import '../data/repositories/recipe_repository.dart';
import '../data/services/ai_service.dart';
import '../data/services/auto_plan_service.dart';
import '../data/services/cloud_store.dart';
import '../data/services/food_image_service.dart';
import '../data/services/gemini_ai_service.dart';
import '../data/services/local_store.dart';
import 'app_state_provider.dart';
import 'cloud_providers.dart';

export 'auth_providers.dart';

/// UID of the active account (`''` for guests). Every per-user document is
/// namespaced under this value, so switching accounts reloads that user's
/// planner, shopping list, favourites and generated recipes.
final userScopeProvider = Provider<String>(
  (ref) => ref.watch(appStateProvider.select((s) => s.value?.profile.uid ?? '')),
);

/// Writes one user's data to disk (SharedPreferences) and mirrors it to
/// Firestore. Every write is best-effort: local storage is the source of
/// truth and the network never blocks the UI.
class UserPersistence {
  UserPersistence(this._ref);

  final Ref _ref;

  String get _uid {
    try {
      return _ref.read(userScopeProvider);
    } catch (_) {
      return 'guest';
    }
  }

  /// Runs [action] off the UI stack and swallows any failure — persistence
  /// must never crash the app or block a tap.
  void _guard(Future<void> Function() action) {
    unawaited(() async {
      try {
        await action();
      } catch (error) {
        if (kDebugMode) debugPrint('Persistence skipped: $error');
      }
    }());
  }

  void favorites(Set<String> recipeIds, List<RecipeCollection> collections) {
    final uid = _uid;
    _guard(() async {
      await LocalStore.instance.writeJson(uid, 'favorites', {
        'recipeIds': recipeIds.toList(growable: false),
        'collections': collections.map((c) => c.toJson()).toList(growable: false),
      });
      final cloud = _ref.read(cloudStoreProvider);
      await cloud.saveFavorites(recipeIds);
      await cloud.saveCollections(collections);
    });
  }

  void planner(List<PlannedMeal> meals) {
    final uid = _uid;
    _guard(() async {
      await LocalStore.instance.writeJson(
        uid,
        'planner',
        meals.map((m) => m.toJson()).toList(growable: false),
      );
      await _ref.read(cloudStoreProvider).savePlanner(meals);
    });
  }

  void shopping(List<ShoppingItem> items) {
    final uid = _uid;
    _guard(() async {
      await LocalStore.instance.writeJson(
        uid,
        'shopping',
        items.map((i) => i.toJson()).toList(growable: false),
      );
      await _ref.read(cloudStoreProvider).saveShopping(items);
    });
  }

  void pantry(List<PantryItem> items) {
    final uid = _uid;
    _guard(() async {
      await LocalStore.instance.writeJson(
        uid,
        'pantry',
        items.map((i) => i.toJson()).toList(growable: false),
      );
      await _ref.read(cloudStoreProvider).savePantry(items);
    });
  }

  void scanHistory(List<ScanRecord> records) {
    final uid = _uid;
    _guard(() async {
      await LocalStore.instance.writeJson(
        uid,
        'scanHistory',
        records.map((r) => r.toJson()).toList(growable: false),
      );
      await _ref.read(cloudStoreProvider).saveScanHistory(records);
    });
  }

  void generatedRecipes(List<Recipe> recipes) {
    final uid = _uid;
    _guard(() async {
      await LocalStore.instance.writeJson(
        uid,
        'generatedRecipes',
        recipes.map((r) => r.toJson()).toList(growable: false),
      );
      await _ref.read(cloudStoreProvider).saveGeneratedRecipes(recipes);
    });
  }
}

final userPersistenceProvider = Provider<UserPersistence>(
  (ref) => UserPersistence(ref),
);

/// Builds weekly plans: Gemini when a key is configured, the local ranking
/// engine otherwise (and whenever an AI answer fails validation).
final autoPlanServiceProvider = Provider<AutoPlanService>(
  (ref) => AutoPlanService(),
);

/// Looks up real food photography for recipes without a baked-in image.
final foodImageServiceProvider = Provider<FoodImageService>(
  (ref) => FoodImageService(),
);

/// Uses Gemini for on-device ingredient detection when an API key was supplied
/// via `--dart-define`; otherwise the bundled demo pipeline.
final aiServiceProvider = Provider<AiService>(
  (ref) => AppConfig.hasGeminiKey ? GeminiAiService() : DemoAiService(),
);

class PantryNotifier extends Notifier<List<PantryItem>> {
  @override
  List<PantryItem> build() => const [];

  void addFromDetected(List<DetectedIngredient> detected) {
    final next = [...state];
    for (final item in detected) {
      final key = item.name.toLowerCase();
      final index = next.indexWhere((e) => e.name.toLowerCase() == key);
      if (index >= 0) {
        final existing = next[index];
        next[index] = PantryItem(
          name: existing.name,
          addedAt: DateTime.now(),
          timesSeen: existing.timesSeen + 1,
        );
      } else {
        next.insert(0, PantryItem(name: item.name, addedAt: DateTime.now()));
      }
    }
    state = next;
    _persist();
  }

  void remove(String name) {
    state = state
        .where((e) => e.name.toLowerCase() != name.toLowerCase())
        .toList(growable: false);
    _persist();
  }

  void clear() {
    state = const [];
    _persist();
  }

  /// Replaces the pantry when another account's data is loaded (or cleared).
  void hydrate(List<PantryItem> items) => state = items;

  void _persist() => ref.read(userPersistenceProvider).pantry(state);

  Set<String> get names => state.map((e) => e.name.toLowerCase()).toSet();
}

final pantryProvider = NotifierProvider<PantryNotifier, List<PantryItem>>(
  PantryNotifier.new,
);

class FavoritesState {
  const FavoritesState({
    this.recipeIds = const {},
    this.collections = const [],
  });

  final Set<String> recipeIds;
  final List<RecipeCollection> collections;

  FavoritesState copyWith({
    Set<String>? recipeIds,
    List<RecipeCollection>? collections,
  }) {
    return FavoritesState(
      recipeIds: recipeIds ?? this.recipeIds,
      collections: collections ?? this.collections,
    );
  }
}

class FavoritesNotifier extends Notifier<FavoritesState> {
  @override
  FavoritesState build() => const FavoritesState();

  void toggle(String recipeId) {
    final ids = {...state.recipeIds};
    if (!ids.remove(recipeId)) ids.add(recipeId);
    state = state.copyWith(recipeIds: ids);
    _persist();
  }

  bool isSaved(String recipeId) => state.recipeIds.contains(recipeId);

  void createCollection(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    state = state.copyWith(
      collections: [
        ...state.collections,
        RecipeCollection(
          id: 'c${DateTime.now().microsecondsSinceEpoch}',
          name: trimmed,
          recipeIds: const [],
        ),
      ],
    );
    _persist();
  }

  void toggleInCollection(String collectionId, String recipeId) {
    state = state.copyWith(
      collections: state.collections
          .map((c) {
            if (c.id != collectionId) return c;
            final ids = [...c.recipeIds];
            if (!ids.remove(recipeId)) ids.add(recipeId);
            return RecipeCollection(id: c.id, name: c.name, recipeIds: ids);
          })
          .toList(growable: false),
    );
    _persist();
  }

  void deleteCollection(String collectionId) {
    state = state.copyWith(
      collections: state.collections
          .where((c) => c.id != collectionId)
          .toList(growable: false),
    );
    _persist();
  }

  /// Replaces favourites when another account's data is loaded (or cleared).
  void hydrate(Set<String> recipeIds, List<RecipeCollection> collections) =>
      state = FavoritesState(recipeIds: recipeIds, collections: collections);

  void _persist() =>
      ref.read(userPersistenceProvider).favorites(state.recipeIds, state.collections);
}

final favoritesProvider = NotifierProvider<FavoritesNotifier, FavoritesState>(
  FavoritesNotifier.new,
);

class ScanNotifier extends Notifier<ScanSession> {
  @override
  ScanSession build() => const ScanSession();

  void freshStart() => state = const ScanSession();

  void reset() => state = const ScanSession();

  Future<void> addAndAnalyze(ScanImage image) async {
    state = state.copyWith(
      images: [...state.images, image],
      phase: ScanPhase.analyzing,
      clearError: true,
    );
    await _analyze();
  }

  Future<void> analyzeExistingImages() async {
    state = state.copyWith(phase: ScanPhase.analyzing, clearError: true);
    await _analyze();
  }

  Future<void> _analyze() async {
    try {
      final detected = await ref
          .read(aiServiceProvider)
          .detectIngredients(state.images);
      if (detected.isEmpty) {
        state = state.copyWith(
          phase: ScanPhase.failed,
          error: 'We could not spot any ingredients. Try more light or move a little closer.',
        );
        return;
      }
      state = state.copyWith(detected: detected, phase: ScanPhase.ready);
      ref
          .read(scanHistoryProvider.notifier)
          .record(detected, imageCount: state.images.length);
    } catch (_) {
      state = state.copyWith(
        phase: ScanPhase.failed,
        error: 'Reading the photo failed. Check your connection and retry.',
      );
    }
  }

  void addManual(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final exists = state.detected.any(
      (d) => d.name.toLowerCase() == trimmed.toLowerCase(),
    );
    if (exists) return;
    state = state.copyWith(
      detected: [
        ...state.detected,
        DetectedIngredient(name: trimmed, confidence: 1, sourceSeed: -1),
      ],
    );
  }

  void removeDetected(String name) {
    state = state.copyWith(
      detected: state.detected
          .where((d) => d.name.toLowerCase() != name.toLowerCase())
          .toList(growable: false),
    );
  }

  void removeImage(int seed) {
    state = state.copyWith(
      images: state.images.where((i) => i.seed != seed).toList(growable: false),
    );
  }
}

final scanProvider = NotifierProvider<ScanNotifier, ScanSession>(
  ScanNotifier.new,
);

/// Finished scans (the ingredients we spotted) kept as a per-user history.
class ScanHistoryNotifier extends Notifier<List<ScanRecord>> {
  @override
  List<ScanRecord> build() => const [];

  void record(List<DetectedIngredient> detected, {int imageCount = 0}) {
    final entry = ScanRecord(
      id: 'sr${DateTime.now().microsecondsSinceEpoch}',
      at: DateTime.now(),
      ingredients: detected.map((d) => d.name).toList(growable: false),
      imageCount: imageCount,
    );
    state = [entry, ...state].take(25).toList(growable: false);
    ref.read(userPersistenceProvider).scanHistory(state);
  }

  void remove(String id) {
    state = state.where((r) => r.id != id).toList(growable: false);
    ref.read(userPersistenceProvider).scanHistory(state);
  }

  void clear() {
    state = const [];
    ref.read(userPersistenceProvider).scanHistory(state);
  }

  /// Replaces the history when another account's data is loaded (or cleared).
  void hydrate(List<ScanRecord> records) => state = records;
}

final scanHistoryProvider =
    NotifierProvider<ScanHistoryNotifier, List<ScanRecord>>(
      ScanHistoryNotifier.new,
    );

class ShoppingNotifier extends Notifier<List<ShoppingItem>> {
  @override
  List<ShoppingItem> build() => const [];

  String _aisleFor(String name, RecipeRepository repo) {
    for (final recipe in repo.all()) {
      for (final ingredient in recipe.ingredients) {
        if (ingredient.name.toLowerCase() == name.toLowerCase()) {
          return ingredient.aisle;
        }
      }
    }
    return Aisles.pantry;
  }

  void addMissing(List<String> names, {required String source}) {
    final repo = ref.read(recipeRepositoryProvider);
    final existing = state.map((e) => e.name.toLowerCase()).toSet();
    final additions = <ShoppingItem>[];
    for (final name in names) {
      if (existing.contains(name.toLowerCase())) continue;
      additions.add(
        ShoppingItem(
          id: 's${DateTime.now().microsecondsSinceEpoch}${additions.length}',
          name: name,
          aisle: _aisleFor(name, repo),
          source: source,
        ),
      );
    }
    if (additions.isNotEmpty) {
      state = [...state, ...additions];
      _persist();
    }
  }

  void addItem({required String name, String quantity = ''}) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final repo = ref.read(recipeRepositoryProvider);
    state = [
      ...state,
      ShoppingItem(
        id: 's${DateTime.now().microsecondsSinceEpoch}',
        name: trimmed,
        aisle: _aisleFor(trimmed, repo),
        quantity: quantity.trim(),
        source: 'Added by you',
      ),
    ];
    _persist();
  }

  void toggle(String id) {
    state = state
        .map((e) => e.id == id ? e.copyWith(checked: !e.checked) : e)
        .toList(growable: false);
    _persist();
  }

  void remove(String id) {
    state = state.where((e) => e.id != id).toList(growable: false);
    _persist();
  }

  void clearChecked() {
    state = state.where((e) => !e.checked).toList(growable: false);
    _persist();
  }

  /// Replaces the list when another account's data is loaded (or cleared).
  void hydrate(List<ShoppingItem> items) => state = items;

  void _persist() => ref.read(userPersistenceProvider).shopping(state);
}

final shoppingProvider = NotifierProvider<ShoppingNotifier, List<ShoppingItem>>(
  ShoppingNotifier.new,
);

class PlannerNotifier extends Notifier<List<PlannedMeal>> {
  @override
  List<PlannedMeal> build() => const [];

  void assign({
    required int day,
    required String recipeId,
    required int servings,
    required MealType mealType,
  }) {
    final meal = PlannedMeal(
      id: 'p${DateTime.now().microsecondsSinceEpoch}',
      day: day,
      recipeId: recipeId,
      servings: servings,
      mealType: mealType,
    );
    state = [...state, meal];
    _sync();
  }

  void moveTo(String mealId, int day) {
    state = state
        .map(
          (m) => m.id == mealId
              ? PlannedMeal(
                  id: m.id,
                  day: day,
                  recipeId: m.recipeId,
                  servings: m.servings,
                  mealType: m.mealType,
                )
              : m,
        )
        .toList(growable: false);
    _sync();
  }

  void remove(String mealId) {
    state = state.where((m) => m.id != mealId).toList(growable: false);
    _sync();
  }

  void autoPlan({required List<String> recipeIds, required int servings}) {
    if (recipeIds.isEmpty) return;
    var cursor = state.length % recipeIds.length;
    final additions = <PlannedMeal>[];
    for (var day = 0; day < 7; day++) {
      if (state.any((m) => m.day == day)) continue;
      final id = recipeIds[cursor % recipeIds.length];
      cursor++;
      additions.add(
        PlannedMeal(
          id: 'p${DateTime.now().microsecondsSinceEpoch}$day',
          day: day,
          recipeId: id,
          servings: servings,
          mealType: MealType.dinner,
        ),
      );
    }
    state = [...state, ...additions];
    _sync();
  }

  /// Preference-aware auto plan. Fills every day that has no meals yet:
  /// Gemini invents the recipes when configured, otherwise the local engine
  /// ranks the catalog. Returns `null` when there is nothing left to fill.
  Future<AutoPlanResult?> autoPlanSmart({
    required PlanPreferences prefs,
    required List<Recipe> pool,
    String contextHint = '',
  }) async {
    final freeDays = [
      for (var day = 0; day < 7; day++)
        if (!state.any((m) => m.day == day)) day,
    ];
    if (freeDays.isEmpty) return null;

    final result = await ref.read(autoPlanServiceProvider).generate(
      prefs: prefs,
      pool: pool,
      freeDays: freeDays,
      avoidRecipeIds: state.map((m) => m.recipeId).toSet(),
      contextHint: contextHint,
    );
    if (result.picks.isEmpty) return result;

    if (result.recipes.isNotEmpty) {
      ref.read(generatedRecipesProvider.notifier).addAll(result.recipes);
    }

    final epoch = DateTime.now().microsecondsSinceEpoch;
    final additions = <PlannedMeal>[];
    for (var i = 0; i < result.picks.length; i++) {
      final pick = result.picks[i];
      additions.add(
        PlannedMeal(
          id: 'p$epoch$i',
          day: pick.day,
          recipeId: pick.recipe.id,
          servings: prefs.people,
          mealType: pick.mealType,
        ),
      );
    }
    state = [...state, ...additions];
    _sync();
    return result;
  }

  void shuffleDays() {
    if (state.isEmpty) return;
    final meals = [...state]..shuffle(Random());
    state = [
      for (var i = 0; i < meals.length; i++)
        PlannedMeal(
          id: meals[i].id,
          day: i % 7,
          recipeId: meals[i].recipeId,
          servings: meals[i].servings,
          mealType: meals[i].mealType,
        ),
    ];
    _sync();
  }

  void clear() {
    state = const [];
    _sync();
  }

  void _sync() => ref.read(userPersistenceProvider).planner(state);

  /// Replaces the plan when another account's data is loaded (or cleared).
  void hydrate(List<PlannedMeal> meals) => state = meals;
}

final plannerProvider = NotifierProvider<PlannerNotifier, List<PlannedMeal>>(
  PlannerNotifier.new,
);

final plannerTrayProvider = Provider<List<Recipe>>((ref) {
  final favorites = ref.watch(favoritesProvider).recipeIds;
  final repo = ref.watch(recipeRepositoryProvider);
  final saved = repo.byIds(favorites);
  if (saved.length >= 5) return saved;
  final extra = repo
      .all()
      .where((r) => !favorites.contains(r.id))
      .take(8 - saved.length)
      .toList(growable: false);
  return [...saved, ...extra];
});

class ScanSuggestion {
  const ScanSuggestion({required this.matches, required this.ingredientCount});

  final List<RecipeMatch> matches;
  final int ingredientCount;
}

final scanSuggestionsProvider = FutureProvider.autoDispose<ScanSuggestion>((
  ref,
) async {
  final session = ref.watch(scanProvider);
  final profile = ref.watch(appStateProvider.select((s) => s.value?.profile));
  final ingredients = session.detected
      .map((d) => d.name)
      .toList(growable: false);
  if (ingredients.isEmpty) {
    return const ScanSuggestion(matches: [], ingredientCount: 0);
  }
  final diets = profile?.diets ?? const <DietTag>[];
  final allergies = profile?.allergies ?? const <String>[];
  final matches = await ref
      .read(aiServiceProvider)
      .suggestRecipes(
        ingredients: ingredients,
        diets: diets,
        allergies: allergies,
      );
  return ScanSuggestion(matches: matches, ingredientCount: ingredients.length);
});

/// Recipes produced by the AI meal planner. They behave exactly like catalog
/// recipes (open, cook, add to the plan) and persist per user so a plan
/// survives a restart even when the API key is absent next launch.
class GeneratedRecipesNotifier extends Notifier<List<Recipe>> {
  @override
  List<Recipe> build() => const [];

  void addAll(List<Recipe> recipes) {
    if (recipes.isEmpty) return;
    final known = state.map((r) => r.id).toSet();
    final added = recipes.where((r) => !known.contains(r.id)).toList(growable: false);
    if (added.isEmpty) return;
    state = [...added, ...state];
    _persist();
    _enrichMissing();
  }

  /// Looks up artwork for every recipe that still has none. Recipes restored
  /// from disk or Firestore arrive without an image and are only enriched on
  /// this path, so it runs after every load as well as after a fresh
  /// generation.
  void _enrichMissing() {
    for (final recipe in state) {
      if (recipe.imageUrl.isEmpty) unawaited(_enrichImage(recipe));
    }
  }

  /// Generated recipes start without artwork; look one up on TheMealDB and
  /// Wikimedia Commons and patch it in when a match exists.
  Future<void> _enrichImage(Recipe recipe) async {
    try {
      final url = await ref.read(foodImageServiceProvider).lookup(recipe.title);
      if (url == null) return;
      state = [
        for (final r in state)
          r.id == recipe.id && r.imageUrl.isEmpty
              ? r.copyWith(imageUrl: url)
              : r,
      ];
      _persist();
    } catch (_) {
      // Artwork is optional — the recipe stays usable without it.
    }
  }

  /// Replaces the list when another account's data is loaded (or cleared).
  void hydrate(List<Recipe> recipes) {
    state = recipes;
    _enrichMissing();
  }

  void _persist() => ref.read(userPersistenceProvider).generatedRecipes(state);
}

final generatedRecipesProvider =
    NotifierProvider<GeneratedRecipesNotifier, List<Recipe>>(
      GeneratedRecipesNotifier.new,
    );

/// The catalog plus anything the planner generated for the signed-in user.
final recipeRepositoryProvider = Provider<RecipeRepository>((ref) {
  final generated = ref.watch(generatedRecipesProvider);
  if (generated.isEmpty) return CatalogRecipeRepository();
  return ComposedRecipeRepository(
    base: CatalogRecipeRepository(),
    extra: generated,
  );
});

class ComposedRecipeRepository implements RecipeRepository {
  const ComposedRecipeRepository({required this.base, required this.extra});

  final RecipeRepository base;
  final List<Recipe> extra;

  List<Recipe> _all() => [...extra, ...base.all()];

  @override
  List<Recipe> all() => _all();

  @override
  Recipe? byId(String id) {
    for (final recipe in _all()) {
      if (recipe.id == id) return recipe;
    }
    return null;
  }

  @override
  List<Recipe> byIds(Iterable<String> ids) =>
      ids.map(byId).whereType<Recipe>().toList(growable: false);

  @override
  List<Recipe> quickPicks({int count = 6}) =>
      _all().take(count).toList(growable: false);
}

/// Loads the active account's documents (local first, Firestore read-back
/// when available) whenever the uid changes, and clears every notifier in
/// between so one account's data is never shown to another.
final userDataCoordinatorProvider = Provider<void>((ref) {
  String? lastUid;
  var generation = 0;

  void clearAll() {
    ref.read(favoritesProvider.notifier).hydrate(const {}, const []);
    ref.read(plannerProvider.notifier).hydrate(const []);
    ref.read(shoppingProvider.notifier).hydrate(const []);
    ref.read(pantryProvider.notifier).hydrate(const []);
    ref.read(scanHistoryProvider.notifier).hydrate(const []);
    ref.read(generatedRecipesProvider.notifier).hydrate(const []);
  }

  Future<void> hydrate(String uid) async {
    final token = ++generation;
    try {
      final local = await _readLocal(uid);
      final cloud = await _readCloud(ref.read(cloudStoreProvider));
      if (!ref.mounted || token != generation) return; // superseded
      ref.read(favoritesProvider.notifier).hydrate(
            cloud?.favorites ?? local.favorites,
            cloud?.collections ?? local.collections,
          );
      ref
          .read(plannerProvider.notifier)
          .hydrate(cloud?.planner ?? local.planner);
      ref
          .read(shoppingProvider.notifier)
          .hydrate(cloud?.shopping ?? local.shopping);
      ref.read(pantryProvider.notifier).hydrate(cloud?.pantry ?? local.pantry);
      ref
          .read(scanHistoryProvider.notifier)
          .hydrate(cloud?.scanHistory ?? local.scanHistory);
      ref
          .read(generatedRecipesProvider.notifier)
          .hydrate(cloud?.generated ?? local.generated);

      final cloudProfile = cloud?.profile;
      if (cloudProfile != null) {
        await ref
            .read(appStateProvider.notifier)
            .applyCloudProfile(cloudProfile);
      }
    } catch (error) {
      if (kDebugMode) debugPrint('User data hydrate skipped: $error');
    }
  }

  ref.listen<AsyncValue<AppState>>(
    appStateProvider,
    (_, next) {
      if (!ref.mounted) return;
      final profile = next.value?.profile;
      if (profile == null) return; // still loading
      if (lastUid == profile.uid) return;
      lastUid = profile.uid;
      clearAll();
      unawaited(hydrate(profile.uid));
    },
    fireImmediately: true,
  );
});

class _LocalData {
  const _LocalData({
    required this.favorites,
    required this.collections,
    required this.planner,
    required this.shopping,
    required this.pantry,
    required this.scanHistory,
    required this.generated,
  });

  final Set<String> favorites;
  final List<RecipeCollection> collections;
  final List<PlannedMeal> planner;
  final List<ShoppingItem> shopping;
  final List<PantryItem> pantry;
  final List<ScanRecord> scanHistory;
  final List<Recipe> generated;
}

class _CloudData {
  const _CloudData({
    required this.profile,
    required this.favorites,
    required this.collections,
    required this.planner,
    required this.shopping,
    required this.pantry,
    required this.scanHistory,
    required this.generated,
  });

  final UserProfile? profile;
  final Set<String>? favorites;
  final List<RecipeCollection>? collections;
  final List<PlannedMeal>? planner;
  final List<ShoppingItem>? shopping;
  final List<PantryItem>? pantry;
  final List<ScanRecord>? scanHistory;
  final List<Recipe>? generated;
}

Future<_LocalData> _readLocal(String uid) async {
  final store = LocalStore.instance;
  final favorites = await store.readJson(uid, 'favorites');
  final planner = await store.readJson(uid, 'planner');
  final shopping = await store.readJson(uid, 'shopping');
  final pantry = await store.readJson(uid, 'pantry');
  final scanHistory = await store.readJson(uid, 'scanHistory');
  final generated = await store.readJson(uid, 'generatedRecipes');
  return _LocalData(
    favorites: _idSet(favorites is Map<String, Object?> ? favorites['recipeIds'] : null),
    collections: _fromJsonList(
      favorites is Map<String, Object?> ? favorites['collections'] : null,
      RecipeCollection.fromJson,
    ),
    planner: _fromJsonList(planner, PlannedMeal.fromJson),
    shopping: _fromJsonList(shopping, ShoppingItem.fromJson),
    pantry: _fromJsonList(pantry, PantryItem.fromJson),
    scanHistory: _fromJsonList(scanHistory, ScanRecord.fromJson),
    generated: _fromJsonList(generated, Recipe.fromJson),
  );
}

Future<_CloudData?> _readCloud(CloudStore store) async {
  try {
    final profile = store.loadProfile();
    final favorites = store.loadFavorites();
    final collections = store.loadCollections();
    final planner = store.loadPlanner();
    final shopping = store.loadShopping();
    final pantry = store.loadPantry();
    final scanHistory = store.loadScanHistory();
    final generated = store.loadGeneratedRecipes();
    return _CloudData(
      profile: await profile,
      favorites: await favorites,
      collections: await collections,
      planner: await planner,
      shopping: await shopping,
      pantry: await pantry,
      scanHistory: await scanHistory,
      generated: await generated,
    );
  } catch (_) {
    return null;
  }
}

Set<String> _idSet(Object? raw) => {
      for (final id in raw as List<Object?>? ?? const []) id.toString(),
    };

List<T> _fromJsonList<T>(
  Object? raw,
  T Function(Map<String, Object?>) fromJson,
) {
  final items = <T>[];
  for (final entry in raw as List<Object?>? ?? const []) {
    if (entry is Map<String, Object?>) {
      try {
        items.add(fromJson(entry));
      } catch (_) {
        // Skip malformed entries instead of losing the whole document.
      }
    }
  }
  return items;
}
