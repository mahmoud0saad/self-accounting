import 'package:app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_state_provider.dart';

/// AppBar action: sign-in when signed out; signed-in email when authenticated.
class AuthAppBarAction extends ConsumerWidget {
  const AuthAppBarAction({super.key});

  static const _maxNameWidth = 140.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final auth = ref.watch(authStateProvider);

    if (auth.isSignedIn) {
      final email = auth.email ?? '';
      return Padding(
        padding: const EdgeInsetsDirectional.only(end: 4),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxNameWidth),
            child: Text(
              email,
              style: Theme.of(context).textTheme.labelLarge,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 4),
      child: TextButton(
        onPressed: () => context.push('/auth/sign-in'),
        child: Text(l.settingsSignIn),
      ),
    );
  }
}
