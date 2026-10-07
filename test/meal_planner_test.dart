import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:pocketchef_ai/data/models/plan_preferences.dart';
import 'package:pocketchef_ai/data/models/recipe.dart';
import 'package:pocketchef_ai/data/repositories/recipe_repository.dart';
import 'package:pocketchef_ai/data/services/auto_plan_service.dart';
import 'package:pocketchef_ai/data/services/meal_planner.dart';

void main() {
  const planner = MealPlanner();

  Recipe recipe({
    required String id,
    List<DietTag> diets = const [],
    List<String> ingredients = const ['Rice'],
    int minutes = 30,
    String cuisine = 'Italian',
  }) {
    return Recipe(
      id: id,
      title: id,
      blurb: '',
      artSeed: id,
      imageUrl: '',
      cuisine: cuisine,
      minutes: minutes,
      calories: 500,
      servings: 2,
      difficulty: Difficulty.easy,
      rating: 4.5,
      ratingCount: 200,
      meals: const [MealType.dinner],
      diets: diets,
      ingredients: [
        for (final name in ingredients)
          RecipeIngredient(name: name, aisle: Aisles.pantry),
      ],
      steps: const [RecipeStep(text: 'Cook', minutes: 10)],
      chefNote: '',
    );
  }

  test('fills every free day and avoids repeating recipes', () {
    final pool = [for (var i = 0; i < 10; i++) recipe(id: 'r$i')];
    final picks = planner.plan(
      pool: pool,
      prefs: const PlanPreferences(),
      freeDays: const [0, 1, 2, 3, 4, 5, 6],
      random: Random(7),
    );

    expect(picks.length, 7);
    expect(picks.map((p) => p.recipe.id).toSet().length, 7);
    expect(picks.map((p) => p.day).toSet(), {0, 1, 2, 3, 4, 5, 6});
  });

  test('never picks a recipe that breaks a diet rule', () {
    final pool = [
      recipe(id: 'veg', diets: const [DietTag.vegetarian]),
      recipe(id: 'meaty'),
      recipe(id: 'vegan', diets: const [DietTag.vegan]),
    ];
    final picks = planner.plan(
      pool: pool,
      prefs: const PlanPreferences(diets: [DietTag.vegetarian]),
      freeDays: const [0, 1],
      random: Random(3),
    );

    expect(picks.length, 2);
    expect(picks.every((p) => p.recipe.id != 'meaty'), isTrue);
  });

  test('never picks a recipe containing an allergen', () {
    final pool = [
      recipe(id: 'nutty', ingredients: const ['Peanut butter', 'Banana']),
      recipe(id: 'safe', ingredients: const ['Oats', 'Milk']),
    ];
    final picks = planner.plan(
      pool: pool,
      prefs: const PlanPreferences(allergies: ['peanut']),
      freeDays: const [0, 1],
      random: Random(1),
    );

    expect(picks.length, 2);
    expect(picks.every((p) => p.recipe.id == 'safe'), isTrue);
  });

  test('completes the week even when the pool is smaller than the slots', () {
    final pool = [recipe(id: 'only'), recipe(id: 'two')];
    final picks = planner.plan(
      pool: pool,
      prefs: const PlanPreferences(),
      freeDays: const [0, 1, 2, 3, 4, 5, 6],
      random: Random(11),
    );

    expect(picks.length, 7);
    expect(picks.every((p) => p.recipe.id == 'only' || p.recipe.id == 'two'), isTrue);
  });

  test('produces multiple meals per day when asked', () {
    final pool = [for (var i = 0; i < 12; i++) recipe(id: 'r$i')];
    final picks = planner.plan(
      pool: pool,
      prefs: const PlanPreferences(mealsPerDay: 2),
      freeDays: const [0, 1],
      random: Random(5),
    );

    expect(picks.length, 4);
    expect(picks.where((p) => p.day == 0).length, 2);
    expect(picks.map((p) => p.mealType).toSet(), {MealType.lunch, MealType.dinner});
  });

  test('auto plan service falls back to the catalog without a Gemini key', () async {
    final service = AutoPlanService();
    expect(service.isAiAvailable, isFalse);

    final result = await service.generate(
      prefs: const PlanPreferences(),
      pool: kCatalog,
      freeDays: const [0, 1, 2],
    );

    expect(result.source, 'local');
    expect(result.isAi, isFalse);
    expect(result.picks.length, 3);
    expect(result.recipes, isEmpty);
    expect(result.picks.every((p) => p.recipe.minutes <= 45), isTrue);
  });
}
