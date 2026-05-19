import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../auth/domain/auth_user.dart';

final profileApiProvider = Provider<ProfileApi>(
  (ref) => ProfileApi(ref.watch(dioProvider)),
);

class ProfileApi {
  ProfileApi(this._dio);

  final Dio _dio;

  Future<AuthUser> updateProfile({
    String? fullName,
    String? photoUrl,
    String? timezone,
    String? locale,
    String? bio,
  }) async {
    final body = <String, dynamic>{};
    if (fullName != null) {
      body['fullName'] = fullName;
    }
    if (photoUrl != null) {
      body['photoUrl'] = photoUrl.isEmpty ? null : photoUrl;
    }
    if (timezone != null) {
      body['timezone'] = timezone.isEmpty ? null : timezone;
    }
    if (locale != null) {
      body['locale'] = locale;
    }
    if (bio != null) {
      body['bio'] = bio.isEmpty ? null : bio;
    }
    final res = await _dio.patch<Map<String, dynamic>>('/users/me', data: body);
    return AuthUser.fromJson(res.data!);
  }
}
