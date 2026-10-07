import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pocketchef_ai/core/theme/app_theme.dart';
import 'package:pocketchef_ai/data/repositories/recipe_repository.dart';
import 'package:pocketchef_ai/data/seed/photo_credits.dart';
import 'package:pocketchef_ai/features/legal/credits_screen.dart';

void main() {
  testWidgets('credits screen renders every photo credit without overflow',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light(), home: const CreditsScreen()),
    );
    await tester.pump();

    expect(photoCredits.length, 87);
    final covered = photoCredits.map((c) => c.dish).toSet();
    final missing = kCatalog
        .where((r) => r.imageUrl.isNotEmpty && !covered.contains(r.title))
        .map((r) => r.title)
        .toList();
    expect(missing, isEmpty);
    expect(find.text('Photo credits'), findsWidgets);
    expect(find.text('Wikimedia Commons'), findsWidgets);
    expect(find.text('TheMealDB'), findsWidgets);
    expect(find.byType(SelectableText), findsWidgets);
    expect(tester.takeException(), isNull);

    for (var i = 0; i < 12; i++) {
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -500));
      await tester.pump();
    }
    expect(tester.takeException(), isNull);
  });
}