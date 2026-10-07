import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/theme_extensions.dart';
import 'skeleton.dart';

class RecipeImage extends StatefulWidget {
  const RecipeImage({
    super.key,
    required this.imageUrl,
    this.borderRadius = 22,
    this.fit = BoxFit.cover,
    this.onSettled,
    this.cacheWidth,
  });

  final String? imageUrl;
  final double borderRadius;
  final BoxFit fit;
  final VoidCallback? onSettled;
  final int? cacheWidth;

  @override
  State<RecipeImage> createState() => _RecipeImageState();
}

class _RecipeImageState extends State<RecipeImage> {
  bool _settled = false;

  static const _headers = <String, String>{
    'User-Agent': 'PocketChef/1.0 (+https://pocketchef.app)',
    'Accept': 'image/*',
  };

  void _settle() {
    if (_settled) return;
    _settled = true;
    final callback = widget.onSettled;
    if (callback != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => callback());
    }
  }

  @override
  void didUpdateWidget(covariant RecipeImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _settled = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final url = widget.imageUrl;
    final Widget content;
    if (url == null || url.isEmpty) {
      _settle();
      content = const _ImageUnavailable();
    } else {
      content = Image(
        image: CachedNetworkImageProvider(
          url,
          headers: _headers,
          maxWidth: widget.cacheWidth,
        ),
        fit: widget.fit,
        gaplessPlayback: true,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded || frame != null) {
            _settle();
          }
          return AnimatedOpacity(
            opacity: wasSynchronouslyLoaded || frame != null ? 1 : 0,
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeOut,
            child: child,
          );
        },
        loadingBuilder: (context, child, progress) {
          if (progress == null) {
            return child;
          }
          return const SizedBox.expand(
            child: ShimmerBox(
              width: double.infinity,
              height: double.infinity,
              radius: 0,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          _settle();
          return const _ImageUnavailable();
        },
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: SizedBox.expand(child: content),
    );
  }
}

class _ImageUnavailable extends StatelessWidget {
  const _ImageUnavailable();

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            constraints.maxHeight < 96 || constraints.maxWidth < 96;
        return Container(
          color: c.surfaceAlt,
          alignment: Alignment.center,
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.image_not_supported_outlined,
                size: compact ? 20 : 26,
                color: c.inkTertiary,
              ),
              if (!compact) ...[
                const SizedBox(height: 8),
                Text(
                  'Image currently unavailable',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.ui(12, color: c.inkTertiary),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}