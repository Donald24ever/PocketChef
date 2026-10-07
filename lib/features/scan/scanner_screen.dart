import 'dart:async';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/theme_extensions.dart';
import '../../core/utils/haptics.dart';
import '../../core/widgets/artwork.dart';
import '../../core/widgets/buttons.dart';
import '../../data/models/scan.dart';
import '../../state/domain_providers.dart';

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key, this.keepPrevious = false});

  final bool keepPrevious;

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  CameraController? _camera;
  bool _initializing = true;
  bool _hasCamera = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    if (!widget.keepPrevious) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(scanProvider.notifier).freshStart();
      });
    }
    _initCamera();
  }

  Future<void> _initCamera() async {
    setState(() {
      _initializing = true;
      _hasCamera = false;
    });
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _initializing = false);
        return;
      }
      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _camera = controller;
        _hasCamera = true;
        _initializing = false;
      });
    } catch (_) {
      if (mounted) setState(() => _initializing = false);
    }
  }

  @override
  void dispose() {
    _camera?.dispose();
    super.dispose();
  }

  Future<void> _capture() async {
    if (_busy) return;
    _busy = true;
    Haptics.medium();
    try {
      Uint8List? bytes;
      try {
        final controller = _camera;
        if (controller != null && controller.value.isInitialized) {
          final file = await controller.takePicture();
          bytes = await file.readAsBytes();
        }
      } catch (_) {
        bytes = null;
      }
      final image = ScanImage(
        bytes: bytes,
        seed: DateTime.now().millisecondsSinceEpoch % 10007,
        label: 'Camera',
      );
      await ref.read(scanProvider.notifier).addAndAnalyze(image);
      if (!mounted) return;
      if (ref.read(scanProvider).phase == ScanPhase.ready) {
        if (widget.keepPrevious) {
          if (context.canPop()) context.pop();
        } else {
          context.pushReplacement('/scan/review');
        }
      }
    } finally {
      _busy = false;
    }
  }

  Future<void> _pickPhotos() async {
    if (_busy) return;
    _busy = true;
    Haptics.light();
    try {
      final picked = await ImagePicker().pickMultiImage();
      if (picked.isEmpty) return;
      final notifier = ref.read(scanProvider.notifier);
      for (var i = 0; i < picked.length; i++) {
        final bytes = await picked[i].readAsBytes();
        await notifier.addAndAnalyze(
          ScanImage(
            bytes: bytes,
            seed: (DateTime.now().millisecondsSinceEpoch + i * 977) % 10007,
            label: 'Library',
          ),
        );
      }
      if (mounted && ref.read(scanProvider).phase == ScanPhase.ready) {
        if (widget.keepPrevious) {
          if (context.canPop()) context.pop();
        } else {
          context.pushReplacement('/scan/review');
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the photo library.')),
        );
      }
    } finally {
      _busy = false;
    }
  }

  Future<void> _demoScan() async {
    if (_busy) return;
    _busy = true;
    Haptics.medium();
    try {
      await ref
          .read(scanProvider.notifier)
          .addAndAnalyze(const ScanImage(seed: 42, label: 'Demo'));
      if (!mounted) return;
      if (ref.read(scanProvider).phase == ScanPhase.ready) {
        if (widget.keepPrevious) {
          if (context.canPop()) context.pop();
        } else {
          context.pushReplacement('/scan/review');
        }
      }
    } finally {
      _busy = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(scanProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF141210),
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_hasCamera && _camera != null)
            CameraPreview(_camera!)
          else
            _FallbackView(
              initializing: _initializing,
              onDemo: _demoScan,
              onPick: _pickPhotos,
            ),
          if (_hasCamera) const _ViewfinderOverlay(),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  child: Row(
                    children: [
                      Semantics(
                        button: true,
                        label: 'Close scanner',
                        child: _GlassIconButton(
                          icon: Icons.close_rounded,
                          onTap: () {
                            Haptics.light();
                            if (context.canPop()) context.pop();
                          },
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Scan your kitchen',
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.ui(
                            15,
                            weight: FontWeight.w700,
                            color: const Color(0xFFFFFBF4),
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                const Spacer(),
                if (_hasCamera) ...[
                  Text(
                    'Fridge, freezer, shelf or a single item',
                    style: context.ui(
                      13.5,
                      color: const Color(0xFFFFFBF4).withValues(alpha: 0.75),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _GlassIconButton(
                          icon: Icons.photo_library_outlined,
                          onTap: _pickPhotos,
                          tooltip: 'Pick photos',
                        ),
                        _ShutterButton(onPressed: _capture),
                        _GlassIconButton(
                          icon: Icons.tips_and_updates_outlined,
                          onTap: () => _showTips(context),
                          tooltip: 'Scanning tips',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 44),
                ] else
                  const SizedBox(height: 120),
              ],
            ),
          ),
          if (session.phase == ScanPhase.analyzing) const _AnalyzingOverlay(),
          if (session.phase == ScanPhase.failed)
            _FailedOverlay(
              message: session.error ?? 'Something went wrong.',
              onRetry: () {
                Haptics.light();
                ref.read(scanProvider.notifier).analyzeExistingImages();
              },
              onClose: () {
                Haptics.light();
                if (context.canPop()) context.pop();
              },
            ),
        ],
      ),
    );
  }

  void _showTips(BuildContext context) {
    Haptics.light();
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          20,
          24,
          24 + MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Get a better scan', style: context.serif(22)),
            const SizedBox(height: 18),
            _tipRow(
              context,
              Icons.wb_twilight_outlined,
              'Good light beats a close-up — open the fridge door wide.',
            ),
            _tipRow(
              context,
              Icons.center_focus_strong_outlined,
              'Fill the frame, but keep items a hand’s width apart.',
            ),
            _tipRow(
              context,
              Icons.burst_mode_outlined,
              'Add more photos for pantry, freezer and cupboards.',
            ),
            const SizedBox(height: 12),
            PrimaryButton(
              label: 'Got it',
              onTap: () => Navigator.of(sheetContext).pop(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tipRow(BuildContext context, IconData icon, String text) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: c.oliveSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 19, color: c.olive),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: context.ui(14.5, color: c.inkSecondary, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({
    required this.icon,
    required this.onTap,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final button = Semantics(
      button: true,
      label: tooltip,
      child: PressScale(
        onTap: onTap,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFF1B1712).withValues(alpha: 0.55),
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFFFFFBF4).withValues(alpha: 0.16),
            ),
          ),
          child: Icon(icon, size: 22, color: const Color(0xFFFFFBF4)),
        ),
      ),
    );
    if (tooltip == null) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}

