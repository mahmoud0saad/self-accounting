import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/data/token_storage.dart';
import '../../features/auth/presentation/providers/auth_state_provider.dart';

class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor(this._ref, this._dio);

  final Ref _ref;
  final Dio _dio;
  bool _refreshing = false;

  bool _isAuthPath(String path) =>
      path.contains('/auth/login') ||
      path.contains('/auth/register') ||
      path.contains('/auth/refresh');

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!_isAuthPath(options.path)) {
      final tokens = await _ref.read(tokenStorageProvider).read();
      if (tokens != null) {
        options.headers['Authorization'] = 'Bearer ${tokens.accessToken}';
      }
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode != 401 ||
        _isAuthPath(err.requestOptions.path) ||
        err.requestOptions.extra['retried'] == true) {
      handler.next(err);
      return;
    }

    if (_refreshing) {
      handler.next(err);
      return;
    }

    _refreshing = true;
    try {
      final storage = _ref.read(tokenStorageProvider);
      final stored = await storage.read();
      if (stored == null) {
        await _ref.read(authStateProvider.notifier).signOut();
        handler.next(err);
        return;
      }

      final refreshed = await _ref
          .read(authRepositoryProvider)
          .refresh(stored.refreshToken);
      await storage.write(
        StoredTokens(
          accessToken: refreshed.accessToken,
          refreshToken: refreshed.refreshToken,
          email: stored.email,
        ),
      );

      final retry = err.requestOptions;
      retry.extra['retried'] = true;
      retry.headers['Authorization'] = 'Bearer ${refreshed.accessToken}';
      final response = await _dio.fetch(retry);
      handler.resolve(response);
    } catch (_) {
      await _ref.read(authStateProvider.notifier).signOut();
      handler.next(err);
    } finally {
      _refreshing = false;
    }
  }
}
