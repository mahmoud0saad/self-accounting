import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client.dart';

const _probeTimeout = Duration(seconds: 5);

Future<bool> probeServerAvailability(Dio dio) async {
  try {
    await dio.get<void>(
      '/health',
      options: Options(
        sendTimeout: _probeTimeout,
        receiveTimeout: _probeTimeout,
        validateStatus: (_) => true,
      ),
    );
    return true;
  } on DioException catch (e) {
    switch (e.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.unknown:
        return false;
      default:
        return true;
    }
  }
}

final serverAvailabilityProvider = FutureProvider<bool>((ref) async {
  final dio = ref.watch(dioBaseProvider);
  return probeServerAvailability(dio);
});

final serverAvailableProvider = Provider<bool>((ref) {
  return ref.watch(serverAvailabilityProvider).maybeWhen(
        data: (available) => available,
        orElse: () => false,
      );
});
