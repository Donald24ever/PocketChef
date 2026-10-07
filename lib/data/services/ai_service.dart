import '../models/recipe.dart';
import '../models/scan.dart';
import '../repositories/recipe_repository.dart';

class RecipeMatch {
  const RecipeMatch({
    required this.recipe,
    required this.matched,
    required this.missing,
    required this.reason,
  });

  final Recipe recipe;
  final List<String> matched;
  final List<String> missing;
  final String reason;
}

abstract class AiService {
  Future<List<DetectedIngredient>> detectIngredients(List<ScanImage> images);

  Future<List<RecipeMatch>> suggestRecipes({
    required List<String> ingredients,
    required List<DietTag> diets,
    required List<String> allergies,
  });

  Future<List<RecipeMatch>> suggestNigerian({
    required List<String> ingredients,
  });
}

class DemoAiService implements AiService {
  static const _fridge = [
    'Eggs',
    'Spinach',
    'Cherry tomatoes',
    'Cheddar',
    'Greek yogurt',
    'Bell peppers',
    'Chicken thighs',
    'Milk',
    'Butter',
    'Onion',
  ];

  static const _cupboard = [
    'Pasta',
    'Canned tomatoes',
    'Garlic',
    'Olive oil',
    'Rice',
    'Red lentils',
    'Flour',
    'Miso paste',
  ];

  static const _freezer = [
    'Salmon fillets',
    'Frozen berries',
    'Sweetcorn',
    'Peas',
  ];

  List<String> _pool(int seed) => switch (seed.abs() % 3) {
    0 => _fridge,
    1 => _cupboard,
    _ => _freezer,
  };

