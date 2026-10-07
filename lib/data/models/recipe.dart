import 'package:flutter/material.dart';

enum MealType {
  breakfast,
  lunch,
  dinner,
  snack;

  String get label => switch (this) {
    MealType.breakfast => 'Breakfast',
    MealType.lunch => 'Lunch',
    MealType.dinner => 'Dinner',
    MealType.snack => 'Snack',
  };

  IconData get icon => switch (this) {
    MealType.breakfast => Icons.wb_sunny_outlined,
    MealType.lunch => Icons.lunch_dining_outlined,
    MealType.dinner => Icons.dinner_dining_outlined,
    MealType.snack => Icons.cookie_outlined,
  };
}

enum Difficulty {
  easy,
  medium,
  hard;

  String get label => switch (this) {
    Difficulty.easy => 'Easy',
    Difficulty.medium => 'Medium',
    Difficulty.hard => 'Involved',
  };
}

enum DietTag {
  vegetarian,
  vegan,
  glutenFree,
  dairyFree,
  highProtein,
  pescatarian,
  keto;

  String get label => switch (this) {
    DietTag.vegetarian => 'Vegetarian',
    DietTag.vegan => 'Vegan',
    DietTag.glutenFree => 'Gluten-free',
    DietTag.dairyFree => 'Dairy-free',
    DietTag.highProtein => 'High protein',
    DietTag.pescatarian => 'Pescatarian',
    DietTag.keto => 'Keto',
  };
}

class RecipeIngredient {
  const RecipeIngredient({
    required this.name,
    required this.aisle,
    this.amount,
    this.unit = '',
  });

  final String name;
  final String aisle;
  final double? amount;
  final String unit;

  String scaledLabel(int servings, int baseServings) {
    if (amount == null) return name;
    final quantity = scaledQuantity(servings, baseServings);
    return quantity.isEmpty ? name : '$quantity $name';
  }

  String scaledQuantity(int servings, int baseServings) {
    if (amount == null) return '';
    final factor = servings / baseServings;
    final value = amount! * factor;
    final rounded = value < 10
        ? (value * 2).roundToDouble() / 2
        : value.roundToDouble();
    final number = rounded == rounded.roundToDouble()
        ? rounded.toInt().toString()
        : rounded.toStringAsFixed(1);
    return unit.isEmpty ? number : '$number $unit';
  }

  Map<String, Object?> toJson() => {
    'name': name,
    'aisle': aisle,
    'amount': amount,
    'unit': unit,
  };

  factory RecipeIngredient.fromJson(Map<String, Object?> json) =>
      RecipeIngredient(
        name: json['name'] as String,
        aisle: json['aisle'] as String? ?? Aisles.pantry,
        amount: (json['amount'] as num?)?.toDouble(),
        unit: json['unit'] as String? ?? '',
      );
}

class RecipeStep {
  const RecipeStep({required this.text, this.minutes});

  final String text;
  final int? minutes;

  Map<String, Object?> toJson() => {'text': text, 'minutes': minutes};

  factory RecipeStep.fromJson(Map<String, Object?> json) => RecipeStep(
    text: json['text'] as String,
    minutes: (json['minutes'] as num?)?.toInt(),
  );
}

class NigerianHeritage {
  const NigerianHeritage({
    required this.origin,
    required this.region,
    required this.significance,
    required this.occasions,
    required this.history,
    required this.pairings,
    required this.drinks,
  });

  final String origin;
  final String region;
  final String significance;
  final List<String> occasions;
  final String history;
  final List<String> pairings;
  final List<String> drinks;
}

class Nutrition {
  const Nutrition({
    this.calories = 0,
    this.proteinG = 0,
    this.carbsG = 0,
    this.fatG = 0,
    this.fiberG = 0,
  });

  final int calories;
  final int proteinG;
  final int carbsG;
  final int fatG;
  final int fiberG;

  Map<String, Object?> toJson() => {
    'calories': calories,
    'proteinG': proteinG,
    'carbsG': carbsG,
    'fatG': fatG,
    'fiberG': fiberG,
  };

