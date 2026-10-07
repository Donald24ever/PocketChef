import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/theme_extensions.dart';
import '../../core/utils/haptics.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/chips.dart';
import '../../core/widgets/misc.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/state_views.dart';
import '../../data/models/recipe.dart';
import '../../state/domain_providers.dart';
import 'widgets/recipe_widgets.dart';

class RecipesScreen extends ConsumerStatefulWidget {
  const RecipesScreen({super.key, required this.source});

  final String source;

  @override
  ConsumerState<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends ConsumerState<RecipesScreen> {
  final Set<String> _filters = <String>{};

  static const Map<String, String> _filterLabels = {
    'quick': 'Under 25 min',
    'vegetarian': 'Vegetarian',
    'highProtein': 'High protein',
    'breakfast': 'Breakfast',
    'lunch': 'Lunch',
    'dinner': 'Dinner',
    'glutenFree': 'Gluten-free',
    'nigerian': 'Nigerian',
  };

  @override
  void initState() {
    super.initState();
    if (widget.source == 'quick') _filters.add('quick');
  }

  bool _matches(Recipe recipe) {
    for (final filter in _filters) {
      final ok = switch (filter) {
        'quick' => recipe.minutes <= 25,
        'vegetarian' => recipe.diets.contains(DietTag.vegetarian),
        'highProtein' => recipe.diets.contains(DietTag.highProtein),
        'glutenFree' => recipe.diets.contains(DietTag.glutenFree),
        'nigerian' => recipe.isNigerian,
        'breakfast' => recipe.meals.contains(MealType.breakfast),
        'lunch' => recipe.meals.contains(MealType.lunch),
        'dinner' => recipe.meals.contains(MealType.dinner),
        _ => true,
      };
      if (!ok) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final repo = ref.watch(recipeRepositoryProvider);
    final filtered = repo.all().where(_matches).toList(growable: false);
    final fromScan = widget.source == 'scan';

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: c.background,
              surfaceTintColor: Colors.transparent,
              foregroundColor: c.ink,
              elevation: 0,
              scrolledUnderElevation: 0,
              title: Text('Recipes', style: context.serif(26)),
              actions: [
                RoundIconButton(
                  icon: Icons.search_rounded,
                  onTap: () {
                    Haptics.light();
                    context.push('/search');
                  },
                  tooltip: 'Search recipes',
                ),
                const SizedBox(width: 8),
                RoundIconButton(
                  icon: Icons.bookmark_outline_rounded,
                  onTap: () {
                    Haptics.light();
                    context.push('/saved');
                  },
                  tooltip: 'Saved recipes',
                ),
                const SizedBox(width: 12),
              ],
            ),
            if (fromScan) ..._buildScanSection(),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(context.hPad, 6, context.hPad, 12),
                child: SizedBox(
                  height: 48,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final entry in _filterLabels.entries)
                        Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: AppChip(
                            label: entry.value,
                            selected: _filters.contains(entry.key),
                            onTap: () {
                              setState(() {
                                if (!_filters.remove(entry.key)) {
                                  _filters.add(entry.key);
                                }
                              });
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            if (filtered.isEmpty)
              SliverToBoxAdapter(
                child: EmptyStateView(
                  icon: Icons.tune_rounded,
                  title: 'No recipes match',
                  message: 'Your filters are a little too clever for the current menu. Loosen one and try again.',
                  actionLabel: 'Clear filters',
                  onAction: () {
                    Haptics.light();
                    setState(_filters.clear);
                  },
                ),
              )
            else if (context.isTablet)
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  context.hPad - 6,
                  4,
                  context.hPad - 6,
                  28,
                ),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 20,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.78,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => RecipeTile(recipe: filtered[index]),
                    childCount: filtered.length,
                  ),
                ),
              )
            else ...[
              SliverToBoxAdapter(
                child: SectionHeader(
                  title: fromScan ? 'More to explore' : 'All ideas',
                  subtitle: fromScan
                      ? 'Recipes outside your scan results'
                      : '${filtered.length} recipes to cook',
                ),
              ),
              SliverList.separated(
                itemCount: filtered.length,
                separatorBuilder: (_, _) => const SizedBox(height: 6),
                itemBuilder: (context, index) => RecipeRow(
                  recipe: filtered[index],
                  subtitle: index == 0 && !fromScan
                      ? filtered[index].blurb
                      : null,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _buildScanSection() {
    final c = context.c;
    final suggestions = ref.watch(scanSuggestionsProvider);

    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.fromLTRB(context.hPad, 8, context.hPad, 4),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: c.featureSurface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(Icons.auto_awesome_rounded, color: c.primary, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: suggestions.when(
                    data: (suggestion) => Text(
                      'Made from your ${suggestion.ingredientCount} scanned ingredients',
                      style: context.ui(
                        14,
                        weight: FontWeight.w600,
                        color: c.onFeatureSurface,
                      ),
                    ),
                    loading: () => Text(
                      'Matching recipes to your scan…',
                      style: context.ui(
                        14,
                        weight: FontWeight.w600,
                        color: c.onFeatureSurface,
                      ),
                    ),
                    error: (_, _) => Text(
                      'Scan match-up failed',
                      style: context.ui(
                        14,
                        weight: FontWeight.w600,
                        color: c.onFeatureSurface,
                      ),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Haptics.light();
                    context.push('/scan/review');
                  },
                  child: Text(
                    'Edit',
                    style: context.ui(
                      14,
                      weight: FontWeight.w700,
                      color: c.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      suggestions.when(
        loading: () => const SliverToBoxAdapter(
          child: Column(
            children: [
              RecipeRowSkeleton(),
              RecipeRowSkeleton(),
              RecipeRowSkeleton(),
            ],
          ),
        ),
        error: (error, _) => SliverToBoxAdapter(
          child: ErrorStateView(
            title: 'Could not match recipes',
            message: 'We lost the connection while matching your scan.',
            onRetry: () => ref.invalidate(scanSuggestionsProvider),
          ),
        ),
        data: (suggestion) {
          if (suggestion.matches.isEmpty) {
            return const SliverToBoxAdapter(
              child: EmptyStateView(
                icon: Icons.restaurant_menu_rounded,
                title: 'No direct matches',
                message: 'Nothing in the current menu uses your scan. Add more photos or explore everything below.',
                compact: true,
              ),
            );
          }
          return SliverList.separated(
            itemCount: suggestion.matches.length,
            separatorBuilder: (_, _) => const SizedBox(height: 6),
            itemBuilder: (context, index) {
              final match = suggestion.matches[index];
              return RecipeRow(recipe: match.recipe, subtitle: match.reason);
            },
          );
        },
      ),
    ];
  }
}
