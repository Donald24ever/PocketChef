import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/theme_extensions.dart';
import '../../core/utils/haptics.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/chips.dart';
import '../../core/widgets/state_views.dart';
import '../../core/widgets/text_fields.dart';
import '../../state/domain_providers.dart';
import 'widgets/recipe_widgets.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key, this.initialQuery = ''});

  final String initialQuery;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final TextEditingController _controller;
  late String _query;

  static const _suggestions = [
    'Eggs',
    'Pasta',
    'Chicken',
    'Spinach',
    'Rice',
    'Salmon',
    'Tomatoes',
  ];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
    _query = widget.initialQuery;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final results = _query.trim().isEmpty
        ? const []
        : ref
              .watch(recipeRepositoryProvider)
              .all()
              .where((r) {
                final q = _query.trim().toLowerCase();
                if (r.title.toLowerCase().contains(q)) return true;
                if (r.cuisine.toLowerCase().contains(q)) return true;
                if (r.blurb.toLowerCase().contains(q)) return true;
                return r.ingredients.any(
                  (i) => i.name.toLowerCase().contains(q),
                );
              })
              .toList(growable: false);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(14, 10, context.hPad, 6),
              child: Row(
                children: [
                  RoundIconButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: () {
                      Haptics.light();
                      if (context.canPop()) context.pop();
                    },
                    tooltip: 'Back',
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppTextField(
                      controller: _controller,
                      hint: 'Recipes or ingredients',
                      autofocus: true,
                      prefixIcon: Icons.search_rounded,
                      onChanged: (value) => setState(() => _query = value),
                      suffix: _query.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.close_rounded, size: 20),
                              onPressed: () {
                                Haptics.light();
                                _controller.clear();
                                setState(() => _query = '');
                              },
                            ),
                    ),
                  ),
                ],
              ),
            ),
            if (_query.trim().isEmpty) ...[
              Padding(
                padding: EdgeInsets.fromLTRB(context.hPad, 16, context.hPad, 4),
                child: Text(
                  'Try these',
                  style: context.ui(
                    13,
                    weight: FontWeight.w700,
                    color: c.inkTertiary,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: context.hPad),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final term in _suggestions)
                      AppChip(
                        label: term,
                        onTap: () {
                          Haptics.light();
                          _controller.text = term;
                          setState(() => _query = term);
                        },
                      ),
                  ],
                ),
              ),
            ] else if (results.isEmpty)
              EmptyStateView(
                icon: Icons.search_off_rounded,
                title: 'No matches',
                message:
                    'Nothing in the menu lines up with "${_query.trim()}". Try an ingredient like eggs or pasta.',
                actionLabel: 'Clear search',
                onAction: () {
                  Haptics.light();
                  _controller.clear();
                  setState(() => _query = '');
                },
              )
            else ...[
              Padding(
                padding: EdgeInsets.fromLTRB(context.hPad, 14, context.hPad, 6),
                child: Text(
                  '${results.length} ${results.length == 1 ? 'match' : 'matches'} for "${_query.trim()}"',
                  style: context.ui(13.5, color: c.inkSecondary),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: results.length,
                  itemBuilder: (context, index) =>
                      RecipeRow(recipe: results[index]),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
