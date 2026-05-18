import 'package:dio/dio.dart';

import '../domain/auth_user.dart';

class AuthApi {
  AuthApi(this._dio);

  final Dio _dio;

  Future<void> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    await _dio.post<Map<String, dynamic>>(
      '/auth/register',
      data: {'email': email, 'password': password, 'fullName': fullName},
    );
  }

  Future<AuthTokens> login({
    required String email,
    required String password,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
    return _parseTokens(res.data!);
  }

  Future<AuthTokens> refresh(String refreshToken) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/auth/refresh',
      data: {'refreshToken': refreshToken},
    );
    return _parseTokens(res.data!);
  }

  Future<void> logout(String refreshToken) async {
    await _dio.post<void>(
      '/auth/logout',
      data: {'refreshToken': refreshToken},
    );
  }

  Future<void> resendConfirmation(String email) async {
    await _dio.post<void>(
      '/auth/resend-confirmation',
      data: {'email': email},
    );
  }

  Future<AuthUser> fetchMe() async {
    final res = await _dio.get<Map<String, dynamic>>('/users/me');
    return AuthUser.fromJson(res.data!);
  }

  AuthTokens _parseTokens(Map<String, dynamic> data) {
    return AuthTokens(
      accessToken: data['accessToken'] as String,
      refreshToken: data['refreshToken'] as String,
      user: AuthUser.fromJson(data['user'] as Map<String, dynamic>),
    );
  }
}

class EmailNotConfirmedException implements Exception {
  EmailNotConfirmedException(this.email);

  final String email;
}
