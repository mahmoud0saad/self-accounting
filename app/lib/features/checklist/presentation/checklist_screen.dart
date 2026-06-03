import 'package:app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/language_toggle_button.dart';
import '../../customization/presentation/providers/catalog_providers.dart';
import '../../customization/presentation/widgets/effective_category_section.dart';
import 'widgets/auth_app_bar_action.dart';
import 'widgets/checklist_progress_header.dart';
import 'widgets/day_picker_bar.dart';
import 'widgets/history_strip.dart';
import 'widgets/streak_pills.dart';
import '../../challenges/presentation/widgets/weekly_challenge_strip.dart';

class ChecklistScreen extends ConsumerWidget {
  const ChecklistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogAsync = ref.watch(effectiveCatalogProvider);
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context); 

    return Scaffold(
      backgroundColor: scheme.surface,
      body: catalogAsync.when(
        data: (catalog) {
          final grouped = catalog.tasksByCategoryKey();
          final hasTasks = catalog.categories.any(
            (cat) => (grouped[cat.key] ?? []).isNotEmpty,
          );

          return CustomScrollView(
            slivers: [
              _checklistSliverAppBar(context, l, scheme, theme),
              SliverToBoxAdapter(
                child: Material(
                  color: scheme.surfaceContainerLow,
                  elevation: 1,
                  child: const Column(
                    children: [
                      DayPickerBar(),
                      // HistoryStrip(),
                      ChecklistProgressHeader(),
                      StreakPills(),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: WeeklyChallengeStrip()),
              if (hasTasks)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      16,
                      16,
                      16,
                      4,
                    ),
                    child: Text(
                      l.tasksSection,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: scheme.onSurfaceVariant,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),
              for (final cat in catalog.categories)
                if ((grouped[cat.key] ?? []).isNotEmpty)
                  SliverToBoxAdapter(
                    child: EffectiveCategorySection(
                      category: cat,
                      tasks: grouped[cat.key]!,
                    ),
                  ),
              SliverToBoxAdapter(child: SizedBox(height: 24 + bottomInset)),
            ],
          );
        },
        loading: () => CustomScrollView(
          slivers: [
            _checklistSliverAppBar(context, l, scheme, theme),
            const SliverToBoxAdapter(child: _ChecklistSkeleton()),
          ],
        ),
        error: (e, _) => CustomScrollView(
          slivers: [
            _checklistSliverAppBar(context, l, scheme, theme),
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        color: scheme.error,
                        size: 40,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$e',
                        textAlign: TextAlign.center,
                        maxLines: 6,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

SliverAppBar _checklistSliverAppBar(
  BuildContext context,
  AppLocalizations l,
  ColorScheme scheme,
  ThemeData theme,
) {
  return SliverAppBar(
    pinned: true,
    floating: false,
    scrolledUnderElevation: 0.5,
    backgroundColor: scheme.surface,
    surfaceTintColor: scheme.surfaceTint,
    title: Text(
      l.appTitle,
      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
    ),
    actions: [
      // PopupMenuButton<String>(
      //   onSelected: (value) {
      //     if (value == 'manage') {
      //       context.push('/manage');
      //     }
      //   },
      //   itemBuilder: (context) => [
      //     PopupMenuItem(
      //       value: 'manage',
      //       child: Text(l.manageChecklistTitle),
      //     ),
      //   ],
      // ),
      const AuthAppBarAction(),
      const LanguageToggleButton(),
    ],
  );
}

class _ChecklistSkeleton extends StatelessWidget {
  const _ChecklistSkeleton();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final placeholder = scheme.surfaceContainerHighest;

    Widget block({required double height, double radius = 12}) {
      return Container(
        height: height,
        decoration: BoxDecoration(
          color: placeholder,
          borderRadius: BorderRadius.circular(radius),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 24),
      child: Column(
        children: [
          block(height: 68, radius: 20),
          const SizedBox(height: 12),
          block(height: 58, radius: 8),
          const SizedBox(height: 12),
          block(height: 120, radius: 24),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: block(height: 36, radius: 999)),
              const SizedBox(width: 8),
              Expanded(child: block(height: 36, radius: 999)),
            ],
          ),
          const SizedBox(height: 16),
          block(height: 56, radius: 12),
          const SizedBox(height: 24),
          block(height: 20, radius: 4),
          const SizedBox(height: 12),
          block(height: 140, radius: 16),
          const SizedBox(height: 12),
          block(height: 140, radius: 16),
        ],
      ),
    );
  }
}
