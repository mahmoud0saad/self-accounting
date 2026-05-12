import 'package:app/l10n/app_localizations.dart';

enum TaskCategory {
  fajr,
  dhuhr,
  asr,
  maghrib,
  isha,
  qiyamEvening,
  quranFasting,
  miscAdhkar,
}

typedef TaskTitleResolver = String Function(AppLocalizations l);

class Task {
  Task({
    required this.id,
    required this.points,
    required this.category,
    required this.titleResolver,
  });

  final String id;
  final int points;
  final TaskCategory category;
  final TaskTitleResolver titleResolver;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Task && other.runtimeType == runtimeType && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
