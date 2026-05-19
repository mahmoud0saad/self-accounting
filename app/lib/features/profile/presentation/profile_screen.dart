import 'package:app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/data/token_storage.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../data/profile_api.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late final TextEditingController _fullName;
  late final TextEditingController _photoUrl;
  late final TextEditingController _timezone;
  late final TextEditingController _bio;
  String? _locale;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authNotifierProvider).user!;
    _fullName = TextEditingController(text: user.fullName);
    _photoUrl = TextEditingController(text: user.photoUrl ?? '');
    _timezone = TextEditingController(text: user.timezone ?? '');
    _bio = TextEditingController(text: user.bio ?? '');
    _locale = user.locale;
  }

  @override
  void dispose() {
    _fullName.dispose();
    _photoUrl.dispose();
    _timezone.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_fullName.text.trim().length < 2) {
      return;
    }
    setState(() => _saving = true);
    try {
      final updated = await ref.read(profileApiProvider).updateProfile(
        fullName: _fullName.text.trim(),
        photoUrl: _photoUrl.text.trim().isEmpty ? '' : _photoUrl.text.trim(),
        timezone: _timezone.text.trim().isEmpty ? null : _timezone.text.trim(),
        locale: _locale,
        bio: _bio.text.trim().isEmpty ? null : _bio.text.trim(),
      );
      final tokens = await ref.read(tokenStorageProvider).read();
      if (tokens != null) {
        await ref.read(tokenStorageProvider).save(
          accessToken: tokens.accessToken,
          refreshToken: tokens.refreshToken,
          user: updated,
        );
      }
      ref.read(authNotifierProvider.notifier).updateUser(updated);
      if (mounted) {
        context.pop();
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final user = ref.watch(authNotifierProvider).user!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.profileTitle),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: Text(l.profileSave),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CircleAvatar(
            radius: 36,
            child: Text(
              user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
              style: const TextStyle(fontSize: 28),
            ),
          ),
          const SizedBox(height: 8),
          Text(user.email, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          TextField(
            controller: _fullName,
            decoration: InputDecoration(labelText: l.authFullNameLabel),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _photoUrl,
            decoration: InputDecoration(labelText: l.profilePhotoUrlLabel),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _timezone,
            decoration: InputDecoration(labelText: l.profileTimezoneLabel),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _locale,
            decoration: InputDecoration(labelText: l.profileLocaleLabel),
            items: [
              DropdownMenuItem(value: 'en', child: Text(l.profileLocaleEn)),
              DropdownMenuItem(value: 'ar', child: Text(l.profileLocaleAr)),
            ],
            onChanged: (v) => setState(() => _locale = v),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _bio,
            maxLines: 3,
            decoration: InputDecoration(labelText: l.profileBioLabel),
          ),
        ],
      ),
    );
  }
}
