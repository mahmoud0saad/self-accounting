import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../domain/auth_user.dart';

class StoredTokens {
  const StoredTokens({
    required this.accessToken,
    required this.refreshToken,
    this.userJson,
  });

  final String accessToken;
  final String refreshToken;
  final String? userJson;
}

class TokenStorage {
  TokenStorage(this._storage);

  static const _accessKey = 'auth_access_token';
  static const _refreshKey = 'auth_refresh_token';
  static const _userKey = 'auth_user_json';

  final FlutterSecureStorage _storage;

  Future<void> save({
    required String accessToken,
    required String refreshToken,
    AuthUser? user,
  }) async {
    await _storage.write(key: _accessKey, value: accessToken);
    await _storage.write(key: _refreshKey, value: refreshToken);
    if (user != null) {
      await _storage.write(
        key: _userKey,
        value: jsonEncode(user.toJson()),
      );
    }
  }

  Future<StoredTokens?> read() async {
    final access = await _storage.read(key: _accessKey);
    final refresh = await _storage.read(key: _refreshKey);
    if (access == null || refresh == null) {
      return null;
    }
    return StoredTokens(
      accessToken: access,
      refreshToken: refresh,
      userJson: await _storage.read(key: _userKey),
    );
  }

  Future<AuthUser?> readUser() async {
    final raw = await _storage.read(key: _userKey);
    if (raw == null) {
      return null;
    }
    return AuthUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> clear() async {
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
    await _storage.delete(key: _userKey);
  }

  Future<String?> readSyncCursor(String userId) =>
      _storage.read(key: 'sync_cursor_$userId');

  Future<void> writeSyncCursor(String userId, String isoDate) =>
      _storage.write(key: 'sync_cursor_$userId', value: isoDate);

  Future<bool> isFirstSyncDone(String userId) async {
    final v = await _storage.read(key: 'first_sync_done_$userId');
    return v == 'true';
  }

  Future<void> markFirstSyncDone(String userId) =>
      _storage.write(key: 'first_sync_done_$userId', value: 'true');

  Future<void> clearUserSyncData(String userId) async {
    await _storage.delete(key: 'sync_cursor_$userId');
    await _storage.delete(key: 'first_sync_done_$userId');
    await _storage.delete(key: 'customization_first_sync_done_$userId');
    await _storage.delete(key: 'customization_server_last_seen_$userId');
    await _storage.delete(key: 'challenge_first_sync_done_$userId');
  }

  Future<bool> isCustomizationFirstSyncDone(String userId) async {
    final v = await _storage.read(key: 'customization_first_sync_done_$userId');
    return v == 'true';
  }

  Future<void> markCustomizationFirstSyncDone(String userId) =>
      _storage.write(key: 'customization_first_sync_done_$userId', value: 'true');

  Future<void> clearCustomizationFirstSyncFlag(String userId) =>
      _storage.delete(key: 'customization_first_sync_done_$userId');

  Future<String?> readCustomizationServerLastSeen(String userId) =>
      _storage.read(key: 'customization_server_last_seen_$userId');

  Future<void> writeCustomizationServerLastSeen(
    String userId,
    String iso,
  ) =>
      _storage.write(key: 'customization_server_last_seen_$userId', value: iso);

  Future<bool> isChallengeFirstSyncDone(String userId) async {
    final v = await _storage.read(key: 'challenge_first_sync_done_$userId');
    return v == 'true';
  }

  Future<void> markChallengeFirstSyncDone(String userId) =>
      _storage.write(key: 'challenge_first_sync_done_$userId', value: 'true');

  Future<void> clearChallengeFirstSyncFlag(String userId) =>
      _storage.delete(key: 'challenge_first_sync_done_$userId');
}

final tokenStorageProvider = Provider<TokenStorage>(
  (ref) => TokenStorage(const FlutterSecureStorage()),
);
