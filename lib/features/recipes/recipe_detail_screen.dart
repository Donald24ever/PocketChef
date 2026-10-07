import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/theme_extensions.dart';
import '../../core/utils/haptics.dart';
import '../../core/utils/route_guard.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/misc.dart';
import '../../core/widgets/recipe_image.dart';
import '../../core/widgets/skeleton.dart';
import '../../data/models/recipe.dart';
import '../../state/domain_providers.dart';
import 'widgets/recipe_widgets.dart';

class RecipeDetailScreen extends ConsumerStatefulWidget {
  const RecipeDetailScreen({super.key, required this.recipeId});

  final String recipeId;

  @override
  ConsumerState<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends ConsumerState<RecipeDetailScreen> {
  late int _servings;
  bool _heroReady = false;

  @override
  void initState() {
    super.initState();
    final recipe = ref.read(recipeRepositoryProvider).byId(widget.recipeId);
    _servings = recipe?.servings ?? 2;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final recipe = ref.watch(
      recipeRepositoryProvider.select((r) => r.byId(widget.recipeId)),
    );
    if (recipe == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Recipe')),
        body: const Center(child: Text('This recipe is no longer available.')),
      );
    }

    final pantryNames = ref.watch(
      pantryProvider.select((p) {
        final names = <String>{};
        for (final item in p) {
          names.add(item.name.toLowerCase());
        }
        return names;
      }),
    );
    final matched = recipe.matchedWith(pantryNames);
    final missing = recipe.missingFrom(pantryNames);
    final viewTop = MediaQuery.paddingOf(context).top;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Hero(
                  tag: 'art-${recipe.id}',
                  child: SizedBox(
                    height: 300,
                    width: double.infinity,
                    child: RecipeImage(
                      imageUrl: recipe.imageUrl,
                      borderRadius: 0,
                      onSettled: () {
                        if (mounted && !_heroReady) {
                          setState(() => _heroReady = true);
                        }
                      },
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  height: 140,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.45),
                          Colors.black.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: viewTop + 6,
                  left: 14,
                  right: 14,
                  child: Row(
                    children: [
                      RoundIconButton(
                        icon: Icons.arrow_back_rounded,
                        background: const Color(0xFFFFFBF4),
                        onTap: () {
                          Haptics.light();
                          if (context.canPop()) context.pop();
                        },
                        tooltip: 'Back',
                      ),
                      const Spacer(),
                      RoundIconButton(
                        icon: Icons.ios_share_rounded,
                        background: const Color(0xFFFFFBF4),
                        onTap: () => _share(recipe),
                        tooltip: 'Share recipe',
                      ),
                      const SizedBox(width: 10),
                      BookmarkButton(
                        recipeId: recipe.id,
                        size: 48,
                        background: const Color(0xFFFFFBF4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Transform.translate(
              offset: const Offset(0, -30),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(context.hPad, 34, context.hPad, 8),
                decoration: BoxDecoration(
                  color: c.background,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(recipe.title, style: context.serif(30, height: 1.12)),
                    const SizedBox(height: 10),
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
                        MetaPill(
                          icon: Icons.restaurant_menu_rounded,
                          label: recipe.difficulty.label,
                        ),
                        RatingLabel(
                          rating: recipe.rating,
                          count: recipe.ratingCount,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${recipe.cuisine} · ${recipe.blurb}',
                      style: context.ui(
                        14.5,
                        color: c.inkSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _MatchStrip(
                      total: recipe.ingredients.length,
                      matched: matched,
                      missing: missing,
                      recipeTitle: recipe.title,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Servings',
                            style: context.ui(15.5, weight: FontWeight.w700),
                          ),
                        ),
                        RoundIconButton(
                          icon: Icons.remove_rounded,
                          size: 48,
                          onTap: _servings > 1
                              ? () {
                                  Haptics.selection();
                                  setState(() => _servings--);
                                }
                              : null,
                          tooltip: 'Fewer servings',
                        ),
                        SizedBox(
                          width: 52,
                          child: Text(
                            '$_servings',
                            textAlign: TextAlign.center,
                            style: context.serif(22),
                          ),
                        ),
                        RoundIconButton(
                          icon: Icons.add_rounded,
                          size: 48,
                          onTap: _servings < 12
                              ? () {
                                  Haptics.selection();
                                  setState(() => _servings++);
                                }
                              : null,
                          tooltip: 'More servings',
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Divider(height: 32),
                    Text('You will need', style: context.serif(22)),
                    const SizedBox(height: 12),
                    for (final ingredient in recipe.ingredients)
                      _IngredientRow(
                        ingredient: ingredient,
                        servings: _servings,
                        baseServings: recipe.servings,
                        available: pantryNames.contains(
                          ingredient.name.toLowerCase(),
                        ),
                        onAdd: () {
                          Haptics.light();
                          ref.read(shoppingProvider.notifier).addMissing([
                            ingredient.name,
                          ], source: recipe.title);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${ingredient.name} added to groceries',
                              ),
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: Text('Method', style: context.serif(22)),
                        ),
                        MetaPill(
                          icon: Icons.format_list_numbered_rounded,
                          label: '${recipe.steps.length} steps',
                          tone: Tone.olive,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (_heroReady)
                      for (var i = 0; i < recipe.steps.length; i++)
                        _StepRow(step: recipe.steps[i], index: i)
                    else
                      const _InstructionsSkeleton(),
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: c.surfaceAlt,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.lightbulb_outline_rounded,
                                size: 18,
                                color: c.olive,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Chef note',
                                style: context.ui(
                                  13,
                                  weight: FontWeight.w700,
                                  color: c.olive,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            recipe.chefNote,
                            style: context.ui(
                              14.5,
                              color: c.inkSecondary,
                              height: 1.55,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (recipe.heritage != null) ...[
                      _HeritageCard(heritage: recipe.heritage!),
                      const SizedBox(height: 32),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: EdgeInsets.fromLTRB(context.hPad, 14, context.hPad, 14),
          decoration: BoxDecoration(
            color: c.surface,
            border: Border(top: BorderSide(color: c.hairline)),
            boxShadow: [
              BoxShadow(
                color: c.shadow,
                blurRadius: 20,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: Row(
            children: [
              BookmarkButton(
                recipeId: recipe.id,
                size: 54,
                iconSize: 24,
                background: c.background,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: PrimaryButton(
                  label: 'Start cooking',
                  icon: Icons.soup_kitchen_rounded,
                  onTap: () {
                    Haptics.medium();
                    RouteGuard.push(context, '/cook/${recipe.id}');
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _share(Recipe recipe) {
    Haptics.light();
    SharePlus.instance.share(
      ShareParams(
        text:
            '${recipe.title} · ${recipe.minutes} min · ${recipe.calories} kcal\n'
            '${recipe.blurb}\n\nShared from PocketChef',
      ),
    );
  }
}

class _MatchStrip extends ConsumerWidget {
  const _MatchStrip({
    required this.total,
    required this.matched,
    required this.missing,
    required this.recipeTitle,
  });

  final int total;
  final List<String> matched;
  final List<String> missing;
  final String recipeTitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final complete = missing.isEmpty;
    final bg = complete ? c.oliveSoft : c.primary.withValues(alpha: 0.12);
    final fg = complete ? c.olive : c.primaryDeep;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(
            complete ? Icons.check_circle_rounded : Icons.shopping_cart_rounded,
            size: 20,
            color: fg,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              complete
                  ? 'You have all $total ingredients'
                  : 'You have ${matched.length} of $total — ${missing.length} to shop',
              style: context.ui(14.5, weight: FontWeight.w600, color: fg),
            ),
          ),
          if (!complete)
            BusyButton(
              label: 'Add ${missing.length}',
              onPressed: () async {
                ref
                    .read(shoppingProvider.notifier)
                    .addMissing(missing, source: recipeTitle);
              },
            ),
        ],
      ),
    );
  }
}

class _IngredientRow extends StatelessWidget {
  const _IngredientRow({
    required this.ingredient,
    required this.servings,
    required this.baseServings,
    required this.available,
    required this.onAdd,
  });

  final RecipeIngredient ingredient;
  final int servings;
  final int baseServings;
  final bool available;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final quantity = ingredient.scaledQuantity(servings, baseServings);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            child: Text(
              quantity.isEmpty ? '—' : quantity,
              style: context.ui(14, weight: FontWeight.w700, color: c.olive),
            ),
          ),
          Expanded(
            child: Text(ingredient.name, style: context.ui(15.5, height: 1.3)),
          ),
          if (available)
            Icon(Icons.check_circle_rounded, size: 20, color: c.olive)
          else
            InkWell(
              onTap: onAdd,
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 44,
                height: 44,
                child: Icon(
                  Icons.add_shopping_cart_rounded,
                  size: 19,
                  color: c.inkTertiary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.step, required this.index});

  final RecipeStep step;
  final int index;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: c.oliveSoft,
              shape: BoxShape.circle,
            ),
            child: Text(
              '${index + 1}',
              style: context.ui(13.5, weight: FontWeight.w800, color: c.olive),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(step.text, style: context.ui(15.5, height: 1.55)),
                if (step.minutes != null) ...[
                  const SizedBox(height: 8),
                  MetaPill(
                    icon: Icons.timer_outlined,
                    label: '${step.minutes} min',
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeritageCard extends StatelessWidget {
  const _HeritageCard({required this.heritage});

  final NigerianHeritage heritage;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: c.oliveSoft.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: c.olive.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flag_outlined, size: 17, color: c.olive),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'THE STORY BEHIND YOUR MEAL',
                  style: context.ui(
                    12,
                    weight: FontWeight.w700,
                    color: c.olive,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              MetaPill(
                icon: Icons.location_on_outlined,
                label: heritage.region,
                tone: Tone.olive,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            heritage.origin,
            style: context.serif(19, height: 1.35),
          ),
          const SizedBox(height: 14),
          _HeritageBlock(
            icon: Icons.favorite_outline_rounded,
            label: 'Why it matters',
            text: heritage.significance,
          ),
          _HeritageBlock(
            icon: Icons.history_edu_rounded,
            label: 'How it came to be',
            text: heritage.history,
          ),
          if (heritage.occasions.isNotEmpty) ...[
            const SizedBox(height: 14),
            _HeritageTags(
              icon: Icons.event_rounded,
              label: 'Reserved for',
              tags: heritage.occasions,
            ),
          ],
          if (heritage.pairings.isNotEmpty) ...[
            const SizedBox(height: 14),
            _HeritageTags(
              icon: Icons.restaurant_rounded,
              label: 'Sits well with',
              tags: heritage.pairings,
            ),
          ],
          if (heritage.drinks.isNotEmpty) ...[
            const SizedBox(height: 14),
            _HeritageTags(
              icon: Icons.local_cafe_rounded,
              label: 'Poured alongside',
              tags: heritage.drinks,
            ),
          ],
        ],
      ),
    );
  }
}

class _HeritageBlock extends StatelessWidget {
  const _HeritageBlock({
    required this.icon,
    required this.label,
    required this.text,
  });

  final IconData icon;
  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: c.olive),
              const SizedBox(width: 7),
              Text(
                label,
                style: context.ui(
                  13,
                  weight: FontWeight.w800,
                  color: c.olive,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            text,
            style: context.ui(14.5, color: c.inkSecondary, height: 1.55),
          ),
        ],
      ),
    );
  }
}

class _HeritageTags extends StatelessWidget {
  const _HeritageTags({
    required this.icon,
    required this.label,
    required this.tags,
  });

  final IconData icon;
  final String label;
  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: c.olive),
            const SizedBox(width: 7),
            Text(
              label,
              style: context.ui(
                13,
                weight: FontWeight.w800,
                color: c.olive,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final tag in tags)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: c.hairline),
                ),
                child: Text(
                  tag,
                  style: context.ui(13, weight: FontWeight.w600),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _InstructionsSkeleton extends StatelessWidget {
  const _InstructionsSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShimmerBox(height: 58, radius: 18),
        SizedBox(height: 12),
        ShimmerBox(height: 58, radius: 18),
        SizedBox(height: 12),
        ShimmerBox(height: 58, radius: 18),
      ],
    );
  }
}
