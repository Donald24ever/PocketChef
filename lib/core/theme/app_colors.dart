import 'package:flutter/material.dart';

class AppPalette {
  const AppPalette({
    required this.brightness,
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.ink,
    required this.inkSecondary,
    required this.inkTertiary,
    required this.primary,
    required this.primaryDeep,
    required this.onPrimary,
    required this.olive,
    required this.oliveSoft,
    required this.gold,
    required this.error,
    required this.success,
    required this.hairline,
    required this.shadow,
    required this.skeletonBase,
    required this.skeletonHighlight,
    required this.featureSurface,
    required this.onFeatureSurface,
    required this.onFeatureSurfaceMuted,
  });

  final Brightness brightness;
  final Color background;
  final Color surface;
  final Color surfaceAlt;
  final Color ink;
  final Color inkSecondary;
  final Color inkTertiary;
  final Color primary;
  final Color primaryDeep;
  final Color onPrimary;
  final Color olive;
  final Color oliveSoft;
  final Color gold;
  final Color error;
  final Color success;
  final Color hairline;
  final Color shadow;
  final Color skeletonBase;
  final Color skeletonHighlight;
  final Color featureSurface;
  final Color onFeatureSurface;
  final Color onFeatureSurfaceMuted;

  bool get isDark => brightness == Brightness.dark;

  Color withOpacity(Color color, double opacity) =>
      color.withValues(alpha: opacity);
}

class AppColors {
  AppColors._();

  static const AppPalette light = AppPalette(
    brightness: Brightness.light,
    background: Color(0xFFFAF6EE),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFF2ECDF),
    ink: Color(0xFF26231E),
    inkSecondary: Color(0xFF6E675C),
    inkTertiary: Color(0xFF9C9488),
    primary: Color(0xFFEC7A3C),
    primaryDeep: Color(0xFFD96527),
    onPrimary: Color(0xFFFFF9F3),
    olive: Color(0xFF667C4B),
    oliveSoft: Color(0xFFE6EBDB),
    gold: Color(0xFFE0A93C),
    error: Color(0xFFC4553B),
    success: Color(0xFF5E8B57),
    hairline: Color(0xFFEAE2D4),
    shadow: Color(0x14000000),
    skeletonBase: Color(0xFFEFE8DA),
    skeletonHighlight: Color(0xFFFAF6EE),
    featureSurface: Color(0xFF26231E),
    onFeatureSurface: Color(0xFFFFFBF4),
    onFeatureSurfaceMuted: Color(0xFFC2BEB8),
  );

  static const AppPalette dark = AppPalette(
    brightness: Brightness.dark,
    background: Color(0xFF191712),
    surface: Color(0xFF221F19),
    surfaceAlt: Color(0xFF2B2721),
    ink: Color(0xFFF4EFE5),
    inkSecondary: Color(0xFFB3AA9C),
    inkTertiary: Color(0xFF837B6F),
    primary: Color(0xFFF0864A),
    primaryDeep: Color(0xFFFF9757),
    onPrimary: Color(0xFF1E1A15),
    olive: Color(0xFF93AC72),
    oliveSoft: Color(0xFF31372A),
    gold: Color(0xFFE8B75A),
    error: Color(0xFFE0836B),
    success: Color(0xFF7FAE77),
    hairline: Color(0xFF353029),
    shadow: Color(0x33000000),
    skeletonBase: Color(0xFF2B2721),
    skeletonHighlight: Color(0xFF37322B),
    featureSurface: Color(0xFF2C2822),
    onFeatureSurface: Color(0xFFF5F1E8),
    onFeatureSurfaceMuted: Color(0xFFBDB9B1),
  );
}

class ArtColors {
  ArtColors._();

  static const List<List<Color>> scenes = [
    [
      Color(0xFFF6E7D2),
      Color(0xFFEFD4AE),
      Color(0xFFFFFBF3),
      Color(0xFFE2703A),
      Color(0xFFB94F24),
      Color(0xFF6B7F4E),
    ],
    [
      Color(0xFFE3EAD6),
      Color(0xFFCFDBBC),
      Color(0xFFFFFDF6),
      Color(0xFF7C9159),
      Color(0xFF55663D),
      Color(0xFFE2A34A),
    ],
    [
      Color(0xFFF4DFD2),
      Color(0xFFEAC9B4),
      Color(0xFFFFF9F1),
      Color(0xFFC96A43),
      Color(0xFF8F4327),
      Color(0xFF6E7F53),
    ],
    [
      Color(0xFFFFEFD6),
      Color(0xFFF7DCAE),
      Color(0xFFFFFDF7),
      Color(0xFFE8B04B),
      Color(0xFFC77C33),
      Color(0xFF8A6B3F),
    ],
    [
      Color(0xFFE9E1D3),
      Color(0xFFD9CDB9),
      Color(0xFFFFFCF5),
      Color(0xFF5E7450),
      Color(0xFF3F5237),
      Color(0xFFD97E45),
    ],
    [
      Color(0xFFF8E3E0),
      Color(0xFFEFCDC7),
      Color(0xFFFFF9F7),
      Color(0xFFD2604F),
      Color(0xFF96413A),
      Color(0xFF6F7F52),
    ],
    [
      Color(0xFFE4E9EE),
      Color(0xFFCFD8E0),
      Color(0xFFFDFEFF),
      Color(0xFF6B7F92),
      Color(0xFF48586A),
      Color(0xFFE0894C),
    ],
    [
      Color(0xFFEFE6D0),
      Color(0xFFE0D2B2),
      Color(0xFFFFFBEF),
      Color(0xFF977C46),
      Color(0xFF6C5730),
      Color(0xFF5F7448),
    ],
  ];
}
