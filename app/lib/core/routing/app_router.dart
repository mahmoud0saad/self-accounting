import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/auth_state_provider.dart';
import '../../features/auth/presentation/sign_in_screen.dart';
import '../../features/auth/presentation/sign_up_screen.dart';
import '../../features/checklist/presentation/checklist_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/settings/data/app_settings_repository.dart';
import '../../features/settings/presentation/notification_onboarding_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/shell/presentation/root_shell.dart';

final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _checklistKey = GlobalKey<NavigatorState>(debugLabel: 'checklist');
final _dashboardKey = GlobalKey<NavigatorState>(debugLabel: 'dashboard');
final _settingsKey = GlobalKey<NavigatorState>(debugLabel: 'settings');

/// Central router. Three branches share a top-level [RootShell] so each tab
/// preserves its state across switches (Phase 4 D1).
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/',
    redirect: (context, state) async {
      final location = state.matchedLocation;
      final authPath =
          location == '/auth/sign-in' || location == '/auth/sign-up';
      final auth = ref.read(authStateProvider);

      if (auth.isSignedIn && authPath) {
        return '/';
      }

      final onboardingPath = location == '/onboarding/notifications';
      final done = await ref
          .read(appSettingsRepositoryProvider)
          .getNotificationOnboardingDone();
      if (!done && !onboardingPath && !authPath) {
        return '/onboarding/notifications';
      }
      if (done && onboardingPath) {
        return '/';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding/notifications',
        builder: (context, state) => const NotificationOnboardingScreen(),
      ),
      GoRoute(
        path: '/auth/sign-in',
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: '/auth/sign-up',
        builder: (context, state) => const SignUpScreen(),
      ),
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
          StatefulShellBranch(
            navigatorKey: _settingsKey,
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
