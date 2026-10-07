import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pocketchef_ai/state/domain_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // Persisted planner writes run through SharedPreferences; keep them
    // in memory so the test never touches platform channels.
    SharedPreferences.setMockInitialValues({});
  });

  test('shuffleDays redistributes meals across days without losing any', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(plannerProvider.notifier);
    notifier.autoPlan(recipeIds: const ['shakshuka', 'pasta'], servings: 2);
    final before = container.read(plannerProvider);
    expect(before.length, 7);

    notifier.shuffleDays();

    final after = container.read(plannerProvider);
    expect(after.length, 7);
    expect(after.map((m) => m.id).toSet(), before.map((m) => m.id).toSet());
    expect(
      after.every((m) => m.day >= 0 && m.day <= 6),
      isTrue,
    );
  });

  test('shuffleDays on an empty plan is a no-op', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(plannerProvider.notifier).shuffleDays();

    expect(container.read(plannerProvider), isEmpty);
  });
}