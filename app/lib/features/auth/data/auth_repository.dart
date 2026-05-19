import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../domain/auth_user.dart';
import 'auth_api.dart';

final authApiProvider = Provider<AuthApi>((ref) => AuthApi(ref.watch(dioProvider)));

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(authApiProvider)),
);

class AuthRepository {
  AuthRepository(this._api);

  final AuthApi _api;

  Future<void> register({
    required String email,
    required String password,
    required String fullName,
  }) =>
      _api.register(email: email, password: password, fullName: fullName);

  Future<AuthTokens> login({
    required String email,
    required String password,
  }) async {
    try {
      return await _api.login(email: email, password: password);
    } on DioException catch (e) {
      final data = e.response?.data;
      if (e.response?.statusCode == 403 &&
          data is Map &&
          data['code'] == 'EMAIL_NOT_CONFIRMED') {
        throw EmailNotConfirmedException(data['email'] as String? ?? email);
      }
      rethrow;
    }
  }

  Future<AuthTokens> refresh(String refreshToken) =>
      _api.refresh(refreshToken);

  Future<void> logout(String refreshToken) => _api.logout(refreshToken);

  Future<void> resendConfirmation(String email) =>
      _api.resendConfirmation(email);

  Future<void> confirmEmailWithCode({
    required String email,
    required String code,
  }) =>
      _api.confirmEmailWithCode(email: email, code: code);

  Future<AuthUser> fetchMe() => _api.fetchMe();
}
