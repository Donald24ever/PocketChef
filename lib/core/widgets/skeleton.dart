import 'package:flutter/material.dart';

import '../theme/theme_extensions.dart';

class ShimmerBox extends StatefulWidget {
  const ShimmerBox({super.key, this.width, this.height = 16, this.radius = 10});

  final double? width;
  final double height;
  final double radius;

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(-1 + 2 * _controller.value, 0),
              end: Alignment(2 * _controller.value, 0),
              colors: [c.skeletonBase, c.skeletonHighlight, c.skeletonBase],
            ),
          ),
        );
      },
    );
  }
}

class RecipeRowSkeleton extends StatelessWidget {
  const RecipeRowSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          const ShimmerBox(width: 104, height: 104, radius: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                ShimmerBox(width: 180, height: 17),
                SizedBox(height: 10),
                ShimmerBox(width: 120, height: 13),
                SizedBox(height: 14),
                ShimmerBox(width: 90, height: 13, radius: 999),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class RecipeCardSkeleton extends StatelessWidget {
  const RecipeCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        ShimmerBox(height: 140, radius: 22),
        SizedBox(height: 12),
        ShimmerBox(width: 160, height: 16),
        SizedBox(height: 8),
        ShimmerBox(width: 100, height: 12),
      ],
    );
  }
}
