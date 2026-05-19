import 'dart:math' as math;

import 'package:app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/time/day_key.dart';
import '../../../challenges/presentation/providers/challenge_providers.dart';
import '../../../customization/domain/catalog_models.dart';
import '../providers/checklist_repositories_provider.dart';
import '../providers/checklist_state_provider.dart';

class EffectiveTaskRow extends ConsumerWidget {
  const EffectiveTaskRow({super.key, required this.task});

  final EffectiveTask task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final activeDay = ref.watch(activeDayProvider);
    final today = DayKey.today();
    final daysAgo = today.daysSince(activeDay);
    final readOnly = daysAgo < 0 || daysAgo >= kMaxEditableDays;

    final checklistAsync = ref.watch(checklistStateProvider);
    final isChecked = checklistAsync.maybeWhen(
      data: (m) => m[task.id] ?? false,
      orElse: () => false,
    );
    final weekBadge = ref.watch(completedChallengeWeekBadgesProvider);
    final showWeekComplete = weekBadge.showsForTask(task.id, task.categoryKey);

    final stateLabel = isChecked ? l.taskStateChecked : l.taskStateUnchecked;
    final semanticsLabel = readOnly
        ? '${l.taskRowSemanticLabel(task.displayName, task.points, stateLabel)}, ${l.readOnlyBadge}'
        : l.taskRowSemanticLabel(task.displayName, task.points, stateLabel);

    void onToggle() {
      if (readOnly) {
        return;
      }
      HapticFeedback.selectionClick();
      ref.read(checklistControllerProvider).toggle(task.id);
    }

    final maxTitleWidth = math.min(
      280.0,
      MediaQuery.sizeOf(context).width - 48,
    );

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
              color: isChecked
                  ? scheme.primary.withValues(alpha: readOnly ? 0.04 : 0.07)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // _AnimatedCheck(isChecked: isChecked, dimmed: readOnly),
                // const SizedBox(width: 12),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxTitleWidth),
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 220),
                    style:
                        theme.textTheme.bodyLarge?.copyWith(
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
                      task.displayName ,
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
                  points: task.points,
                  dim: isChecked || readOnly,
                  l: l,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedCheck extends StatelessWidget {
  const _AnimatedCheck({required this.isChecked, required this.dimmed});

  final bool isChecked;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 220),
      opacity: dimmed ? 0.45 : 1,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutBack,
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: isChecked ? scheme.primary : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(
            color: isChecked
                ? scheme.primary
                : scheme.outline.withValues(alpha: 0.6),
            width: 2,
          ),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          transitionBuilder: (child, anim) =>
              ScaleTransition(scale: anim, child: child),
          child: isChecked
              ? Icon(
                  Icons.check_rounded,
                  key: const ValueKey('on'),
                  color: scheme.onPrimary,
                  size: 18,
                )
              : const SizedBox.shrink(key: ValueKey('off')),
        ),
      ),
    );
  }
}

class _PointsBadge extends StatelessWidget {
  const _PointsBadge({
    required this.points,
    required this.dim,
    required this.l,
  });

  final int points;
  final bool dim;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 220),
      opacity: dim ? 0.55 : 1.0,
      child: Container(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: 10,
          vertical: 5,
        ),
        decoration: BoxDecoration(
          color: scheme.primaryContainer,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.star_rounded,
              size: 14,
              color: scheme.onPrimaryContainer,
            ),
            const SizedBox(width: 4),
            Text(
              '$points ${l.pointsLabel}',
              style: text.labelMedium?.copyWith(
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
