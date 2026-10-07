import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/theme_extensions.dart';

int stableHash(String value) {
  var hash = 2166136261;
  for (final unit in value.codeUnits) {
    hash ^= unit;
    hash = (hash * 16777619) & 0x7fffffff;
  }
  return hash;
}

class DishArtwork extends StatelessWidget {
  const DishArtwork({super.key, required this.seed, this.radius = 22});

  final String seed;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: CustomPaint(
        painter: DishPainter(seed: seed),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class DishPainter extends CustomPainter {
  DishPainter({required this.seed});

  final String seed;

  @override
  void paint(Canvas canvas, Size size) {
    final hash = stableHash(seed);
    final scene = ArtColors.scenes[hash % ArtColors.scenes.length];
    final variant = (hash >> 8) % 4;
    final random = Random(hash);
    final w = size.width;
    final h = size.height;
    final minDim = min(w, h);

    final bg = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [scene[0], scene[1]],
      ).createShader(Offset.zero & size);

    canvas.drawRect(Offset.zero & size, bg);

    canvas.drawCircle(
      Offset(w * 0.82, h * 0.16),
      minDim * 0.34,
      Paint()..color = scene[2].withValues(alpha: 0.35),
    );
    canvas.drawCircle(
      Offset(w * 0.12, h * 0.88),
      minDim * 0.3,
      Paint()..color = scene[5].withValues(alpha: 0.14),
    );

    if (w >= 150) {
      final utensil = Paint()
        ..color = const Color(0xFF000000).withValues(alpha: 0.1)
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 5;
      canvas.drawLine(
        Offset(w * 0.07, h * 0.3),
        Offset(w * 0.07, h * 0.7),
        utensil,
      );
      canvas.drawLine(
        Offset(w * 0.93, h * 0.3),
        Offset(w * 0.93, h * 0.7),
        utensil,
      );
    }

    final center = Offset(w / 2, h / 2);
    final plateR = minDim * 0.31;

    canvas.drawCircle(
      center + const Offset(0, 6),
      plateR,
      Paint()
        ..color = const Color(0xFF000000).withValues(alpha: 0.07)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    canvas.drawCircle(center, plateR, Paint()..color = scene[2]);
    canvas.drawCircle(
      center,
      plateR * 0.88,
      Paint()
        ..color = scene[2]
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFF000000).withValues(alpha: 0.05),
    );

    canvas.save();
    canvas.clipPath(
      Path()..addOval(Rect.fromCircle(center: center, radius: plateR)),
    );
    _paintFood(canvas, center, plateR, variant, scene, random);
    _paintGarnish(canvas, center, plateR, scene, random);
    canvas.restore();
  }

  void _paintFood(
    Canvas canvas,
    Offset center,
    double plateR,
    int variant,
    List<Color> scene,
    Random random,
  ) {
    final food1 = Paint()..color = scene[3];
    final food2 = Paint()..color = scene[4];
    final food3 = Paint()..color = scene[5];

    switch (variant) {
      case 0:
        canvas.drawCircle(center, plateR * 0.58, food1);
        canvas.drawCircle(
          center + Offset(-plateR * 0.2, -plateR * 0.15),
          plateR * 0.24,
          food3,
        );
        for (var i = 0; i < 5; i++) {
          final angle = (i / 5) * 2 * pi + 0.4;
          canvas.drawCircle(
            center + Offset(cos(angle), sin(angle)) * plateR * 0.74,
            plateR * 0.12,
            i.isEven ? food2 : food3,
          );
        }
      case 1:
        for (var i = 0; i < 8; i++) {
          final angle = random.nextDouble() * 2 * pi;
          final dist = random.nextDouble() * plateR * 0.62;
          final rect = Rect.fromCenter(
            center: center + Offset(cos(angle), sin(angle)) * dist,
            width: plateR * (0.3 + random.nextDouble() * 0.24),
            height: plateR * (0.16 + random.nextDouble() * 0.12),
          );
          canvas.save();
          canvas.translate(rect.center.dx, rect.center.dy);
          canvas.rotate(random.nextDouble() * pi);
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(
                center: Offset.zero,
                width: rect.width,
                height: rect.height,
              ),
              Radius.circular(plateR * 0.1),
            ),
            i.isEven ? food1 : food2,
          );
          canvas.restore();
        }
        canvas.drawCircle(
          center + Offset(plateR * 0.1, plateR * 0.1),
          plateR * 0.3,
          food3..color = scene[5],
        );
      case 2:
        canvas.save();
        canvas.translate(center.dx, center.dy);
        canvas.rotate(-0.14);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(0, plateR * 0.1),
              width: plateR * 1.3,
              height: plateR * 0.56,
            ),
            Radius.circular(plateR * 0.24),
          ),
          food2,
        );
        canvas.drawCircle(
          Offset(-plateR * 0.2, -plateR * 0.34),
          plateR * 0.34,
          food1,
        );
        canvas.restore();
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: plateR * 0.78),
          -0.6,
          1.4,
          false,
          Paint()
            ..color = scene[5]
            ..style = PaintingStyle.stroke
            ..strokeWidth = plateR * 0.12
            ..strokeCap = StrokeCap.round,
        );
      default:
        for (var i = 0; i < 3; i++) {
          final start = -pi / 2 + i * (2 * pi / 3);
          final path = Path()
            ..moveTo(center.dx, center.dy)
            ..arcTo(
              Rect.fromCircle(center: center, radius: plateR * 0.7),
              start,
              1.7,
              false,
            )
            ..close();
          canvas.drawPath(path, i.isEven ? food1 : food2);
        }
        canvas.drawCircle(center, plateR * 0.16, food3);
    }
  }

  void _paintGarnish(
    Canvas canvas,
    Offset center,
    double plateR,
    List<Color> scene,
    Random random,
  ) {
    for (var i = 0; i < 8; i++) {
      final angle = random.nextDouble() * 2 * pi;
      final dist = plateR * (0.35 + random.nextDouble() * 0.55);
      canvas.drawCircle(
        center + Offset(cos(angle), sin(angle)) * dist,
        plateR * (0.03 + random.nextDouble() * 0.03),
        Paint()..color = scene[5],
      );
    }
  }

  @override
  bool shouldRepaint(DishPainter oldDelegate) => oldDelegate.seed != seed;
}

