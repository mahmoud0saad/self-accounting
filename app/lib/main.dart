import 'package:flutter/material.dart';

import 'core/routing/app_router.dart';

void main() {
  runApp(const MuhasabahApp());
}

class MuhasabahApp extends StatelessWidget {
  const MuhasabahApp({super.key});

  static const Color _seedColor = Color(0xFF4C9A6E);

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.light,
    );

    return MaterialApp.router(
      title: 'Muhasabah',
      theme: ThemeData(colorScheme: colorScheme, useMaterial3: true),
      routerConfig: appRouter,
    );
  }
}
