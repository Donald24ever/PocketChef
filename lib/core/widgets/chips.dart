import 'package:flutter/material.dart';

import '../theme/theme_extensions.dart';
import '../utils/haptics.dart';

class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.icon,
    this.trailing,
    this.onDelete,
    this.color,
    this.dense = false,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;
  final Widget? trailing;
  final VoidCallback? onDelete;
  final Color? color;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final accent = color ?? c.primary;
    return InkWell(
      onTap: onTap == null
          ? null
          : () {
              Haptics.selection();
              onTap!();
            },
      borderRadius: BorderRadius.circular(999),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          height: dense ? 38 : 44,
          padding: EdgeInsets.symmetric(horizontal: icon != null ? 14 : 16),
          decoration: BoxDecoration(
            color: selected ? accent : c.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: selected ? accent : c.hairline),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 17,
                  color: selected ? c.onPrimary : c.inkSecondary,
                ),
                const SizedBox(width: 7),
              ],
              Text(
                label,
                maxLines: 1,
                style: context.ui(
                  14.5,
                  weight: FontWeight.w600,
                  color: selected ? c.onPrimary : c.ink,
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 6), trailing!],
              if (onDelete != null) ...[
                const SizedBox(width: 2),
                GestureDetector(
                  onTap: onDelete,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4, right: 4),
                    child: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: selected ? c.onPrimary : c.inkTertiary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class IngredientChip extends StatelessWidget {
  const IngredientChip({
    super.key,
    required this.label,
    this.confidence,
    this.onDelete,
    this.added = false,
    this.delayedEntrance,
  });

  final String label;
  final double? confidence;
  final VoidCallback? onDelete;
  final bool added;
  final Widget? delayedEntrance;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      height: 44,
      padding: EdgeInsets.only(left: 16, right: onDelete != null ? 4 : 16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: added ? c.olive.withValues(alpha: 0.5) : c.hairline,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: confidence == null
                  ? c.olive
                  : (confidence! >= 0.9 ? c.olive : c.gold),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 9),
          Text(label, style: context.ui(14.5, weight: FontWeight.w600)),
          if (confidence != null) ...[
            const SizedBox(width: 7),
            Text(
              '${(confidence! * 100).round()}%',
              style: context.ui(12, color: c.inkTertiary),
            ),
          ],
          if (onDelete != null)
            InkWell(
              onTap: () {
                Haptics.light();
                onDelete!();
              },
              borderRadius: BorderRadius.circular(999),
              child: SizedBox(
                width: 40,
                height: 44,
                child: Icon(Icons.close, size: 17, color: c.inkTertiary),
              ),
            ),
        ],
      ),
    );
  }
}
