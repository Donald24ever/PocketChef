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

  /// Wikimedia Commons — free, no key required, and far more complete than
  /// TheMealDB for everyday dishes (it is where the catalog's own photos
  /// come from).
  static const String _commonsHost = 'https://commons.wikimedia.org/w/api.php';

  static const String _userAgent = 'PocketChef/1.0 (+https://pocketchef.app)';

  /// Words that carry no dish information — dropping them turns
  /// "Classic scrambled eggs with Feta" into queries the sources can match.
  static const Set<String> _filler = {
    'a',
    'an',
    'the',
    'and',
    'with',
    'of',
    'in',
    'on',
    'for',
    'style',
    'styles',
    'recipe',
    'recipes',
    'dish',
    'dishes',
    'meal',
    'meals',
    'classic',
    'best',
    'easy',
    'quick',
    'simple',
    'homemade',
    'traditional',
    'perfect',
    'fresh',
  };

  static final Map<String, String?> _cache = {};

  /// Returns a URL for [title], or `null` when no source knows the dish.
  /// Repeated lookups for the same title are served from memory.
  Future<String?> lookup(String title) async {
    final key = title.trim().toLowerCase();
    if (key.isEmpty) return null;
    if (_cache.containsKey(key)) return _cache[key];

    String? url;
    for (final query in _queries(key)) {
      url = await _searchMealDb(query) ?? await _searchCommons(query);
      if (url != null) break;
    }
    _cache[key] = url;
    return url;
  }

  /// Candidate search terms, most specific first: the full title, then
  /// progressively shorter versions built from the words that actually name
  /// the dish, ending on the single most descriptive word.
  List<String> _queries(String title) {
    final words = title
        .split(RegExp(r'\s+'))
        .where((w) => w.contains(RegExp(r'[A-Za-z0-9]')))
        .toList(growable: false);
    final significant =
        words.where((w) => !_filler.contains(w)).toList(growable: false);
    final candidates = <String>[];
    void add(String query) {
      final trimmed = query.trim();
      if (trimmed.isEmpty || candidates.contains(trimmed)) return;
      candidates.add(trimmed);
    }

    add(title);
    if (significant.length >= 3) add(significant.take(3).join(' '));
    if (significant.length >= 2) add(significant.take(2).join(' '));
    if (significant.isNotEmpty) {
      significant.sort((a, b) => b.length.compareTo(a.length));
      add(significant.first);
    }
    return candidates;
  }

  Future<String?> _searchMealDb(String query) async {
    if (query.isEmpty) return null;
    try {
      final uri = Uri.parse('$_mealDbHost/search.php').replace(
        queryParameters: {'s': query},
      );
      final response = await _client
          .get(uri, headers: {'User-Agent': _userAgent})
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

  /// Searches Wikimedia Commons and returns the result whose filename shares
  /// the most words with [query], so a stray keyword cannot hand back an
  /// unrelated photo. Results that share nothing with the query are rejected
  /// so the caller can try a shorter query instead.
  Future<String?> _searchCommons(String query) async {
    if (query.isEmpty) return null;
    try {
      final uri = Uri.parse(_commonsHost).replace(queryParameters: {
        'action': 'query',
        'format': 'json',
        'generator': 'search',
        'gsrnamespace': '6',
        'gsrlimit': '10',
        'gsrsearch': 'filetype:bitmap $query',
        'prop': 'imageinfo',
        'iiprop': 'url',
        'iiurlwidth': '960',
      });
      final response = await _client
          .get(uri, headers: {'User-Agent': _userAgent})
          .timeout(const Duration(seconds: 6));
      if (response.statusCode != 200) return null;
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return null;
      final queryMap = decoded['query'];
      if (queryMap is! Map<String, dynamic>) return null;
      final pages = queryMap['pages'];
      if (pages is! Map<String, dynamic> || pages.isEmpty) return null;

      final results = <(int, String, String)>[];
      for (final page in pages.values) {
        if (page is! Map<String, dynamic>) continue;
        final title = page['title'];
        final info = page['imageinfo'];
        if (title is! String || info is! List || info.isEmpty) continue;
        final first = info.first;
        if (first is! Map<String, dynamic>) continue;
        final url = (first['thumburl'] ?? first['url']);
        if (url is! String || !url.startsWith('http')) continue;
        final index = page['index'];
        results.add((
          index is int ? index : results.length,
          title,
          url.split('?').first,
        ));
      }
      if (results.isEmpty) return null;
      results.sort((a, b) => a.$1.compareTo(b.$1));

      final terms = query
          .split(RegExp(r'\s+'))
          .where((w) => w.length > 1)
          .toList(growable: false);
      // A one-word hit ("eggs") is not enough once the query has more words,
      // otherwise a longer query resolves to a worse photo than a shorter one.
      final required = terms.length >= 2 ? 2 : 1;
      var best = 0;
      var bestUrl = '';
      for (final (_, title, url) in results) {
        final score = _overlap(terms, title);
        if (score > best) {
          best = score;
          bestUrl = url;
        }
      }
      return best >= required && bestUrl.isNotEmpty ? bestUrl : null;
    } catch (_) {
      // Offline or rate-limited: fall through.
    }
    return null;
  }

  /// How many of [terms] appear in the Commons file name (or vice versa),
  /// so "Scrambled egg.jpg" scores for both "scrambled" and "eggs".
  int _overlap(Iterable<String> terms, String fileName) {
    final tokens = fileName
        .toLowerCase()
        .split(RegExp(r'[^a-z0-9]+'))
        .where((t) => t.length > 1)
        .toList(growable: false);
    var score = 0;
    for (final term in terms) {
      for (final token in tokens) {
        if (token == term || token.startsWith(term) || term.startsWith(token)) {
          score++;
          break;
        }
      }
    }
    return score;
  }

  void dispose() => _client.close();
}
