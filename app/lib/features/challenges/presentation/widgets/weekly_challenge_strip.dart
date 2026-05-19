import 'package:app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../customization/presentation/providers/catalog_providers.dart';
import '../../domain/challenge_models.dart';
import '../challenge_l10n.dart';
import '../providers/challenge_providers.dart';

class WeeklyChallengeStrip extends ConsumerWidget {
  const WeeklyChallengeStrip({super.key});

  static const double _maxHeight = 56;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogAsync = ref.watch(effectiveCatalogProvider);
    if (catalogAsync.isLoading || catalogAsync.hasError) {
      return const SizedBox.shrink();
    }

    final progressAsync = ref.watch(currentWeekProgressProvider);
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    return progressAsync.when(
      data: (items) {
        if (items.isEmpty) {
          return _ZeroState(l: l, scheme: scheme);
        }
        if (items.length == 1) {
          return _SingleRow(item: items.first, l: l, scheme: scheme);
        }
        return _ChipRow(items: items, l: l, scheme: scheme);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _ZeroState extends StatelessWidget {
  const _ZeroState({required this.l, required this.scheme});

  final AppLocalizations l;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 8),
      child: Material(
        color: scheme.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => context.push('/challenges'),
          borderRadius: BorderRadius.circular(12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: WeeklyChallengeStrip._maxHeight),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l.challengeStartThisWeek,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: scheme.onPrimaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  Icon(Icons.chevron_right, color: scheme.onPrimaryContainer),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SingleRow extends StatelessWidget {
  const _SingleRow({
    required this.item,
    required this.l,
    required this.scheme,
  });

  final ChallengeWithWeek item;
  final AppLocalizations l;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final title = challengeDisplayTitle(l, item.challenge);
    final achieved = item.week?.achievedCount ?? 0;
    final goal = item.challenge.goalCount;
    final frac = goal == 0 ? 0.0 : (achieved / goal).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 8),
      child: Material(
        color: scheme.secondaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => context.push('/challenges'),
          borderRadius: BorderRadius.circular(12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: WeeklyChallengeStrip._maxHeight),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                      Text(
                        l.challengeProgress(achieved, goal),
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: frac,
                    minHeight: 4,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChipRow extends StatelessWidget {
  const _ChipRow({
    required this.items,
    required this.l,
    required this.scheme,
  });

  final List<ChallengeWithWeek> items;
  final AppLocalizations l;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 8),
      child: SizedBox(
        height: WeeklyChallengeStrip._maxHeight,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, i) {
            final item = items[i];
            final achieved = item.week?.achievedCount ?? 0;
            final goal = item.challenge.goalCount;
            return ActionChip(
              label: Text(
                '${challengeDisplayTitle(l, item.challenge)}  ${l.challengeProgress(achieved, goal)}',
                overflow: TextOverflow.ellipsis,
              ),
              onPressed: () => context.push('/challenges'),
            );
          },
        ),
      ),
    );
  }
}
