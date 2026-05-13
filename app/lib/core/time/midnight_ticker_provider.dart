import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'midnight_ticker_service.dart';

final midnightTickerServiceProvider = Provider<MidnightTickerService>((ref) {
  final svc = MidnightTickerService();
  ref.onDispose(svc.dispose);
  return svc;
});
