import 'package:app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../customization/presentation/providers/catalog_providers.dart';
import '../data/challenge_repository.dart';
import '../domain/challenge_models.dart';
import 'challenge_l10n.dart';
import 'providers/challenge_providers.dart';

class ChallengesScreen extends ConsumerStatefulWidget {
  const ChallengesScreen({super.key});

  @override
  ConsumerState<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends ConsumerState<ChallengesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.challengesThisWeekTab),
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            Tab(text: l.challengesThisWeekTab),
            Tab(text: l.challengesBrowseTab),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          const _ThisWeekTab(),
          _BrowseTab(onSubscribed: () => _tabs.animateTo(0)),
        ],
      ),
    );
  }
}

class _ThisWeekTab extends ConsumerWidget {
  const _ThisWeekTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final progress = ref.watch(currentWeekProgressProvider);

    return progress.when(
      data: (items) {
        if (items.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                l.challengeStartThisWeek,
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) => _ChallengeCard(
            item: items[i],
            onToggle: (archived) async {
              final repo = ref.read(challengeRepositoryProvider);
              await repo.setArchived(
                items[i].challenge.id,
                archived: archived,
              );
              ref.invalidate(currentWeekProgressProvider);
              ref.invalidate(activeUserChallengesProvider);
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  const _ChallengeCard({required this.item, required this.onToggle});

  final ChallengeWithWeek item;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final title = challengeDisplayTitle(l, item.challenge);
    final achieved = item.week?.achievedCount ?? 0;
    final goal = item.challenge.goalCount;
    final frac = goal == 0 ? 0.0 : (achieved / goal).clamp(0.0, 1.0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Switch(
              value: !item.challenge.isArchived,
              onChanged: (v) => onToggle(!v),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: frac, minHeight: 6),
                  const SizedBox(height: 4),
                  Text(l.challengeProgress(achieved, goal)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrowseTab extends ConsumerWidget {
  const _BrowseTab({required this.onSubscribed});

  final VoidCallback onSubscribed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final templates = ref.watch(challengeTemplatesProvider);
    final active = ref.watch(activeUserChallengesProvider);

    return templates.when(
      data: (list) {
        final subscribed = active.asData?.value
                ?.map((c) => c.templateCode)
                .whereType<String>()
                .toSet() ??
            {};

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final t in list)
              ListTile(
                title: Text(_templateTitle(l, t.code, t.defaultTitle)),
                subtitle: Text(l.challengeProgress(0, t.goalCount)),
                trailing: FilledButton.tonal(
                  onPressed: subscribed.contains(t.code)
                      ? null
                      : () => _subscribe(ref, context, t.code),
                  child: Text(
                    subscribed.contains(t.code)
                        ? l.challengeSubscribed
                        : l.challengeSubscribe,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => _showCreateSheet(context, ref),
              icon: const Icon(Icons.add),
              label: Text(l.challengeCreateCustom),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
    );
  }

  String _templateTitle(AppLocalizations l, String code, String fallback) {
    final c = UserChallenge(
      id: '',
      templateCode: code,
      startedAt: DateTime.now(),
      updatedAt: DateTime.now(),
      template: ChallengeTemplate(
        code: code,
        defaultTitle: fallback,
        defaultIcon: 'star',
        sourceKind: 'TASK_WEEKLY_COUNT',
        sourceRef: '',
        goalCount: 7,
        defaultSortOrder: 0,
        isActive: true,
      ),
    );
    return challengeDisplayTitle(l, c);
  }

  Future<void> _subscribe(
    WidgetRef ref,
    BuildContext context,
    String code,
  ) async {
    try {
      await ref.read(challengeRepositoryProvider).subscribeToTemplate(code);
      ref.invalidate(activeUserChallengesProvider);
      ref.invalidate(currentWeekProgressProvider);
      onSubscribed();
    } on Object catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    }
  }

  Future<void> _showCreateSheet(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context)!;
    final titleCtrl = TextEditingController();
    var goal = 7;

    final catalog = ref.read(effectiveCatalogProvider).asData?.value;
    if (catalog == null || catalog.tasks.isEmpty) {
      return;
    }
    var taskId = catalog.tasks.first.id;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: 16 + MediaQuery.viewPaddingOf(ctx).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: InputDecoration(labelText: l.manageChecklistNameLabel),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: taskId,
              items: [
                for (final t in catalog.tasks)
                  DropdownMenuItem(value: t.id, child: Text(t.displayName)),
              ],
              onChanged: (v) {
                if (v != null) {
                  taskId = v;
                }
              },
            ),
            Slider(
              value: goal.toDouble(),
              min: 1,
              max: 7,
              divisions: 6,
              label: '$goal',
              onChanged: (v) => goal = v.round(),
            ),
            FilledButton(
              onPressed: () async {
                final name = titleCtrl.text.trim();
                if (name.length < 2) {
                  return;
                }
                await ref.read(challengeRepositoryProvider).createCustom(
                      title: name,
                      icon: 'star',
                      sourceKind: 'TASK_WEEKLY_COUNT',
                      sourceRef: taskId,
                      goalCount: goal,
                    );
                ref.invalidate(activeUserChallengesProvider);
                ref.invalidate(currentWeekProgressProvider);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  onSubscribed();
                }
              },
              child: Text(l.manageChecklistSave),
            ),
          ],
        ),
      ),
    );
  }
}
