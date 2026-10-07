import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/theme_extensions.dart';
import '../../core/utils/haptics.dart';
import '../../core/widgets/recipe_image.dart';
import '../../core/widgets/chips.dart';
import '../../core/widgets/misc.dart';
import '../../data/services/ai_service.dart';
import '../../state/domain_providers.dart';
import '../recipes/widgets/recipe_widgets.dart';

const kNigerianRegions = ['National', 'South-West', 'South-East', 'South-South', 'North'];

const _ingredientQuickPick = [
  'Yam',
  'Plantain',
  'Beans',
  'Palm oil',
  'Egusi',
  'Pepper',
  'Tomatoes',
  'Onion',
  'Fish',
  'Chicken',
];

const _regionNotes = <String, String>{
  'National':
      'Found everywhere — from village wakes to city catch-alls. These are the '
          'dishes every Nigerian kitchen claims as its own.',
  'South-West':
      'Yoruba heartland. Owambe weekends are built on smoky jollof, asaro, '
          'akara and efo — big flavour, bigger spirits.',
  'South-East':
      'Igbo home cooking: rich seed-and-leaf soups like egusi, oha and '
          'bitterleaf, served with pounded yam or garri.',
  'South-South':
      'Delta creeks, palm forests and coastal bounty. Banga, afang and '
          'vegetable soups carry the flavours of the rivers.',
  'North':
      'Hausa and Fulani street smoke — suya on the grill and pepper-soup '
          'warmth echoing from Kano to Kaduna.',
};

class NigerianScreen extends ConsumerStatefulWidget {
  const NigerianScreen({super.key, this.initialRegion});

  final String? initialRegion;

  @override
  ConsumerState<NigerianScreen> createState() => _NigerianScreenState();
}

class _NigerianScreenState extends ConsumerState<NigerianScreen> {
  late String? _region;
  final Set<String> _selected = {};
  Future<List<RecipeMatch>>? _matchFuture;

  @override
  void initState() {
    super.initState();
    _region = widget.initialRegion != null &&
            kNigerianRegions.contains(widget.initialRegion)
        ? widget.initialRegion
        : null;
  }

  void _toggleIngredient(String name) {
    setState(() {
      if (_selected.contains(name)) {
        _selected.remove(name);
      } else {
        _selected.add(name);
      }
      _matchFuture = _selected.isEmpty
          ? null
          : ref
              .read(aiServiceProvider)
              .suggestNigerian(ingredients: _selected.toList());
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final allNigerian = ref
        .watch(recipeRepositoryProvider)
        .all()
        .where((r) => r.isNigerian)
        .toList(growable: false);
    final countByRegion = <String, int>{};
    for (final recipe in allNigerian) {
      final region = recipe.heritage?.region;
      if (region == null) continue;
      countByRegion[region] = (countByRegion[region] ?? 0) + 1;
    }
    final visibleRegions = _region == null
        ? kNigerianRegions
        : [if (countByRegion.containsKey(_region)) _region!];

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(context.hPad, 6, context.hPad, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      'Nigerian Kitchen',
                      style: context.serif(22),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(context.hPad, 8, context.hPad, 0),
                child: _NigerianHeaderHero(
                  count: allNigerian.length,
                  imageUrl: allNigerian.isNotEmpty
                      ? allNigerian.first.imageUrl
                      : null,
                  artSeed: allNigerian.isNotEmpty
                      ? allNigerian.first.artSeed
                      : null,
                  onMatch: () {
                    Haptics.light();
                    if (_selected.length < 2) return;
                    setState(() {
                      _matchFuture = ref
                          .read(aiServiceProvider)
                          .suggestNigerian(
                            ingredients: _selected.toList(),
                          );
                    });
                  },
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 62,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.fromLTRB(context.hPad, 14, context.hPad, 0),
                  itemCount: kNigerianRegions.length + 1,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return AppChip(
                        label: 'All regions',
                        selected: _region == null,
                        onTap: () => setState(() => _region = null),
                      );
                    }
                    final region = kNigerianRegions[index - 1];
                    return AppChip(
                      label: region,
                      selected: _region == region,
                      onTap: () => setState(() => _region = region),
                    );
                  },
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _FoodMatchCard(
                selected: _selected,
                onToggle: _toggleIngredient,
                future: _matchFuture,
              ),
            ),
            for (final region in visibleRegions) ...[
              SliverToBoxAdapter(
                child: SectionHeader(
                  title: region,
                  subtitle: '${countByRegion[region] ?? 0} dishes',
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    context.hPad,
                    0,
                    context.hPad,
                    4,
                  ),
                  child: _RegionNote(text: _regionNotes[region] ?? ''),
                ),
              ),
              SliverList.separated(
                itemCount: countByRegion[region] ?? 0,
                separatorBuilder: (_, _) => const SizedBox(height: 4),
                itemBuilder: (context, index) {
                  final recipes = allNigerian
                      .where((r) => r.heritage?.region == region)
                      .toList(growable: false)
                    ..sort(
                      (a, b) => b.ratingCount.compareTo(a.ratingCount),
                    );
                  return RecipeRow(recipe: recipes[index]);
                },
              ),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }
}

class _NigerianHeaderHero extends StatelessWidget {
  const _NigerianHeaderHero({
    required this.count,
    required this.onMatch,
    required this.imageUrl,
    this.artSeed,
  });

