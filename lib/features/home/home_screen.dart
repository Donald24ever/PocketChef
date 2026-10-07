import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/theme_extensions.dart';
import '../../core/utils/haptics.dart';
import '../../core/widgets/artwork.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/chips.dart';
import '../../core/widgets/misc.dart';
import '../../core/widgets/recipe_image.dart';
import '../../data/models/recipe.dart';
import '../../data/models/user.dart';
import '../../state/app_state_provider.dart';
import '../../state/domain_providers.dart';
import '../recipes/widgets/recipe_widgets.dart';
import 'home_collections.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final profile =
        ref.watch(appStateProvider).value?.profile ?? UserProfile.guest;
    final pantry = ref.watch(pantryProvider);
    final pantryNames = pantry.map((e) => e.name.toLowerCase()).toSet();
    final savedCount = ref.watch(
      favoritesProvider.select((s) => s.recipeIds.length),
    );

    final repo = ref.watch(recipeRepositoryProvider);
    final all = repo.all();
    final shelves = buildHomeCollections(recipes: all, pantry: pantryNames);
    final firstName = profile.name.trim().split(' ').first;

    final allNigerian = all.where((r) => r.isNigerian).toList(growable: false);
    final regionCounts = <String, int>{};
    for (final recipe in allNigerian) {
      final region = recipe.heritage?.region;
      if (region == null) continue;
      regionCounts[region] = (regionCounts[region] ?? 0) + 1;
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(context.hPad, 14, context.hPad, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '$_greeting, $firstName',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.ui(
                              13.5,
                              weight: FontWeight.w600,
                              color: c.inkSecondary,
                            ),
                          ),
                        ),
                        RoundIconButton(
                          icon: Icons.bookmark_outline_rounded,
                          onTap: () {
                            Haptics.light();
                            context.push('/saved');
                          },
                          badge: savedCount > 0 ? 1 : null,
                          tooltip: 'Saved recipes',
                        ),
                        const SizedBox(width: 10),
                        _ProfileAvatar(profile: profile),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'What’s in your kitchen today?',
                      style: context.serif(27, height: 1.16),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      'Scan your available ingredients and let PocketChef find meals you can cook.',
                      style: context.ui(
                        14,
                        color: c.inkSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(context.hPad, 16, context.hPad, 4),
                child: _ScanHeroCard(
                  onScan: () {
                    Haptics.medium();
                    context.push('/scan');
                  },
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(context.hPad, 14, context.hPad, 0),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 3,
                        child: _QuickTile(
                          dark: true,
                          icon: Icons.bolt_rounded,
                          title: 'Dinner in 20',
                          caption: 'Fast recipes only',
                          onTap: () {
                            Haptics.light();
                            context.go('/recipes?source=quick');
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: _QuickTile(
                          dark: false,
                          icon: Icons.calendar_month_rounded,
                          title: 'Plan week',
                          caption: 'Meals & groceries',
                          onTap: () {
                            Haptics.light();
                            context.go('/plan');
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (pantry.isEmpty)
              const SliverToBoxAdapter(child: _PantryEmptyHint())
            else
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(context.hPad, 22, 0, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'FROM YOUR SCANS',
                        style: context.ui(
                          11.5,
                          weight: FontWeight.w700,
                          color: c.inkTertiary,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 48,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: pantry.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 10),
                          itemBuilder: (context, index) {
                            final item = pantry[index];
                            return AppChip(
                              label: item.name,
                              onTap: () {
                                Haptics.light();
                                context.push(
                                  '/search?q=${Uri.encodeComponent(item.name)}',
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: SectionHeader(
                title: 'Tonight’s shortlist',
                subtitle: 'Sorted by what you already have',
                actionLabel: 'See all',
                onAction: () => context.go('/recipes'),
              ),
            ),
            if (shelves.shortlist.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: FeatureRecipeCard(
                  recipe: shelves.shortlist.first,
                  eyebrow: 'BEST MATCH FOR YOUR KITCHEN',
                ),
              ),
              SliverList.separated(
                itemCount: shelves.shortlist.length - 1,
                separatorBuilder: (_, _) => const SizedBox(height: 4),
                itemBuilder: (context, index) =>
                    RecipeRow(recipe: shelves.shortlist[index + 1]),
              ),
            ],
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(context.hPad, 24, context.hPad, 0),
                child: _PlanBanner(
                  onTap: () {
                    Haptics.light();
                    context.go('/plan');
                  },
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 4)),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(context.hPad, 20, context.hPad, 0),
                child: _NigerianHero(
                  onTap: () {
                    Haptics.light();
                    context.push('/nigerian');
                  },
                  imageUrl: shelves.popularNigerian.isNotEmpty
                      ? shelves.popularNigerian.first.imageUrl
                      : null,
                  artSeed: shelves.popularNigerian.isNotEmpty
                      ? shelves.popularNigerian.first.artSeed
                      : null,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _RecipeShelf(
                title: 'Popular Nigerian meals',
                subtitle: 'The dishes Nigerians argue over — lovingly',
                recipes: shelves.popularNigerian,
                onAction: () {
                  Haptics.light();
                  context.push('/nigerian');
                },
              ),
            ),
            SliverToBoxAdapter(
              child: _RecipeShelf(
                title: 'Quick Nigerian dishes',
                subtitle: 'Under 45 minutes, maximum flavour',
                recipes: shelves.quickNigerian,
                onAction: () {
                  Haptics.light();
                  context.push('/nigerian');
                },
              ),
            ),
            SliverToBoxAdapter(
              child: _RecipeShelf(
                title: 'Healthy Nigerian recipes',
                subtitle: 'Lighter bowls, the same soul',
                recipes: shelves.healthyNigerian,
                onAction: () {
                  Haptics.light();
                  context.push('/nigerian');
                },
              ),
            ),
            SliverToBoxAdapter(
              child: _RegionShelf(
                regions: const [
                  'National',
                  'South-West',
                  'South-East',
                  'South-South',
                  'North',
                ],
                counts: regionCounts,
                onSelect: (region) {
                  Haptics.light();
                  context.push(
                    '/nigerian?region=${Uri.encodeComponent(region)}',
                  );
                },
              ),
            ),
            SliverToBoxAdapter(
              child: SectionHeader(
                title: 'Weekend family meals',
                subtitle: 'Big pots for big tables',
                actionLabel: 'See all',
                onAction: () {
                  Haptics.light();
                  context.push('/nigerian');
                },
              ),
            ),
            if (shelves.weekend.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: FeatureRecipeCard(
                  recipe: shelves.weekend.first,
                  eyebrow: 'WEEKEND FAMILY MEAL',
                ),
              ),
              if (shelves.weekend.length > 1)
                SliverList.separated(
                  itemCount: shelves.weekend.length - 1,
                  separatorBuilder: (_, _) => const SizedBox(height: 4),
                  itemBuilder: (context, index) =>
                      RecipeRow(recipe: shelves.weekend[index + 1]),
                ),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }
}

class _ScanHeroCard extends StatelessWidget {
  const _ScanHeroCard({required this.onScan});

  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onScan,
      child: SizedBox(
        height: 104,
        width: double.infinity,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              const DishArtwork(seed: 'kitchen-fridge-scan', radius: 24),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      const Color(0xFF1B1712).withValues(alpha: 0.9),
                      const Color(0xFF1B1712).withValues(alpha: 0.3),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 16, 14),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFFBF4),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        size: 22,
                        color: Color(0xFF26231E),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Scan ingredients',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.serif(
                              19,
                              color: const Color(0xFFFFFBF4),
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Point at your fridge and let PocketChef read it',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.ui(
                              12.5,
                              color: const Color(0xFFFFFBF4)
                                  .withValues(alpha: 0.72),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 20,
                      color: const Color(0xFFFFFBF4).withValues(alpha: 0.9),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final initials = Text(
      profile.initials,
      style: context.ui(15, weight: FontWeight.w700, color: c.olive),
    );
    return Semantics(
      button: true,
      label: 'Your profile',
      child: PressScale(
        onTap: () {
          Haptics.light();
          context.go('/profile');
        },
        child: Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(color: c.oliveSoft, shape: BoxShape.circle),
          child: profile.hasPhoto
              ? Image.network(
                  profile.photoUrl!,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => initials,
                )
              : initials,
        ),
      ),
    );
  }
}

class _QuickTile extends StatelessWidget {
  const _QuickTile({
    required this.dark,
    required this.icon,
    required this.title,
    required this.caption,
    required this.onTap,
  });

  final bool dark;
  final IconData icon;
  final String title;
  final String caption;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final bg = dark ? c.featureSurface : c.oliveSoft;
    final fg = dark ? c.onFeatureSurface : c.olive;
    final sub = dark ? c.onFeatureSurfaceMuted : c.olive.withValues(alpha: 0.8);
    return PressScale(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 104),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 22, color: fg),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.ui(16, weight: FontWeight.w700, color: fg),
                ),
                const SizedBox(height: 2),
                Text(
                  caption,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.ui(12.5, color: sub),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PantryEmptyHint extends StatelessWidget {
  const _PantryEmptyHint();

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: EdgeInsets.fromLTRB(context.hPad, 22, context.hPad, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: c.hairline),
        ),
        child: Row(
          children: [
            Icon(Icons.kitchen_outlined, size: 22, color: c.olive),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Nothing scanned yet — your pantry shows up here.',
                style: context.ui(13.5, color: c.inkSecondary),
              ),
            ),
            TextButton(
              onPressed: () {
                Haptics.light();
                context.push('/scan');
              },
              child: const Text('Scan now'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanBanner extends StatelessWidget {
  const _PlanBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return PressScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: c.hairline),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: c.primary.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                Icons.edit_calendar_rounded,
                color: c.primaryDeep,
                size: 23,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Plan your week',
                    style: context.ui(15.5, weight: FontWeight.w700),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Drop meals into days, shop from one list',
                    style: context.ui(13, color: c.inkSecondary),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: c.inkTertiary),
          ],
        ),
      ),
    );
  }
}

