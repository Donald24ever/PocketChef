import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/theme_extensions.dart';
import '../../core/utils/haptics.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/misc.dart';
import '../../data/models/recipe.dart';
import '../../data/models/user.dart';
import '../../state/app_state_provider.dart';
import '../../state/domain_providers.dart';

const _goals = [
  'Balanced plates',
  'More plants',
  'High protein',
  'Family favorites',
  'Budget cooking',
];

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final async = ref.watch(appStateProvider);
    final profile = async.value?.profile ?? UserProfile.guest;
    final favorites = ref.watch(favoritesProvider).recipeIds.length;
    final planCount = ref.watch(plannerProvider).length;
    final pantryCount = ref.watch(pantryProvider).length;
    final authed = async.value?.authed ?? false;

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.only(bottom: 40),
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(context.hPad, 14, context.hPad, 6),
              child: Row(
                children: [
                  Text('Profile', style: context.serif(26)),
                  const Spacer(),
                  RoundIconButton(
                    icon: Icons.bookmark_outline_rounded,
                    onTap: () {
                      Haptics.light();
                      context.push('/saved');
                    },
                    tooltip: 'Saved recipes',
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(context.hPad, 8, context.hPad, 4),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: c.hairline),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 68,
                          height: 68,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: c.primary.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            profile.initials,
                            style: context.serif(26, color: c.primaryDeep),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                profile.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: context.serif(22, height: 1.2),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                profile.email.isEmpty
                                    ? 'Continuing as guest'
                                    : profile.email,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: context.ui(13.5, color: c.inkSecondary),
                              ),
                            ],
                          ),
                        ),
                        Semantics(
                          button: true,
                          label: 'Rename',
                          child: InkWell(
                            onTap: () {
                              Haptics.light();
                              _renameSheet(context, ref, profile);
                            },
                            borderRadius: BorderRadius.circular(22),
                            child: SizedBox(
                              width: 44,
                              height: 44,
                              child: Icon(
                                Icons.edit_outlined,
                                size: 20,
                                color: c.inkTertiary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        _StatBox(label: 'Saved', value: '$favorites'),
                        const SizedBox(width: 10),
                        _StatBox(label: 'Planned', value: '$planCount'),
                        const SizedBox(width: 10),
                        _StatBox(label: 'Pantry', value: '$pantryCount'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SectionHeader(
              title: 'Taste profile',
              subtitle: 'Sharper suggestions when this is filled in',
              padding: EdgeInsets.fromLTRB(context.hPad, 22, context.hPad, 8),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: context.hPad),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: c.hairline),
                ),
                child: Column(
                  children: [
                    _LinkRow(
                      icon: Icons.restaurant_outlined,
                      title: 'Diets',
                      value: profile.diets.isEmpty
                          ? 'None set'
                          : profile.diets.map((d) => d.label).join(', '),
                      onTap: () {
                        Haptics.light();
                        _dietsSheet(context, ref, profile);
                      },
                    ),
                    const Divider(height: 1, indent: 54),
                    _LinkRow(
                      icon: Icons.warning_amber_rounded,
                      title: 'Allergies',
                      value: profile.allergies.isEmpty
                          ? 'None set'
                          : profile.allergies.join(', '),
                      onTap: () {
                        Haptics.light();
                        _allergiesSheet(context, ref, profile);
                      },
                    ),
                    const Divider(height: 1, indent: 54),
                    _LinkRow(
                      icon: Icons.flag_outlined,
                      title: 'Weekly goal',
                      value: profile.goal,
                      onTap: () {
                        Haptics.light();
                        _goalSheet(context, ref, profile);
                      },
                    ),
                    const Divider(height: 1, indent: 54),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.groups_outlined,
                            size: 22,
                            color: c.inkSecondary,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text('Family size', style: context.ui(15.5)),
                          ),
                          Semantics(
                            button: true,
                            label: 'Fewer people',
                            child: InkWell(
                              onTap: profile.familySize > 1
                                  ? () {
                                      Haptics.selection();
                                      _setSize(ref, profile, -1);
                                    }
                                  : null,
                              borderRadius: BorderRadius.circular(16),
                              child: SizedBox(
                                width: 44,
                                height: 44,
                                child: Icon(
                                  Icons.remove_rounded,
                                  size: 20,
                                  color: profile.familySize > 1
                                      ? c.ink
                                      : c.inkTertiary,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 34,
                            child: Text(
                              '${profile.familySize}',
                              textAlign: TextAlign.center,
                              style: context.serif(18),
                            ),
                          ),
                          Semantics(
                            button: true,
                            label: 'More people',
                            child: InkWell(
                              onTap: profile.familySize < 8
                                  ? () {
                                      Haptics.selection();
                                      _setSize(ref, profile, 1);
                                    }
                                  : null,
                              borderRadius: BorderRadius.circular(16),
                              child: SizedBox(
                                width: 44,
                                height: 44,
                                child: Icon(
                                  Icons.add_rounded,
                                  size: 20,
                                  color: profile.familySize < 8
                                      ? c.ink
                                      : c.inkTertiary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SectionHeader(
              title: 'App',
              padding: EdgeInsets.fromLTRB(context.hPad, 24, context.hPad, 8),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: context.hPad),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: c.hairline),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Appearance',
                      style: context.ui(
                        13,
                        weight: FontWeight.w700,
                        color: c.inkSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 44,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: c.surfaceAlt,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        children: [
                          for (final pref in ThemePreference.values)
                            Expanded(
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  Haptics.selection();
                                  ref
                                      .read(appStateProvider.notifier)
                                      .setTheme(pref);
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: async.value?.theme == pref
                                        ? c.surface
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    pref.label,
                                    style: context.ui(
                                      13.5,
                                      weight: FontWeight.w700,
                                      color: async.value?.theme == pref
                                          ? c.ink
                                          : c.inkSecondary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Material(
                      type: MaterialType.transparency,
                      child: SwitchListTile.adaptive(
                        value: profile.notifications,
                        contentPadding: EdgeInsets.zero,
                        activeTrackColor: c.primary,
                        title: Text(
                          'Meal reminders',
                          style: context.ui(15.5, weight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          'A nudge when it is time to start dinner',
                          style: context.ui(13, color: c.inkTertiary),
                        ),
                        onChanged: (value) {
                          Haptics.selection();
                          ref
                              .read(appStateProvider.notifier)
                              .updateProfile(
                                profile.copyWith(notifications: value),
                              );
                        },
                      ),
                    ),
                    const Divider(height: 1),
                    _LinkRow(
                      icon: Icons.cloud_outlined,
                      title: 'Cloud sync',
                      value: 'Demo data',
                      onTap: () {
                        Haptics.light();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Cloud sync connects when you add your Firebase project (see README).',
                            ),
                          ),
                        );
                      },
                    ),
                    _LinkRow(
                      icon: Icons.shield_outlined,
                      title: 'Privacy & security',
                      value: 'Account & data',
                      onTap: () {
                        Haptics.light();
                        context.push('/privacy');
                      },
                    ),
                    _LinkRow(
                      icon: Icons.info_outline_rounded,
                      title: 'About PocketChef',
                      value: 'v1.0.0',
                      onTap: () {
                        Haptics.light();
                        showAboutDialog(
                          context: context,
                          applicationName: 'PocketChef',
                          applicationVersion: '1.0.0',
                          applicationLegalese:
                              'Scan your kitchen, cook what you have.',
                        );
                      },
                    ),
                    _LinkRow(
                      icon: Icons.description_outlined,
                      title: 'Terms of Service',
                      value: '',
                      onTap: () {
                        Haptics.light();
                        context.push('/legal/terms');
                      },
                    ),
                    _LinkRow(
                      icon: Icons.privacy_tip_outlined,
                      title: 'Privacy Policy',
                      value: '',
                      onTap: () {
                        Haptics.light();
                        context.push('/legal/privacy');
                      },
                    ),
                    _LinkRow(
                      icon: Icons.photo_library_outlined,
                      title: 'Photo credits',
                      value: '',
                      onTap: () {
                        Haptics.light();
                        context.push('/legal/credits');
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 26),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: context.hPad),
              child: authed
                  ? PrimaryButton(
                      label: 'Sign out',
                      icon: Icons.logout_rounded,
                      danger: true,
                      onTap: () => _confirmSignOut(context, ref),
                    )
                  : PrimaryButton(
                      label: 'Sign in to sync',
                      icon: Icons.login_rounded,
                      onTap: () {
                        Haptics.medium();
                        context.push('/welcome');
                      },
                    ),
            ),
            const SizedBox(height: 14),
            Center(
              child: Text(
                'PocketChef · Crafted for hungry humans',
                style: context.ui(12.5, color: c.inkTertiary),
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                'Designed by DonTwice',
                style: context.ui(12.5, color: c.inkTertiary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _setSize(WidgetRef ref, UserProfile profile, int delta) {
    ref
        .read(appStateProvider.notifier)
        .updateProfile(
          profile.copyWith(
            familySize: (profile.familySize + delta).clamp(1, 8),
          ),
        );
  }

  Future<void> _renameSheet(
    BuildContext context,
    WidgetRef ref,
    UserProfile profile,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return _RenameDialog(profile: profile, ref: ref);
      },
    );
  }

  Future<void> _dietsSheet(
    BuildContext context,
    WidgetRef ref,
    UserProfile profile,
  ) async {
    var selection = {...profile.diets};
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final c = sheetContext.c;
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Diets', style: sheetContext.serif(24)),
                    const SizedBox(height: 6),
                    Text(
                      'We skip recipes that break these rules.',
                      style: sheetContext.ui(14, color: c.inkSecondary),
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final diet in DietTag.values)
                          ActionChip(
                            avatar: selection.contains(diet)
                                ? Icon(
                                    Icons.check_rounded,
                                    size: 17,
                                    color: c.onPrimary,
                                  )
                                : null,
                            label: Text(diet.label),
                            labelStyle: sheetContext.ui(
                              14.5,
                              weight: FontWeight.w600,
                              color: selection.contains(diet)
                                  ? c.onPrimary
                                  : c.ink,
                            ),
                            backgroundColor: selection.contains(diet)
                                ? c.primary
                                : c.surface,
                            side: BorderSide(
                              color: selection.contains(diet)
                                  ? c.primary
                                  : c.hairline,
                            ),
                            onPressed: () {
                              Haptics.selection();
                              setSheetState(() {
                                if (!selection.remove(diet)) {
                                  selection.add(diet);
                                }
                              });
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    PrimaryButton(
                      label: 'Save diets',
                      onTap: () {
                        Haptics.medium();
                        ref
                            .read(appStateProvider.notifier)
                            .updateProfile(
                              profile.copyWith(diets: selection.toList()),
                            );
                        Navigator.of(sheetContext).pop();
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _allergiesSheet(
    BuildContext context,
    WidgetRef ref,
    UserProfile profile,
  ) async {
    final controller = TextEditingController();
    var items = [...profile.allergies];
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        final c = sheetContext.c;
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                4,
                24,
                24 + MediaQuery.paddingOf(sheetContext).bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Allergies', style: sheetContext.serif(24)),
                  const SizedBox(height: 6),
                  Text(
                    'Anything here never appears in suggestions.',
                    style: sheetContext.ui(14, color: c.inkSecondary),
                  ),
                  const SizedBox(height: 18),
                  for (final item in items)
                    Row(
                      children: [
                        Icon(
                          Icons.remove_circle_outline_rounded,
                          size: 20,
                          color: c.error,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(item, style: sheetContext.ui(15.5)),
                        ),
                        SizedBox(
                          width: 44,
                          height: 44,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.close_rounded, size: 18),
                            tooltip: 'Remove $item',
                            onPressed: () {
                              Haptics.light();
                              setSheetState(() => items.remove(item));
                            },
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller,
                          decoration: const InputDecoration(
                            hintText: 'Add an allergy…',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      RoundIconButton(
                        icon: Icons.add_rounded,
                        background: c.primary,
                        color: c.onPrimary,
                        onTap: () {
                          final value = controller.text.trim();
                          if (value.isEmpty) return;
                          Haptics.light();
                          setSheetState(() {
                            if (!items.contains(value)) items.add(value);
                          });
                          controller.clear();
                        },
                        tooltip: 'Add allergy',
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  PrimaryButton(
                    label: 'Save allergies',
                    onTap: () {
                      Haptics.medium();
                      ref
                          .read(appStateProvider.notifier)
                          .updateProfile(profile.copyWith(allergies: items));
                      Navigator.of(sheetContext).pop();
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    controller.dispose();
  }

  Future<void> _goalSheet(
    BuildContext context,
    WidgetRef ref,
    UserProfile profile,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final c = sheetContext.c;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Weekly goal', style: sheetContext.serif(24)),
                const SizedBox(height: 12),
                for (final goal in _goals)
                  InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      Haptics.light();
                      ref
                          .read(appStateProvider.notifier)
                          .updateProfile(profile.copyWith(goal: goal));
                      Navigator.of(sheetContext).pop();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          Icon(
                            profile.goal == goal
                                ? Icons.radio_button_checked_rounded
                                : Icons.radio_button_unchecked_rounded,
                            size: 22,
                            color: profile.goal == goal
                                ? c.primary
                                : c.inkTertiary,
                          ),
                          const SizedBox(width: 14),
                          Text(goal, style: sheetContext.ui(16)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    Haptics.medium();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final c = dialogContext.c;
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
          title: Text('Sign out?', style: dialogContext.serif(22)),
          content: Text(
            'Your saved recipes and plan stay on this device.',
            style: dialogContext.ui(15, color: c.inkSecondary, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Stay'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Sign out'),
            ),
          ],
        );
      },
    );
    if (confirmed == true) {
      await ref.read(appStateProvider.notifier).signOut();
      if (context.mounted) context.go('/welcome');
    }
  }
}

class _RenameDialog extends StatefulWidget {
  const _RenameDialog({required this.profile, required this.ref});

  final UserProfile profile;
  final WidgetRef ref;

  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.profile.name);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      title: Text('Your name', style: context.serif(22)),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(hintText: 'Chef name'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            Haptics.light();
            widget.ref
                .read(appStateProvider.notifier)
                .updateProfile(
                  widget.profile.copyWith(name: _controller.text.trim()),
                );
            Navigator.of(context).pop();
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Expanded(
      child: Container(
        height: 74,
        decoration: BoxDecoration(
          color: c.surfaceAlt,
          borderRadius: BorderRadius.circular(18),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(value, style: context.serif(24)),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                style: context.ui(
                  12.5,
                  weight: FontWeight.w600,
                  color: c.inkSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 22, color: c.inkSecondary),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: context.ui(15.5, weight: FontWeight.w600),
              ),
            ),
            Flexible(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: context.ui(14, color: c.inkTertiary),
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, size: 20, color: c.inkTertiary),
          ],
        ),
      ),
    );
  }
}
