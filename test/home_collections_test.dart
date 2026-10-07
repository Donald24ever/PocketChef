import 'package:flutter_test/flutter_test.dart';

import 'package:pocketchef_ai/data/models/recipe.dart';
import 'package:pocketchef_ai/data/repositories/recipe_repository.dart';
import 'package:pocketchef_ai/features/home/home_collections.dart';

void main() {
  final shelves = buildHomeCollections(recipes: kCatalog, pantry: const {});

  List<int> sorted(List<int> values, {required bool descending}) {
    final copy = [...values];
    copy.sort(descending ? (a, b) => b.compareTo(a) : (a, b) => a.compareTo(b));
    return copy;
  }

  test('every home shelf is filled', () {
    expect(shelves.shortlist, hasLength(HomeCollections.shortlistCount));
    expect(shelves.popularNigerian, hasLength(HomeCollections.shelfCount));
    expect(shelves.quickNigerian, hasLength(HomeCollections.shelfCount));
    expect(shelves.healthyNigerian, hasLength(HomeCollections.shelfCount));
    expect(shelves.weekend, hasLength(HomeCollections.shelfCount));
  });

  test('no dish is repeated across shelves', () {
    final ids = shelves.all.map((r) => r.id).toList(growable: false);
    expect(ids.toSet(), hasLength(ids.length));
  });

  test('popular shelf is ranked by how often it is rated', () {
    final counts =
        shelves.popularNigerian.map((r) => r.ratingCount).toList(growable: false);
    expect(counts, sorted(counts, descending: true));
    expect(shelves.popularNigerian.every((r) => r.isNigerian), isTrue);
  });

  test('quick shelf only holds dishes ready within 45 minutes', () {
    final minutes =
        shelves.quickNigerian.map((r) => r.minutes).toList(growable: false);
    expect(minutes.every((m) => m <= 45), isTrue);
    expect(minutes, sorted(minutes, descending: false));
    expect(shelves.quickNigerian.every((r) => r.isNigerian), isTrue);
  });

  test('healthy shelf is the lightest of what is left', () {
    final calories =
        shelves.healthyNigerian.map((r) => r.calories).toList(growable: false);
    expect(calories, sorted(calories, descending: false));
    expect(calories.every((kcal) => kcal <= 500), isTrue);
    expect(shelves.healthyNigerian.every((r) => r.isNigerian), isTrue);
  });

  test('weekend shelf keeps its family-sized anchors', () {
    expect(shelves.weekend.every((r) => r.isNigerian), isTrue);
    final ids = shelves.weekend.map((r) => r.id).toSet();
    expect(ids.contains('ofada-rice-ayamase') || ids.contains('banga-soup'),
        isTrue);
  });

  test('shortlist ranks what the kitchen already has first', () {
    const pantry = {'eggs', 'spinach'};
    int matches(Recipe recipe) => recipe.ingredients
        .where((i) => pantry.contains(i.name.toLowerCase()))
        .length;

    final best = kCatalog.map(matches).reduce((a, b) => a > b ? a : b);
    expect(best, greaterThan(0), reason: 'the pantry must match some dish');

    final withPantry = buildHomeCollections(recipes: kCatalog, pantry: pantry);
    expect(matches(withPantry.shortlist.first), best);

    final ranked = withPantry.shortlist.map(matches).toList(growable: false);
    expect(ranked, sorted(ranked, descending: true));
  });
}
