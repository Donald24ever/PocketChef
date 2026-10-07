import 'dart:math';

import '../models/plan_preferences.dart';
import '../models/recipe.dart';

/// One planned slot produced by [MealPlanner].
class PlanPick {
  const PlanPick({
    required this.day,
    required this.mealType,
    required this.recipe,
  });

  final int day;
  final MealType mealType;
  final Recipe recipe;
}

/// Local meal-planning engine: scores every candidate against the user's
/// preferences, then picks a varied, mostly non-repeating week.
///
/// Used directly when no Gemini key is configured and as the fallback when an
/// AI plan cannot be parsed — the app always returns a usable plan.
class MealPlanner {
  const MealPlanner();

  /// Fills every slot in [freeDays] (days with no meal yet).
  ///
  /// Diet and allergy rules are never relaxed. Time budget, cuisine and
  /// variety are relaxed in that order when the pool runs dry, so the plan is
  /// always complete.
  List<PlanPick> plan({
    required List<Recipe> pool,
    required PlanPreferences prefs,
    required List<int> freeDays,
    Set<String> avoidRecipeIds = const {},
    Random? random,
  }) {
    final rng = random ?? Random();
    final safe = pool.where((r) => _satisfies(r, prefs)).toList(growable: false);
    if (safe.isEmpty || freeDays.isEmpty) return const [];

    final pantry = prefs.availableIngredients
        .map((i) => i.toLowerCase())
        .toSet();
    final ceiling = prefs.budget.perServingCeiling;

    bool acceptsTime(Recipe r) => r.minutes <= prefs.maxMinutes;
    bool acceptsCuisine(Recipe r) => _matchesCuisine(r, prefs.cuisine);
    bool acceptsBudget(Recipe r) => r.estimatedCost <= ceiling;
    bool acceptsVariety(Recipe r) => !avoidRecipeIds.contains(r.id);

    var candidates = safe
        .where((r) =>
            acceptsTime(r) &&
            acceptsCuisine(r) &&
            acceptsBudget(r) &&
            acceptsVariety(r))
        .toList(growable: false);

    if (candidates.length < prefs.slotCount(freeDays)) {
      candidates = safe
          .where((r) =>
              acceptsTime(r) && acceptsCuisine(r) && acceptsVariety(r))
          .toList(growable: false);
    }
    if (candidates.length < prefs.slotCount(freeDays)) {
      candidates = safe
          .where((r) => acceptsTime(r) && acceptsVariety(r))
          .toList(growable: false);
    }
    if (candidates.length < prefs.slotCount(freeDays)) {
      candidates = safe.where(acceptsTime).toList(growable: false);
    }
    if (candidates.length < prefs.slotCount(freeDays)) {
      candidates = safe.where(acceptsVariety).toList(growable: false);
    }
    if (candidates.isEmpty) candidates = safe;

    final ranked = [...candidates]..sort(
        (a, b) => _score(b, prefs, pantry, ceiling, rng)
            .compareTo(_score(a, prefs, pantry, ceiling, rng)),
      );

    final picks = <PlanPick>[];
    final usedIds = <String>{};
    var cursor = 0;
    final mealTypes = prefs.mealTypes;

    for (final day in freeDays) {
      for (var m = 0; m < mealTypes.length; m++) {
        Recipe? pick;
        // First pass avoids repeating a recipe already used this week; the
        // second pass allows repeats so small pools still fill the week.
        for (var step = 0; step < ranked.length && pick == null; step++) {
          final candidate = ranked[(cursor + step) % ranked.length];
          if (usedIds.contains(candidate.id)) continue;
          pick = candidate;
          cursor = (cursor + step + 1) % ranked.length;
        }
        if (pick == null) {
          pick = ranked[cursor % ranked.length];
          cursor = (cursor + 1) % ranked.length;
        }
        usedIds.add(pick.id);
        picks.add(
          PlanPick(day: day, mealType: mealTypes[m], recipe: pick),
        );
      }
    }
    return picks;
  }

  double _score(
    Recipe recipe,
    PlanPreferences prefs,
    Set<String> pantry,
    double ceiling,
    Random rng,
  ) {
    var score = recipe.rating * 2;
    if (recipe.ratingCount >= 300) score += 1;
    if (recipe.ratingCount >= 800) score += 0.5;

    var overlap = 0;
    for (final ingredient in recipe.ingredients) {
      if (pantry.contains(ingredient.name.toLowerCase())) overlap++;
    }
    score += overlap * 1.5;

    if (prefs.cuisine.isNotEmpty && _matchesCuisine(recipe, prefs.cuisine)) {
      score += 2;
    }

    final cost = recipe.estimatedCost;
    if (cost <= ceiling) {
      score += 1.5;
    } else {
      score -= (cost - ceiling) * 0.8;
    }

    if (recipe.minutes <= prefs.maxMinutes) {
      score += 1;
    } else {
      score -= (recipe.minutes - prefs.maxMinutes) / 15;
    }

    if (prefs.mealsPerDay > 1) {
      score += switch (recipe.meals.first) {
        MealType.breakfast => recipe.calories < 450 ? 1 : 0,
        _ => 0,
      };
    }

    // Small jitter so two identical runs still feel fresh.
    return score + rng.nextDouble() * 0.6;
  }

  bool _satisfies(Recipe recipe, PlanPreferences prefs) {
    for (final diet in prefs.diets) {
      if (!_satisfiesDiet(recipe, diet)) return false;
    }
    return !_containsAllergen(recipe, prefs.allergies);
  }

  bool _satisfiesDiet(Recipe recipe, DietTag diet) {
    switch (diet) {
      case DietTag.vegetarian:
        return recipe.diets.contains(DietTag.vegetarian) ||
            recipe.diets.contains(DietTag.vegan);
      case DietTag.vegan:
        return recipe.diets.contains(DietTag.vegan);
      case DietTag.pescatarian:
        return recipe.diets.contains(DietTag.pescatarian) ||
            recipe.diets.contains(DietTag.vegetarian) ||
            recipe.diets.contains(DietTag.vegan);
      default:
        return recipe.diets.contains(diet);
    }
  }

  bool _containsAllergen(Recipe recipe, List<String> allergies) {
    for (final allergen in allergies) {
      final needle = allergen.trim().toLowerCase();
      if (needle.isEmpty) continue;
      for (final ingredient in recipe.ingredients) {
        if (ingredient.name.toLowerCase().contains(needle)) return true;
      }
    }
    return false;
  }

  bool _matchesCuisine(Recipe recipe, String cuisine) {
    final needle = cuisine.trim().toLowerCase();
    if (needle.isEmpty) return true;
    return recipe.cuisine.toLowerCase().contains(needle) ||
        (recipe.region ?? '').toLowerCase().contains(needle) ||
        (recipe.category ?? '').toLowerCase().contains(needle);
  }
}
