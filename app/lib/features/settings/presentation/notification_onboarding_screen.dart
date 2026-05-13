import 'package:app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../notifications/providers/notification_service_provider.dart';
import '../data/app_settings_repository.dart';

class NotificationOnboardingScreen extends ConsumerWidget {
  const NotificationOnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(24, 48, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.notifications_none_rounded, size: 64),
              const SizedBox(height: 24),
              Text(
                l.onboardingNotifTitle,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                l.onboardingNotifBody,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              FilledButton(
                onPressed: () => _enable(context, ref),
                child: Text(l.onboardingNotifEnableButton),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => _skip(context, ref),
                child: Text(l.onboardingNotifSkipButton),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _enable(BuildContext context, WidgetRef ref) async {
    await ref.read(notificationServiceProvider).requestPermission();
    await ref
        .read(appSettingsRepositoryProvider)
        .setNotificationOnboardingDone(true);
    if (context.mounted) {
      context.go('/');
    }
  }

  Future<void> _skip(BuildContext context, WidgetRef ref) async {
    await ref
        .read(appSettingsRepositoryProvider)
        .setNotificationOnboardingDone(true);
    if (context.mounted) {
      context.go('/');
    }
  }
}
