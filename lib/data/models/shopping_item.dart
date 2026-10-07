import '../models/recipe.dart';

class ShoppingItem {
  const ShoppingItem({
    required this.id,
    required this.name,
    required this.aisle,
    this.quantity = '',
    this.source = '',
    this.checked = false,
  });

  final String id;
  final String name;
  final String aisle;
  final String quantity;
  final String source;
  final bool checked;

  ShoppingItem copyWith({bool? checked}) => ShoppingItem(
    id: id,
    name: name,
    aisle: aisle,
    quantity: quantity,
    source: source,
    checked: checked ?? this.checked,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'aisle': aisle,
    'quantity': quantity,
    'source': source,
    'checked': checked,
  };

  factory ShoppingItem.fromJson(Map<String, Object?> json) => ShoppingItem(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    aisle: json['aisle'] as String? ?? Aisles.pantry,
    quantity: json['quantity'] as String? ?? '',
    source: json['source'] as String? ?? '',
    checked: json['checked'] as bool? ?? false,
  );
}

class PlannedMeal {
  const PlannedMeal({
    required this.id,
    required this.day,
    required this.recipeId,
    required this.servings,
    required this.mealType,
  });

  final String id;
  final int day;
  final String recipeId;
  final int servings;
  final MealType mealType;

  Map<String, Object?> toJson() => {
    'id': id,
    'day': day,
    'recipeId': recipeId,
    'servings': servings,
    'mealType': mealType.name,
  };

  factory PlannedMeal.fromJson(Map<String, Object?> json) => PlannedMeal(
    id: json['id'] as String? ?? '',
    day: (json['day'] as num?)?.toInt() ?? 0,
    recipeId: json['recipeId'] as String? ?? '',
    servings: (json['servings'] as num?)?.toInt() ?? 2,
    mealType: MealType.values.firstWhere(
      (m) => m.name == json['mealType'],
      orElse: () => MealType.dinner,
    ),
  );
}
