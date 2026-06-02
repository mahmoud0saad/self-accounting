import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/app_settings_repository.dart';
import '../../domain/eod_summary_settings.dart';

final eodSettingsProvider = StreamProvider<EodSummarySettings>((ref) {
  return ref.watch(appSettingsRepositoryProvider).watchEodSettings();
});
