import 'package:app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../customization/presentation/widgets/restore_catalog_dialog.dart';
import '../../sync/data/customization_restore_provider.dart';
import '../../sync/data/sync_service.dart';
import 'providers/auth_provider.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final sync = ref.read(syncServiceProvider);
    setState(() => _loading = true);
    final status = await ref
        .read(authNotifierProvider.notifier)
        .signIn(email: _email.text, password: _password.text);
    if (!mounted) {
      return;
    }
    setState(() => _loading = false);
    if (status == AuthStatus.authenticated) {
      if (!mounted) {
        return;
      }
      final l = AppLocalizations.of(context)!;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 16),
              Flexible(child: Text(l.syncLoadingMessage)),
            ],
          ),
        ),
      );

      ref.read(customizationRestoreConfirmProvider).call =
          (total) => showRestoreCatalogDialog(context, l, total);

      final restore = ref.read(customizationRestoreServiceProvider);
      await restore.restoreIfNeeded(
        confirmReplacePrompt:
            ref.read(customizationRestoreConfirmProvider).call,
      );

      final days = await sync.runFirstSignInMigrationIfNeeded();
      await sync.syncNow();

      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
      if (days > 0) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.syncHistorySnack(days))));
        context.go('/');
      }
      if (mounted) {
        context.go('/');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final auth = ref.watch(authNotifierProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(l.authSignInTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (auth.errorMessage != null) ...[
                  Text(
                    auth.errorMessage!,
                    style: TextStyle(color: scheme.error),
                  ),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  decoration: InputDecoration(labelText: l.authEmailLabel),
                  validator: (v) =>
                      v != null && v.contains('@') ? null : l.authEmailInvalid,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _password,
                  obscureText: true,
                  autofillHints: const [AutofillHints.password],
                  decoration: InputDecoration(labelText: l.authPasswordLabel),
                  validator: (v) => v != null && v.length >= 8
                      ? null
                      : l.authPasswordTooShort,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l.authSignInTitle),
                ),
                TextButton(
                  onPressed: () => context.push('/auth/sign-up'),
                  child: Text(l.authNoAccountPrompt),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
