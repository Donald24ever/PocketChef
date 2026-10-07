import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'fonts.dart';

class AppTheme {
  AppTheme._();

  static ThemeData light() => _build(AppColors.light);

  static ThemeData dark() => _build(AppColors.dark);

  static TextStyle _ui(
    AppPalette p, {
    required double size,
    FontWeight weight = FontWeight.w400,
    Color? color,
    double? height,
    double? letterSpacing,
    FontStyle? fontStyle,
  }) {
    return Fonts.ui(
      TextStyle(
        fontSize: size,
        fontWeight: weight,
        color: color ?? p.ink,
        height: height,
        letterSpacing: letterSpacing,
        fontStyle: fontStyle,
      ),
    );
  }

  static TextStyle _display(
    AppPalette p, {
    required double size,
    FontWeight weight = FontWeight.w600,
    Color? color,
    double? height,
    double? letterSpacing,
  }) {
    return Fonts.display(
      TextStyle(
        fontSize: size,
        fontWeight: weight,
        color: color ?? p.ink,
        height: height,
        letterSpacing: letterSpacing,
      ),
    );
  }

  static ThemeData _build(AppPalette p) {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: p.primary,
          brightness: p.brightness,
        ).copyWith(
          primary: p.primary,
          onPrimary: p.onPrimary,
          secondary: p.olive,
          onSecondary: Colors.white,
          error: p.error,
          onError: Colors.white,
          surface: p.surface,
          onSurface: p.ink,
          surfaceContainerHighest: p.surfaceAlt,
          outline: p.hairline,
        );

    final textTheme = TextTheme(
      displayLarge: _display(p, size: 56, height: 1.04, letterSpacing: -1),
      displayMedium: _display(p, size: 44, height: 1.06, letterSpacing: -0.8),
      displaySmall: _display(p, size: 36, height: 1.1, letterSpacing: -0.6),
      headlineLarge: _display(p, size: 32, height: 1.14, letterSpacing: -0.4),
      headlineMedium: _display(p, size: 27, height: 1.18, letterSpacing: -0.3),
      headlineSmall: _ui(p, size: 22, weight: FontWeight.w700, height: 1.25),
      titleLarge: _ui(p, size: 19, weight: FontWeight.w700, height: 1.3),
      titleMedium: _ui(p, size: 16.5, weight: FontWeight.w600, height: 1.35),
      titleSmall: _ui(p, size: 15, weight: FontWeight.w600, height: 1.35),
      bodyLarge: _ui(p, size: 16.5, height: 1.5),
      bodyMedium: _ui(p, size: 15, height: 1.5),
      bodySmall: _ui(p, size: 13, height: 1.45),
      labelLarge: _ui(p, size: 15.5, weight: FontWeight.w600, height: 1.2),
      labelMedium: _ui(
        p,
        size: 13,
        weight: FontWeight.w600,
        height: 1.25,
        letterSpacing: 0.2,
      ),
      labelSmall: _ui(
        p,
        size: 11.5,
        weight: FontWeight.w600,
        height: 1.2,
        letterSpacing: 0.4,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: p.brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: p.background,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: p.background,
        surfaceTintColor: Colors.transparent,
        foregroundColor: p.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: _display(p, size: 24, height: 1.2),
      ),
      dividerTheme: DividerThemeData(
        color: p.hairline,
        thickness: 1,
        space: 1,
        indent: 0,
        endIndent: 0,
      ),
      cardTheme: CardThemeData(
        color: p.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: p.hairline),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: p.primary,
          foregroundColor: p.onPrimary,
          minimumSize: const Size(56, 56),
          padding: const EdgeInsets.symmetric(horizontal: 26),
          textStyle: _ui(p, size: 16, weight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.ink,
          minimumSize: const Size(56, 52),
          padding: const EdgeInsets.symmetric(horizontal: 22),
          textStyle: _ui(p, size: 16, weight: FontWeight.w600),
          side: BorderSide(color: p.hairline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.primary,
          textStyle: _ui(p, size: 15, weight: FontWeight.w700),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: p.ink,
        contentTextStyle: _ui(p, size: 14.5, color: p.background),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surfaceAlt,
        hintStyle: _ui(p, size: 15.5, color: p.inkTertiary),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: p.primary, width: 1.4),
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: p.primary,
        selectionColor: p.primary.withValues(alpha: 0.25),
        selectionHandleColor: p.primary,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: p.inkSecondary,
        textColor: p.ink,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: p.primary),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
