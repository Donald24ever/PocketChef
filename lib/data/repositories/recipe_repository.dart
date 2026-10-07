import '../models/recipe.dart';
import '../seed/global_recipe_catalog.dart';
import '../seed/nigerian_recipe_catalog.dart';
import '../seed/recipe_catalog.dart';
import '../seed/western_recipe_catalog.dart';

abstract class RecipeRepository {
  List<Recipe> all();

  Recipe? byId(String id);

  List<Recipe> byIds(Iterable<String> ids);

  List<Recipe> quickPicks({int count = 6});
}

const List<Recipe> kCatalog = [
  ...kRecipeCatalog,
  ...kNigerianRecipeCatalog,
  ...kWesternRecipeCatalog,
  ...kGlobalRecipeCatalog,
];

class CatalogRecipeRepository implements RecipeRepository {
  @override
  List<Recipe> all() => kCatalog;

  @override
  Recipe? byId(String id) {
    for (final recipe in kCatalog) {
      if (recipe.id == id) return recipe;
    }
    return null;
  }

  @override
  List<Recipe> byIds(Iterable<String> ids) =>
      ids.map(byId).whereType<Recipe>().toList(growable: false);

  @override
  List<Recipe> quickPicks({int count = 6}) =>
      kCatalog.take(count).toList(growable: false);
}