class _NigerianHero extends StatelessWidget {
  const _NigerianHero({
    required this.onTap,
    required this.imageUrl,
    this.artSeed,
  });

  final VoidCallback onTap;
  final String? imageUrl;
  final String? artSeed;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onTap,
      child: SizedBox(
        height: 200,
        width: double.infinity,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            fit: StackFit.expand,
            children: [
              RecipeImage(imageUrl: imageUrl, borderRadius: 0, artSeed: artSeed),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF2A2318).withValues(alpha: 0.9),
                      const Color(0xFF0F0C08).withValues(alpha: 0.74),
                    ],
                  ),
                ),
              ),
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.restaurant_rounded,
                            size: 14,
                            color: const Color(0xFFFFB47A),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'NIGERIAN KITCHEN',
                            style: context.ui(
                              11,
                              weight: FontWeight.w700,
                              color: const Color(0xFFFFB47A),
                              letterSpacing: 1.6,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        'From Lagos to\nKaduna',
                        style: context.serif(
                          26,
                          color: const Color(0xFFFFFBF4),
                          height: 1.12,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Regional classics, family stories and the dishes that built them',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.ui(
                          13.5,
                          color: const Color(0xFFFFF3E6).withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        height: 42,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBF4),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Explore Nigerian meals',
                              style: context.ui(
                                14,
                                weight: FontWeight.w700,
                                color: const Color(0xFF26231E),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 16,
                              color: const Color(0xFF26231E),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecipeShelf extends StatelessWidget {
  const _RecipeShelf({
    required this.title,
    required this.subtitle,
    required this.recipes,
    required this.onAction,
  });

  final String title;
  final String subtitle;
  final List<Recipe> recipes;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: title,
          subtitle: subtitle,
          actionLabel: 'See all',
          onAction: onAction,
        ),
        if (recipes.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: context.hPad),
            child: Text(
              'More dishes on the way',
              style: context.ui(13, color: c.inkTertiary),
            ),
          )
        else
          SizedBox(
            height: 216,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: context.hPad),
              itemCount: recipes.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final recipe = recipes[index];
                return SizedBox(
                  width: 176,
                  child: RecipeTile(
                    recipe: recipe,
                    subtitle: recipe.heritage?.region,
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _RegionShelf extends StatelessWidget {
  const _RegionShelf({
    required this.regions,
    required this.counts,
    required this.onSelect,
  });

  final List<String> regions;
  final Map<String, int> counts;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Regional dishes',
          subtitle: 'Pick a corner of Nigeria',
        ),
        SizedBox(
          height: 116,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: context.hPad),
            itemCount: regions.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final region = regions[index];
              return _RegionCard(
                label: region,
                count: counts[region] ?? 0,
                onTap: () => onSelect(region),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _RegionCard extends StatelessWidget {
  const _RegionCard({
    required this.label,
    required this.count,
    required this.onTap,
  });

  final String label;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return PressScale(
      onTap: onTap,
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.hairline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: c.oliveSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.location_on_outlined, size: 17, color: c.olive),
            ),
            const Spacer(),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.serif(16, height: 1.1),
            ),
            const SizedBox(height: 3),
            Text(
              '$count recipes',
              style: context.ui(12.5, color: c.inkSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
