import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/theme_extensions.dart';
import '../../core/utils/haptics.dart';
import '../../core/widgets/buttons.dart';

class AppBottomBar extends StatelessWidget {
  const AppBottomBar({super.key, required this.shell});

  final StatefulNavigationShell shell;

  void _select(int index) {
    if (shell.currentIndex == index) {
      shell.goBranch(index, initialLocation: true);
      return;
    }
    Haptics.selection();
    shell.goBranch(index);
  }

  void _openScanner(BuildContext context) {
    Haptics.medium();
    context.push('/scan');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        boxShadow: [
          BoxShadow(
            color: c.shadow,
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Row(
                children: [
                  Expanded(
                    child: _NavItem(
                      label: 'Home',
                      selectedIcon: Icons.home_rounded,
                      icon: Icons.home_outlined,
                      selected: shell.currentIndex == 0,
                      onTap: () => _select(0),
                    ),
                  ),
                  Expanded(
                    child: _NavItem(
                      label: 'Recipes',
                      selectedIcon: Icons.menu_book_rounded,
                      icon: Icons.menu_book_outlined,
                      selected: shell.currentIndex == 1,
                      onTap: () => _select(1),
                    ),
                  ),
                  _ScanAction(onTap: () => _openScanner(context)),
                  Expanded(
                    child: _NavItem(
                      label: 'Plan',
                      selectedIcon: Icons.calendar_month_rounded,
                      icon: Icons.calendar_month_outlined,
                      selected: shell.currentIndex == 2,
                      onTap: () => _select(2),
                    ),
                  ),
                  Expanded(
                    child: _NavItem(
                      label: 'Profile',
                      selectedIcon: Icons.person_rounded,
                      icon: Icons.person_outline_rounded,
                      selected: shell.currentIndex == 3,
                      onTap: () => _select(3),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ScanAction extends StatelessWidget {
  const _ScanAction({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Semantics(
      button: true,
      label: 'Scan ingredients with camera',
      child: SizedBox(
        width: 72,
        height: 64,
        child: Center(
          child: PressScale(
            onTap: onTap,
            scale: 0.92,
            child: Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: c.primary,
                shape: BoxShape.circle,
                border: Border.all(color: c.surface, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: c.primary.withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(
                Icons.camera_alt_rounded,
                size: 25,
                color: c.onPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final activeColor = c.primaryDeep;
    final idleColor = c.inkTertiary;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
              decoration: BoxDecoration(
                color: selected
                    ? c.primary.withValues(alpha: 0.14)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                switchInCurve: Curves.easeOutCubic,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(scale: animation, child: child),
                ),
                child: Icon(
                  selected ? selectedIcon : icon,
                  key: ValueKey<bool>(selected),
                  size: 24,
                  color: selected ? activeColor : idleColor,
                ),
              ),
            ),
            const SizedBox(height: 3),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: context.ui(
                  11.5,
                  weight: FontWeight.w600,
                  color: selected ? activeColor : idleColor,
                  letterSpacing: 0.2,
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
