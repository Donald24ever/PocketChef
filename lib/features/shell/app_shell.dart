import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_bottom_bar.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: shell,
      bottomNavigationBar: AppBottomBar(shell: shell),
    );
  }
}
