import '../../checklist/domain/task.dart';

class CategoryNotificationSchedule {
  const CategoryNotificationSchedule({
    required this.category,
    required this.enabled,
    required this.hour,
    required this.minute,
  });

  final TaskCategory category;
  final bool enabled;
  final int hour;
  final int minute;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryNotificationSchedule &&
          other.category == category &&
          other.enabled == enabled &&
          other.hour == hour &&
          other.minute == minute;

  @override
  int get hashCode => Object.hash(category, enabled, hour, minute);
}
