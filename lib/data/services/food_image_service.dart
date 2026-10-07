import 'dart:convert';

import 'package:http/http.dart' as http;

/// Resolves real food photography for recipes that do not carry a baked-in
/// image (the AI-generated ones).
///
/// Sources are tried in order and every network call is best-effort: a
/// failure just leaves the recipe on its generated artwork.
class FoodImageService {
  FoodImageService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// TheMealDB's public demo endpoint — free, no key required.
  static const String _mealDbHost = 'https://www.themealdb.com/api/json/v1/1';

  static final Map<String, String?> _cache = {};

  /// Returns a URL for [title], or `null` when no source knows the dish.
  /// Repeated lookups for the same title are served from memory.
  Future<String?> lookup(String title) async {
    final key = title.trim().toLowerCase();
    if (key.isEmpty) return null;
    if (_cache.containsKey(key)) return _cache[key];

    final url = await _searchMealDb(key) ?? await _searchMealDb(_words(key));
    _cache[key] = url;
    return url;
  }

  Future<String?> _searchMealDb(String query) async {
    if (query.isEmpty) return null;
    try {
      final uri = Uri.parse('$_mealDbHost/search.php').replace(
        queryParameters: {'s': query},
      );
      final response = await _client
          .get(uri)
          .timeout(const Duration(seconds: 6));
      if (response.statusCode != 200) return null;
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return null;
      final meals = decoded['meals'];
      if (meals is! List || meals.isEmpty) return null;
      final first = meals.first;
      if (first is! Map<String, dynamic>) return null;
      final thumb = first['strMealThumb'];
      if (thumb is String && thumb.startsWith('http')) return thumb;
    } catch (_) {
      // Offline or rate-limited: fall through.
    }
    return null;
  }

  /// First two words of the title — meal names are often long for the demo
  /// endpoint's exact-ish matching.
  String _words(String title) {
    final parts = title.split(RegExp(r'\s+')).where((w) => w.length > 2);
    return parts.take(2).join(' ');
  }

  void dispose() => _client.close();
}
