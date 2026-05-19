import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:network_logger/network_logger.dart';

import '../../features/auth/presentation/confirm_email_screen.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/sign_in_screen.dart';
import '../../features/auth/presentation/sign_up_screen.dart';
import '../../features/checklist/presentation/checklist_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/settings/data/app_settings_repository.dart';
import '../../features/settings/presentation/notification_onboarding_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/shell/presentation/root_shell.dart';
import '../../features/sync/data/sync_service.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _checklistKey = GlobalKey<NavigatorState>(debugLabel: 'checklist');
final _dashboardKey = GlobalKey<NavigatorState>(debugLabel: 'dashboard');
final _settingsKey = GlobalKey<NavigatorState>(debugLabel: 'settings');

/// Central router. Three branches share a top-level [RootShell] so each tab
/// preserves its state across switches (Phase 4 D1).
final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefreshNotifier();
  ref.onDispose(refresh.dispose);
  ref.listen(authNotifierProvider, (_, __) => refresh.refresh());

  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) async {
      final auth = ref.read(authNotifierProvider);
      final loc = state.matchedLocation;
      final isAuthRoute = loc.startsWith('/auth');
      final isOnboarding = loc == '/onboarding/notifications';

      if (auth.status == AuthStatus.unknown) {
        return null;
      }

      if (auth.status == AuthStatus.emailPending && loc != '/auth/confirm') {
        return '/auth/confirm';
      }

      if (auth.status == AuthStatus.authenticated && isAuthRoute) {
        return '/';
      }

      final done = await ref
          .read(appSettingsRepositoryProvider)
          .getNotificationOnboardingDone();
      if (!done && !isOnboarding && !isAuthRoute) {
        return '/onboarding/notifications';
      }
      if (done && isOnboarding) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/auth/sign-in',
        builder: (context, state) =>
            const _DebugNetworkLoggerAttach(child: SignInScreen()),
      ),
      GoRoute(
        path: '/auth/sign-up',
        builder: (context, state) =>
            const _DebugNetworkLoggerAttach(child: SignUpScreen()),
      ),
      GoRoute(
        path: '/auth/confirm',
        builder: (context, state) =>
            const _DebugNetworkLoggerAttach(child: ConfirmEmailScreen()),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) =>
            const _DebugNetworkLoggerAttach(child: ProfileScreen()),
      ),
      GoRoute(
        path: '/onboarding/notifications',
        builder: (context, state) => const _DebugNetworkLoggerAttach(
          child: NotificationOnboardingScreen(),
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => RootShell(shell: shell),
        branches: [
          StatefulShellBranch(
            navigatorKey: _checklistKey,
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) =>
                    const _DebugNetworkLoggerAttach(child: ChecklistScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _dashboardKey,
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (context, state) =>
                    const _DebugNetworkLoggerAttach(child: DashboardScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _settingsKey,
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) =>
                    const _DebugNetworkLoggerAttach(child: SettingsScreen()),
              ),
            ],
          ),
        ],
      ),
    ],
  );

  // Sync on every route/tab change. The in-flight guard inside
  // SyncService.syncNow collapses bursts so this stays cheap.
  String? lastLocation;
  void onRouteChange() {
    final loc = router.routerDelegate.currentConfiguration.uri.toString();
    if (loc == lastLocation) {
      return;
    }
    lastLocation = loc;
    // Fire-and-forget; offline / unauth runs are no-ops inside syncNow.
    ref.read(syncServiceProvider).syncNow();
  }

  router.routerDelegate.addListener(onRouteChange);
  ref.onDispose(() => router.routerDelegate.removeListener(onRouteChange));

  return router;
});

class _RouterRefreshNotifier extends ChangeNotifier {
  void refresh() => notifyListeners();
}

class _DebugNetworkLoggerAttach extends StatefulWidget {
  const _DebugNetworkLoggerAttach({required this.child});

  final Widget child;

  @override
  State<_DebugNetworkLoggerAttach> createState() =>
      _DebugNetworkLoggerAttachState();
}

class _DebugNetworkLoggerAttachState extends State<_DebugNetworkLoggerAttach> {
  static OverlayEntry? _entry;

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _attach());
    }
  }

  void _attach() {
    if (_entry != null || !mounted) {
      return;
    }
    if (Overlay.maybeOf(context, rootOverlay: true) == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _attach());
      return;
    }
    _entry = NetworkLoggerOverlay.attachTo(context);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
