import 'package:app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/db/app_database_provider.dart';
import '../../../../core/i18n/locale_provider.dart';
import '../../../notifications/providers/app_localizations_provider.dart';
import '../../../sync/data/sync_service.dart';
import '../../data/catalog_repository.dart';
import '../../domain/catalog_models.dart';

final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  return DriftCatalogRepository(
    ref.watch(appDatabaseProvider),
    sync: ref.watch(syncServiceProvider),
  );
});

final effectiveCatalogProvider = StreamProvider<EffectiveCatalog>((ref) {
  final l = ref.watch(appLocalizationsProvider);
  if (l != null) {
    return ref.watch(catalogRepositoryProvider).watchEffective(l);
  }
  final locale = ref.watch(localeProvider) ?? const Locale('en');
  return ref
      .watch(catalogRepositoryProvider)
      .watchEffective(lookupAppLocalizations(locale));
});
