import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/theme_extensions.dart';
import '../../core/utils/haptics.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/chips.dart';
import '../../core/widgets/state_views.dart';
import '../../data/models/user.dart';
import '../../state/domain_providers.dart';
import '../recipes/widgets/recipe_widgets.dart';

class SavedScreen extends ConsumerStatefulWidget {
  const SavedScreen({super.key});

  @override
  ConsumerState<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends ConsumerState<SavedScreen> {
  String _collectionId = '';

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final favorites = ref.watch(favoritesProvider);
    final repo = ref.watch(recipeRepositoryProvider);
    final all = repo.byIds(favorites.recipeIds);
    final selected = _collectionId.isEmpty
        ? all
        : favorites.collections
              .where((col) => col.id == _collectionId)
              .expand((col) => repo.byIds(col.recipeIds))
              .toList(growable: false);
    final recipes = _collectionId.isEmpty
        ? all
        : selected.where(all.contains).toList(growable: false);

    return Scaffold(
      backgroundColor: c.background,
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
              leading: RoundIconButton(
                icon: Icons.arrow_back_rounded,
                background: c.surface,
                onTap: () {
                  Haptics.light();
                  if (context.canPop()) context.pop();
                },
                tooltip: 'Back',
              ),
              leadingWidth: 60,
              title: Text('Saved', style: context.serif(26)),
              actions: [
                if (all.isNotEmpty)
                  RoundIconButton(
                    icon: Icons.ios_share_rounded,
                    onTap: () => _share(all.map((r) => r.title).toList()),
                    tooltip: 'Share saved recipes',
                  ),
                const SizedBox(width: 12),
              ],
            ),
            if (all.isEmpty)
              SliverToBoxAdapter(
                child: EmptyStateView(
                  icon: Icons.favorite_outline_rounded,
                  title: 'Nothing saved yet',
                  message: 'Tap the heart on any recipe and your shortlist shows up here, ready to share.',
                  actionLabel: 'Browse recipes',
                  onAction: () {
                    Haptics.light();
                    context.go('/recipes');
                  },
                ),
              )
            else ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    context.hPad,
                    8,
                    context.hPad,
                    6,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${all.length} saved ${all.length == 1 ? 'recipe' : 'recipes'}',
                        style: context.ui(13.5, color: c.inkSecondary),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 48,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: AppChip(
                                label: 'All',
                                selected: _collectionId.isEmpty,
                                onTap: () {
                                  Haptics.selection();
                                  setState(() => _collectionId = '');
                                },
                              ),
                            ),
                            for (final collection in favorites.collections)
                              Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: AppChip(
                                  label: collection.name,
                                  selected: _collectionId == collection.id,
                                  onDelete: _collectionId == collection.id
                                      ? () => _deleteCollection(collection.id)
                                      : null,
                                  trailing: Text(
                                    '${collection.recipeIds.length}',
                                    style: context.ui(
                                      12.5,
                                      weight: FontWeight.w700,
                                      color: _collectionId == collection.id
                                          ? c.onPrimary
                                          : c.inkTertiary,
                                    ),
                                  ),
                                  onTap: () {
                                    Haptics.selection();
                                    setState(
                                      () => _collectionId =
                                          _collectionId == collection.id
                                          ? ''
                                          : collection.id,
                                    );
                                  },
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: AppChip(
                                label: 'New collection',
                                icon: Icons.add_rounded,
                                onTap: _createCollection,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (recipes.isEmpty)
                const SliverToBoxAdapter(
                  child: EmptyStateView(
                    icon: Icons.folder_open_rounded,
                    title: 'Collection is empty',
                    message: 'Use the menu on any saved recipe to move it into this collection.',
                    compact: true,
                  ),
                )
              else if (context.isTablet)
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    context.hPad - 6,
                    8,
                    context.hPad - 6,
                    32,
                  ),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 20,
                          crossAxisSpacing: 14,
                          childAspectRatio: 0.78,
                        ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) =>
                          _SavedTile(recipeId: recipes[index].id),
                      childCount: recipes.length,
                    ),
                  ),
                )
              else
                SliverList.separated(
                  itemCount: recipes.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 6),
                  itemBuilder: (context, index) => _SavedTile(
                    recipeId: recipes[index].id,
                    collections: favorites.collections,
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _createCollection() async {
    Haptics.light();
    final name = await showDialog<String>(
      context: context,
      builder: (_) => const _NewCollectionDialog(),
    );
    final trimmed = name?.trim() ?? '';
    if (trimmed.isEmpty) return;
    ref.read(favoritesProvider.notifier).createCollection(trimmed);
  }

  void _deleteCollection(String id) {
    Haptics.light();
    ref.read(favoritesProvider.notifier).deleteCollection(id);
    if (_collectionId == id) setState(() => _collectionId = '');
  }

  void _share(List<String> titles) {
    Haptics.light();
    SharePlus.instance.share(
      ShareParams(
        text:
            'My PocketChef shortlist\n${titles.map((t) => '• $t').join('\n')}',
      ),
    );
  }
}

class _NewCollectionDialog extends StatefulWidget {
  const _NewCollectionDialog();

  @override
  State<_NewCollectionDialog> createState() => _NewCollectionDialogState();
}

class _NewCollectionDialogState extends State<_NewCollectionDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(26),
      ),
      title: Text('New collection', style: context.serif(22)),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(hintText: 'Weeknight dinners…'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            Haptics.light();
            Navigator.of(context).pop(_controller.text);
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}

class _SavedTile extends ConsumerWidget {
  const _SavedTile({required this.recipeId, this.collections});

  final String recipeId;
  final List<RecipeCollection>? collections;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final repo = ref.watch(recipeRepositoryProvider);
    final recipe = repo.byId(recipeId);
    if (recipe == null) return const SizedBox.shrink();

    return Stack(
      children: [
        RecipeRow(recipe: recipe),
        if (collections != null && collections!.isNotEmpty)
          Positioned(
            right: 72,
            top: 14,
            child: Semantics(
              button: true,
              label: 'Organize ${recipe.title}',
              child: InkWell(
                onTap: () {
                  Haptics.light();
                  _showCollectionSheet(context, recipe.id);
                },
                borderRadius: BorderRadius.circular(22),
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(
                    Icons.more_horiz_rounded,
                    size: 22,
                    color: c.inkTertiary,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _showCollectionSheet(BuildContext context, String recipeId) {
    Haptics.light();
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => Consumer(
        builder: (ctx, sheetRef, _) {
          final c = sheetContext.c;
          final notifier = sheetRef.read(favoritesProvider.notifier);
          final collections = sheetRef.watch(favoritesProvider).collections;
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Collections', style: sheetContext.serif(22)),
                  const SizedBox(height: 6),
                  Text(
                    'Choose where this recipe lives.',
                    style: sheetContext.ui(14, color: c.inkSecondary),
                  ),
                  const SizedBox(height: 16),
                  for (final collection in collections)
                    InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        Haptics.light();
                        notifier.toggleInCollection(collection.id, recipeId);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Icon(
                              collection.recipeIds.contains(recipeId)
                                  ? Icons.check_circle_rounded
                                  : Icons.circle_outlined,
                              size: 22,
                              color: collection.recipeIds.contains(recipeId)
                                  ? c.olive
                                  : c.inkTertiary,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                collection.name,
                                style: sheetContext.ui(16),
                              ),
                            ),
                            Text(
                              '${collection.recipeIds.length}',
                              style: sheetContext.ui(
                                13.5,
                                color: c.inkTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