class LogoMark extends StatelessWidget {
  const LogoMark({super.key, this.size = 56});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: context.c.primary,
        borderRadius: BorderRadius.circular(size * 0.3),
        boxShadow: [
          BoxShadow(
            color: context.c.primary.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        'P',
        style: context.serif(
          size * 0.56,
          weight: FontWeight.w700,
          color: context.c.onPrimary,
          height: 1,
        ),
      ),
    );
  }
}

class OnboardingScene extends StatelessWidget {
  const OnboardingScene({super.key, required this.variant});

  final int variant;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: ScenePainter(variant: variant, palette: context.c),
      size: const Size.square(240),
    );
  }
}

class ScenePainter extends CustomPainter {
  ScenePainter({required this.variant, required this.palette});

  final int variant;
  final AppPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final bone = palette.surface;
    final ink = palette.ink;
    final orange = palette.primary;
    final olive = palette.olive;
    final hairline = palette.hairline;
    final soft = palette.surfaceAlt;

    void roundRect(Rect rect, double r, Color color) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(r)),
        Paint()..color = color,
      );
    }

    switch (variant) {
      case 0:
        roundRect(
          Rect.fromLTWH(w * 0.22, h * 0.08, w * 0.56, h * 0.84),
          24,
          bone,
        );
        canvas.drawRect(
          Rect.fromLTWH(w * 0.22, h * 0.08, w * 0.56, h * 0.84),
          Paint()
            ..color = hairline
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
        canvas.drawLine(
          Offset(w * 0.22, h * 0.42),
          Offset(w * 0.78, h * 0.42),
          Paint()
            ..color = hairline
            ..strokeWidth = 2,
        );
        roundRect(
          Rect.fromLTWH(w * 0.27, h * 0.14, w * 0.1, h * 0.2),
          8,
          orange,
        );
        roundRect(
          Rect.fromLTWH(w * 0.4, h * 0.18, w * 0.14, h * 0.12),
          8,
          olive,
        );
        roundRect(
          Rect.fromLTWH(w * 0.57, h * 0.13, w * 0.16, h * 0.2),
          8,
          soft,
        );
        roundRect(
          Rect.fromLTWH(w * 0.27, h * 0.5, w * 0.2, h * 0.14),
          10,
          orange.withValues(alpha: 0.75),
        );
        roundRect(
          Rect.fromLTWH(w * 0.5, h * 0.48, w * 0.22, h * 0.2),
          10,
          olive.withValues(alpha: 0.75),
        );
        roundRect(Rect.fromLTWH(w * 0.3, h * 0.7, w * 0.4, h * 0.12), 10, soft);
        roundRect(
          Rect.fromLTWH(w * 0.75, h * 0.3, w * 0.05, h * 0.22),
          4,
          ink.withValues(alpha: 0.5),
        );
      case 1:
        roundRect(
          Rect.fromLTWH(w * 0.14, h * 0.2, w * 0.72, h * 0.56),
          28,
          bone,
        );
        canvas.drawCircle(
          Offset(w * 0.5, h * 0.48),
          w * 0.16,
          Paint()..color = soft,
        );
        canvas.drawCircle(
          Offset(w * 0.5, h * 0.48),
          w * 0.1,
          Paint()..color = orange,
        );
        canvas.drawCircle(
          Offset(w * 0.5, h * 0.48),
          w * 0.045,
          Paint()..color = bone,
        );
        void chip(double x, double y, double cw, Color color) {
          roundRect(Rect.fromLTWH(x, y, cw, h * 0.1), 12, color);
        }

        chip(w * 0.04, h * 0.06, w * 0.3, olive.withValues(alpha: 0.9));
        chip(w * 0.62, h * 0.08, w * 0.32, orange);
        chip(w * 0.02, h * 0.82, w * 0.34, soft);
        chip(w * 0.6, h * 0.84, w * 0.36, olive);
        final bracket = Paint()
          ..color = ink.withValues(alpha: 0.55)
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;
        void corner(Offset o, double dx, double dy) {
          canvas.drawLine(o, o + Offset(dx, 0), bracket);
          canvas.drawLine(o, o + Offset(0, dy), bracket);
        }

        corner(Offset(w * 0.08, h * 0.14), 26, 26);
        corner(Offset(w * 0.92, h * 0.14), -26, 26);
        corner(Offset(w * 0.08, h * 0.86), 26, -26);
        corner(Offset(w * 0.92, h * 0.86), -26, -26);
      default:
        canvas.drawCircle(
          Offset(w * 0.5, h * 0.56),
          w * 0.32,
          Paint()..color = bone,
        );
        canvas.drawCircle(
          Offset(w * 0.5, h * 0.56),
          w * 0.24,
          Paint()
            ..color = orange.withValues(alpha: 0.85)
            ..style = PaintingStyle.stroke
            ..strokeWidth = w * 0.07,
        );
        canvas.drawCircle(
          Offset(w * 0.5, h * 0.56),
          w * 0.09,
          Paint()..color = olive,
        );
        void sparkle(Offset o, double s) {
          final path = Path()
            ..moveTo(o.dx, o.dy - s)
            ..quadraticBezierTo(o.dx, o.dy, o.dx + s, o.dy)
            ..quadraticBezierTo(o.dx, o.dy, o.dx, o.dy + s)
            ..quadraticBezierTo(o.dx, o.dy, o.dx - s, o.dy)
            ..quadraticBezierTo(o.dx, o.dy, o.dx, o.dy - s)
            ..close();
          canvas.drawPath(path, Paint()..color = orange);
        }

        sparkle(Offset(w * 0.2, h * 0.2), w * 0.06);
        sparkle(Offset(w * 0.82, h * 0.28), w * 0.045);
        sparkle(Offset(w * 0.74, h * 0.86), w * 0.05);
        canvas.drawArc(
          Rect.fromCircle(center: Offset(w * 0.36, h * 0.24), radius: w * 0.1),
          0.6,
          2.4,
          false,
          Paint()
            ..color = ink.withValues(alpha: 0.4)
            ..strokeWidth = 3
            ..strokeCap = StrokeCap.round
            ..style = PaintingStyle.stroke,
        );
    }
  }

  @override
  bool shouldRepaint(ScenePainter oldDelegate) =>
      oldDelegate.variant != variant;
}
