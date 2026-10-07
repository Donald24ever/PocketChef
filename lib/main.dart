import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/firebase/firebase_bootstrap.dart';

void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      await FirebaseBootstrap.init();

      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        _report(details.exception, details.stack);
      };

      ErrorWidget.builder = (details) =>
          _FatalErrorView(message: _messageFor(details.exception));

      PlatformDispatcher.instance.onError = (error, stack) {
        _report(error, stack);
        return true;
      };

      runApp(const ProviderScope(child: PocketChefApp()));
    },
    (error, stack) => _report(error, stack),
  );
}

void _report(Object error, StackTrace? stack) {
  FirebaseBootstrap.reportError(error, stack);
  if (kDebugMode) {
    debugPrint('PocketChef error: $error');
    if (stack != null) debugPrintStack(stackTrace: stack);
  }
}

String _messageFor(Object error) =>
    error is FormatException || error is StateError
    ? 'Something went wrong displaying this screen.'
    : 'Something went wrong.';

class _FatalErrorView extends StatelessWidget {
  const _FatalErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: ColoredBox(
        color: const Color(0xFFFBF7F0),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.restaurant_menu_rounded,
                  size: 40,
                  color: Color(0xFFE07A3E),
                ),
                const SizedBox(height: 14),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.4,
                    color: Color(0xFF2B2622),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}