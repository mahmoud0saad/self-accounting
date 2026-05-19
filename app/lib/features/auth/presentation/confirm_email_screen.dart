import 'package:app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../customization/presentation/widgets/restore_catalog_dialog.dart';
import '../../sync/data/customization_restore_provider.dart';
import '../../sync/presentation/providers/sync_provider.dart';
import 'providers/auth_provider.dart';

class ConfirmEmailScreen extends ConsumerStatefulWidget {
  const ConfirmEmailScreen({super.key});

  @override
  ConsumerState<ConfirmEmailScreen> createState() =>
      _ConfirmEmailScreenState();
}

class _ConfirmEmailScreenState extends ConsumerState<ConfirmEmailScreen> {
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _resendBusy = false;
  bool _confirmBusy = false;
  DateTime? _lastResend;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

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

  Future<void> _submitCode() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final sync = ref.read(syncServiceProvider);
    setState(() => _confirmBusy = true);
    final status = await ref
        .read(authNotifierProvider.notifier)
        .confirmEmailCode(_codeController.text.trim());
    if (!mounted) {
      return;
    }
    setState(() => _confirmBusy = false);

    if (status == null) {
      return;
    }

    final l = AppLocalizations.of(context)!;

    if (status == AuthStatus.authenticated) {
      ref.read(customizationRestoreConfirmProvider).call =
          (total) => showRestoreCatalogDialog(context, l, total);

      await ref.read(customizationRestoreServiceProvider).restoreIfNeeded(
            confirmReplacePrompt:
                ref.read(customizationRestoreConfirmProvider).call,
          );

      final days = await sync.runFirstSignInMigrationIfNeeded();
      await sync.syncNow();
      if (mounted && days > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.syncHistorySnack(days))),
        );
      }
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l.authEmailConfirmedSignIn)),
    );
    if (mounted) {
      context.go('/auth/sign-in');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final auth = ref.watch(authNotifierProvider);
    final email = auth.pendingEmail ?? auth.user?.email ?? '';
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(l.authConfirmEmailTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l.authConfirmEmailCodeBody(email),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                if (auth.errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    auth.errorMessage!,
                    style: TextStyle(color: scheme.error),
                  ),
                ],
                const SizedBox(height: 24),
                TextFormField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 6,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  autofillHints: const [AutofillHints.oneTimeCode],
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    letterSpacing: 8,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    labelText: l.authConfirmationCodeLabel,
                    counterText: '',
                    hintText: '000000',
                  ),
                  validator: (v) {
                    if (v == null || !RegExp(r'^\d{6}$').hasMatch(v)) {
                      return l.authCodeInvalid;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _confirmBusy ? null : _submitCode,
                  child: _confirmBusy
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l.authConfirmCodeButton),
                ),
                const SizedBox(height: 12),
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
      ),
    );
  }
}
