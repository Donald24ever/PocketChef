import '../models/recipe.dart';
import '../models/scan.dart';
import 'ai_service.dart';
import 'gemini_service.dart';

/// [AiService] backed by the Gemini API for image ingredient detection.
///
/// Recipe recommendation stays on the deterministic local matcher (fast,
/// offline, and impossible to hallucinate a dish). Only detection calls the
/// network, and only for images that actually carry bytes — seeded/demo
/// images fall back to the local pipeline, so the app never regresses when a
/// key is absent or the network is down.
class GeminiAiService implements AiService {
  GeminiAiService({GeminiService? client, DemoAiService? matcher})
    : _client = client ?? GeminiService(),
      _matcher = matcher ?? DemoAiService();

  final GeminiService _client;
  final DemoAiService _matcher;

  @override
  Future<List<DetectedIngredient>> detectIngredients(
    List<ScanImage> images,
  ) async {
    final detected = <String, DetectedIngredient>{};
    var usedRemote = false;

    for (final image in images) {
      if (!image.hasBytes) continue;
      final names = await _client.detectIngredients(
        imageBytes: image.bytes!,
        mimeType: 'image/jpeg',
      );
      usedRemote = true;
      for (final name in names) {
        detected.putIfAbsent(
          name,
          () => DetectedIngredient(
            name: name,
            confidence: 0.92,
            sourceSeed: image.seed,
          ),
        );
      }
    }

    if (!usedRemote) return _matcher.detectIngredients(images);
    return detected.values.toList(growable: false);
  }

  @override
  Future<List<RecipeMatch>> suggestRecipes({
    required List<String> ingredients,
    required List<DietTag> diets,
    required List<String> allergies,
  }) {
    return _matcher.suggestRecipes(
      ingredients: ingredients,
      diets: diets,
      allergies: allergies,
    );
  }

  @override
  Future<List<RecipeMatch>> suggestNigerian({
    required List<String> ingredients,
  }) => _matcher.suggestNigerian(ingredients: ingredients);
}