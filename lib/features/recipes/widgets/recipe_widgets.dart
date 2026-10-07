import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme_extensions.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/utils/route_guard.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/misc.dart';
import '../../../core/widgets/recipe_image.dart';
import '../../../data/models/recipe.dart';
import '../../../state/domain_providers.dart';

class BookmarkButton extends ConsumerWidget {
  const BookmarkButton({
    super.key,
    required this.recipeId,
    this.size = 48,
    this.iconSize = 22,
    this.background,
  });

  final String recipeId;
  final double size;
  final double iconSize;
  final Color? background;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final saved = ref.watch(
      favoritesProvider.select((s) => s.recipeIds.contains(recipeId)),
    );
    return Semantics(
      button: true,
      label: saved ? 'Remove from saved' : 'Save recipe',
      child: PressScale(
        onTap: () {
          Haptics.medium();
          ref.read(favoritesProvider.notifier).toggle(recipeId);
        },
        child: SizedBox(
          width: size,
          height: size,
          child: Material(
            color: background ?? c.surface,
            shape: CircleBorder(
              side: background == null
                  ? BorderSide(color: c.hairline)
                  : BorderSide.none,
            ),
            clipBehavior: Clip.antiAlias,
            child: Icon(
              saved ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
              size: iconSize,
              color: saved ? c.primaryDeep : c.inkSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class RecipeRow extends StatelessWidget {
  const RecipeRow({
    super.key,
    required this.recipe,
    this.subtitle,
    this.onTap,
    this.showBookmark = true,
  });

  final Recipe recipe;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool showBookmark;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return PressScale(
      onTap:
          onTap ??
          () {
            Haptics.light();
            RouteGuard.push(context, '/recipe/${recipe.id}');
          },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 104,
              height: 104,
              child: RecipeImage(
                imageUrl: recipe.imageUrl,
                borderRadius: 20,
                artSeed: recipe.artSeed,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.ui(
                      16.5,
                      weight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle ?? recipe.blurb,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.ui(13.5, color: c.inkSecondary),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 2,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            size: 15,
                            color: c.inkTertiary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${recipe.minutes} min',
                            style: context.ui(
                              12.5,
                              weight: FontWeight.w600,
                              color: c.inkSecondary,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        recipe.difficulty.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.ui(
                          12.5,
                          weight: FontWeight.w600,
                          color: c.inkSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (showBookmark) ...[
              const SizedBox(width: 8),
              BookmarkButton(recipeId: recipe.id),
            ],
          ],
        ),
      ),
    );
  }
}

class FeatureRecipeCard extends StatelessWidget {
  const FeatureRecipeCard({
    super.key,
    required this.recipe,
    this.eyebrow,
    this.onTap,
  });

  final Recipe recipe;
  final String? eyebrow;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return PressScale(
      onTap:
          onTap ??
          () {
            Haptics.light();
            RouteGuard.push(context, '/recipe/${recipe.id}');
          },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: c.hairline),
          boxShadow: [
            BoxShadow(
              color: c.shadow,
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 180,
              width: double.infinity,
              child: RecipeImage(
                imageUrl: recipe.imageUrl,
                borderRadius: 0,
                artSeed: recipe.artSeed,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (eyebrow != null) ...[
                    Text(
                      eyebrow!,
                      style: context.ui(
                        11.5,
                        weight: FontWeight.w700,
                        color: c.primaryDeep,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          recipe.title,
                          style: context.serif(23, height: 1.2),
                        ),
                      ),
                      BookmarkButton(recipeId: recipe.id),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    recipe.blurb,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.ui(
                      14.5,
                      color: c.inkSecondary,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      MetaPill(
                        icon: Icons.schedule_rounded,
                        label: '${recipe.minutes} min',
                      ),
                      MetaPill(
                        icon: Icons.local_fire_department_outlined,
                        label: '${recipe.calories} kcal',
                        tone: Tone.olive,
                      ),
                      RatingLabel(
                        rating: recipe.rating,
                        count: recipe.ratingCount,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RecipeTile extends StatelessWidget {
  const RecipeTile({
    super.key,
    required this.recipe,
    this.onTap,
    this.subtitle,
  });

  final Recipe recipe;
  final VoidCallback? onTap;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return PressScale(
      onTap:
          onTap ??
          () {
            Haptics.light();
            RouteGuard.push(context, '/recipe/${recipe.id}');
          },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 1.25,
                child: RecipeImage(
                imageUrl: recipe.imageUrl,
                borderRadius: 20,
                artSeed: recipe.artSeed,
              ),
              ),
              Positioned(
                top: 6,
                right: 6,
                child: BookmarkButton(
                  recipeId: recipe.id,
                  size: 40,
                  iconSize: 18,
                  background: context.c.surface.withValues(alpha: 0.92),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            recipe.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: context.ui(15.5, weight: FontWeight.w700, height: 1.3),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle ?? '${recipe.minutes} min · ${recipe.difficulty.label}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.ui(12.5, color: c.inkSecondary),
          ),
        ],
      ),
    );
  }
}
