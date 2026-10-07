import 'package:flutter/material.dart';

import '../theme/theme_extensions.dart';
import '../theme/app_colors.dart';
import '../utils/haptics.dart';

class PressScale extends StatefulWidget {
  const PressScale({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 0.97,
    this.duration = const Duration(milliseconds: 120),
  });

  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final Duration duration;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final interactive = widget.onTap != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: interactive
          ? () {
              Haptics.light();
              widget.onTap!();
            }
          : null,
      onTapDown: interactive ? (_) => setState(() => _pressed = true) : null,
      onTapUp: interactive ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: interactive ? () => setState(() => _pressed = false) : null,
      child: AnimatedScale(
        scale: _pressed ? widget.scale : 1,
        duration: widget.duration,
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.onTap,
    this.loading = false,
    this.icon,
    this.expanded = true,
    this.danger = false,
  });

  final String label;
  final VoidCallback? onTap;
  final bool loading;
  final IconData? icon;
  final bool expanded;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final enabled = onTap != null && !loading;
    final background = danger ? c.error : c.primary;
    final foreground = danger ? Colors.white : c.onPrimary;

    final button = PressScale(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 26),
        decoration: BoxDecoration(
          color: enabled ? background : background.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(18),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: background.withValues(alpha: 0.32),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (loading)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: foreground,
                ),
              )
            else if (icon != null) ...[
              Icon(icon, size: 21, color: foreground),
              const SizedBox(width: 10),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.ui(
                  16,
                  weight: FontWeight.w700,
                  color: foreground,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (!expanded) {
      return Semantics(
        button: true,
        enabled: enabled,
        label: label,
        child: button,
      );
    }
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: SizedBox(width: double.infinity, child: button),
    );
  }
}

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    this.onTap,
    this.icon,
    this.expanded = true,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final button = PressScale(
      onTap: onTap,
      child: Container(
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: context.c.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: context.c.hairline),
        ),
        child: Row(
          mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20, color: context.c.ink),
              const SizedBox(width: 10),
            ],
            Text(label, style: context.ui(16, weight: FontWeight.w600)),
          ],
        ),
      ),
    );
    if (!expanded) {
      return Semantics(button: true, label: label, child: button);
    }
    return Semantics(
      button: true,
      label: label,
      child: SizedBox(width: double.infinity, child: button),
    );
  }
}

Color? _autoForeground(AppPalette c, Color? background) {
  if (background == null) return c.ink;
  return ThemeData.estimateBrightnessForColor(background) == Brightness.dark
      ? c.onFeatureSurface
      : c.featureSurface;
}

class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.color,
    this.background,
    this.size = 48,
    this.iconSize = 22,
    this.badge,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final Color? color;
  final Color? background;
  final double size;
  final double iconSize;
  final int? badge;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final Color? foreground = color ?? _autoForeground(c, background);
    final button = PressScale(
      onTap: onTap,
      child: SizedBox(
        width: size,
        height: size,
        child: Material(
          color: background ?? c.surface,
          shape: CircleBorder(
            side: background == null
                ? BorderSide(color: c.hairline)
                : BorderSide.none,
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Padding(
                padding: EdgeInsets.all((size - iconSize) / 2 - 2),
                child: Icon(icon, size: iconSize, color: foreground),
              ),
              if (badge != null && badge! > 0)
                Positioned(
                  top: 7,
                  right: 7,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: c.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    if (tooltip == null) {
      return Semantics(button: true, label: tooltip, child: button);
    }
    return Semantics(
      button: true,
      label: tooltip,
      child: Tooltip(message: tooltip!, child: button),
    );
  }
}
