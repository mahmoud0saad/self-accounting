import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../notification_service.dart';
import '../notification_service_factory.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return createNotificationService();
});
