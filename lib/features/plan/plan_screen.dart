import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_extensions.dart';
import '../../core/utils/haptics.dart';
import '../../core/utils/route_guard.dart';
import '../../core/widgets/recipe_image.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/misc.dart';
import '../../core/widgets/state_views.dart';
import '../../core/widgets/text_fields.dart';
import '../../data/models/plan_preferences.dart';
import '../../data/models/recipe.dart';
import '../../data/models/shopping_item.dart';
import '../../state/app_state_provider.dart';
import '../../state/domain_providers.dart';

class PlanScreen extends ConsumerStatefulWidget {
  const PlanScreen({super.key});

  @override
  ConsumerState<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends ConsumerState<PlanScreen> {
  int _segment = 0;

  static const _segmentLabels = ['Meal plan', 'Groceries'];

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Scaffold(
      backgroundColor: c.background,
      floatingActionButton: _segment == 1
          ? FloatingActionButton.extended(
              onPressed: () {
                Haptics.light();
                _showAddSheet();
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add item'),
            )
          : null,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(context.hPad, 8, context.hPad, 4),
              child: Container(
                height: 46,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: c.surfaceAlt,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  children: [
                    for (var i = 0; i < _segmentLabels.length; i++)
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            Haptics.selection();
                            setState(() => _segment = i);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOutCubic,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _segment == i
                                  ? c.surface
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(999),
                              boxShadow: _segment == i
                                  ? [
                                      BoxShadow(
                                        color: c.shadow,
                                        blurRadius: 10,
                                        offset: const Offset(0, 3),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Text(
                              _segmentLabels[i],
                              style: context.ui(
                                14.5,
                                weight: FontWeight.w700,
                                color: _segment == i ? c.ink : c.inkSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: IndexedStack(
                index: _segment,
                children: const [_MealPlanTab(), _GroceriesTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddSheet() async {
    Haptics.light();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => const _AddGrocerySheet(),
    );
  }
}

class _AddGrocerySheet extends ConsumerStatefulWidget {
  const _AddGrocerySheet();

  @override
  ConsumerState<_AddGrocerySheet> createState() => _AddGrocerySheetState();
}

class _AddGrocerySheetState extends ConsumerState<_AddGrocerySheet> {
  final _name = TextEditingController();
  final _quantity = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _quantity.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Give the item a name');
      return;
    }
    Haptics.light();
    ref
        .read(shoppingProvider.notifier)
        .addItem(name: name, quantity: _quantity.text);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final insets = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        4,
        24,
        24 + insets + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Add to groceries', style: context.serif(24)),
          const SizedBox(height: 18),
          AppTextField(
            controller: _name,
            label: 'Item',
            hint: 'Olive oil, lemons, bread…',
            autofocus: true,
            errorText: _error,
            textInputAction: TextInputAction.next,
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
          ),
          const SizedBox(height: 14),
          AppTextField(
            controller: _quantity,
            label: 'Quantity (optional)',
            hint: '1 jar, 250 g…',
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 22),
          PrimaryButton(
            label: 'Add to list',
            icon: Icons.add_rounded,
            onTap: _submit,
          ),
          const SizedBox(height: 14),
          Text(
            'Tip: long-press recipes in the plan tray, then drop them onto a day.',
            style: context.ui(12.5, color: c.inkTertiary),
          ),
        ],
      ),
    );
  }
}

/// Preference sheet behind the "Auto-plan" action: people, time budget,
/// diets, cuisine and how many meals a day. Generates the week on submit.
class _AutoPlanSheet extends ConsumerStatefulWidget {
  const _AutoPlanSheet();

  @override
  ConsumerState<_AutoPlanSheet> createState() => _AutoPlanSheetState();
}

class _AutoPlanSheetState extends ConsumerState<_AutoPlanSheet> {
  static const _timeOptions = [20, 30, 45, 60, 90];
  static const _mealOptions = [
    (1, 'Dinner'),
    (2, 'Lunch + dinner'),
    (3, 'All three'),
  ];
  static const _cuisineOptions = [
    '',
    'Nigerian',
    'Italian',
    'Mexican',
    'Indian',
    'Chinese',
    'Thai',
    'Japanese',
    'Vietnamese',
    'American',
    'Greek',
  ];

  late int _people;
  late Set<DietTag> _diets;
  int _maxMinutes = 45;
  BudgetTier _budget = BudgetTier.moderate;
  String _cuisine = '';
  int _mealsPerDay = 1;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(appStateProvider).value?.profile;
    _people = profile?.familySize ?? 2;
    _diets = {...?profile?.diets};
  }

  Future<void> _generate() async {
    Haptics.medium();
    setState(() {
      _busy = true;
      _error = null;
    });

    final profile = ref.read(appStateProvider).value?.profile;
    final pantry = ref
        .read(pantryProvider)
        .map((item) => item.name)
        .toList(growable: false);
    final prefs = PlanPreferences(
      people: _people,
      diets: _diets.toList(growable: false),
      allergies: profile?.allergies ?? const [],
      maxMinutes: _maxMinutes,
      budget: _budget,
      cuisine: _cuisine,
      mealsPerDay: _mealsPerDay,
      availableIngredients: pantry,
    );
    final pool = ref.read(recipeRepositoryProvider).all();

    try {
      final result = await ref
          .read(plannerProvider.notifier)
          .autoPlanSmart(prefs: prefs, pool: pool);
      if (!mounted) return;
      if (result == null) {
        setState(() {
          _busy = false;
          _error = 'Every day already has a meal. Remove one, then plan again.';
        });
        return;
      }
      if (result.picks.isEmpty) {
        setState(() {
          _busy = false;
          _error = 'No recipes matched those rules — widen the time or budget.';
        });
        return;
      }
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      final message = result.isAi
          ? 'Your week is planned with ${result.recipes.length} fresh AI meals.'
          : 'Your week is planned from the recipe collection.';
      messenger.showSnackBar(SnackBar(content: Text(message)));
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Planning failed. Check your connection and try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.86,
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            24,
            4,
            24,
            24 + inset + MediaQuery.paddingOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Plan my week', style: context.serif(24)),
              const SizedBox(height: 6),
              Text(
                'Tell us the basics — we fill every open day, AI-crafted when a '
                'Gemini key is configured, from the collection otherwise.',
                style: context.ui(14, color: c.inkSecondary),
              ),
              const SizedBox(height: 18),
              _Stepper(
                label: 'People',
                value: '$_people',
                onDecrease: _people > 1
                    ? () {
                        Haptics.selection();
                        setState(() => _people--);
                      }
                    : null,
                onIncrease: _people < 12
                    ? () {
                        Haptics.selection();
                        setState(() => _people++);
                      }
                    : null,
              ),
              const SizedBox(height: 16),
              _chipLabel(context, 'Ready within'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final minutes in _timeOptions)
                    _selectChip(
                      context,
                      label: '$minutes min',
                      selected: _maxMinutes == minutes,
                      onTap: () {
                        Haptics.selection();
                        setState(() => _maxMinutes = minutes);
                      },
                    ),
                ],
              ),
              const SizedBox(height: 16),
              _chipLabel(context, 'Budget per serving'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final tier in BudgetTier.values)
                    _selectChip(
                      context,
                      label: tier.label,
                      selected: _budget == tier,
                      onTap: () {
                        Haptics.selection();
                        setState(() => _budget = tier);
                      },
                    ),
                ],
              ),
              const SizedBox(height: 16),
              _chipLabel(context, 'Meals a day'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final (value, label) in _mealOptions)
                    _selectChip(
                      context,
                      label: label,
                      selected: _mealsPerDay == value,
                      onTap: () {
                        Haptics.selection();
                        setState(() => _mealsPerDay = value);
                      },
                    ),
                ],
              ),
              const SizedBox(height: 16),
              _chipLabel(context, 'Cuisine'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final cuisine in _cuisineOptions)
                    _selectChip(
                      context,
                      label: cuisine.isEmpty ? 'Any' : cuisine,
                      selected: _cuisine == cuisine,
                      onTap: () {
                        Haptics.selection();
                        setState(() => _cuisine = cuisine);
                      },
                    ),
                ],
              ),
              const SizedBox(height: 16),
              _chipLabel(context, 'Diets'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final diet in DietTag.values)
                    _selectChip(
                      context,
                      label: diet.label,
                      selected: _diets.contains(diet),
                      onTap: () {
                        Haptics.selection();
                        setState(() {
                          if (!_diets.remove(diet)) _diets.add(diet);
                        });
                      },
                    ),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 14),
                Text(
                  _error!,
                  style: context.ui(13.5, color: c.error),
                ),
              ],
              const SizedBox(height: 22),
              PrimaryButton(
                label: 'Generate plan',
                icon: Icons.auto_awesome_rounded,
                loading: _busy,
                onTap: _busy ? null : _generate,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chipLabel(BuildContext context, String text) => Text(
    text,
    style: context.ui(13, weight: FontWeight.w700, color: context.c.inkSecondary),
  );

  Widget _selectChip(
    BuildContext context, {
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final c = context.c;
    return ActionChip(
      label: Text(label),
      labelStyle: context.ui(
        14,
        weight: FontWeight.w600,
        color: selected ? c.onPrimary : c.ink,
      ),
      backgroundColor: selected ? c.primary : c.surface,
      side: BorderSide(color: selected ? c.primary : c.hairline),
      onPressed: onTap,
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.label,
    required this.value,
    required this.onDecrease,
    required this.onIncrease,
  });

  final String label;
  final String value;
  final VoidCallback? onDecrease;
  final VoidCallback? onIncrease;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: context.ui(14.5, weight: FontWeight.w700),
          ),
        ),
        _stepButton(context, icon: Icons.remove_rounded, onTap: onDecrease),
        SizedBox(
          width: 42,
          child: Text(
            value,
            textAlign: TextAlign.center,
            style: context.ui(16, weight: FontWeight.w800),
          ),
        ),
        _stepButton(context, icon: Icons.add_rounded, onTap: onIncrease),
      ],
    );
  }

  Widget _stepButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    final c = context.c;
    return PressScale(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: c.surface,
          shape: BoxShape.circle,
          border: Border.all(color: c.hairline),
        ),
        child: Icon(
          icon,
          size: 20,
          color: onTap == null ? c.inkTertiary : c.ink,
        ),
      ),
    );
  }
}

