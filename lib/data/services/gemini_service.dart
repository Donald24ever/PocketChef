import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/app_config.dart';

/// Thrown when the Gemini backend cannot satisfy a request.
class GeminiException implements Exception {
  const GeminiException(this.message);

  final String message;

  @override
  String toString() => 'GeminiException: $message';
}

/// Thin client over the Gemini REST API.
///
/// The API key is read from [AppConfig] (a `--dart-define` value) and sent in
/// the `x-goog-api-key` header, so it never appears in a URL or a log line.
class GeminiService {
  GeminiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const String _host = 'https://generativelanguage.googleapis.com';

  bool get isConfigured => AppConfig.hasGeminiKey;

  /// Detects the ingredients visible in an image and returns their names.
  Future<List<String>> detectIngredients({
    required List<int> imageBytes,
    required String mimeType,
  }) async {
    final text = await _generate([
      {
        'text': 'List the food ingredients visible in this image. '
            'Return only a comma-separated list of ingredient names, '
            'lowercase, with no extra commentary.',
      },
      {
        'inline_data': {
          'mime_type': mimeType,
          'data': base64Encode(imageBytes),
        },
      },
    ]);

    return text
        .split(',')
        .map((ingredient) => ingredient.trim().toLowerCase())
        .where((ingredient) => ingredient.isNotEmpty)
        .toList(growable: false);
  }

  /// Generates recipe text from a free-form prompt.
  Future<String> generateRecipe({required String prompt}) {
    return _generate([
      {'text': prompt},
    ]);
  }

  /// Generates a structured meal-plan answer (JSON) from [prompt].
  Future<String> generateMealPlan({required String prompt}) {
    return _generate([
      {'text': prompt},
    ]);
  }

  Future<String> _generate(List<Map<String, Object>> parts) async {
    if (!isConfigured) {
      throw const GeminiException('Gemini API key is not configured.');
    }

    final uri = Uri.parse(
      '$_host/v1beta/models/${AppConfig.geminiModel}:generateContent',
    );

    final http.Response response;
    try {
      response = await _client
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'x-goog-api-key': AppConfig.geminiApiKey,
            },
            body: jsonEncode({
              'contents': [
                {'parts': parts},
              ],
            }),
          )
          .timeout(const Duration(seconds: 90));
    } on TimeoutException {
      throw const GeminiException('Gemini took too long to respond. Try again.');
    }

    if (response.statusCode != 200) {
      throw GeminiException(
        'Gemini request failed with status ${response.statusCode}.',
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return _extractText(decoded);
  }

  String _extractText(Map<String, dynamic> json) {
    final candidates = json['candidates'];
    if (candidates is! List || candidates.isEmpty) return '';

    final content = (candidates.first as Map<String, dynamic>)['content'];
    if (content is! Map<String, dynamic>) return '';

    final parts = content['parts'];
    if (parts is! List || parts.isEmpty) return '';

    final text = (parts.first as Map<String, dynamic>)['text'];
    return text is String ? text.trim() : '';
  }

  void dispose() => _client.close();
}