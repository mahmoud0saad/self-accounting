import 'dart:collection';

import 'package:app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/language_toggle_button.dart';
import 'widgets/auth_app_bar_action.dart';
import '../domain/task.dart';
import 'providers/task_catalog_provider.dart';
import 'widgets/category_section.dart';
import 'widgets/checklist_progress_header.dart';
import 'widgets/day_picker_bar.dart';
import 'widgets/history_strip.dart';
import 'widgets/streak_pills.dart';

LinkedHashMap<TaskCategory, List<Task>> _groupByCategoryInOrder(
  List<Task> tasks,
) {
  final LinkedHashMap<TaskCategory, List<Task>> map = LinkedHashMap();
  for (final t in tasks) {
    map.putIfAbsent(t.category, () => <Task>[]).add(t);
  }
  return map;
}

class ChecklistScreen extends ConsumerWidget {
  const ChecklistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(taskCatalogProvider);
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
        actions: const [AuthAppBarAction(), LanguageToggleButton()],
      ),
      body: tasksAsync.when(
        data: (tasks) {
          final grouped = _groupByCategoryInOrder(tasks);
          return CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(child: DayPickerBar()),
              const SliverToBoxAdapter(child: HistoryStrip()),
              const SliverToBoxAdapter(child: ChecklistProgressHeader()),
              const SliverToBoxAdapter(child: StreakPills()),
              for (final entry in grouped.entries)
                SliverToBoxAdapter(
                  child: CategorySection(
                    category: entry.key,
                    tasks: entry.value,
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
