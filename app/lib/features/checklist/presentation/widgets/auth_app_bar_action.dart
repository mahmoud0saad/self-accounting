import 'package:app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/api/server_availability_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class AuthAppBarAction extends ConsumerWidget {
  const AuthAppBarAction({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final auth = ref.watch(authNotifierProvider);
    final serverAvailable = ref.watch(serverAvailableProvider);

    if (auth.status == AuthStatus.unknown) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (auth.status == AuthStatus.unauthenticated ||
        auth.status == AuthStatus.emailPending) {
      if (!serverAvailable) {
        return const SizedBox.shrink();
      }
      return TextButton(
        onPressed: () => context.push('/auth/sign-in'),
        child: Text(l.authSignInTitle),
      );
    }

    final user = auth.user!;
    final name = user.fullName;
    final display = name.length > 14 ? '${name.substring(0, 14)}…' : name;

    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => context.push('/profile'),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 16,
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(fontSize: 14),
              ),
            ),
            const SizedBox(width: 6),
            Text(display, style: Theme.of(context).textTheme.labelLarge),
          ],
        ),
      ),
    );
  }
}
