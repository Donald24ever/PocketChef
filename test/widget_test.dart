import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pocketchef_ai/app/app.dart';

void main() {
  Future<void> boot(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'onboarded': true, 'authed': true});
    await tester.pumpWidget(ProviderScope(child: PocketChefApp()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('splash lands on home for an authed user', (tester) async {
    await boot(tester);

    expect(find.text('Home'), findsWidgets);
    expect(find.text('Recipes'), findsWidgets);
    expect(find.text('Plan'), findsWidgets);
    expect(find.text('Profile'), findsWidgets);
  });

  testWidgets('bottom bar switches to the plan tab', (tester) async {
    await boot(tester);

    await tester.tap(find.text('Plan').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Meal plan'), findsOneWidget);
    expect(find.text('Groceries'), findsOneWidget);
    expect(find.text('This week'), findsOneWidget);
  });

  testWidgets('demo scan reaches the ingredient review screen', (tester) async {
    await boot(tester);

    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/camera'),
      (call) async => <Object?>[],
    );

    await tester.tap(find.byIcon(Icons.camera_alt_rounded).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Run a demo scan'), findsOneWidget);

    await tester.tap(find.text('Run a demo scan'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 2400));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Your ingredients'), findsOneWidget);
  });
}
