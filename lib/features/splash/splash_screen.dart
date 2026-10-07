import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/theme_extensions.dart';
import '../../core/widgets/artwork.dart';
import '../../state/app_state_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 1300), _navigate);
  }

  void _navigate() {
    if (!mounted || _navigated) return;
    final session = ref.read(sessionProvider);
    if (!session.ready) {
      Timer(const Duration(milliseconds: 300), _navigate);
      return;
    }
    _navigated = true;
    final target = !session.onboarded
        ? '/onboarding'
        : !session.authed
        ? '/welcome'
        : '/home';
    context.go(target);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Scaffold(
      backgroundColor: c.background,
      body: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) => Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: Transform.scale(scale: 0.88 + value * 0.12, child: child),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const LogoMark(size: 76),
              const SizedBox(height: 22),
              Text('PocketChef', style: context.serif(34, height: 1.1)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: c.oliveSoft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'COOK WHAT YOU HAVE',
                  style: context.ui(
                    11.5,
                    weight: FontWeight.w700,
                    color: c.olive,
                    letterSpacing: 1.4,
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
