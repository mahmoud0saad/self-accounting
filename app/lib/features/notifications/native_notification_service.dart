import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
// ignore: depend_on_referenced_packages
import 'package:timezone/data/latest_all.dart' as tzdata;
// ignore: depend_on_referenced_packages
import 'package:timezone/timezone.dart' as tz;

import 'notification_service.dart';

class NativeNotificationService implements NotificationService {
  NativeNotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const String _appUserModelId = 'Muhasabah.SelfAccounting.App';
  static const String _notificationGuid =
      '6FCA9E57-67A6-45C6-821D-0C7E5D7B7F42';

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  @override
  Future<NotificationPermissionStatus> permissionStatus() async {
    await _ensureInitialized();
    return NotificationPermissionStatus.unknown;
  }

  @override
  Future<bool> requestPermission() async {
    return _ensureInitialized();
  }

  @override
  Future<void> scheduleDaily({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    await _ensureInitialized();
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: _nextInstanceOfTime(hour, minute),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'muhasabah_daily_reminders',
          'Daily reminders',
          channelDescription: 'Gentle reminders for daily worship tasks.',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        windows: WindowsNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  @override
  Future<void> cancel(int id) async {
    await _ensureInitialized();
    await _plugin.cancel(id: id);
  }

  @override
  Future<void> cancelAll() async {
    await _ensureInitialized();
    await _plugin.cancelAll();
  }

  Future<bool> _ensureInitialized() async {
    if (_initialized) {
      return true;
    }
    await _configureTimezone();
    final ok = await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
        macOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
        windows: WindowsInitializationSettings(
          appName: 'Muhasabah',
          appUserModelId: _appUserModelId,
          guid: _notificationGuid,
        ),
      ),
    );
    _initialized = ok ?? true;
    return _initialized;
  }

  Future<void> _configureTimezone() async {
    tzdata.initializeTimeZones();
    try {
      final local = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(local.identifier));
    } on Object {
      tz.setLocalLocation(tz.local);
    }
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}

NotificationService createPlatformNotificationService() {
  return NativeNotificationService();
}
