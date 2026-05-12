import 'package:app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/task.dart';
import '../providers/checklist_state_provider.dart';

class TaskRow extends ConsumerWidget {
  const TaskRow({super.key, required this.task});

  final Task task;

  void _toggle(WidgetRef ref) {
    HapticFeedback.selectionClick();
    ref.read(checklistStateProvider.notifier).toggle(task.id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final title = task.titleResolver(l);
    final isChecked = ref.watch(
      checklistStateProvider.select((m) => m[task.id] ?? false),
    );

    final stateLabel = isChecked ? l.taskStateChecked : l.taskStateUnchecked;

    return Semantics(
      label: l.taskRowSemanticLabel(title, task.points, stateLabel),
      toggled: isChecked,
      button: true,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _toggle(ref),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            padding: const EdgeInsetsDirectional.fromSTEB(10, 10, 10, 10),
            decoration: BoxDecoration(
              color: isChecked
                  ? scheme.primary.withValues(alpha: 0.07)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _AnimatedCheck(isChecked: isChecked),
                const SizedBox(width: 12),
                Expanded(
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 220),
                    style:
                        theme.textTheme.bodyLarge?.copyWith(
                          color: isChecked
                              ? scheme.onSurface.withValues(alpha: 0.55)
                              : scheme.onSurface,
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
                    child: Text(title),
                  ),
                ),
                const SizedBox(width: 8),
                _PointsBadge(points: task.points, dim: isChecked, l: l),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedCheck extends StatelessWidget {
  const _AnimatedCheck({required this.isChecked});

  final bool isChecked;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
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
