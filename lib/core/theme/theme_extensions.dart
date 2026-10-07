import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'fonts.dart';

extension AppContext on BuildContext {
  AppPalette get c => Theme.of(this).brightness == Brightness.dark
      ? AppColors.dark
      : AppColors.light;

  TextTheme get t => Theme.of(this).textTheme;

  Size get screen => MediaQuery.sizeOf(this);

  double get screenWidth => screen.width;

  double get screenHeight => screen.height;

  bool get isWide => screenWidth >= 720;

  bool get isTablet => screenWidth >= 600;

  double get hPad => isWide ? 32 : 20;

  double get contentMax => isWide ? 720 : screenWidth;

  TextStyle serif(
    double size, {
    FontWeight weight = FontWeight.w600,
    Color? color,
    double? height,
    double? letterSpacing,
  }) {
    return Fonts.display(
      TextStyle(
        fontSize: size,
        fontWeight: weight,
        color: color ?? c.ink,
        height: height,
        letterSpacing: letterSpacing,
      ),
    );
  }

  TextStyle ui(
    double size, {
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
        color: color ?? c.ink,
        height: height,
        letterSpacing: letterSpacing,
        fontStyle: fontStyle,
      ),
    );
  }
}

extension AppWidgets on Widget {
  Widget padded(EdgeInsetsGeometry padding) =>
      Padding(padding: padding, child: this);

  Widget clickable(VoidCallback onTap, {String? hint}) => Semantics(
    button: true,
    label: hint,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: this,
    ),
  );
}
