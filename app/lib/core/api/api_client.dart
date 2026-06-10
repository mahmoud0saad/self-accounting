import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:network_logger/network_logger.dart';

import '../../features/auth/data/token_storage.dart';
import 'api_config.dart';

final dioBaseProvider = Provider<Dio>(
  (ref) => Dio(
    BaseOptions(
      baseUrl: apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  ),
);

final dioProvider = Provider<Dio>((ref) {
  final base = ref.watch(dioBaseProvider);
  final dio = Dio(base.options);
  final storage = ref.read(tokenStorageProvider);

  // if (kDebugMode) {
  //   dio.interceptors.add(DioNetworkLogger());
  // }

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final tokens = await storage.read();
        if (tokens != null && tokens.accessToken.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer ${tokens.accessToken}';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode != 401) {
          handler.next(error);
          return;
        }
        final tokens = await storage.read();
        if (tokens == null || tokens.refreshToken.isEmpty) {
          handler.next(error);
          return;
        }
        try {
          final refreshRes = await ref.read(dioBaseProvider).post<Map<String, dynamic>>(
            '/auth/refresh',
            data: {'refreshToken': tokens.refreshToken},
          );
          final data = refreshRes.data!;
          final access = data['accessToken'] as String;
          final refresh = data['refreshToken'] as String;
          await storage.save(
            accessToken: access,
            refreshToken: refresh,
          );
          final opts = error.requestOptions;
          opts.headers['Authorization'] = 'Bearer $access';
          final response = await dio.fetch(opts);
          handler.resolve(response);
        } catch (_) {
          await storage.clear();
          handler.next(error);
        }
      },
    ),
  );

  return dio;
});
