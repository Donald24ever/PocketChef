import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

class RouteGuard {
  RouteGuard._();

  static final Map<String, int> _last = {};

  static Future<void> push(
    BuildContext context,
    String location, {
    Object? extra,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final previous = _last[location] ?? 0;
    if (now - previous < 600) return;
    _last[location] = now;
    await context.push<void>(location, extra: extra);
  }

  static void reset() => _last.clear();
}