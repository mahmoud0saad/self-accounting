import 'package:app/l10n/app_localizations.dart';

import '../../checklist/data/static_task_catalog.dart';
import '../../checklist/domain/task.dart';
import '../domain/catalog_models.dart';

/// Default categories aligned with [TaskCategory] and notification keys.
List<DefaultCategory> buildDefaultCategories(AppLocalizations l) {
  return [
    DefaultCategory(
      code: TaskCategory.fajr.name,
      defaultName: l.categoryFajr,
      defaultIcon: 'wb_twilight',
      defaultSortOrder: 0,
      isFard: true,
    ),
    DefaultCategory(
      code: TaskCategory.dhuhr.name,
      defaultName: l.categoryDhuhr,
      defaultIcon: 'wb_sunny',
      defaultSortOrder: 1,
      isFard: true,
    ),
    DefaultCategory(
      code: TaskCategory.asr.name,
      defaultName: l.categoryAsr,
      defaultIcon: 'partly_cloudy_day',
      defaultSortOrder: 2,
      isFard: true,
    ),
    DefaultCategory(
      code: TaskCategory.maghrib.name,
      defaultName: l.categoryMaghrib,
      defaultIcon: 'wb_twilight',
      defaultSortOrder: 3,
      isFard: true,
    ),
    DefaultCategory(
      code: TaskCategory.isha.name,
      defaultName: l.categoryIsha,
      defaultIcon: 'nights_stay',
      defaultSortOrder: 4,
      isFard: true,
    ),
    DefaultCategory(
      code: TaskCategory.qiyamEvening.name,
      defaultName: l.categoryQiyamEvening,
      defaultIcon: 'bedtime',
      defaultSortOrder: 5,
      isFard: false,
    ),
    DefaultCategory(
      code: TaskCategory.quranFasting.name,
      defaultName: l.categoryQuranFasting,
      defaultIcon: 'menu_book',
      defaultSortOrder: 6,
      isFard: false,
    ),
    DefaultCategory(
      code: TaskCategory.miscAdhkar.name,
      defaultName: l.categoryMiscAdhkar,
      defaultIcon: 'auto_awesome',
      defaultSortOrder: 7,
      isFard: false,
    ),
  ];
}

List<DefaultTask> buildDefaultTasks(AppLocalizations l) {
  var order = 0;
  return [
    for (final t in staticTaskCatalog)
      DefaultTask(
        code: t.id,
        defaultName: t.titleResolver(l),
        categoryCode: t.category.name,
        defaultPoints: t.points,
        defaultIcon: 'star',
        defaultSortOrder: order++,
      ),
  ];
}