class _ShutterButton extends StatelessWidget {
  const _ShutterButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Semantics(
      button: true,
      label: 'Take photo',
      child: PressScale(
        onTap: onPressed,
        scale: 0.9,
        child: Container(
          width: 78,
          height: 78,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFFFFBF4), width: 4),
          ),
          alignment: Alignment.center,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBF4),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.camera_alt_rounded,
              size: 28,
              color: c.primaryDeep,
            ),
          ),
        ),
      ),
    );
  }
}

class _ViewfinderOverlay extends StatelessWidget {
  const _ViewfinderOverlay();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(child: CustomPaint(painter: _BracketPainter()));
  }
}

class _BracketPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final side = w * 0.72;
    final box = Rect.fromCenter(
      center: Offset(w / 2, h * 0.46),
      width: side,
      height: side,
    );
    final paint = Paint()
      ..color = const Color(0xFFFFFBF4).withValues(alpha: 0.92)
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    const len = 34.0;
    final l = box.left;
    final t = box.top;
    final b = box.bottom;
    final r = box.right;
    canvas.drawPath(
      Path()
        ..moveTo(l, t + len)
        ..lineTo(l, t)
        ..lineTo(l + len, t),
      paint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(r - len, t)
        ..lineTo(r, t)
        ..lineTo(r, t + len),
      paint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(l, b - len)
        ..lineTo(l, b)
        ..lineTo(l + len, b),
      paint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(r - len, b)
        ..lineTo(r, b)
        ..lineTo(r, b - len),
      paint,
    );
    canvas.drawOval(
      box.deflate(box.width * 0.18),
      paint
        ..color = const Color(0xFFFFFBF4).withValues(alpha: 0.35)
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(_BracketPainter oldDelegate) => false;
}

