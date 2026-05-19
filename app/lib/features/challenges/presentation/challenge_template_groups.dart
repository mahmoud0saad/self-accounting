import '../../checklist/data/static_task_catalog.dart';
import '../../checklist/domain/task.dart';
import '../domain/challenge_models.dart';

String challengeTemplateGroupKey(ChallengeTemplate template) {
  if (template.sourceKind == 'CATEGORY_WEEKLY_COUNT') {
    return template.sourceRef;
  }
  for (final t in staticTaskCatalog) {
    if (t.id == template.sourceRef) {
      return _categoryCodeFor(t.category);
    }
  }
  return 'misc';
}

String _categoryCodeFor(TaskCategory category) {
  return switch (category) {
    TaskCategory.fajr => 'fajr',
    TaskCategory.dhuhr => 'dhuhr',
    TaskCategory.asr => 'asr',
    TaskCategory.maghrib => 'maghrib',
    TaskCategory.isha => 'isha',
    TaskCategory.qiyamEvening => 'qiyamEvening',
    TaskCategory.quranFasting => 'quranFasting',
    TaskCategory.miscAdhkar => 'miscAdhkar',
  };
}

Map<String, List<ChallengeTemplate>> groupChallengeTemplates(
  List<ChallengeTemplate> templates,
) {
  final grouped = <String, List<ChallengeTemplate>>{};
  for (final t in templates) {
    final key = challengeTemplateGroupKey(t);
    grouped.putIfAbsent(key, () => []).add(t);
  }
  for (final list in grouped.values) {
    list.sort((a, b) => a.defaultSortOrder.compareTo(b.defaultSortOrder));
  }
  return grouped;
}
