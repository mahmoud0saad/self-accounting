import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/app_settings_repository.dart';

final onboardingDoneProvider = FutureProvider.autoDispose<bool>((ref) {
  return ref
      .watch(appSettingsRepositoryProvider)
      .getNotificationOnboardingDone();
});
