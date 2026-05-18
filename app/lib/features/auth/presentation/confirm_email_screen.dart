import 'package:app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../sync/presentation/providers/sync_provider.dart';
import 'providers/auth_provider.dart';

class ConfirmEmailScreen extends ConsumerStatefulWidget {
  const ConfirmEmailScreen({super.key});

  @override
  ConsumerState<ConfirmEmailScreen> createState() =>
      _ConfirmEmailScreenState();
}

class _ConfirmEmailScreenState extends ConsumerState<ConfirmEmailScreen> {
  bool _resendBusy = false;
  bool _checkBusy = false;
  DateTime? _lastResend;

  Future<void> _resend() async {
    if (_lastResend != null &&
        DateTime.now().difference(_lastResend!) < const Duration(minutes: 1)) {
      return;
    }
    setState(() => _resendBusy = true);
    await ref.read(authNotifierProvider.notifier).resendConfirmation();
    _lastResend = DateTime.now();
    if (mounted) {
      setState(() => _resendBusy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.authResendSent)),
      );
    }
  }

  Future<void> _checkAgain() async {
    setState(() => _checkBusy = true);
    await ref.read(authNotifierProvider.notifier).refreshProfile();
    final auth = ref.read(authNotifierProvider);
    if (auth.status == AuthStatus.authenticated) {
      await ref.read(syncServiceProvider).runFirstSignInMigrationIfNeeded();
      await ref.read(syncServiceProvider).syncNow();
      if (mounted) {
        context.go('/');
      }
    }
    if (mounted) {
      setState(() => _checkBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final auth = ref.watch(authNotifierProvider);
    final email = auth.pendingEmail ?? auth.user?.email ?? '';

    return Scaffold(
      appBar: AppBar(title: Text(l.authConfirmEmailTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l.authConfirmEmailBody(email), style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: _resendBusy ? null : _resend,
                child: _resendBusy
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l.authResendConfirmation),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _checkBusy ? null : _checkAgain,
                child: _checkBusy
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l.authCheckAgain),
              ),
              const Spacer(),
              TextButton(
                onPressed: () =>
                    ref.read(authNotifierProvider.notifier).signOutLocal(),
                child: Text(l.authSignOut),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
