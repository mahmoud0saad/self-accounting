// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'notification_service.dart';

@JS('Notification')
extension type _JSNotification._(JSObject _) implements JSObject {
  external factory _JSNotification(String title, JSObject options);

  external static JSString get permission;

  external static JSPromise<JSString> requestPermission();
}

class WebNotificationService implements NotificationService {
  final Map<int, Timer> _timers = <int, Timer>{};

  @override
  Future<NotificationPermissionStatus> permissionStatus() async {
    return switch (_JSNotification.permission.toDart) {
      'granted' => NotificationPermissionStatus.granted,
      'denied' => NotificationPermissionStatus.denied,
      _ => NotificationPermissionStatus.unknown,
    };
  }

  @override
  Future<bool> requestPermission() async {
    final result = await _JSNotification.requestPermission().toDart;
    return result.toDart == 'granted';
  }

  @override
  Future<void> scheduleDaily({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    await cancel(id);
    final now = DateTime.now();
    var next = DateTime(now.year, now.month, now.day, hour, minute);
    if (!next.isAfter(now)) {
      next = next.add(const Duration(days: 1));
    }
    // Web has no service worker in Phase 5: timers are lost when the tab closes.
    _timers[id] = Timer(next.difference(now), () {
      _fire(title, body);
      _timers[id] = Timer.periodic(
        const Duration(days: 1),
        (_) => _fire(title, body),
      );
    });
  }

  @override
  Future<void> cancel(int id) async {
    _timers.remove(id)?.cancel();
  }

  @override
  Future<void> cancelAll() async {
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
  }

  void _fire(String title, String body) {
    final options = JSObject();
    options.setProperty('body'.toJS, body.toJS);
    _JSNotification(title, options);
  }
}

NotificationService createPlatformNotificationService() {
  return WebNotificationService();
}
