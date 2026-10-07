import 'dart:convert';

import '../models/plan_preferences.dart';
import '../models/recipe.dart';
import 'gemini_service.dart';
import 'meal_planner.dart';

/// A generated plan: which recipe goes on which day, plus any brand-new
/// recipes the AI invented (empty for local plans).
class AutoPlanResult {
  const AutoPlanResult({
    required this.picks,
    required this.recipes,
    required this.source,
  });

  final List<PlanPick> picks;
  final List<Recipe> recipes;

  /// `'ai'` when Gemini produced the recipes, `'local'` otherwise.
  final String source;

  bool get isAi => source == 'ai';
}

/// Builds a week of meals.
///
/// With a Gemini key the AI invents fresh recipes shaped by the user's
/// preferences; without one — or whenever the AI answer cannot be trusted —
/// the local [MealPlanner] ranks the bundled catalog instead. A plan is
/// always produced.
class AutoPlanService {
  AutoPlanService({
    GeminiService? gemini,
    MealPlanner? planner,
  }) : _gemini = gemini ?? GeminiService(),
       _planner = planner ?? const MealPlanner();

  final GeminiService _gemini;
  final MealPlanner _planner;

  bool get isAiAvailable => _gemini.isConfigured;

  Future<AutoPlanResult> generate({
    required PlanPreferences prefs,
    required List<Recipe> pool,
    required List<int> freeDays,
    Set<String> avoidRecipeIds = const {},
    String contextHint = '',
  }) async {
    final slots = prefs.slotCount(freeDays);
    if (slots == 0) return const AutoPlanResult(picks: [], recipes: [], source: 'local');

    if (isAiAvailable) {
      try {
        final ai = await _generateWithAi(
          prefs: prefs,
          slots: slots,
          contextHint: contextHint,
        ).timeout(const Duration(seconds: 90));
        if (ai.length == slots) {
          return AutoPlanResult(
            picks: _schedule(ai, prefs, freeDays),
            recipes: ai,
            source: 'ai',
          );
        }
      } catch (_) {
        // Any AI failure falls through to the local engine.
      }
    }

    return AutoPlanResult(
      picks: _planner.plan(
        pool: pool,
        prefs: prefs,
        freeDays: freeDays,
        avoidRecipeIds: avoidRecipeIds,
      ),
      recipes: const [],
      source: 'local',
    );
  }

  /// Assigns the AI recipes to days in order (breakfast→lunch→dinner per day),
  /// so the schedule is always valid no matter what order the model returned.
  List<PlanPick> _schedule(
    List<Recipe> recipes,
    PlanPreferences prefs,
    List<int> freeDays,
  ) {
    final mealTypes = prefs.mealTypes;
    final picks = <PlanPick>[];
    for (var i = 0; i < recipes.length; i++) {
      picks.add(
        PlanPick(
          day: freeDays[i ~/ mealTypes.length],
          mealType: mealTypes[i % mealTypes.length],
          recipe: recipes[i],
        ),
      );
    }
    return picks;
  }

  Future<List<Recipe>> _generateWithAi({
    required PlanPreferences prefs,
    required int slots,
    required String contextHint,
  }) async {
    final text = await _gemini.generateMealPlan(
      prompt: _prompt(prefs, slots, contextHint),
    );
    final recipes = _parse(text, prefs, slots);
    return recipes;
  }

