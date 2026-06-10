import 'package:app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../challenges/presentation/providers/challenge_providers.dart';
import '../../../customization/domain/catalog_models.dart';
import '../providers/checklist_state_provider.dart';
import '../providers/effective_task_row_state_provider.dart';

/// Max width of a single task chip when laid out in a [Wrap].
const double kEffectiveTaskRowMaxWidth = 280;

class EffectiveTaskRow extends ConsumerWidget {
  const EffectiveTaskRow({super.key, required this.task});

  final EffectiveTask task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final (readOnly, isChecked, challengeVisual) = ref.watch(
      effectiveTaskRowStateProvider(task.id).select(
        (s) => (s.readOnly, s.isChecked, s.challengeVisual),
      ),
    );
    final showWeekComplete = ref.watch(
      effectiveTaskRowStateProvider(task.id).select((s) => s.showWeekComplete),
    );

    final stateLabel = isChecked ? l.taskStateChecked : l.taskStateUnchecked;
    final challengeHint = switch (challengeVisual) {
      TaskChallengeVisualState.pending => l.challengeTaskPendingThisDay,
      TaskChallengeVisualState.contributed => l.challengeTaskContributedThisDay,
      _ => null,
    };
    final baseSemantics = l.taskRowSemanticLabel(
      task.displayName,
      task.points,
      stateLabel,
    );
    final semanticsLabel = readOnly
        ? '$baseSemantics, ${l.readOnlyBadge}'
        : challengeHint == null
        ? baseSemantics
        : '$baseSemantics, $challengeHint';

    void onToggle() {
      if (readOnly) {
        return;
      }
      HapticFeedback.selectionClick();
      ref.read(checklistControllerProvider).toggle(task.id).catchError((_) {
        if (!context.mounted) {
          return;
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.taskToggleFailed)));
      });
    }

    final challengeFill = effectiveTaskRowChallengeFillColor(
      challengeVisual,
      scheme,
      readOnly,
    );
    final challengeBorder = effectiveTaskRowChallengeBorder(
      challengeVisual,
      scheme,
      readOnly,
    );
    final containerFill = isChecked
        ? scheme.primary.withValues(alpha: readOnly ? 0.04 : 0.07)
        : challengeFill ?? Colors.transparent;

    return Semantics(
      label: semanticsLabel,
      toggled: isChecked,
      button: !readOnly,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: readOnly ? null : onToggle,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            padding: const EdgeInsetsDirectional.fromSTEB(10, 10, 10, 10),
            decoration: BoxDecoration(
              color: containerFill,
              border: challengeBorder,
              borderRadius: BorderRadius.circular(14),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: kEffectiveTaskRowMaxWidth,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 220),
                      style:
                          theme.textTheme.bodyMedium?.copyWith(
                            color: isChecked
                                ? scheme.onSurface.withValues(
                                    alpha: readOnly ? 0.4 : 0.55,
                                  )
                                : scheme.onSurface.withValues(
                                    alpha: readOnly ? 0.55 : 1.0,
                                  ),
                            decoration: isChecked
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                            decorationColor: scheme.onSurface.withValues(
                              alpha: 0.45,
                            ),
                            decorationThickness: 1.5,
                            fontWeight: isChecked
                                ? FontWeight.w400
                                : FontWeight.w500,
                          ) ??
                          const TextStyle(),
                      child: Text(
                        task.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  if (showWeekComplete) ...[
                    const SizedBox(width: 6),
                    Tooltip(
                      message: l.challengeCompletedThisWeek,
                      child: Container(
                        padding: const EdgeInsetsDirectional.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          l.challengeCompletedThisWeek,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(width: 8),
                  _PointsBadge(
                    taskId: task.id,
                    points: task.points,
                    l: l,
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

class _PointsBadge extends ConsumerWidget {
  const _PointsBadge({
    required this.taskId,
    required this.points,
    required this.l,
  });

  final String taskId;
  final int points;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dim = ref.watch(
      effectiveTaskRowStateProvider(taskId).select(
        (s) => s.isChecked || s.readOnly,
      ),
    );
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 220),
      opacity: dim ? 0.55 : 1.0,
      child: Container(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: 4,
          vertical: 5,
        ),
        decoration: BoxDecoration(
          color: scheme.primaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.star_rounded,
              size: 10,
              color: scheme.onPrimaryContainer,
            ),
            Text(
              '$points ${l.pointsLabel}',
              style: text.labelSmall?.copyWith(
                color: scheme.onPrimaryContainer,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
