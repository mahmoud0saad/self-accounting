import 'package:app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Full-screen empty state shown when the active dashboard window has no
/// recorded activity. Mission-aligned encouraging copy + CTA that switches to
/// the Checklist tab (D10).
class DashboardEmptyState extends StatelessWidget {
  const DashboardEmptyState({super.key, required this.onOpenChecklist});

  final VoidCallback onOpenChecklist;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l = AppLocalizations.of(context)!;

    return Center(
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.insights_outlined,
              size: 56,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              l.dashboardEmptyTitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l.dashboardEmptyBody,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onOpenChecklist,
              icon: const Icon(Icons.checklist_rtl_rounded),
              label: Text(l.dashboardEmptyCtaLabel),
            ),
          ],
        ),
      ),
    );
  }
}