  String _prompt(PlanPreferences prefs, int slots, String contextHint) {
    final diet = prefs.diets.isEmpty
        ? 'none'
        : prefs.diets.map((d) => d.label).join(', ');
    final allergens = prefs.allergies.isEmpty ? 'none' : prefs.allergies.join(', ');
    final cuisine = prefs.cuisine.isEmpty ? 'any cuisine' : '${prefs.cuisine} cuisine';
    final pantry = prefs.availableIngredients.isEmpty
        ? 'nothing special'
        : prefs.availableIngredients.take(12).join(', ');
    final ceiling = prefs.budget.perServingCeiling.toStringAsFixed(2);

    return '''
You are PocketChef's meal planner. Invent exactly $slots different home-cooked recipes for a household of ${prefs.people}.

Hard rules:
- Every recipe must be ready within ${prefs.maxMinutes} minutes of total time.
- Diet requirement: $diet. A recipe must be tagged accordingly.
- Never use these allergens: $allergens.
- Target about \$$ceiling per serving (tier: ${prefs.budget.label}).
- Focus: $cuisine. Vary the dishes — no two recipes alike, vary proteins and cuisines.
- Pantry already available (prefer recipes that use these): $pantry.
${contextHint.isEmpty ? '' : 'Extra note: $contextHint\n'}
Return ONLY valid minified JSON, no prose, no markdown fences, in exactly this shape:
{"recipes":[{"title":"","blurb":"","cuisine":"","region":"","category":"","minutes":30,"prepMinutes":10,"calories":500,"servings":${prefs.people},"difficulty":"easy","rating":4.6,"ratingCount":120,"diets":[],"costPerServing":3.0,"ingredients":[{"name":"","aisle":"Pantry","amount":200,"unit":"g"}],"steps":[{"text":"","minutes":5}],"chefNote":"","nutrition":{"calories":500,"proteinG":25,"carbsG":50,"fatG":18,"fiberG":6}}]}
Required: at least 4 ingredients and 3 steps per recipe, real ingredient names, aisle one of Produce|Meat & fish|Dairy & eggs|Bakery|Frozen|Pantry|Condiments, difficulty one of easy|medium|hard, diets chosen from vegetarian|vegan|glutenFree|dairyFree|highProtein|pescatarian|keto.
''';
  }

  List<Recipe> _parse(String text, PlanPreferences prefs, int slots) {
    final json = _decodeJson(text);
    if (json == null) return const [];

    final rawRecipes = json['recipes'];
    if (rawRecipes is! List) return const [];

    final epoch = DateTime.now().millisecondsSinceEpoch;
    final recipes = <Recipe>[];
    for (var i = 0; i < rawRecipes.length && recipes.length < slots; i++) {
      final raw = rawRecipes[i];
      if (raw is! Map<String, dynamic>) continue;
      try {
        final recipe = _normalise(raw, epoch, i, prefs);
        if (_isUsable(recipe)) recipes.add(recipe);
      } catch (_) {
        // Skip malformed entries; the caller falls back if we come up short.
      }
    }
    return recipes;
  }

  Recipe _normalise(
    Map<String, dynamic> raw,
    int epoch,
    int index,
    PlanPreferences prefs,
  ) {
    final title = (raw['title'] as String? ?? '').trim();
    final mealType = prefs.mealTypes[index % prefs.mealTypes.length];
    final data = <String, Object?>{
      ...raw,
      'id': 'gen-$epoch-$index',
      'title': title,
      'artSeed': title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-'),
      'imageUrl': (raw['imageUrl'] as String?) ?? '',
      'meals': [mealType.name],
      if ((raw['servings'] as num?) == null) 'servings': prefs.people,
      if (raw['diets'] is! List) 'diets': const <String>[],
      if (raw['ingredients'] is! List) 'ingredients': const [],
      if (raw['steps'] is! List) 'steps': const [],
    };
    return Recipe.fromJson(data);
  }

  bool _isUsable(Recipe recipe) =>
      recipe.title.isNotEmpty &&
      recipe.ingredients.length >= 4 &&
      recipe.steps.length >= 3 &&
      recipe.minutes > 0 &&
      recipe.minutes <= 240;

  Map<String, dynamic>? _decodeJson(String text) {
    var cleaned = text.trim();
    final fence = RegExp(r'^```(?:json)?\s*([\s\S]*?)\s*```$');
    final match = fence.firstMatch(cleaned);
    if (match != null) cleaned = match.group(1)!.trim();
    final start = cleaned.indexOf('{');
    final end = cleaned.lastIndexOf('}');
    if (start < 0 || end <= start) return null;
    try {
      final decoded = jsonDecode(cleaned.substring(start, end + 1));
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {
      return null;
    }
    return null;
  }
}
