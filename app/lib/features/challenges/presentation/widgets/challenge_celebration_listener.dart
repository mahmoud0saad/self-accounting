import 'package:app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/challenge_repository.dart';
import '../../domain/challenge_models.dart';
import '../challenge_l10n.dart';
import '../providers/challenge_providers.dart';

/// Shows the completion modal when a challenge newly completes.
class ChallengeCelebrationListener extends ConsumerStatefulWidget {
  const ChallengeCelebrationListener({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<ChallengeCelebrationListener> createState() =>
      _ChallengeCelebrationListenerState();
}

class _ChallengeCelebrationListenerState
    extends ConsumerState<ChallengeCelebrationListener> {
  final Set<String> _shown = {};

  @override
  Widget build(BuildContext context) {
    ref.listen(challengeCelebrationProvider, (prev, next) {
      if (next == null) {
        return;
      }
      final week = next.week!;
      final key = '${next.challenge.id}:${week.weekStart}';
      if (_shown.contains(key)) {
        return;
      }
      _shown.add(key);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _showModal(context, next);
      });
    });
    return widget.child;
  }

  Future<void> _showModal(BuildContext context, ChallengeWithWeek item) async {
    final l = AppLocalizations.of(context)!;
    final title = challengeDisplayTitle(l, item.challenge);
    final goal = item.challenge.goalCount;
    final scheme = Theme.of(context).colorScheme;

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        backgroundColor: scheme.surface,
        title: Text(l.challengeCelebrationTitle),
        content: Text(l.challengeCelebrationBody(title, goal)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.push('/challenges');
            },
            child: Text(l.challengeViewChallenge),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: scheme.primary,
            ),
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l.challengeContinue),
          ),
        ],
      ),
    );

    final week = item.week!;
    await ref.read(challengeRepositoryProvider).markCelebrationSeen(
          item.challenge.id,
          week.weekStart,
        );
    ref.invalidate(currentWeekProgressProvider);
  }
}
