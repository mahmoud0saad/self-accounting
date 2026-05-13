import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart';

/// Overridden in [main] with the opened [AppDatabase] instance.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  throw StateError('appDatabaseProvider must be overridden in main()');
});
