import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pocketchef_ai/app/app.dart';
import 'package:pocketchef_ai/core/theme/app_colors.dart';
import 'package:pocketchef_ai/state/app_state_provider.dart';

double _relativeLuminance(Color color) {
  double linear(double channel) => channel <= 0.03928
      ? channel / 12.92
      : math.pow((channel + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * linear(color.r) +
      0.7152 * linear(color.g) +
      0.0722 * linear(color.b);
}

double _contrast(Color a, Color b) {
  final la = _relativeLuminance(a);
  final lb = _relativeLuminance(b);
  final hi = math.max(la, lb);
  final lo = math.min(la, lb);
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  group('feature card contrast (WCAG AA)', () {
    for (final entry in {
      'light': AppColors.light,
      'dark': AppColors.dark,
    }.entries) {
      test('${entry.key} feature card meets 4.5:1 for both text tones', () {
        final p = entry.value;
        expect(
          _contrast(p.onFeatureSurface, p.featureSurface),
          greaterThanOrEqualTo(4.5),
          reason: '${entry.key} primary feature text',
        );
        expect(
          _contrast(p.onFeatureSurfaceMuted, p.featureSurface),
          greaterThanOrEqualTo(4.5),
          reason: '${entry.key} muted feature text',
        );
      });
    }
  });

  Future<void> boot(WidgetTester tester, ThemeMode mode) async {
    SharedPreferences.setMockInitialValues({'onboarded': true, 'authed': true});
    await tester.pumpWidget(
      ProviderScope(
        overrides: [themeModeProvider.overrideWithValue(mode)],
        child: const PocketChefApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('quick tile text stays visible in dark mode', (tester) async {
    await boot(tester, ThemeMode.dark);

    final title = tester.widget<Text>(find.text('Dinner in 20'));
    final caption = tester.widget<Text>(find.text('Fast recipes only'));
    final tile = tester.widget<Container>(
      find
          .ancestor(of: find.text('Dinner in 20'), matching: find.byType(Container))
          .first,
    );
    final background = (tile.decoration! as BoxDecoration).color!;

    expect(title.style!.color, AppColors.dark.onFeatureSurface);
    expect(caption.style!.color, AppColors.dark.onFeatureSurfaceMuted);
    expect(background, AppColors.dark.featureSurface);
    expect(
      _contrast(title.style!.color!, background),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      _contrast(caption.style!.color!, background),
      greaterThanOrEqualTo(4.5),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('quick tile text stays visible in light mode', (tester) async {
    await boot(tester, ThemeMode.light);

    final title = tester.widget<Text>(find.text('Dinner in 20'));
    final tile = tester.widget<Container>(
      find
          .ancestor(of: find.text('Dinner in 20'), matching: find.byType(Container))
          .first,
    );
    final background = (tile.decoration! as BoxDecoration).color!;

    expect(title.style!.color, AppColors.light.onFeatureSurface);
    expect(background, AppColors.light.featureSurface);
    expect(
      _contrast(title.style!.color!, background),
      greaterThanOrEqualTo(4.5),
    );
    expect(tester.takeException(), isNull);
  });
}