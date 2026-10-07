import 'recipe.dart';

/// How much the planner is willing to spend per serving.
enum BudgetTier {
  thrifty,
  moderate,
  splurge;

  String get label => switch (this) {
    BudgetTier.thrifty => 'Thrifty',
    BudgetTier.moderate => 'Moderate',
    BudgetTier.splurge => 'Splurge',
  };

  /// Soft ceiling the scoring engine rewards recipes under.
  double get perServingCeiling => switch (this) {
    BudgetTier.thrifty => 2.5,
    BudgetTier.moderate => 4.5,
    BudgetTier.splurge => 8,
  };
}

/// Everything the auto-planner needs to build a week of meals.
class PlanPreferences {
  const PlanPreferences({
    this.people = 2,
    this.diets = const [],
    this.allergies = const [],
    this.maxMinutes = 45,
    this.budget = BudgetTier.moderate,
    this.cuisine = '',
    this.mealsPerDay = 1,
    this.availableIngredients = const [],
  });

  /// Diners the plan is cooked for (drives servings on every slot).
  final int people;

  /// Diets every chosen recipe must satisfy.
  final List<DietTag> diets;

  /// Allergens that must not appear in any ingredient.
  final List<String> allergies;

  /// Longest recipe the plan should prefer (minutes, inclusive).
  final int maxMinutes;

  final BudgetTier budget;

  /// Preferred cuisine/region, or `''` for anything.
  final String cuisine;

  /// 1 = dinner, 2 = lunch + dinner, 3 = all three mains.
  final int mealsPerDay;

  /// Ingredients already in the pantry — recipes that use them score higher.
  final List<String> availableIngredients;

  PlanPreferences copyWith({
    int? people,
    List<DietTag>? diets,
    List<String>? allergies,
    int? maxMinutes,
    BudgetTier? budget,
    String? cuisine,
    int? mealsPerDay,
    List<String>? availableIngredients,
  }) {
    return PlanPreferences(
      people: people ?? this.people,
      diets: diets ?? this.diets,
      allergies: allergies ?? this.allergies,
      maxMinutes: maxMinutes ?? this.maxMinutes,
      budget: budget ?? this.budget,
      cuisine: cuisine ?? this.cuisine,
      mealsPerDay: mealsPerDay ?? this.mealsPerDay,
      availableIngredients: availableIngredients ?? this.availableIngredients,
    );
  }

  Map<String, Object?> toJson() => {
    'people': people,
    'diets': diets.map((d) => d.name).toList(growable: false),
    'allergies': allergies,
    'maxMinutes': maxMinutes,
    'budget': budget.name,
    'cuisine': cuisine,
    'mealsPerDay': mealsPerDay,
    'availableIngredients': availableIngredients,
  };

  factory PlanPreferences.fromJson(Map<String, Object?> json) {
    final diets = <DietTag>[];
    for (final name in json['diets'] as List<Object?>? ?? const []) {
      final match = DietTag.values.where((d) => d.name == name);
      if (match.isNotEmpty) diets.add(match.first);
    }
    return PlanPreferences(
      people: (json['people'] as num?)?.toInt() ?? 2,
      diets: diets,
      allergies: [
        for (final a in json['allergies'] as List<Object?>? ?? const [])
          a.toString(),
      ],
      maxMinutes: (json['maxMinutes'] as num?)?.toInt() ?? 45,
      budget: BudgetTier.values.firstWhere(
        (b) => b.name == json['budget'],
        orElse: () => BudgetTier.moderate,
      ),
      cuisine: json['cuisine'] as String? ?? '',
      mealsPerDay: (json['mealsPerDay'] as num?)?.toInt() ?? 1,
      availableIngredients: [
        for (final i in json['availableIngredients'] as List<Object?>? ?? const [])
          i.toString(),
      ],
    );
  }

  /// Slots the planner fills: one per free day per meal time.
  int slotCount(List<int> freeDays) => freeDays.length * mealsPerDay;

  /// Meal types produced per day, in serving order.
  List<MealType> get mealTypes => switch (mealsPerDay) {
    1 => const [MealType.dinner],
    2 => const [MealType.lunch, MealType.dinner],
    _ => const [MealType.breakfast, MealType.lunch, MealType.dinner],
  };
}