class _FallbackView extends StatelessWidget {
  const _FallbackView({
    required this.initializing,
    required this.onDemo,
    required this.onPick,
  });

  final bool initializing;
  final VoidCallback onDemo;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    if (initializing) {
      return Container(
        color: const Color(0xFF141210),
        alignment: Alignment.center,
        child: const SizedBox(
          width: 30,
          height: 30,
          child: CircularProgressIndicator(
            strokeWidth: 2.6,
            color: Color(0xFFFFFBF4),
          ),
        ),
      );
    }
    return Container(
      color: const Color(0xFF141210),
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2620),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.videocam_off_outlined,
                      size: 30,
                      color: Color(0xFFFFFBF4),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Camera unavailable',
                    textAlign: TextAlign.center,
                    style: context.serif(22, color: const Color(0xFFFFFBF4)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No live camera here. Pick photos from your library or run a demo scan.',
                    textAlign: TextAlign.center,
                    style: context.ui(
                      14.5,
                      color: const Color(0xFFFFFBF4).withValues(alpha: 0.7),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(label: 'Run a demo scan', onTap: onDemo),
                  const SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: onPick,
                    icon: Icon(
                      Icons.photo_library_outlined,
                      size: 19,
                      color: const Color(0xFFFFFBF4).withValues(alpha: 0.8),
                    ),
                    label: Text(
                      'Choose photos instead',
                      style: context.ui(
                        15,
                        weight: FontWeight.w600,
                        color: const Color(0xFFFFFBF4).withValues(alpha: 0.8),
                      ),
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

class _AnalyzingOverlay extends StatefulWidget {
  const _AnalyzingOverlay();

  @override
  State<_AnalyzingOverlay> createState() => _AnalyzingOverlayState();
}

class _AnalyzingOverlayState extends State<_AnalyzingOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sweep = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  int _statusIndex = 0;
  Timer? _timer;

  static const _messages = [
    'Reading your photo…',
    'Spotting ingredients…',
    'Naming what we found…',
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 750), (_) {
      if (mounted) {
        setState(() => _statusIndex = (_statusIndex + 1) % _messages.length);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _sweep.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      color: const Color(0xFF141210).withValues(alpha: 0.94),
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 230,
                height: 230,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  color: const Color(0xFF221F19),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    const DishArtwork(seed: 'scanning-frame', radius: 0),
                    AnimatedBuilder(
                      animation: _sweep,
                      builder: (context, _) => Align(
                        alignment: Alignment(0, -1 + 2 * _sweep.value),
                        child: Container(
                          height: 3,
                          margin: const EdgeInsets.symmetric(horizontal: 26),
                          decoration: BoxDecoration(
                            color: c.primary,
                            boxShadow: [
                              BoxShadow(
                                color: c.primary.withValues(alpha: 0.55),
                                blurRadius: 16,
                                spreadRadius: 3,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: c.primary,
                ),
              ),
              const SizedBox(height: 20),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 240),
                child: Text(
                  _messages[_statusIndex],
                  key: ValueKey<int>(_statusIndex),
                  style: context.ui(
                    16,
                    weight: FontWeight.w600,
                    color: const Color(0xFFFFFBF4),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You can add more photos afterwards',
                style: context.ui(
                  13,
                  color: const Color(0xFFFFFBF4).withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FailedOverlay extends StatelessWidget {
  const _FailedOverlay({
    required this.message,
    required this.onRetry,
    required this.onClose,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      color: const Color(0xFF141210).withValues(alpha: 0.96),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 340),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: c.error.withValues(alpha: 0.16),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.error_outline_rounded,
                      size: 32,
                      color: c.error,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'We hit a snag',
                    textAlign: TextAlign.center,
                    style: context.serif(23, color: const Color(0xFFFFFBF4)),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: context.ui(
                      14.5,
                      color: const Color(0xFFFFFBF4).withValues(alpha: 0.72),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 26),
                  PrimaryButton(label: 'Try again', onTap: onRetry),
                  const SizedBox(height: 6),
                  TextButton(
                    onPressed: onClose,
                    child: Text(
                      'Not now',
                      style: context.ui(
                        15,
                        weight: FontWeight.w600,
                        color: const Color(0xFFFFFBF4).withValues(alpha: 0.7),
                      ),
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
