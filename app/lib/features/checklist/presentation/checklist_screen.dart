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

class ChecklistScreen extends ConsumerWidget {
  const ChecklistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogAsync = ref.watch(effectiveCatalogProvider);
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        backgroundColor: scheme.surface,
        scrolledUnderElevation: 0.5,
        surfaceTintColor: scheme.surfaceTint,
        title: Text(
          l.appTitle,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'manage') {
                context.push('/manage');
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'manage',
                child: Text(l.manageChecklistTitle),
              ),
            ],
          ),
          const AuthAppBarAction(),
          const LanguageToggleButton(),
        ],
      ),
      body: catalogAsync.when(
        data: (catalog) {
          final grouped = catalog.tasksByCategoryKey();
          return CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(child: DayPickerBar()),
              // const SliverToBoxAdapter(child: HistoryStrip()),
              const SliverToBoxAdapter(child: ChecklistProgressHeader()),
              const SliverToBoxAdapter(child: StreakPills()),
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
        loading: () => Center(child: Text(l.loadingChecklist)),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }
}
