import 'native_notification_service.dart'
    if (dart.library.js_interop) 'web_notification_service.dart';
import 'notification_service.dart';

NotificationService createNotificationService() {
  return createPlatformNotificationService();
}
