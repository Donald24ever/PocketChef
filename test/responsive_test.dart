import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pocketchef_ai/app/app.dart';
import 'package:pocketchef_ai/features/recipes/widgets/recipe_widgets.dart';

void main() {
  Future<void> boot(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'onboarded': true, 'authed': true});
    await tester.pumpWidget(const ProviderScope(child: PocketChefApp()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pump(const Duration(milliseconds: 400));
  }

  Future<void> setSize(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  final sizes = <String, Size>{
    'compact 320x568': const Size(320, 568),
    'small 360x640': const Size(360, 640),
    'large 430x932': const Size(430, 932),
    'tablet 820x1180': const Size(820, 1180),
  };

  for (final entry in sizes.entries) {
    testWidgets('tabs render without overflow at ${entry.key}', (tester) async {
      await setSize(tester, entry.value);
      await boot(tester);
      expect(tester.takeException(), isNull);

      for (final tab in ['Recipes', 'Plan', 'Profile', 'Home']) {
        await tester.tap(find.text(tab).first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(tester.takeException(), isNull, reason: '$tab overflowed');
      }
    });
  }

  testWidgets('recipe detail and cook mode render without overflow',
      (tester) async {
    await setSize(tester, const Size(320, 568));
    await boot(tester);

    await tester.tap(find.text('Recipes').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.byType(RecipeRow).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);
    expect(find.text('Start cooking'), findsOneWidget);

    await tester.tap(find.text('Start cooking'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);
  });

  testWidgets('demo scan review renders without overflow on small screen',
      (tester) async {
    await setSize(tester, const Size(320, 568));
    await boot(tester);

    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/camera'),
      (call) async => <Object?>[],
    );

    await tester.tap(find.byIcon(Icons.camera_alt_rounded).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Run a demo scan'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 2400));
    await tester.pump(const Duration(milliseconds: 500));

    expect(tester.takeException(), isNull);
    expect(find.text('Your ingredients'), findsOneWidget);
  });
}