  factory Nutrition.fromJson(Map<String, Object?> json) => Nutrition(
    calories: (json['calories'] as num?)?.toInt() ?? 0,
    proteinG: (json['proteinG'] as num?)?.toInt() ?? 0,
    carbsG: (json['carbsG'] as num?)?.toInt() ?? 0,
    fatG: (json['fatG'] as num?)?.toInt() ?? 0,
    fiberG: (json['fiberG'] as num?)?.toInt() ?? 0,
  );
}

class Recipe {
  const Recipe({
    required this.id,
    required this.title,
    required this.blurb,
    required this.artSeed,
    required this.imageUrl,
    required this.cuisine,
    required this.minutes,
    required this.calories,
    required this.servings,
    required this.difficulty,
    required this.rating,
    required this.ratingCount,
    required this.meals,
    required this.diets,
    required this.ingredients,
    required this.steps,
    required this.chefNote,
    this.heritage,
    this.category,
    this.prepMinutes,
    this.costPerServing,
    this.nutrition,
    this.region,
  });

  final String id;
  final String title;
  final String blurb;
  final String artSeed;
  final String imageUrl;
  final String cuisine;
  final int minutes;
  final int calories;
  final int servings;
  final Difficulty difficulty;
  final double rating;
  final int ratingCount;
  final List<MealType> meals;
  final List<DietTag> diets;
  final List<RecipeIngredient> ingredients;
  final List<RecipeStep> steps;
  final String chefNote;
  final NigerianHeritage? heritage;

  /// Food category, e.g. "Rice dish", "Pasta", "Soup". Falls back to the
  /// dominant meal type when the recipe doesn't declare one.
  final String? category;

  /// Active preparation time in minutes. Falls back to ~35% of [minutes].
  final int? prepMinutes;

  /// Authoritative cost per serving in USD when the catalog or the AI
  /// supplied one; otherwise a shelf-price heuristic is used.
  final double? costPerServing;

  final Nutrition? nutrition;

  /// Country/region the dish belongs to (e.g. "Nigeria", "Italy").
  final String? region;

  bool get isNigerian => heritage != null || region == 'Nigeria';

  bool get isQuick => minutes <= 25;

  String get foodCategory {
    final declared = category;
    if (declared != null && declared.isNotEmpty) return declared;
    if (meals.contains(MealType.breakfast)) return 'Breakfast';
    if (ingredients.any((i) => i.name.toLowerCase().contains('rice'))) {
      return 'Rice dish';
    }
    return 'Main course';
  }

  int get prepTime => prepMinutes ?? (minutes * 0.35).round().clamp(3, minutes);

  int get cookTime => (minutes - prepTime).clamp(1, minutes);

  double get estimatedCost {
    final declared = costPerServing;
    if (declared != null) return declared;
    var score = 0.0;
    for (final ingredient in ingredients) {
      score += switch (ingredient.aisle) {
        Aisles.meatFish => 2.4,
        Aisles.dairyEggs => 1.1,
        Aisles.frozen => 1.2,
        Aisles.produce => 0.7,
        Aisles.bakery => 0.6,
        Aisles.condiments => 0.3,
        _ => 0.5,
      };
    }
    final perServing = 1.4 + (score * 0.85) / servings.clamp(1, 12);
    return perServing.clamp(1.0, 15.0);
  }

  double estimatedTotalCost(int people) => estimatedCost * people;

