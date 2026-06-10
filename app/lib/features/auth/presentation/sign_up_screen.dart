import 'package:app/core/widgets/app_logo.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'providers/auth_provider.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _fullName.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _loading = true);
    await ref.read(authNotifierProvider.notifier).signUp(
      email: _email.text,
      password: _password.text,
      fullName: _fullName.text,
    );
    if (!mounted) {
      return;
    }
    setState(() => _loading = false);
    if (ref.read(authNotifierProvider).status == AuthStatus.emailPending) {
      context.go('/auth/confirm');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final auth = ref.watch(authNotifierProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(l.authSignUpTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AppLogo(),
                const SizedBox(height: 24),
                if (auth.errorMessage != null) ...[
                  Text(
                    auth.errorMessage!,
                    style: TextStyle(color: scheme.error),
                  ),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: _fullName,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(labelText: l.authFullNameLabel),
                  validator: (v) =>
                      v != null && v.trim().length >= 2 ? null : l.authFullNameInvalid,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(labelText: l.authEmailLabel),
                  validator: (v) =>
                      v != null && v.contains('@') ? null : l.authEmailInvalid,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _password,
                  obscureText: true,
                  decoration: InputDecoration(labelText: l.authPasswordLabel),
                  validator: (v) => v != null && v.length >= 8
                      ? null
                      : l.authPasswordTooShort,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _confirmPassword,
                  obscureText: true,
                  decoration:
                      InputDecoration(labelText: l.authConfirmPasswordLabel),
                  validator: (v) => v == _password.text
                      ? null
                      : l.authPasswordMismatch,
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
                      : Text(l.authSignUpTitle),
                ),
                TextButton(
                  onPressed: () => context.pop(),
                  child: Text(l.authHaveAccountPrompt),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
