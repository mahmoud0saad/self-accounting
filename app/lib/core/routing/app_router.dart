import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/checklist/presentation/checklist_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/shell/presentation/root_shell.dart';

final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _checklistKey = GlobalKey<NavigatorState>(debugLabel: 'checklist');
final _dashboardKey = GlobalKey<NavigatorState>(debugLabel: 'dashboard');

/// Central router. Two branches share a top-level [RootShell] so each tab
/// preserves its state across switches (Phase 4 D1).
final GoRouter appRouter = GoRouter(
  navigatorKey: _rootKey,
  initialLocation: '/',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => RootShell(shell: shell),
      branches: [
        StatefulShellBranch(
          navigatorKey: _checklistKey,
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const ChecklistScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _dashboardKey,
          routes: [
            GoRoute(
              path: '/dashboard',
              builder: (context, state) => const DashboardScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);