  final int count;
  final VoidCallback onMatch;
  final String? imageUrl;
  final String? artSeed;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Stack(
        children: [
          SizedBox(
            height: 176,
            width: double.infinity,
            child: RecipeImage(imageUrl: imageUrl, borderRadius: 0, artSeed: artSeed),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF0F0C08).withValues(alpha: 0.88),
                    const Color(0xFF2A2318).withValues(alpha: 0.55),
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.egg_alt_rounded, size: 15, color: const Color(0xFFFFB47A)),
                      const SizedBox(width: 6),
                      Text(
                        '$count DISHES · STORIES · REGIONS',
                        style: context.ui(
                          11,
                          weight: FontWeight.w700,
                          color: const Color(0xFFFFB47A),
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    'Nigeria on\na plate',
                    style: context.serif(28, color: const Color(0xFFFFFBF4), height: 1.12),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Classic recipes, teaching you where they come from and '
                    'why they matter.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.ui(13.5, color: const Color(0xFFFFF3E6).withValues(alpha: 0.82)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FoodMatchCard extends StatelessWidget {
  const _FoodMatchCard({
    required this.selected,
    required this.onToggle,
    required this.future,
  });

  final Set<String> selected;
  final ValueChanged<String> onToggle;
  final Future<List<RecipeMatch>>? future;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: EdgeInsets.fromLTRB(context.hPad, 16, context.hPad, 0),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: c.hairline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome_rounded, size: 20, color: c.olive),
                const SizedBox(width: 8),
                Text(
                  'AI food matching',
                  style: context.ui(16.5, weight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              'Tap what is in your kitchen — PocketChef picks the Nigerian '
              'dishes you can cook tonight.',
              style: context.ui(13.5, color: c.inkSecondary, height: 1.4),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 0,
              children: [
                for (final ingredient in _ingredientQuickPick)
                  AppChip(
                    label: ingredient,
                    color: c.olive,
                    selected: selected.contains(ingredient),
                    onTap: () => onToggle(ingredient),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<RecipeMatch>>(
              future: future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting ||
                    (snapshot.connectionState == ConnectionState.none &&
                        future != null)) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: LinearProgressIndicator(minHeight: 3),
                  );
                }
                if (snapshot.hasError) {
                  return Text(
                    'Could not match ingredients. Try again.',
                    style: context.ui(13, color: c.primaryDeep),
                  );
                }
                final results = snapshot.data ?? const [];
                if (results.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cook with what you have',
                        style: context.ui(13.5, weight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      for (final match in results.take(5)) ...[
                        RecipeRow(
                          recipe: match.recipe,
                          subtitle: match.matched.take(3).join(', ') +
                              (match.matched.length > 3
                                  ? ' +${match.matched.length - 3} more'
                                  : ''),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _RegionNote extends StatelessWidget {
  const _RegionNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.oliveSoft.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.location_on_outlined, size: 18, color: c.olive),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: context.ui(13.5, color: c.inkSecondary, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}