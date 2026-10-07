import 'dart:typed_data';

enum ScanPhase { idle, capturing, analyzing, ready, failed }

class ScanImage {
  const ScanImage({this.bytes, required this.seed, this.label = ''});

  final Uint8List? bytes;
  final int seed;
  final String label;

  bool get hasBytes => bytes != null && bytes!.isNotEmpty;
}

class DetectedIngredient {
  const DetectedIngredient({
    required this.name,
    required this.confidence,
    required this.sourceSeed,
  });

  final String name;
  final double confidence;
  final int sourceSeed;
}

class ScanSession {
  const ScanSession({
    this.images = const [],
    this.detected = const [],
    this.phase = ScanPhase.idle,
    this.error,
  });

  final List<ScanImage> images;
  final List<DetectedIngredient> detected;
  final ScanPhase phase;
  final String? error;

  ScanSession copyWith({
    List<ScanImage>? images,
    List<DetectedIngredient>? detected,
    ScanPhase? phase,
    String? error,
    bool clearError = false,
  }) {
    return ScanSession(
      images: images ?? this.images,
      detected: detected ?? this.detected,
      phase: phase ?? this.phase,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
