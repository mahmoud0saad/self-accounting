import 'package:app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/challenge_models.dart';
import '../challenge_l10n.dart';
import '../providers/challenge_providers.dart';

class WeeklyChallengeStrip extends ConsumerWidget {
  const WeeklyChallengeStrip({super.key});

  static const double _maxHeight = 56;
  static const double _bottomPadding = 8;
  static const double _slotHeight = _maxHeight + _bottomPadding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final layout = ref.watch(weeklyChallengeStripLayoutProvider);

    final Widget content = switch (layout) {
      WeeklyChallengeStripLayout.zero => _ZeroState(l: l, scheme: scheme),
      WeeklyChallengeStripLayout.single => _SingleRowStrip(l: l, scheme: scheme),
      WeeklyChallengeStripLayout.multi => _ChipRowStrip(l: l, scheme: scheme),
    };

    return SizedBox(
      height: _slotHeight,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, _bottomPadding),
        child: SizedBox(height: _maxHeight, child: content),
      ),
    );
  }
}

class _ZeroState extends StatelessWidget {
  const _ZeroState({required this.l, required this.scheme});

  final AppLocalizations l;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: scheme.primaryContainer.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => context.push('/challenges'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
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
    );
  }
}

class _SingleRowStrip extends ConsumerWidget {
  const _SingleRowStrip({required this.l, required this.scheme});

  final AppLocalizations l;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challenge = ref.watch(
      activeUserChallengesProvider.select(
        (async) => async.value?.firstOrNull,
      ),
    );
    if (challenge == null) {
      return _ZeroState(l: l, scheme: scheme);
    }

    final title = challengeDisplayTitle(l, challenge);

    return Material(
      color: scheme.secondaryContainer.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => context.push('/challenges'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
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
                  _ChallengeProgressText(
                    challengeId: challenge.id,
                    fallbackGoal: challenge.goalCount,
                    l: l,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              _ChallengeProgressBar(
                challengeId: challenge.id,
                fallbackGoal: challenge.goalCount,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChallengeProgressText extends ConsumerWidget {
  const _ChallengeProgressText({
    required this.challengeId,
    required this.fallbackGoal,
    required this.l,
  });

  final String challengeId;
  final int fallbackGoal;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(challengeWeekProgressProvider(challengeId));
    final achieved = progress?.achieved ?? 0;
    final goal = progress?.goal ?? fallbackGoal;

    return Text(
      l.challengeProgress(achieved, goal),
      style: Theme.of(context).textTheme.labelMedium,
    );
  }
}

class _ChallengeProgressBar extends ConsumerWidget {
  const _ChallengeProgressBar({
    required this.challengeId,
    required this.fallbackGoal,
  });

  final String challengeId;
  final int fallbackGoal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(challengeWeekProgressProvider(challengeId));
    final achieved = progress?.achieved ?? 0;
    final goal = progress?.goal ?? fallbackGoal;
    final frac = goal == 0 ? 0.0 : (achieved / goal).clamp(0.0, 1.0);

    return LinearProgressIndicator(
      value: frac,
      minHeight: 4,
      borderRadius: BorderRadius.circular(2),
    );
  }
}

class _ChipRowStrip extends ConsumerWidget {
  const _ChipRowStrip({required this.l, required this.scheme});

  final AppLocalizations l;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challenges = ref.watch(
      activeUserChallengesProvider.select((async) => async.value ?? const []),
    );

    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: challenges.length,
      separatorBuilder: (_, __) => const SizedBox(width: 8),
      itemBuilder: (context, i) {
        final challenge = challenges[i];
        return _ChallengeChip(
          key: ValueKey(challenge.id),
          challenge: challenge,
          l: l,
        );
      },
    );
  }
}

class _ChallengeChip extends ConsumerWidget {
  const _ChallengeChip({
    required super.key,
    required this.challenge,
    required this.l,
  });

  final UserChallenge challenge;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = challengeDisplayTitle(l, challenge);
    final progress = ref.watch(challengeWeekProgressProvider(challenge.id));
    final achieved = progress?.achieved ?? 0;
    final goal = progress?.goal ?? challenge.goalCount;

    return ActionChip(
      label: Text(
        '$title  ${l.challengeProgress(achieved, goal)}',
        overflow: TextOverflow.ellipsis,
      ),
      onPressed: () => context.push('/challenges'),
    );
  }
}
