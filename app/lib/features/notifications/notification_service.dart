enum NotificationPermissionStatus { granted, denied, unknown }

abstract class NotificationService {
  Future<NotificationPermissionStatus> permissionStatus();

  Future<bool> requestPermission();

  Future<void> scheduleDaily({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  });

  Future<void> cancel(int id);

  Future<void> cancelAll();
}