  @override
  Future<List<DetectedIngredient>> detectIngredients(
    List<ScanImage> images,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 2100));
    final seen = <String, DetectedIngredient>{};
    for (final image in images) {
      final pool = _pool(image.seed);
      final count = 4 + (image.seed.abs() % 3);
      for (var i = 0; i < count; i++) {
        final name = pool[(image.seed.abs() + i * 3) % pool.length];
        final confidence = 0.8 + ((image.seed.abs() * 37 + i * 13) % 19) / 100;
        seen[name] = DetectedIngredient(
          name: name,
          confidence: confidence.clamp(0.8, 0.99),
          sourceSeed: image.seed,
        );
      }
    }
    return seen.values.toList(growable: false);
  }

  static const _aliases = <String, Set<String>>{
    'Tomatoes': {'tomato', 'fresh tomatoes', 'chopped tomatoes'},
    'Tomato paste': {'tomato paste', 'tomato puree', 'tin tomato'},
    'Pepper (Scotch bonnet)': {
      'pepper',
      'scotch bonnet',
      'scotch bonnets',
      'ata rodo',
      'fresh pepper',
    },
    'Green chilli (Ata rodo)': {'green chilli', 'chilli', 'ata rodo'},
    'Onion': {'onions', 'chopped onion'},
    'Red onion': {'red onions'},
    'Eggs': {'egg'},
    'Spinach': {'fresh spinach'},
    'Chicken thighs': {'chicken thigh', 'chicken drumsticks', 'chicken breast'},
    'Beef sirloin': {'beef', 'sirloin'},
    'Carrot': {'carrots'},
    'Green beans': {'green bean'},
    'Sweetcorn': {'corn', 'sweet corn'},
    'Garlic': {'garlic cloves'},
    'Ginger': {'fresh ginger', 'ginger root'},
    'Yam': {'white yam', 'punched yam', 'yam tuber'},
    'Ripe plantain': {'plantain', 'dodo', 'ripe plantain', 'plantains'},
    'Black-eyed beans': {'beans', 'black eyed beans', 'brown beans'},
    'Honey beans': {'ere'},
    'Palm oil': {'palm oil', 'red palm oil'},
    'Red palm oil': {'red palm oil'},
    'Egusi seeds': {'egusi', 'melon seeds', 'egusi seeds'},
    'Ogbono seeds': {'ogbono', 'wild mango seeds'},
    'Crayfish': {'crayfish powder', 'ground crayfish'},
    'Stockfish': {'dry stockfish', 'dried stockfish'},
    'Dried fish': {'dry fish'},
    'Smoked fish': {'smoked mackerel'},
    'Catfish': {'fish', 'fresh fish', 'catfish'},
    'Assorted meats': {'assorted meat', 'chicken', 'gizzard'},
    'Goat meat or catfish': {'goat meat', 'goat'},
    'Mackerel or corned beef': {'mackerel', 'corned beef'},
    'Prawns': {'prawn', 'shrimp', 'shrimps'},
    'Periwinkle': {'periwinkles'},
    'Bitterleaf': {'bitter leaf', 'bitter leaves'},
    'Ugu leaves': {'ugu', 'pumpkin leaves'},
    'Waterleaf': {'water leaves'},
    'Scent leaves': {'scent leaf', 'nchanwu'},
    'Oha leaves': {'oha', 'oha leaf'},
    'Okazi leaves': {'okazi', 'okazi leaf', 'ukazi'},
    'Locust beans (Iru)': {'iru', 'locust beans'},
    'Palm nut concentrate': {'palm nut', 'banga'},
    'Cocoyam': {'taro', 'ede', 'malanga'},
    'Pepper soup spice': {'pepper soup', 'pepper soup mix'},
    'Suya pepper (Yaji)': {'suya pepper', 'suya spice', 'yaji'},
    'Groundnut oil': {'peanut oil'},
    'Coconut milk': {'coconut cream', 'coconut'},
    'Yam flour (Elubo)': {'yam flour', 'elubo', 'amala flour'},
    'Rice': {'long grain rice', 'basmati rice'},
    'Ofada rice': {'ofada', 'local rice'},
  };

  bool _have(
    String ingredient,
    Set<String> available,
  ) {
    final name = ingredient.toLowerCase();
    if (available.contains(name)) return true;
    final aliases = _aliases[ingredient];
    if (aliases == null) return false;
    return aliases.any(available.contains);
  }

  List<RecipeMatch> _matchRecipes({
    required Iterable<Recipe> pool,
    required Set<String> available,
    required Set<String> blocked,
    required List<DietTag> diets,
  }) {
    final matches = <RecipeMatch>[];
    for (final recipe in pool) {
      if (!diets.every(recipe.diets.contains)) continue;
      final allowed = recipe.ingredients.where(
        (i) => !blocked.contains(i.name.toLowerCase()),
      );
      final matched = allowed
          .where((i) => _have(i.name, available))
          .map((i) => i.name)
          .toList();
      final missing = allowed
          .where((i) => !_have(i.name, available))
          .map((i) => i.name)
          .toList();
      if (matched.isEmpty) continue;
      matches.add(
        RecipeMatch(
          recipe: recipe,
          matched: matched,
          missing: missing,
          reason: _reason(matched.length, recipe.ingredients.length),
        ),
      );
    }
    return matches;
  }

  @override
  Future<List<RecipeMatch>> suggestRecipes({
    required List<String> ingredients,
    required List<DietTag> diets,
    required List<String> allergies,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    final available = ingredients.map((e) => e.toLowerCase()).toSet();
    final blocked = allergies.map((e) => e.toLowerCase()).toSet();

    final matches = _matchRecipes(
      pool: kCatalog,
      available: available,
      blocked: blocked,
      diets: diets,
    );

    matches.sort((a, b) {
      final ratio =
          (b.matched.length / b.recipe.ingredients.length) -
          (a.matched.length / a.recipe.ingredients.length);
      if (ratio != 0) return ratio > 0 ? 1 : -1;
      return a.recipe.minutes.compareTo(b.recipe.minutes);
    });
    return matches;
  }

  @override
  Future<List<RecipeMatch>> suggestNigerian({
    required List<String> ingredients,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    final available = ingredients.map((e) => e.toLowerCase()).toSet();
    final matches = _matchRecipes(
      pool: kCatalog.where((r) => r.isNigerian),
      available: available,
      blocked: const {},
      diets: const [],
    );
    matches.sort((a, b) {
      final ratio =
          (b.matched.length / b.recipe.ingredients.length) -
          (a.matched.length / a.recipe.ingredients.length);
      if (ratio != 0) return ratio > 0 ? 1 : -1;
      return b.recipe.ratingCount.compareTo(a.recipe.ratingCount);
    });
    return matches;
  }

  String _reason(int matched, int total) {
    final ratio = matched / total;
    if (ratio >= 0.7) return 'You have almost everything';
    if (ratio >= 0.45) return 'Uses $matched things you scanned';
    if (matched >= 2) return 'Built around your $matched ingredients';
    return 'Starts with what you scanned';
  }
}
