import 'package:app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/time/day_key.dart';
import '../providers/checklist_repositories_provider.dart';
import '../providers/checklist_state_provider.dart';
import '../providers/daily_progress_provider.dart';

class ChecklistProgressHeader extends ConsumerWidget {
  const ChecklistProgressHeader({super.key});

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.resetTodayDialogTitle),
        content: Text(l.resetTodayDialogBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.resetTodayDialogCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              l.resetTodayDialogConfirm,
              style: TextStyle(color: Theme.of(ctx).colorScheme.primary),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await ref.read(checklistControllerProvider).resetActiveDay();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(dailyProgressProvider);
    final activeDay = ref.watch(activeDayProvider);
    final today = DayKey.today();
    // Phase 3 D11 / V13: read-only pill only on days ≥ 2 in the past.
    // Today and yesterday are editable (D2 / kMaxEditableDays = 2).
    final daysAgo = today.daysSince(activeDay);
    final isEditable = daysAgo >= 0 && daysAgo < 2;
    final readOnly = !isEditable;

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l = AppLocalizations.of(context)!;

    final progress = progressAsync.maybeWhen(
      data: (p) => p,
      orElse: () => null,
    );

    final fraction = progress?.fraction ?? 0.0;
    final percentInt = progress?.percentInt ?? 0;
    final isComplete = fraction >= 1.0;

    final child = Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 8),
      child: Container(
        padding: const EdgeInsetsDirectional.fromSTEB(20, 20, 20, 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: AlignmentDirectional.topStart,
            end: AlignmentDirectional.bottomEnd,
            colors: [
              scheme.primaryContainer,
              Color.alphaBlend(
                scheme.primary.withValues(alpha: 0.10),
                scheme.surfaceContainerHighest,
              ),
            ],
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (readOnly)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(bottom: 6),
                      child: Container(
                        padding: const EdgeInsetsDirectional.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          l.readOnlyBadge,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  if (progressAsync.isLoading)
                    Text(
                      l.loadingChecklist,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: scheme.onPrimaryContainer.withValues(alpha: 0.9),
                      ),
                    )
                  else ...[
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: percentInt.toDouble()),
                      duration: const Duration(milliseconds: 320),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) {
                        return Text(
                          '${value.round()}%',
                          style: theme.textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: scheme.onPrimaryContainer,
                            height: 1.05,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 6),
                    Text(
                      progress == null
                          ? '—'
                          : l.pointsRatio(
                              progress.completedPoints,
                              progress.totalPoints,
                            ),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onPrimaryContainer.withValues(
                          alpha: 0.85,
                        ),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      progress == null
                          ? '—'
                          : '${progress.completedTasks} / ${progress.totalTasks}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: scheme.onPrimaryContainer.withValues(
                          alpha: 0.65,
                        ),
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 16),
            if (!progressAsync.isLoading && progress != null)
              _ProgressRing(fraction: fraction, complete: isComplete),
          ],
        ),
      ),
    );

    if (!isEditable) {
      return child;
    }

    return GestureDetector(
      onLongPress: () => _confirmReset(context, ref),
      child: child,
    );
  }
}

class _ProgressRing extends StatelessWidget {
  const _ProgressRing({required this.fraction, required this.complete});

  final double fraction;
  final bool complete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 88,
      height: 88,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: fraction.clamp(0.0, 1.0)),
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        builder: (context, value, _) {
          return Stack(
            alignment: AlignmentDirectional.center,
            children: [
              SizedBox.expand(
                child: CircularProgressIndicator(
                  value: value,
                  strokeWidth: 8,
                  strokeCap: StrokeCap.round,
                  backgroundColor: scheme.onPrimaryContainer.withValues(
                    alpha: 0.12,
                  ),
                  valueColor: AlwaysStoppedAnimation<Color>(scheme.primary),
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                transitionBuilder: (child, anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: complete
                    ? Icon(
                        Icons.check_rounded,
                        key: const ValueKey('done'),
                        color: scheme.primary,
                        size: 36,
                      )
                    : Icon(
                        Icons.local_florist_rounded,
                        key: const ValueKey('grow'),
                        color: scheme.primary.withValues(alpha: 0.85),
                        size: 28,
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
