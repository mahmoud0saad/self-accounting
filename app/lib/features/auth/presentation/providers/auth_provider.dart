import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/server_availability_provider.dart';
import '../../../../core/db/app_database_provider.dart';
import '../../data/auth_api.dart';
import '../../data/auth_repository.dart';
import '../../data/token_storage.dart';
import '../../domain/auth_user.dart';

enum AuthStatus { unknown, unauthenticated, authenticated, emailPending }

class AuthState {
  const AuthState({
    required this.status,
    this.user,
    this.pendingEmail,
    this.errorMessage,
  });

  final AuthStatus status;
  final AuthUser? user;
  final String? pendingEmail;
  final String? errorMessage;

  static const unknown = AuthState(status: AuthStatus.unknown);
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    Future.microtask(_bootstrap);
    return AuthState.unknown;
  }

  Future<void> _bootstrap() async {
    final storage = ref.read(tokenStorageProvider);
    final tokens = await storage.read();
    if (tokens == null) {
      state = const AuthState(status: AuthStatus.unauthenticated);
      return;
    }
    final serverAvailable = await ref.read(serverAvailabilityProvider.future);
    if (!serverAvailable) {
      final user = _userFromStoredTokens(tokens);
      if (user != null) {
        state = _stateForUser(user);
      } else {
        state = const AuthState(status: AuthStatus.unauthenticated);
      }
      return;
    }
    try {
      final user = await ref.read(authRepositoryProvider).fetchMe();
      await storage.save(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
        user: user,
      );
      state = _stateForUser(user);
    } catch (_) {
      await storage.clear();
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  AuthUser? _userFromStoredTokens(StoredTokens tokens) {
    final raw = tokens.userJson;
    if (raw == null) {
      return null;
    }
    try {
      return AuthUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  AuthState _stateForUser(AuthUser user) {
    if (!user.isEmailConfirmed) {
      return AuthState(
        status: AuthStatus.emailPending,
        user: user,
        pendingEmail: user.email,
      );
    }
    return AuthState(status: AuthStatus.authenticated, user: user);
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    state = AuthState.unknown;
    try {
      await ref.read(authRepositoryProvider).register(
        email: email.trim(),
        password: password,
        fullName: fullName.trim(),
      );
      state = AuthState(
        status: AuthStatus.emailPending,
        pendingEmail: email.trim().toLowerCase(),
      );
    } on DioException catch (e) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: _friendlyDioMessage(e),
      );
    }
  }

  Future<AuthStatus> signIn({
    required String email,
    required String password,
  }) async {
    state = AuthState.unknown;
    try {
      final tokens = await ref.read(authRepositoryProvider).login(
        email: email.trim(),
        password: password,
      );
      await ref.read(tokenStorageProvider).save(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
        user: tokens.user,
      );
      state = _stateForUser(tokens.user);
    } on EmailNotConfirmedException catch (e) {
      state = AuthState(
        status: AuthStatus.emailPending,
        pendingEmail: e.email,
      );
    } on DioException catch (e) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: _friendlyDioMessage(e),
      );
    }
    return state.status;
  }

  Future<void> refreshProfile() async {
    final current = state.user;
    if (current == null) {
      return;
    }
    try {
      final user = await ref.read(authRepositoryProvider).fetchMe();
      await ref.read(tokenStorageProvider).save(
        accessToken: (await ref.read(tokenStorageProvider).read())!.accessToken,
        refreshToken:
            (await ref.read(tokenStorageProvider).read())!.refreshToken,
        user: user,
      );
      state = _stateForUser(user);
    } on DioException catch (e) {
      state = state.copyWithError(_friendlyDioMessage(e));
    }
  }

  Future<void> resendConfirmation() async {
    final email = state.pendingEmail ?? state.user?.email;
    if (email == null) {
      return;
    }
    await ref.read(authRepositoryProvider).resendConfirmation(email);
  }

  /// Returns the resulting [AuthStatus], or `null` when confirmation failed.
  Future<AuthStatus?> confirmEmailCode(String code) async {
    final email = state.pendingEmail ?? state.user?.email;
    if (email == null) {
      return null;
    }
    try {
      await ref.read(authRepositoryProvider).confirmEmailWithCode(
        email: email,
        code: code,
      );
      final tokens = await ref.read(tokenStorageProvider).read();
      if (tokens != null) {
        await refreshProfile();
        return state.status;
      }
      state = AuthState(
        status: AuthStatus.unauthenticated,
        pendingEmail: email,
      );
      return AuthStatus.unauthenticated;
    } on DioException catch (e) {
      state = AuthState(
        status: AuthStatus.emailPending,
        pendingEmail: email,
        user: state.user,
        errorMessage: _friendlyDioMessage(e),
      );
      return null;
    }
  }

  Future<void> signOut() async {
    final tokens = await ref.read(tokenStorageProvider).read();
    if (tokens != null) {
      try {
        await ref.read(authRepositoryProvider).logout(tokens.refreshToken);
      } catch (_) {}
    }
    await signOutLocal();
  }

  Future<void> signOutLocal() async {
    final userId = state.user?.id;
    final db = ref.read(appDatabaseProvider);
    final storage = ref.read(tokenStorageProvider);
    await db.clearUserData();
    if (userId != null) {
      await storage.clearUserSyncData(userId);
    }
    await storage.clear();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  void updateUser(AuthUser user) {
    state = _stateForUser(user);
  }

  String _friendlyDioMessage(DioException e) {
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout) {
      return 'You\'re offline. We\'ll keep your day saved here until you\'re back.';
    }
    final data = e.response?.data;
    if (data is Map && data['message'] is String) {
      return data['message'] as String;
    }
    if (e.response?.statusCode == 401) {
      return 'That email and password don\'t match. Try again.';
    }
    return 'Something went wrong. Please try again.';
  }
}

extension on AuthState {
  AuthState copyWithError(String message) => AuthState(
    status: status,
    user: user,
    pendingEmail: pendingEmail,
    errorMessage: message,
  );
}

final authNotifierProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

final isAuthenticatedProvider = Provider<bool>((ref) {
  final s = ref.watch(authNotifierProvider);
  return s.status == AuthStatus.authenticated;
});
