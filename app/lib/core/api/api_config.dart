import 'package:flutter/foundation.dart';

/// Override with `--dart-define=API_BASE_URL=http://host:3000/v1`.
class ApiConfig {
  static String get baseUrl {
    const fromEnv = String.fromEnvironment('API_BASE_URL');
    if (fromEnv.isNotEmpty) {
      return fromEnv;
    }
    if (kIsWeb ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      return 'http://localhost:3000/v1';
    }
    return 'http://10.0.2.2:3000/v1';
  }
}
