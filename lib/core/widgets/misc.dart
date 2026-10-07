import 'package:flutter/material.dart';

import '../theme/theme_extensions.dart';
import '../utils/haptics.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.padding = const EdgeInsets.fromLTRB(20, 28, 12, 4),
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.serif(23, height: 1.2)),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: context.ui(13.5, color: c.inkSecondary),
                  ),
                ],
              ],
            ),
          ),
          if (actionLabel != null)
            TextButton(
              onPressed: () {
                Haptics.light();
                onAction?.call();
              },
              child: Text(actionLabel!),
            ),
        ],
      ),
    );
  }
}

class MetaPill extends StatelessWidget {
  const MetaPill({
    super.key,
    required this.icon,
    required this.label,
    this.tone = Tone.neutral,
  });

  final IconData icon;
  final String label;
  final Tone tone;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final (bg, fg) = switch (tone) {
      Tone.neutral => (c.surfaceAlt, c.inkSecondary),
      Tone.primary => (c.primary.withValues(alpha: 0.14), c.primaryDeep),
      Tone.olive => (c.oliveSoft, c.olive),
    };
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 11),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: fg),
          const SizedBox(width: 6),
          Text(
            label,
            style: context.ui(12.5, weight: FontWeight.w600, color: fg),
          ),
        ],
      ),
    );
  }
}

enum Tone { neutral, primary, olive }

class RatingLabel extends StatelessWidget {
  const RatingLabel({super.key, required this.rating, required this.count});

  final double rating;
  final int count;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star_rounded, size: 17, color: c.gold),
        const SizedBox(width: 4),
        Text(
          rating.toStringAsFixed(1),
          style: context.ui(13.5, weight: FontWeight.w700),
        ),
        const SizedBox(width: 4),
        Text('($count)', style: context.ui(13, color: c.inkTertiary)),
      ],
    );
  }
}

class BusyButton extends StatefulWidget {
  const BusyButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.done = false,
  });

  final String label;
  final Future<void> Function() onPressed;
  final bool done;

  @override
  State<BusyButton> createState() => _BusyButtonState();
}

class _BusyButtonState extends State<BusyButton> {
  bool _busy = false;

  Future<void> _run() async {
    if (_busy) return;
    setState(() => _busy = true);
    Haptics.light();
    try {
      await widget.onPressed();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return InkWell(
      onTap: _run,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: c.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_busy)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: c.primaryDeep,
                ),
              )
            else
              Icon(
                widget.done ? Icons.check_rounded : Icons.add_rounded,
                size: 19,
                color: c.primaryDeep,
              ),
            const SizedBox(width: 8),
            Text(
              _busy ? 'Working…' : widget.label,
              style: context.ui(
                14.5,
                weight: FontWeight.w700,
                color: c.primaryDeep,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
