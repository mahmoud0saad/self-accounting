import 'package:app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Top-level Material 3 [NavigationBar] shell that hosts the two app branches
/// (Checklist, Dashboard) inside a [StatefulShellRoute.indexedStack].
///
/// Each branch keeps its widget tree alive across switches, so providers and
/// scroll positions survive tab changes (D1).
class RootShell extends StatelessWidget {
  const RootShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (i) =>
            shell.goBranch(i, initialLocation: i == shell.currentIndex),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.checklist),
            selectedIcon: const Icon(Icons.checklist_rtl_rounded),
            label: l.navChecklistLabel,
          ),
          NavigationDestination(
            icon: const Icon(Icons.insights),
            selectedIcon: const Icon(Icons.insights_rounded),
            label: l.navDashboardLabel,
          ),
        ],
      ),
    );
  }
}
