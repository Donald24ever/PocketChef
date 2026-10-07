import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Fonts {
  Fonts._();

  static final bool runtimeFetch = !Platform.environment.containsKey(
    'FLUTTER_TEST',
  );

  static TextStyle ui(TextStyle style) =>
      runtimeFetch ? GoogleFonts.figtree(textStyle: style) : style;

  static TextStyle display(TextStyle style) =>
      runtimeFetch ? GoogleFonts.fraunces(textStyle: style) : style;
}
