import 'package:app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/streak.dart';
import '../providers/checklist_repositories_provider.dart';
import '../providers/streak_provider.dart';

/// "Current" + "Best" streak pills displayed below [ChecklistProgressHeader].
/// Mission-aligned tone — no shaming copy when the streak is zero (D7).
class StreakPills extends ConsumerWidget {
  const StreakPills({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streakAsync = ref.watch(streakProvider);
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 4, 16, 12),
      child: streakAsync.maybeWhen(
        data: (streak) => _PillRow(streak: streak, l: l, scheme: scheme),
        orElse: () => const SizedBox(height: 0),
      ),
    );
  }
}

class _PillRow extends StatelessWidget {
  const _PillRow({required this.streak, required this.l, required this.scheme});

  final Streak streak;
  final AppLocalizations l;
  final ColorScheme scheme;

  String _currentLabel() {
    if (streak.current == 0) {
      return l.streakCurrentEmpty;
    }
    return l.streakCurrentLabel(streak.current);
  }

  String _longestLabel() {
    final base = l.streakLongestLabel(streak.longest);
    final hitCap =
        streak.longest >= kMaxHistoryDays &&
        streak.windowDays >= kMaxHistoryDays;
    return hitCap ? '$base ${l.streakLongestWindowQualifier}' : base;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Flexible(
          child: _Pill(
            icon: Icons.local_fire_department_rounded,
            label: _currentLabel(),
            scheme: scheme,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: _Pill(
            icon: Icons.workspace_premium_rounded,
            label: _longestLabel(),
            scheme: scheme,
          ),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.label, required this.scheme});

  final IconData icon;
  final String label;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: scheme.onSecondaryContainer),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: text.labelLarge?.copyWith(
                color: scheme.onSecondaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