class _MealPlanTab extends ConsumerWidget {
  const _MealPlanTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final meals = ref.watch(plannerProvider);
    final tray = ref.watch(plannerTrayProvider);
    final weekStart = DateTime.now().subtract(
      Duration(days: DateTime.now().weekday - 1),
    );
    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return ListView(
      padding: EdgeInsets.only(bottom: 120),
      children: [
        SectionHeader(
          title: 'This week',
          subtitle:
              '${_fmtDay(weekStart)} — ${_fmtDay(weekStart.add(const Duration(days: 6)))}',
          actionLabel: 'Auto-plan',
          onAction: () {
            Haptics.medium();
            showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              showDragHandle: true,
              builder: (_) => const _AutoPlanSheet(),
            );
          },
        ),
        if (meals.isNotEmpty)
          _ReshuffleButton(
            onTap: () {
              Haptics.medium();
              ref.read(plannerProvider.notifier).shuffleDays();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Days reshuffled.')),
              );
            },
          ),
        for (var day = 0; day < 7; day++)
          _DayDropTarget(
            day: day,
            dayLabel: dayNames[day],
            date: weekStart.add(Duration(days: day)),
            meals: meals.where((m) => m.day == day).toList(growable: false),
            nextMealType: () => _nextMealType(ref, day),
          ),
        const SizedBox(height: 12),
        Padding(
          padding: EdgeInsets.fromLTRB(context.hPad, 12, context.hPad, 0),
          child: Row(
            children: [
              Icon(
                Icons.drag_indicator_rounded,
                size: 18,
                color: c.inkTertiary,
              ),
              const SizedBox(width: 8),
              Text(
                'Long-press a recipe, drag it onto a day',
                style: context.ui(13, color: c.inkSecondary),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 138,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(
              horizontal: context.hPad,
              vertical: 10,
            ),
            itemCount: tray.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final recipe = tray[index];
              return LongPressDraggable<Recipe>(
                data: recipe,
                hapticFeedbackOnStart: true,
                feedback: Material(
                  color: Colors.transparent,
                  child: Container(
                    width: 150,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: c.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: c.hairline),
                      boxShadow: [
                        BoxShadow(
                          color: c.shadow,
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 56,
                          width: double.infinity,
                          child: RecipeImage(
                              imageUrl: recipe.imageUrl,
                              borderRadius: 14,
                              cacheWidth: 220,
                              artSeed: recipe.artSeed,
                            ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          recipe.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.ui(13, weight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
                childWhenDragging: Opacity(
                  opacity: 0.35,
                  child: _TrayCard(recipe: recipe),
                ),
                child: _TrayCard(recipe: recipe),
              );
            },
          ),
        ),
      ],
    );
  }

  MealType _nextMealType(WidgetRef ref, int day) {
    final used = ref
        .read(plannerProvider)
        .where((m) => m.day == day)
        .map((m) => m.mealType)
        .toSet();
    for (final type in [MealType.breakfast, MealType.lunch, MealType.dinner]) {
      if (!used.contains(type)) return type;
    }
    return MealType.dinner;
  }

  static String _fmtDay(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${d.day} ${months[d.month - 1]}';
  }
}

class _ReshuffleButton extends StatelessWidget {
  const _ReshuffleButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: EdgeInsets.fromLTRB(context.hPad, 0, context.hPad, 4),
      child: Align(
        alignment: Alignment.centerRight,
        child: PressScale(
          onTap: onTap,
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(
              color: c.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.shuffle_rounded, size: 17, color: c.primaryDeep),
                const SizedBox(width: 7),
                Text(
                  'Reshuffle days',
                  style: context.ui(
                    13.5,
                    weight: FontWeight.w700,
                    color: c.primaryDeep,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TrayCard extends StatelessWidget {
  const _TrayCard({required this.recipe});

  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      width: 150,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 56,
            width: double.infinity,
            child: RecipeImage(
                              imageUrl: recipe.imageUrl,
                              borderRadius: 14,
                              cacheWidth: 220,
                              artSeed: recipe.artSeed,
                            ),
          ),
          const SizedBox(height: 8),
          Text(
            recipe.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: context.ui(13, weight: FontWeight.w700, height: 1.25),
          ),
        ],
      ),
    );
  }
}

class _DayDropTarget extends ConsumerStatefulWidget {
  const _DayDropTarget({
    required this.day,
    required this.dayLabel,
    required this.date,
    required this.meals,
    required this.nextMealType,
  });

  final int day;
  final String dayLabel;
  final DateTime date;
  final List<PlannedMeal> meals;
  final MealType Function() nextMealType;

  @override
  ConsumerState<_DayDropTarget> createState() => _DayDropTargetState();
}

class _DayDropTargetState extends ConsumerState<_DayDropTarget> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final isToday = DateUtils.isSameDay(widget.date, DateTime.now());

    return Padding(
      padding: EdgeInsets.fromLTRB(context.hPad, 6, context.hPad, 6),
      child: DragTarget<Object>(
        onWillAcceptWithDetails: (_) {
          setState(() => _hovering = true);
          return true;
        },
        onLeave: (_) => setState(() => _hovering = false),
        onAcceptWithDetails: (details) {
          setState(() => _hovering = false);
          Haptics.medium();
          final data = details.data;
          if (data is Recipe) {
            ref
                .read(plannerProvider.notifier)
                .assign(
                  day: widget.day,
                  recipeId: data.id,
                  servings:
                      ref.read(appStateProvider).value?.profile.familySize ?? 2,
                  mealType: widget.nextMealType(),
                );
          } else if (data is PlannedMeal) {
            ref.read(plannerProvider.notifier).moveTo(data.id, widget.day);
          }
        },
        builder: (context, candidates, _) {
          final accepting = _hovering || candidates.isNotEmpty;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
            decoration: BoxDecoration(
              color: accepting
                  ? c.oliveSoft
                  : (isToday ? c.primary.withValues(alpha: 0.07) : c.surface),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: accepting
                    ? c.olive
                    : (isToday
                          ? c.primary.withValues(alpha: 0.35)
                          : c.hairline),
                width: accepting ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      widget.dayLabel,
                      style: context.ui(
                        13,
                        weight: FontWeight.w800,
                        color: isToday ? c.primaryDeep : c.inkSecondary,
                        letterSpacing: 0.7,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${widget.date.day}',
                      style: context.ui(13, color: c.inkTertiary),
                    ),
                    const Spacer(),
                    if (widget.meals.isEmpty)
                      Text(
                        'Open day',
                        style: context.ui(12.5, color: c.inkTertiary),
                      ),
                  ],
                ),
                if (widget.meals.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: c.background.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: c.hairline,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Text(
                        'Drag a recipe here',
                        style: context.ui(13, color: c.inkTertiary),
                      ),
                    ),
                  )
                else
                  for (final meal in widget.meals) _MealRow(meal: meal),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MealRow extends ConsumerWidget {
  const _MealRow({required this.meal});

  final PlannedMeal meal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final recipe = ref.watch(
      recipeRepositoryProvider.select((r) => r.byId(meal.recipeId)),
    );
    if (recipe == null) return const SizedBox.shrink();

    return LongPressDraggable<PlannedMeal>(
      data: meal,
      hapticFeedbackOnStart: true,
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          width: 240,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: c.hairline),
            boxShadow: [BoxShadow(color: c.shadow, blurRadius: 24)],
          ),
          child: Text(
            recipe.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.ui(14.5, weight: FontWeight.w700),
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.35,
        child: _mealBody(context, ref, recipe, c),
      ),
      child: _mealBody(context, ref, recipe, c),
    );
  }

  Widget _mealBody(
    BuildContext context,
    WidgetRef ref,
    Recipe recipe,
    AppPalette c,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Haptics.light();
          RouteGuard.push(context, '/recipe/${recipe.id}');
        },
        child: Container(
          padding: const EdgeInsets.fromLTRB(8, 8, 4, 8),
          decoration: BoxDecoration(
            color: c.background.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 46,
                height: 46,
                child: RecipeImage(
                  imageUrl: recipe.imageUrl,
                  borderRadius: 12,
                  cacheWidth: 200,
                  artSeed: recipe.artSeed,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(meal.mealType.icon, size: 13, color: c.olive),
                        const SizedBox(width: 5),
                        Text(
                          meal.mealType.label,
                          style: context.ui(
                            11.5,
                            weight: FontWeight.w700,
                            color: c.olive,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${meal.servings} pers.',
                          style: context.ui(11.5, color: c.inkTertiary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      recipe.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.ui(14.5, weight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 44,
                height: 44,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: c.inkTertiary,
                  ),
                  tooltip: 'Remove from plan',
                  onPressed: () {
                    Haptics.light();
                    ref.read(plannerProvider.notifier).remove(meal.id);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GroceriesTab extends ConsumerWidget {
  const _GroceriesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final items = ref.watch(shoppingProvider);
    final checkedCount = items.where((i) => i.checked).length;

    if (items.isEmpty) {
      return ListView(
        children: [
          EmptyStateView(
            icon: Icons.shopping_cart_outlined,
            title: 'Groceries list is empty',
            message: 'Scan your fridge or open a recipe — missing ingredients land here automatically.',
            actionLabel: 'Scan now',
            onAction: () {
              Haptics.light();
              RouteGuard.push(context, '/scan');
            },
          ),
        ],
      );
    }

    return ListView(
      padding: EdgeInsets.only(bottom: 120),
      children: [
        SectionHeader(
          title: 'Groceries',
          subtitle: '${items.length} items · $checkedCount in the cart',
          actionLabel: checkedCount > 0 ? 'Clear checked' : null,
          onAction: checkedCount > 0
              ? () {
                  Haptics.light();
                  ref.read(shoppingProvider.notifier).clearChecked();
                }
              : null,
        ),
        for (final aisle in Aisles.order)
          if (items.any((i) => i.aisle == aisle)) ...[
            Padding(
              padding: EdgeInsets.fromLTRB(context.hPad, 18, context.hPad, 6),
              child: Text(
                aisle.toUpperCase(),
                style: context.ui(
                  12,
                  weight: FontWeight.w800,
                  color: c.inkTertiary,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            for (final item in items.where((i) => i.aisle == aisle))
              _ShoppingRow(item: item),
          ],
        const SizedBox(height: 24),
      ],
    );
  }
}

class _ShoppingRow extends ConsumerWidget {
  const _ShoppingRow({required this.item});

  final ShoppingItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.hPad, vertical: 3),
      child: Row(
        children: [
          Semantics(
            toggled: item.checked,
            label: 'Mark ${item.name}',
            child: InkWell(
              onTap: () {
                Haptics.selection();
                ref.read(shoppingProvider.notifier).toggle(item.id);
              },
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 46,
                height: 46,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  margin: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: item.checked ? c.olive : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: item.checked ? c.olive : c.inkTertiary,
                      width: 1.6,
                    ),
                  ),
                  child: item.checked
                      ? const Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: Colors.white,
                        )
                      : null,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.quantity.isEmpty
                      ? item.name
                      : '${item.name} · ${item.quantity}',
                  style: context
                      .ui(
                        15.5,
                        weight: FontWeight.w600,
                        color: item.checked ? c.inkTertiary : c.ink,
                      )
                      .copyWith(
                        decoration: item.checked
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                ),
                if (item.source.isNotEmpty)
                  Text(
                    item.source,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.ui(12, color: c.inkTertiary),
                  ),
              ],
            ),
          ),
          SizedBox(
            width: 44,
            height: 44,
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: Icon(
                Icons.delete_outline_rounded,
                size: 19,
                color: c.inkTertiary,
              ),
              tooltip: 'Remove ${item.name}',
              onPressed: () {
                Haptics.light();
                ref.read(shoppingProvider.notifier).remove(item.id);
              },
            ),
          ),
        ],
      ),
    );
  }
}
