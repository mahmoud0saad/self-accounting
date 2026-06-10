class ChallengeTemplate {
  const ChallengeTemplate({
    required this.code,
    required this.defaultTitle,
    required this.defaultIcon,
    required this.sourceKind,
    required this.sourceRef,
    required this.goalCount,
    required this.defaultSortOrder,
    required this.isActive,
  });

  final String code;
  final String defaultTitle;
  final String defaultIcon;
  final String sourceKind;
  final String sourceRef;
  final int goalCount;
  final int defaultSortOrder;
  final bool isActive;
}

class UserChallenge {
  const UserChallenge({
    required this.id,
    this.templateCode,
    this.customTitle,
    this.customIcon,
    this.customSourceKind,
    this.customSourceRef,
    this.customGoalCount,
    required this.startedAt,
    this.archivedAt,
    required this.updatedAt,
    this.template,
  });

  final String id;
  final String? templateCode;
  final String? customTitle;
  final String? customIcon;
  final String? customSourceKind;
  final String? customSourceRef;
  final int? customGoalCount;
  final DateTime startedAt;
  final DateTime? archivedAt;
  final DateTime updatedAt;
  final ChallengeTemplate? template;

  bool get isArchived => archivedAt != null;

  String get displayTitleFallback =>
      template?.defaultTitle ?? customTitle ?? '';

  String displayIcon() {
    if (template != null) {
      return template!.defaultIcon;
    }
    return customIcon ?? 'star';
  }

  String get sourceKind =>
      template?.sourceKind ?? customSourceKind ?? 'TASK_WEEKLY_COUNT';

  String get sourceRef => template?.sourceRef ?? customSourceRef ?? '';

  int get goalCount => template?.goalCount ?? customGoalCount ?? 7;

  /// Custom goals above 7 count distinct completion days since [startedAt].
  bool get usesCumulativeProgress =>
      templateCode == null && (customGoalCount ?? 0) > 7;
}

class ChallengeWeek {
  const ChallengeWeek({
    required this.id,
    required this.userChallengeId,
    required this.weekStart,
    required this.weekEnd,
    required this.goalCount,
    required this.achievedCount,
    required this.status,
    this.completedAt,
    this.celebrationSeenAt,
    required this.updatedAt,
  });

  final String id;
  final String userChallengeId;
  final String weekStart;
  final String weekEnd;
  final int goalCount;
  final int achievedCount;
  final String status;
  final DateTime? completedAt;
  final DateTime? celebrationSeenAt;
  final DateTime updatedAt;

  bool get isCompleted => status == 'COMPLETED';
}

class ChallengeWithWeek {
  const ChallengeWithWeek({
    required this.challenge,
    this.week,
  });

  final UserChallenge challenge;
  final ChallengeWeek? week;
}
