import 'package:go_router/go_router.dart';

import '../../features/home/presentation/home_screen.dart';

/// Central router. Add feature-local `GoRoute`s here as the app grows.
final GoRouter appRouter = GoRouter(
  routes: [GoRoute(path: '/', builder: (context, state) => const HomeScreen())],
);
