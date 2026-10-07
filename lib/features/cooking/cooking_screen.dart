import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_extensions.dart';
import '../../core/utils/haptics.dart';
import '../../core/widgets/recipe_image.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/misc.dart';
import '../../state/domain_providers.dart';

class CookingScreen extends ConsumerStatefulWidget {
  const CookingScreen({super.key, required this.recipeId});

  final String recipeId;

  @override
  ConsumerState<CookingScreen> createState() => _CookingScreenState();
}

class _CookingScreenState extends ConsumerState<CookingScreen> {
  int _step = 0;
  int _remaining = 0;
  Timer? _timer;
  bool _checkedIn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkIn());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _checkIn() {
    if (_checkedIn || !mounted) return;
    final recipe = ref.read(recipeRepositoryProvider).byId(widget.recipeId);
    if (recipe == null) return;
    _checkedIn = true;
    final pantryNames = ref
        .read(pantryProvider)
        .map((e) => e.name.toLowerCase())
        .toSet();
    final missing = recipe.missingFrom(pantryNames);
    if (missing.isNotEmpty) {
      ref
          .read(shoppingProvider.notifier)
          .addMissing(missing, source: recipe.title);
    }
  }

  Future<void> _tick() async {
    final repo = ref.read(recipeRepositoryProvider);
    final recipe = repo.byId(widget.recipeId);
    if (recipe == null) return;
    if (_step < recipe.steps.length - 1) {
      Haptics.medium();
      setState(() => _step++);
      _stopTimer();
    } else {
      Haptics.heavy();
      _stopTimer();
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          final c = dialogContext.c;
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(26),
            ),
            title: Text('Nicely done', style: dialogContext.serif(24)),
            content: Text(
              '${recipe.title} is cooked. Your missing ingredients are waiting in groceries if you need them.',
              style: context.ui(15, color: c.inkSecondary, height: 1.5),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Haptics.light();
                  Navigator.of(dialogContext).pop();
                  context.go('/home');
                },
                child: const Text('Done'),
              ),
            ],
          );
        },
      );
    }
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _startTimer(int minutes) {
    Haptics.medium();
    _stopTimer();
    setState(() => _remaining = minutes * 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_remaining <= 1) {
        timer.cancel();
        setState(() => _remaining = 0);
        Haptics.heavy();
      } else {
        setState(() => _remaining--);
      }
    });
  }

  String get _clock {
    final m = _remaining ~/ 60;
    final s = _remaining % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final recipe = ref.watch(
      recipeRepositoryProvider.select((r) => r.byId(widget.recipeId)),
    );
    if (recipe == null) {
      return const Scaffold(body: Center(child: Text('Recipe not found.')));
    }

    return Theme(
      data: AppTheme.dark(),
      child: Builder(
        builder: (context) {
          final c = context.c;
          final pantryNames = ref.watch(
            pantryProvider.select((p) {
              final names = <String>{};
              for (final item in p) {
                names.add(item.name.toLowerCase());
              }
              return names;
            }),
          );
          final missing = recipe.missingFrom(pantryNames);
          if (recipe.steps.isEmpty) {
            return Scaffold(
              backgroundColor: c.background,
              appBar: AppBar(title: Text(recipe.title, style: context.serif(20))),
              body: const Center(
                child: Text('This recipe has no steps yet.'),
              ),
            );
          }
          final step = recipe.steps[_step];
          final progress = (_step + 1) / recipe.steps.length;

          return Scaffold(
            backgroundColor: c.background,
            body: SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: context.hPad),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        RoundIconButton(
                          icon: Icons.close_rounded,
                          background: c.surface,
                          color: c.ink,
                          onTap: () {
                            Haptics.light();
                            _stopTimer();
                            if (context.canPop()) context.pop();
                          },
                          tooltip: 'Exit cooking mode',
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 8,
                              backgroundColor: c.surface,
                              color: c.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Text(
                          '${_step + 1} / ${recipe.steps.length}',
                          style: context.ui(
                            14,
                            weight: FontWeight.w700,
                            color: c.inkSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                recipe.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: context.serif(24, height: 1.15),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                step.minutes != null
                                    ? 'About ${step.minutes} min on this step'
                                    : 'Take your time',
                                style: context.ui(13.5, color: c.inkSecondary),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        SizedBox(
                          width: 76,
                          height: 76,
                          child: RecipeImage(
                            imageUrl: recipe.imageUrl,
                            borderRadius: 22,
                            cacheWidth: 240,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(22),
                              decoration: BoxDecoration(
                                color: c.surface,
                                borderRadius: BorderRadius.circular(26),
                                border: Border.all(color: c.hairline),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: c.primary.withValues(
                                            alpha: 0.16,
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Text(
                                          '${_step + 1}',
                                          style: context.ui(
                                            17,
                                            weight: FontWeight.w800,
                                            color: c.primaryDeep,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Text(
                                        'Step ${_step + 1}',
                                        style: context.ui(
                                          14,
                                          weight: FontWeight.w700,
                                          color: c.primaryDeep,
                                          letterSpacing: 0.6,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 18),
                                  Text(
                                    step.text,
                                    style: context.ui(19, height: 1.55),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.fromLTRB(
                                18,
                                16,
                                14,
                                16,
                              ),
                              decoration: BoxDecoration(
                                color: missing.isEmpty
                                    ? c.oliveSoft
                                    : c.gold.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    missing.isEmpty
                                        ? Icons.check_circle_rounded
                                        : Icons.shopping_bag_rounded,
                                    size: 20,
                                    color: missing.isEmpty ? c.olive : c.gold,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      missing.isEmpty
                                          ? 'You have every ingredient for this recipe'
                                          : 'Missing ${missing.join(', ')} — added to your shopping list',
                                      style: context.ui(
                                        14,
                                        weight: FontWeight.w600,
                                        color: missing.isEmpty
                                            ? c.olive
                                            : c.ink,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (step.minutes != null) ...[
                              const SizedBox(height: 16),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: c.surface,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: c.hairline),
                                ),
                                child: Wrap(
                                  spacing: 14,
                                  runSpacing: 10,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.timer_outlined,
                                          size: 22,
                                          color: c.inkSecondary,
                                        ),
                                        const SizedBox(width: 14),
                                        Text(
                                          _remaining > 0
                                              ? _clock
                                              : '${step.minutes} min timer',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: _remaining > 0
                                              ? context.serif(
                                                  30,
                                                  letterSpacing: 2,
                                                )
                                              : context.ui(
                                                  15,
                                                  weight: FontWeight.w600,
                                                  color: c.inkSecondary,
                                                ),
                                        ),
                                      ],
                                    ),
                                    if (_remaining > 0)
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          RoundIconButton(
                                            icon: Icons.refresh_rounded,
                                            size: 46,
                                            iconSize: 20,
                                            onTap: () {
                                              Haptics.light();
                                              _stopTimer();
                                              setState(() => _remaining = 0);
                                            },
                                            tooltip: 'Reset timer',
                                          ),
                                          const SizedBox(width: 8),
                                          RoundIconButton(
                                            icon: _timer == null
                                                ? Icons.play_arrow_rounded
                                                : Icons.pause_rounded,
                                            size: 46,
                                            iconSize: 22,
                                            background: c.primary,
                                            color: c.onPrimary,
                                            onTap: () {
                                              Haptics.light();
                                              if (_timer == null) {
                                                _startExistingTimer();
                                              } else {
                                                _stopTimer();
                                                setState(() {});
                                              }
                                            },
                                            tooltip: 'Pause or resume timer',
                                          ),
                                        ],
                                      )
                                    else
                                      BusyButton(
                                        label: 'Start timer',
                                        onPressed: () async {
                                          _startTimer(step.minutes!);
                                        },
                                      ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),
                            SectionHeader(
                              title: 'Gather first',
                              subtitle:
                                  '${recipe.ingredients.length} ingredients scaled for your servings',
                              padding: const EdgeInsets.fromLTRB(0, 8, 0, 4),
                            ),
                            for (final ingredient in recipe.ingredients)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      pantryNames.contains(
                                            ingredient.name.toLowerCase(),
                                          )
                                          ? Icons.check_circle_rounded
                                          : Icons.circle_outlined,
                                      size: 20,
                                      color:
                                          pantryNames.contains(
                                            ingredient.name.toLowerCase(),
                                          )
                                          ? c.olive
                                          : c.inkTertiary,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        ingredient.scaledLabel(
                                          recipe.servings,
                                          recipe.servings,
                                        ),
                                        style: context.ui(15.5),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        if (_step > 0)
                          RoundIconButton(
                            icon: Icons.arrow_back_rounded,
                            background: c.surface,
                            onTap: () {
                              Haptics.light();
                              _stopTimer();
                              setState(() => _step--);
                            },
                            tooltip: 'Previous step',
                          ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: PrimaryButton(
                            label: _step == recipe.steps.length - 1
                                ? 'Finish'
                                : 'Next step',
                            icon: _step == recipe.steps.length - 1
                                ? Icons.check_rounded
                                : Icons.arrow_forward_rounded,
                            onTap: _tick,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _startExistingTimer() {
    _stopTimer();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_remaining <= 1) {
        timer.cancel();
        setState(() => _remaining = 0);
        Haptics.heavy();
      } else {
        setState(() => _remaining--);
      }
    });
    setState(() {});
  }
}
