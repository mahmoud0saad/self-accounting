import 'package:app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../customization/presentation/providers/catalog_providers.dart';
import '../data/challenge_repository.dart';
import '../domain/challenge_models.dart';
import 'challenge_l10n.dart';
import 'challenge_template_groups.dart';
import 'providers/challenge_providers.dart';
import 'widgets/custom_challenge_sheet.dart';

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
          _ThisWeekTab(onBrowse: () => _tabs.animateTo(1)),
          _BrowseTab(onSubscribed: () => _tabs.animateTo(0)),
        ],
      ),
    );
  }
}

class _ThisWeekTab extends ConsumerWidget {
  const _ThisWeekTab({required this.onBrowse});

  final VoidCallback onBrowse;

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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l.challengeStartThisWeek,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.tonal(
                    onPressed: onBrowse,
                    child: Text(l.challengeBrowseTemplatesCta),
                  ),
                ],
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
    final catalog = ref.watch(effectiveCatalogProvider).asData?.value;

    return templates.when(
      data: (list) {
        final subscribed = active.maybeWhen(
          data: (challenges) => challenges
              .map((c) => c.templateCode)
              .whereType<String>()
              .toSet(),
          orElse: () => <String>{},
        );

        final grouped = groupChallengeTemplates(list);
        final groupKeys = grouped.keys.toList()
          ..sort((a, b) {
            final catA = catalog?.categories
                .where((c) => c.key == a)
                .map((c) => c.sortOrder)
                .firstOrNull;
            final catB = catalog?.categories
                .where((c) => c.key == b)
                .map((c) => c.sortOrder)
                .firstOrNull;
            return (catA ?? 99).compareTo(catB ?? 99);
          });

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final groupKey in groupKeys) ...[
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: Text(
                  catalog?.categories
                          .where((c) => c.key == groupKey)
                          .map((c) => c.displayName)
                          .firstOrNull ??
                      groupKey,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              for (final t in grouped[groupKey]!)
                ListTile(
                  title: Text(_templateTitle(l, t)),
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
            ],
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => showCustomChallengeSheet(
                context,
                ref,
                onCreated: onSubscribed,
              ),
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

  String _templateTitle(AppLocalizations l, ChallengeTemplate t) {
    final c = UserChallenge(
      id: '',
      templateCode: t.code,
      startedAt: DateTime.now(),
      updatedAt: DateTime.now(),
      template: t,
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
}
