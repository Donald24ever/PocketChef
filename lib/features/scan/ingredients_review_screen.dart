import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/theme_extensions.dart';
import '../../core/utils/haptics.dart';
import '../../core/widgets/artwork.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/chips.dart';
import '../../core/widgets/text_fields.dart';
import '../../data/models/scan.dart';
import '../../state/app_state_provider.dart';
import '../../state/domain_providers.dart';

class IngredientsReviewScreen extends ConsumerStatefulWidget {
  const IngredientsReviewScreen({super.key});

  @override
  ConsumerState<IngredientsReviewScreen> createState() =>
      _IngredientsReviewScreenState();
}

class _IngredientsReviewScreenState
    extends ConsumerState<IngredientsReviewScreen> {
  final _manual = TextEditingController();
  bool _finding = false;

  @override
  void dispose() {
    _manual.dispose();
    super.dispose();
  }

  Future<void> _findRecipes() async {
    if (_finding) return;
    setState(() => _finding = true);
    Haptics.medium();
    try {
      final session = ref.read(scanProvider);
      if (session.detected.isNotEmpty) {
        ref.read(pantryProvider.notifier).addFromDetected(session.detected);
      }
      final suggestions = await ref.read(scanSuggestionsProvider.future);
      if (!mounted) return;
      if (suggestions.matches.isEmpty) {
        setState(() => _finding = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No matches yet — add a few more ingredients and try again.',
            ),
          ),
        );
        return;
      }
      context.go('/recipes?source=scan');
    } catch (_) {
      if (mounted) {
        setState(() => _finding = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Finding recipes failed. Retry?')),
        );
      }
    }
  }

  void _restartScan() {
    Haptics.medium();
    ref.read(scanProvider.notifier).freshStart();
    if (context.canPop()) context.pop();
    context.push('/scan');
  }

  Future<void> _addPhotos() async {
    Haptics.light();
    final source = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          20 + MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Add a photo', style: context.serif(20)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.of(sheetContext).pop('camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from library'),
              onTap: () => Navigator.of(sheetContext).pop('library'),
            ),
            ListTile(
              leading: const Icon(Icons.restart_alt_rounded),
              title: const Text('Start a new scan'),
              onTap: () => Navigator.of(sheetContext).pop('restart'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || source == null) return;

    if (source == 'restart') {
      _restartScan();
      return;
    }

    if (source == 'camera') {
      context.push('/scan', extra: 'keep');
      return;
    }

    try {
      final picked = await ImagePicker().pickMultiImage();
      if (picked.isEmpty) return;
      final notifier = ref.read(scanProvider.notifier);
      for (var i = 0; i < picked.length; i++) {
        final bytes = await picked[i].readAsBytes();
        await notifier.addAndAnalyze(
          ScanImage(
            bytes: bytes,
            seed: (DateTime.now().millisecondsSinceEpoch + i * 613) % 10007,
            label: 'Library',
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the photo library.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final session = ref.watch(scanProvider);
    final profile = ref.watch(appStateProvider).value?.profile;
    final detected = session.detected;

    if (detected.isEmpty && session.phase != ScanPhase.analyzing) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () {
              if (context.canPop()) context.pop();
            },
          ),
        ),
        body: Center(
          child: NoIngredientsView(onScan: () => context.push('/scan')),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(context.hPad, 8, 8, 0),
              child: Row(
                children: [
                  RoundIconButton(
                    icon: Icons.close_rounded,
                    onTap: () {
                      Haptics.light();
                      if (context.canPop()) context.pop();
                    },
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Your ingredients', style: context.serif(26)),
                        Text(
                          '${detected.length} found in ${session.images.length} '
                          '${session.images.length == 1 ? 'photo' : 'photos'}',
                          style: context.ui(13.5, color: c.inkSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 84,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: context.hPad),
                children: [
                  for (final image in session.images)
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: SizedBox(
                          width: 84,
                          height: 84,
                          child: image.hasBytes
                              ? Image.memory(image.bytes!, fit: BoxFit.cover)
                              : DishArtwork(
                                  seed: 'photo-${image.seed}',
                                  radius: 16,
                                ),
                        ),
                      ),
                    ),
                  PressScale(
                    onTap: _addPhotos,
                    child: Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        color: c.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: c.hairline,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_a_photo_rounded,
                            size: 21,
                            color: c.inkSecondary,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Add',
                            style: context.ui(
                              12,
                              weight: FontWeight.w600,
                              color: c.inkSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (session.phase == ScanPhase.analyzing)
              Padding(
                padding: EdgeInsets.fromLTRB(context.hPad, 14, context.hPad, 0),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Updating ingredients…',
                      style: context.ui(13.5, color: c.inkSecondary),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(context.hPad, 0, context.hPad, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (var i = 0; i < detected.length; i++)
                          IngredientChip(
                                label: detected[i].name,
                                confidence: detected[i].sourceSeed == -1
                                    ? null
                                    : detected[i].confidence,
                                onDelete: () {
                                  Haptics.light();
                                  ref
                                      .read(scanProvider.notifier)
                                      .removeDetected(detected[i].name);
                                },
                              )
                              .animate()
                              .fadeIn(
                                duration: 240.ms,
                                delay: (i * 50).ms,
                                curve: Curves.easeOut,
                              )
                              .slideY(
                                begin: 0.2,
                                end: 0,
                                duration: 240.ms,
                                delay: (i * 50).ms,
                                curve: Curves.easeOutCubic,
                              ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            controller: _manual,
                            hint: 'Add something we missed',
                            textInputAction: TextInputAction.done,
                            onSubmitted: (value) {
                              if (value.trim().isEmpty) return;
                              ref.read(scanProvider.notifier).addManual(value);
                              _manual.clear();
                              Haptics.light();
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Semantics(
                          button: true,
                          label: 'Add ingredient',
                          child: PressScale(
                            onTap: () {
                              if (_manual.text.trim().isEmpty) return;
                              ref
                                  .read(scanProvider.notifier)
                                  .addManual(_manual.text);
                              _manual.clear();
                              Haptics.light();
                            },
                            child: Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                color: c.ink,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                Icons.add_rounded,
                                color: c.background,
                                size: 26,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (profile != null && profile.diets.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: c.oliveSoft,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.eco_outlined, size: 19, color: c.olive),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Matching recipes for: '
                                '${profile.diets.map((d) => d.label).join(', ')}',
                                style: context.ui(
                                  13.5,
                                  weight: FontWeight.w600,
                                  color: c.olive,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 26),
                    Text(
                      'LOOKS RIGHT?',
                      style: context.ui(
                        11.5,
                        weight: FontWeight.w700,
                        color: c.inkTertiary,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    PrimaryButton(
                      label: 'Find recipes',
                      loading: _finding,
                      icon: Icons.auto_awesome_rounded,
                      onTap: _finding ? null : _findRecipes,
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: TextButton(
                        onPressed: _finding ? null : _restartScan,
                        child: Text(
                          'Start a new scan',
                          style: context.ui(
                            14.5,
                            weight: FontWeight.w600,
                            color: c.inkSecondary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NoIngredientsView extends StatelessWidget {
  const NoIngredientsView({super.key, required this.onScan});

  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: EdgeInsets.all(context.hPad),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: c.oliveSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.search_off_rounded, size: 38, color: c.olive),
          ),
          const SizedBox(height: 22),
          Text('Nothing to review', style: context.serif(22)),
          const SizedBox(height: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: Text(
              'We could not find ingredients in this scan. Try again with better light.',
              textAlign: TextAlign.center,
              style: context.ui(15, color: c.inkSecondary, height: 1.5),
            ),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'Scan again',
            expanded: false,
            icon: Icons.camera_alt_rounded,
            onTap: onScan,
          ),
        ],
      ),
    );
  }
}