  Nutrition get macroSummary =>
      nutrition ?? Nutrition(calories: calories);

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'blurb': blurb,
    'artSeed': artSeed,
    'imageUrl': imageUrl,
    'cuisine': cuisine,
    'minutes': minutes,
    'calories': calories,
    'servings': servings,
    'difficulty': difficulty.name,
    'rating': rating,
    'ratingCount': ratingCount,
    'meals': meals.map((m) => m.name).toList(growable: false),
    'diets': diets.map((d) => d.name).toList(growable: false),
    'ingredients': ingredients.map((i) => i.toJson()).toList(growable: false),
    'steps': steps.map((s) => s.toJson()).toList(growable: false),
    'chefNote': chefNote,
    'category': category,
    'prepMinutes': prepMinutes,
    'costPerServing': costPerServing,
    'region': region,
    if (nutrition != null) 'nutrition': nutrition!.toJson(),
  };

  factory Recipe.fromJson(Map<String, Object?> json) {
    final meals = <MealType>[];
    for (final name in json['meals'] as List<Object?>? ?? const []) {
      final match = MealType.values.where((m) => m.name == name);
      if (match.isNotEmpty) meals.add(match.first);
    }
    final diets = <DietTag>[];
    for (final name in json['diets'] as List<Object?>? ?? const []) {
      final match = DietTag.values.where((d) => d.name == name);
      if (match.isNotEmpty) diets.add(match.first);
    }
    return Recipe(
      id: json['id'] as String,
      title: json['title'] as String,
      blurb: json['blurb'] as String? ?? '',
      artSeed: json['artSeed'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      cuisine: json['cuisine'] as String? ?? 'International',
      minutes: (json['minutes'] as num?)?.toInt() ?? 30,
      calories: (json['calories'] as num?)?.toInt() ?? 0,
      servings: (json['servings'] as num?)?.toInt() ?? 2,
      difficulty: Difficulty.values.firstWhere(
        (d) => d.name == json['difficulty'],
        orElse: () => Difficulty.easy,
      ),
      rating: (json['rating'] as num?)?.toDouble() ?? 4.5,
      ratingCount: (json['ratingCount'] as num?)?.toInt() ?? 0,
      meals: meals.isEmpty ? const [MealType.dinner] : meals,
      diets: diets,
      ingredients: [
        for (final raw in json['ingredients'] as List<Object?>? ?? const [])
          RecipeIngredient.fromJson(raw! as Map<String, Object?>),
      ],
      steps: [
        for (final raw in json['steps'] as List<Object?>? ?? const [])
          RecipeStep.fromJson(raw! as Map<String, Object?>),
      ],
      chefNote: json['chefNote'] as String? ?? '',
      category: json['category'] as String?,
      prepMinutes: (json['prepMinutes'] as num?)?.toInt(),
      costPerServing: (json['costPerServing'] as num?)?.toDouble(),
      region: json['region'] as String?,
      nutrition: json['nutrition'] is Map<String, Object?>
          ? Nutrition.fromJson(json['nutrition']! as Map<String, Object?>)
          : null,
    );
  }

  Recipe copyWith({
    String? imageUrl,
    String? title,
    double? rating,
    int? ratingCount,
    String? category,
    String? region,
    double? costPerServing,
    Nutrition? nutrition,
  }) {
    return Recipe(
      id: id,
      title: title ?? this.title,
      blurb: blurb,
      artSeed: artSeed,
      imageUrl: imageUrl ?? this.imageUrl,
      cuisine: cuisine,
      minutes: minutes,
      calories: calories,
      servings: servings,
      difficulty: difficulty,
      rating: rating ?? this.rating,
      ratingCount: ratingCount ?? this.ratingCount,
      meals: meals,
      diets: diets,
      ingredients: ingredients,
      steps: steps,
      chefNote: chefNote,
      heritage: heritage,
      category: category ?? this.category,
      prepMinutes: prepMinutes,
      costPerServing: costPerServing ?? this.costPerServing,
      nutrition: nutrition ?? this.nutrition,
      region: region ?? this.region,
    );
  }

  List<String> missingFrom(Set<String> available) => ingredients
      .where((i) => !available.contains(i.name.toLowerCase()))
      .map((i) => i.name)
      .toList();

  List<String> matchedWith(Set<String> available) => ingredients
      .where((i) => available.contains(i.name.toLowerCase()))
      .map((i) => i.name)
      .toList();
}

class Aisles {
  Aisles._();

  static const produce = 'Produce';
  static const meatFish = 'Meat & fish';
  static const dairyEggs = 'Dairy & eggs';
  static const bakery = 'Bakery';
  static const frozen = 'Frozen';
  static const pantry = 'Pantry';
  static const condiments = 'Condiments';

  static const order = [
    produce,
    meatFish,
    dairyEggs,
    bakery,
    frozen,
    pantry,
    condiments,
  ];
}
