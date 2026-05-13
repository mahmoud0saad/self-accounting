class TaskNotificationToggle {
  const TaskNotificationToggle({
    required this.taskId,
    required this.notificationsEnabled,
  });

  final String taskId;
  final bool notificationsEnabled;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskNotificationToggle &&
          other.taskId == taskId &&
          other.notificationsEnabled == notificationsEnabled;

  @override
  int get hashCode => Object.hash(taskId, notificationsEnabled);
}
