import '../../data/models/recipe.dart';

/// Dishes that anchor the weekend shelf. Anything another shelf already
/// claimed is skipped, and the shelf is topped up with the highest-rated
/// Nigerian recipes still on offer so it always holds [HomeCollections.shelfCount]
/// dishes.
const kWeekendRecipeIds = <String>[
  'jollof-rice',
  'fried-rice',
  'ofada-rice-ayamase',
  'pounded-yam',
  'banga-soup',
  'oha-soup',
];

/// The five recipe lists rendered on the home screen.
///
/// Every shelf draws from one shared pool in a fixed order (shortlist →
/// popular → quick → healthy → weekend), so a dish is never repeated across
/// sections and each list still matches its own heading.
class HomeCollections {
  const HomeCollections({
    required this.shortlist,
    required this.popularNigerian,
    required this.quickNigerian,
    required this.healthyNigerian,
    required this.weekend,
  });

  static const int shortlistCount = 4;
  static const int shelfCount = 6;

  /// Best pantry matches: one feature card plus a few rows.
  final List<Recipe> shortlist;

  /// Highest-rated Nigerian dishes.
  final List<Recipe> popularNigerian;

  /// Nigerian dishes ready within 45 minutes.
  final List<Recipe> quickNigerian;

  /// The lightest Nigerian dishes left after the shelves above have picked.
  final List<Recipe> healthyNigerian;

  /// Big-pot family dishes for the weekend.
  final List<Recipe> weekend;

  Iterable<Recipe> get all => [
        ...shortlist,
        ...popularNigerian,
        ...quickNigerian,
        ...healthyNigerian,
        ...weekend,
      ];
}

/// Splits [recipes] into the distinct, title-true lists the home screen shows.
///
/// [pantry] holds lower-cased ingredient names the shopper already has, used
/// to rank the shortlist.
HomeCollections buildHomeCollections({
  required List<Recipe> recipes,
  required Set<String> pantry,
}) {
  final claimed = <String>{};

  List<Recipe> claim(Iterable<Recipe> pool, int count) {
    final picked = <Recipe>[];
    for (final recipe in pool) {
      if (picked.length >= count) break;
      if (claimed.add(recipe.id)) picked.add(recipe);
    }
    return picked;
  }

  final shortlistPool = [...recipes]..sort((a, b) {
      final byMatch = _matchCount(b, pantry) - _matchCount(a, pantry);
      if (byMatch != 0) return byMatch;
      return a.minutes.compareTo(b.minutes);
    });

  final nigerian = recipes.where((r) => r.isNigerian).toList(growable: false);

  final popularPool = [...nigerian]
    ..sort((a, b) => b.ratingCount.compareTo(a.ratingCount));
  final quickPool = nigerian.where((r) => r.minutes <= 45).toList()
    ..sort((a, b) => a.minutes.compareTo(b.minutes));
  final healthyPool = [...nigerian]
    ..sort((a, b) => a.calories.compareTo(b.calories));
  final byRating = [...nigerian]
    ..sort((a, b) => b.ratingCount.compareTo(a.ratingCount));

  final byId = {for (final recipe in nigerian) recipe.id: recipe};
  final weekendPool = <Recipe>[
    for (final id in kWeekendRecipeIds)
      if (byId[id] != null) byId[id]!,
    ...byRating,
  ];

  return HomeCollections(
    shortlist: claim(shortlistPool, HomeCollections.shortlistCount),
    popularNigerian: claim(popularPool, HomeCollections.shelfCount),
    quickNigerian: claim(quickPool, HomeCollections.shelfCount),
    healthyNigerian: claim(healthyPool, HomeCollections.shelfCount),
    weekend: claim(weekendPool, HomeCollections.shelfCount),
  );
}

int _matchCount(Recipe recipe, Set<String> pantry) => recipe.ingredients
    .where((i) => pantry.contains(i.name.toLowerCase()))
    .length;
