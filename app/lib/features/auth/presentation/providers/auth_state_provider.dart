import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/public_dio_provider.dart';
import '../../data/auth_repository.dart';
import '../../data/token_storage.dart';

enum AuthStatus { signedOut, signingIn, signedIn }

class AuthState {
  const AuthState({required this.status, this.email});

  final AuthStatus status;
  final String? email;

  bool get isSignedIn => status == AuthStatus.signedIn;
}

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(publicDioProvider));
});

class AuthStateNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    Future.microtask(_restoreSession);
    return const AuthState(status: AuthStatus.signedOut);
  }

  Future<void> _restoreSession() async {
    final stored = await ref.read(tokenStorageProvider).read();
    if (stored == null) {
      return;
    }
    state = AuthState(status: AuthStatus.signedIn, email: stored.email);
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = AuthState(status: AuthStatus.signingIn, email: email);
    try {
      final tokens = await ref
          .read(authRepositoryProvider)
          .login(email: email.trim(), password: password);
      await _persist(tokens, email.trim());
      state = AuthState(status: AuthStatus.signedIn, email: email.trim());
    } catch (_) {
      state = const AuthState(status: AuthStatus.signedOut);
      rethrow;
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
  }) async {
    state = AuthState(status: AuthStatus.signingIn, email: email);
    try {
      final tokens = await ref
          .read(authRepositoryProvider)
          .register(email: email.trim(), password: password);
      await _persist(tokens, email.trim());
      state = AuthState(status: AuthStatus.signedIn, email: email.trim());
    } catch (_) {
      state = const AuthState(status: AuthStatus.signedOut);
      rethrow;
    }
  }

  Future<void> signOut() async {
    await ref.read(tokenStorageProvider).clear();
    state = const AuthState(status: AuthStatus.signedOut);
  }

  Future<void> _persist(AuthTokens tokens, String email) async {
    await ref.read(tokenStorageProvider).write(
      StoredTokens(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
        email: email,
      ),
    );
  }
}

final authStateProvider = NotifierProvider<AuthStateNotifier, AuthState>(
  AuthStateNotifier.new,
);
