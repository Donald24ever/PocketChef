import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/theme_extensions.dart';
import '../../core/utils/haptics.dart';
import '../../core/widgets/artwork.dart';
import '../../core/widgets/buttons.dart';
import '../../state/app_state_provider.dart';

class _OnboardingPage {
  const _OnboardingPage({
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.variant,
  });

  final String eyebrow;
  final String title;
  final String body;
  final int variant;
}

const _pages = [
  _OnboardingPage(
    eyebrow: 'STEP ONE',
    title: 'Open your fridge',
    body: 'Photograph whatever you have — leftovers, a drawer of veg, that one lonely egg.',
    variant: 0,
  ),
  _OnboardingPage(
    eyebrow: 'STEP TWO',
    title: 'We spot the ingredients',
    body: 'PocketChef reads your photo and names what is really in it. Fix anything we miss.',
    variant: 1,
  ),
  _OnboardingPage(
    eyebrow: 'STEP THREE',
    title: 'Cook something good',
    body: 'Recipes you can make right now, step by step — with a shopping list for the rest.',
    variant: 2,
  ),
];

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    Haptics.medium();
    await ref.read(appStateProvider.notifier).completeOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final isLast = _index == _pages.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 12, 0),
              child: Row(
                children: [
                  Text('PocketChef', style: context.serif(20)),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      Haptics.light();
                      _finish();
                    },
                    child: Text(
                      'Skip',
                      style: context.ui(
                        15,
                        weight: FontWeight.w600,
                        color: c.inkSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) {
                  Haptics.selection();
                  setState(() => _index = i);
                },
                itemBuilder: (context, i) {
                  final page = _pages[i];
                  return SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      context.hPad,
                      12,
                      context.hPad,
                      8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 300),
                            child: AspectRatio(
                              aspectRatio: 1.15,
                              child: OnboardingScene(variant: page.variant),
                            ),
                          ),
                        ),
                        const SizedBox(height: 36),
                        Text(
                          page.eyebrow,
                          style: context.ui(
                            12,
                            weight: FontWeight.w700,
                            color: c.primaryDeep,
                            letterSpacing: 1.6,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          page.title,
                          style: context.serif(34, height: 1.12),
                        ),
                        const SizedBox(height: 14),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 360),
                          child: Text(
                            page.body,
                            style: context.ui(
                              16.5,
                              color: c.inkSecondary,
                              height: 1.55,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pages.length, (i) {
                      final active = i == _index;
                      return GestureDetector(
                        onTap: () {
                          Haptics.selection();
                          _controller.animateToPage(
                            i,
                            duration: const Duration(milliseconds: 280),
                            curve: Curves.easeOutCubic,
                          );
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 240),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: active ? 26 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: active ? c.primary : c.hairline,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 26),
                  PrimaryButton(
                    label: isLast ? 'Start scanning' : 'Continue',
                    onTap: isLast
                        ? () => _finish()
                        : () {
                            Haptics.light();
                            _controller.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOutCubic,
                            );
                          },
                    icon: isLast ? Icons.camera_alt_rounded : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
