# Phase 5 — Local Notifications · Plan

> Numbered task groups. Each group is self-contained and ordered for least-rework. Adjacent groups may be collapsed into one commit, but the ordering should be preserved. Budget: **3 days** per `spec/roadmap.md`.

---

## 1. Branch & sanity

1.1. Confirm you are on `feature/phase-5-local-notifications` (branched off `master` after the Phase 4 merge).
1.2. From `/app`: `flutter pub get` then `flutter analyze` — must report `No issues found!` before any code lands. Regression check that Phase 4's committed state is clean.
1.3. From `/app`: `flutter test` — confirm all prior mandatory tests pass:
   - `test/data/drift_checklist_repository_test.dart`
   - `test/data/drift_history_repository_test.dart`
   - `test/domain/streak_calculator_test.dart`
   - `test/features/dashboard/dashboard_aggregator_test.dart`
   - `test/features/dashboard/dashboard_range_picker_test.dart`
1.4. Open `app/lib/core/database/app_database.dart`. Confirm `schemaVersion = 1`. This is the value we will bump in group 3.
1.5. Confirm the bottom nav in `root_shell.dart` has exactly **two** destinations (`Checklist`, `Dashboard`). Phase 5 adds the third.

## 2. New dependencies

2.1. From `/app`:
   ```bash
   flutter pub add flutter_local_notifications flutter_timezone package_info_plus
   ```
2.2. From `/app`: `flutter pub get` — confirm no transitive conflicts with `flutter_riverpod`, `drift`, `go_router`, or `intl`.
2.3. From `/app`: `flutter analyze` — must be clean.
2.4. Commit: `chore(app): add flutter_local_notifications, flutter_timezone, package_info_plus for Phase 5`.

## 3. Drift schema v2 — new tables

3.1. Open `app/lib/core/database/app_database.dart`. After the existing table definitions, add three new Drift table classes:

   ```dart
   class CategoryNotificationSchedules extends Table {
     TextColumn get category => text()();
     BoolColumn get enabled => boolean().withDefault(const Constant(true))();
     IntColumn get hour => integer()();
     IntColumn get minute => integer()();

     @override
     Set<Column> get primaryKey => {category};
   }

   class TaskNotificationToggles extends Table {
     IntColumn get taskId => integer()();
     BoolColumn get notificationsEnabled =>
         boolean().withDefault(const Constant(true))();

     @override
     Set<Column> get primaryKey => {taskId};
   }

   class AppSettings extends Table {
     TextColumn get key => text()();
     TextColumn get value => text()();

     @override
     Set<Column> get primaryKey => {key};
   }
   ```

3.2. Add the three table classes to the `@DriftDatabase(tables: [...])` annotation.
3.3. Bump `schemaVersion` from `1` to `2`.
3.4. Add the migration strategy:

   ```dart
   @override
   MigrationStrategy get migration => MigrationStrategy(
     onCreate: (m) async {
       await m.createAll();
       await _seedNotificationDefaults();
     },
     onUpgrade: (m, from, to) async {
       if (from == 1 && to == 2) {
         await m.createTable(categoryNotificationSchedules);
         await m.createTable(taskNotificationToggles);
         await m.createTable(appSettings);
         await _seedNotificationDefaults();
       }
     },
   );
   ```

3.5. Implement the private `_seedNotificationDefaults()` method on the database class. It must run idempotently (uses `insertOnConflictUpdate`):

   ```dart
   static const _kDefaultTimes = {
     'fajr':         (5,  0),
     'dhuhr':        (13, 0),
     'asr':          (16, 0),
     'maghrib':      (18, 30),
     'isha':         (20, 0),
     'qiyamEvening': (21, 0),
     'quranFasting':  (6,  0),
     'miscAdhkar':   (7,  30),
   };

   Future<void> _seedNotificationDefaults() async {
     for (final e in _kDefaultTimes.entries) {
       await into(categoryNotificationSchedules).insertOnConflictUpdate(
         CategoryNotificationSchedulesCompanion(
           category: Value(e.key),
           enabled:  const Value(true),
           hour:     Value(e.value.$1),
           minute:   Value(e.value.$2),
         ),
       );
     }
     for (final task in staticTaskCatalog) {
       await into(taskNotificationToggles).insertOnConflictUpdate(
         TaskNotificationTogglesCompanion(
           taskId:               Value(task.id),
           notificationsEnabled: const Value(true),
         ),
       );
     }
     for (final kv in const {
       'notification_onboarding_done': 'false',
       'eod_enabled':                  'true',
       'eod_hour':                     '21',
       'eod_minute':                   '30',
     }.entries) {
       await into(appSettings).insertOnConflictUpdate(
         AppSettingsCompanion(key: Value(kv.key), value: Value(kv.value)),
       );
     }
   }
   ```

3.6. From `/app`: `dart run build_runner build --delete-conflicting-outputs` — regenerates Drift code. Confirm the generated `app_database.g.dart` includes companions and accessors for the three new tables.
3.7. From `/app`: `flutter analyze` — must be clean.

## 4. Domain layer — value objects

4.1. Create `app/lib/features/settings/domain/category_notification_schedule.dart` — `CategoryNotificationSchedule` per `requirements.md` §3.3.
4.2. Create `app/lib/features/settings/domain/task_notification_toggle.dart` — `TaskNotificationToggle`.
4.3. Create `app/lib/features/settings/domain/eod_summary_settings.dart` — `EodSummarySettings` (include `static const int thresholdPercent = 50`).
4.4. All three: `const` constructor, `==` / `hashCode` override on all fields. No Flutter imports — pure Dart.

## 5. Repository layer

5.1. Create `app/lib/features/settings/data/notification_settings_repository.dart`:

   ```dart
   class NotificationSettingsRepository {
     const NotificationSettingsRepository(this._db);
     final AppDatabase _db;

     Stream<List<CategoryNotificationSchedule>> watchCategorySchedules();
     Future<void> setCategoryEnabled(TaskCategory c, bool enabled);
     Future<void> setCategoryTime(TaskCategory c, int hour, int minute);

     Stream<List<TaskNotificationToggle>> watchTaskToggles();
     Future<void> setTaskEnabled(int taskId, bool enabled);
   }
   ```

   Implement using Drift's `.watchExpression` / `.into().insertOnConflictUpdate()` patterns consistent with Phase 2's `DriftChecklistRepository`.

5.2. Create `app/lib/features/settings/data/app_settings_repository.dart`:

   ```dart
   class AppSettingsRepository {
     const AppSettingsRepository(this._db);
     final AppDatabase _db;

     Future<bool> getNotificationOnboardingDone();
     Future<void> setNotificationOnboardingDone(bool value);

     Stream<EodSummarySettings> watchEodSettings();
     Future<void> setEodEnabled(bool enabled);
     Future<void> setEodTime(int hour, int minute);
   }
   ```

   All writes use `insertOnConflictUpdate` on `AppSettings`. `watchEodSettings()` builds an `EodSummarySettings` from three separate key rows and emits a combined stream.

5.3. Create repository Riverpod providers in `app/lib/features/settings/data/`:

   ```dart
   final notificationSettingsRepositoryProvider =
       Provider<NotificationSettingsRepository>((ref) =>
           NotificationSettingsRepository(ref.watch(appDatabaseProvider)));

   final appSettingsRepositoryProvider =
       Provider<AppSettingsRepository>((ref) =>
           AppSettingsRepository(ref.watch(appDatabaseProvider)));
   ```

## 6. Notification service abstraction & implementations

6.1. Create `app/lib/features/notifications/notification_service.dart` with the abstract `NotificationService` interface per `requirements.md` §3.9.
6.2. Create `app/lib/features/notifications/native_notification_service.dart` — wraps `FlutterLocalNotificationsPlugin`:

   Key points:
   - `initialize()` in `requestPermission()` uses only `WindowsInitializationSettings` (app name: `"Muhasabah"`, app user model ID and GUID: generated — see group 13).
   - `scheduleDaily` calls `_plugin.zonedSchedule` with `matchDateTimeComponents: DateTimeComponents.time`.
   - `_nextInstanceOfTime` helper: if today's `hour:minute` is already past, return tomorrow's.
   - Import `package:flutter_timezone/flutter_timezone.dart` and call `tz.initializeTimeZones(); tz.setLocalLocation(...)` once in `requestPermission()`.

6.3. Create `app/lib/features/notifications/web_notification_service.dart` (only meaningful on Web; safe to compile elsewhere):

   ```dart
   @JS('Notification')
   @staticInterop
   class _JSNotification {
     external static Object requestPermission();
     external factory _JSNotification(String title, JSObject options);
   }

   class WebNotificationService implements NotificationService {
     final _timers = <int, Timer>{};

     @override
     Future<bool> requestPermission() async {
       final result = await promiseToFuture<String>(_JSNotification.requestPermission());
       return result == 'granted';
     }

     @override
     Future<void> scheduleDaily({...}) async {
       _timers[id]?.cancel();
       final now = DateTime.now();
       var next = DateTime(now.year, now.month, now.day, hour, minute);
       if (next.isBefore(now)) next = next.add(const Duration(days: 1));
       _timers[id] = Timer(next.difference(now), () {
         _fire(title, body);
         _timers[id] = Timer.periodic(const Duration(days: 1), (_) => _fire(title, body));
       });
     }

     void _fire(String title, String body) {
       final opts = newObject<JSObject>();
       opts['body'] = body.toJS;
       _JSNotification(title, opts);
     }

     @override
     Future<void> cancel(int id) async { _timers.remove(id)?.cancel(); }
     @override
     Future<void> cancelAll() async { _timers.values.forEach((t) => t.cancel()); _timers.clear(); }
   }
   ```

6.4. Create `app/lib/features/notifications/providers/notification_service_provider.dart`:

   ```dart
   final notificationServiceProvider = Provider<NotificationService>((ref) {
     if (kIsWeb) return WebNotificationService();
     return NativeNotificationService();
   });
   ```

## 7. Notification scheduler

7.1. Create `app/lib/features/notifications/notification_scheduler.dart`. The scheduler reads live settings from the repositories and re-arms all scheduled notifications via a single `syncAll()` method:

   ```dart
   class NotificationScheduler {
     const NotificationScheduler({
       required NotificationService service,
       required NotificationSettingsRepository notifRepo,
       required AppSettingsRepository settingsRepo,
       required List<Task> taskCatalog,
       required AppLocalizations l,
     });

     Future<void> syncAll() async {
       await _service.cancelAll();
       final categories = await _notifRepo.watchCategorySchedules().first;
       final toggles = await _notifRepo.watchTaskToggles().first;
       final eod = await _settingsRepo.watchEodSettings().first;

       for (final schedule in categories) {
         if (!schedule.enabled) continue;
         final body = _buildCategoryBody(schedule.category, toggles);
         if (body == null) continue; // all tasks muted
         await _service.scheduleDaily(
           id: 100 + TaskCategory.values.indexOf(schedule.category),
           title: _localizedCategoryName(schedule.category),
           body: body,
           hour: schedule.hour,
           minute: schedule.minute,
         );
       }

       if (eod.enabled) {
         await _service.scheduleDaily(
           id: 200,
           title: _l.settingsEodToggleLabel,
           body: '', // composed at fire time by a Riverpod listener (§7.2)
           hour: eod.hour,
           minute: eod.minute,
         );
       }
     }

     String? _buildCategoryBody(TaskCategory category, List<TaskNotificationToggle> toggles) {
       final enabled = _taskCatalog
           .where((t) => t.category == category)
           .where((t) => toggles.firstWhere((tt) => tt.taskId == t.id,
               orElse: () => TaskNotificationToggle(taskId: t.id, notificationsEnabled: true))
               .notificationsEnabled)
           .toList();
       if (enabled.isEmpty) return null;
       if (enabled.length <= 3) return enabled.map((t) => t.name).join(', ');
       return _l.notifCategoryBody('${enabled.length} tasks ready');
     }
   }
   ```

7.2. **EOD body at fire time:** Because `flutter_local_notifications` pre-schedules the notification body string, the EOD notification body is computed when `syncAll()` runs (which re-runs on any checklist change via `ref.listen`). This means the EOD body reflects the completion % **at the last `syncAll()` call**, not precisely at fire time. This is acceptable for a "gentle nudge" use case. Document in `plan.md` §7 comments.

7.3. Create `app/lib/features/notifications/providers/notification_scheduler_provider.dart`:

   ```dart
   final notificationSchedulerProvider = Provider<NotificationScheduler>((ref) {
     return NotificationScheduler(
       service: ref.watch(notificationServiceProvider),
       notifRepo: ref.watch(notificationSettingsRepositoryProvider),
       settingsRepo: ref.watch(appSettingsRepositoryProvider),
       taskCatalog: ref.watch(taskCatalogProvider).value ?? [],
       l: ref.watch(appLocalizationsProvider) ?? AppLocalizationsEn(),
     );
   });
   ```

7.4. Create `app/lib/features/notifications/providers/app_localizations_provider.dart`:

   ```dart
   final appLocalizationsProvider = StateProvider<AppLocalizations?>((ref) => null);
   ```

   This is overridden at the root widget level once `AppLocalizations` is available (see group 11).

7.5. In `app/lib/main.dart`, after `runApp`, call `syncAll()` via a `WidgetsBinding.instance.addPostFrameCallback` once the provider scope and DB are ready. Also add a `ref.listen` on the combined notification settings providers (category schedules + task toggles + EOD) to re-call `syncAll()` whenever any setting changes.

## 8. Settings screen — scaffold and nav wiring

8.1. Create `app/lib/features/settings/presentation/settings_screen.dart` as a stub:

   ```dart
   class SettingsScreen extends StatelessWidget {
     const SettingsScreen({super.key});
     @override
     Widget build(BuildContext context) =>
         const Scaffold(body: Center(child: Text('Settings — Phase 5')));
   }
   ```

8.2. Add the Settings branch to `app/lib/core/routing/app_router.dart`:

   ```dart
   final _settingsKey = GlobalKey<NavigatorState>(debugLabel: 'settings');

   // Inside StatefulShellRoute.indexedStack branches:
   StatefulShellBranch(
     navigatorKey: _settingsKey,
     routes: [GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen())],
   ),
   ```

8.3. Update `app/lib/features/shell/presentation/root_shell.dart` to add the third destination:

   ```dart
   NavigationDestination(
     icon: const Icon(Icons.settings),
     selectedIcon: const Icon(Icons.settings_rounded),
     label: l.navSettingsLabel,
   ),
   ```

8.4. Add `navSettingsLabel` and `settingsTitle` to both `app_en.arb` and `app_ar.arb` (`TODO:` for Arabic).
8.5. From `/app`: `flutter run -d chrome`. Confirm three-tab bottom nav renders and the Settings stub is reachable.
8.6. From `/app`: `flutter analyze` — clean.

## 9. Notification onboarding screen

9.1. Create `app/lib/features/settings/presentation/providers/onboarding_done_provider.dart`:

   ```dart
   final onboardingDoneProvider = FutureProvider.autoDispose<bool>((ref) =>
       ref.watch(appSettingsRepositoryProvider).getNotificationOnboardingDone());
   ```

9.2. Add a router redirect to `app_router.dart` (inside the `GoRouter` factory, as a top-level `redirect` parameter):

   ```dart
   redirect: (context, state) async {
     if (state.matchedLocation == '/onboarding/notifications') return null;
     // read without watching — router redirect runs outside widget tree
     final repo = ref.read(appSettingsRepositoryProvider);
     final done = await repo.getNotificationOnboardingDone();
     if (!done) return '/onboarding/notifications';
     return null;
   },
   ```

   Register the route outside the `StatefulShellRoute`:
   ```dart
   GoRoute(
     path: '/onboarding/notifications',
     builder: (_, __) => const NotificationOnboardingScreen(),
   ),
   ```

9.3. Create `app/lib/features/settings/presentation/notification_onboarding_screen.dart`:

   ```dart
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
                 Text(l.onboardingNotifTitle,
                     style: Theme.of(context).textTheme.headlineSmall,
                     textAlign: TextAlign.center),
                 const SizedBox(height: 16),
                 Text(l.onboardingNotifBody,
                     style: Theme.of(context).textTheme.bodyMedium,
                     textAlign: TextAlign.center),
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
       await ref.read(appSettingsRepositoryProvider).setNotificationOnboardingDone(true);
       if (context.mounted) context.go('/');
     }

     Future<void> _skip(BuildContext context, WidgetRef ref) async {
       await ref.read(appSettingsRepositoryProvider).setNotificationOnboardingDone(true);
       if (context.mounted) context.go('/');
     }
   }
   ```

9.4. Add the four onboarding ARB keys (`onboardingNotifTitle`, `onboardingNotifBody`, `onboardingNotifEnableButton`, `onboardingNotifSkipButton`) to both locale files.
9.5. From `/app`: cold-launch on a fresh DB. Confirm the onboarding screen appears; no bottom nav is visible. Tap "Not now". Confirm the shell opens and onboarding never repeats on restart.

## 10. Providers — notification settings

10.1. Create `app/lib/features/settings/presentation/providers/notification_settings_provider.dart`:

   ```dart
   final categorySchedulesProvider =
       StreamProvider<List<CategoryNotificationSchedule>>((ref) =>
           ref.watch(notificationSettingsRepositoryProvider).watchCategorySchedules());

   final taskTogglesProvider =
       StreamProvider<List<TaskNotificationToggle>>((ref) =>
           ref.watch(notificationSettingsRepositoryProvider).watchTaskToggles());
   ```

10.2. Create `app/lib/features/settings/presentation/providers/eod_settings_provider.dart`:

   ```dart
   final eodSettingsProvider = StreamProvider<EodSummarySettings>((ref) =>
       ref.watch(appSettingsRepositoryProvider).watchEodSettings());
   ```

10.3. Add a `ref.listen` in the root widget (or in `main.dart` via a startup listener) that watches all three providers above and calls `ref.read(notificationSchedulerProvider).syncAll()` whenever any emits a new value.

## 11. Settings UI — widgets

11.1. Create `app/lib/features/settings/presentation/widgets/settings_section_card.dart` — mirrors `DashboardSectionCard` from Phase 4 (same Card + title + Padding structure).
11.2. Create `app/lib/features/settings/presentation/widgets/task_notif_toggle_tile.dart`:

   ```dart
   class TaskNotifToggleTile extends ConsumerWidget {
     const TaskNotifToggleTile({super.key, required this.task, required this.enabled});
     final Task task;
     final bool enabled;

     @override
     Widget build(BuildContext context, WidgetRef ref) {
       final l = AppLocalizations.of(context)!;
       return Semantics(
         label: l.settingsTaskNotifToggleA11y(task.name),
         child: SwitchListTile(
           title: Text(task.name),
           value: enabled,
           onChanged: (v) =>
               ref.read(notificationSettingsRepositoryProvider).setTaskEnabled(task.id, v),
         ),
       );
     }
   }
   ```

11.3. Create `app/lib/features/settings/presentation/widgets/category_schedule_tile.dart`:
   - `ExpansionTile` with leading: `_categoryIcon(category)` (reuse or mirror Phase 4's category icon map).
   - Title: localized category name.
   - Trailing: `Row` of [time `ActionChip` | `Switch` for `schedule.enabled`].
   - Time `ActionChip` opens `showTimePicker(context, initialTime: TimeOfDay(hour: schedule.hour, minute: schedule.minute))` on tap; on confirm calls `setCategoryTime`.
   - Expanded children: one `TaskNotifToggleTile` per task in the category, resolved from the catalog.
   - If all tasks in the category are toggled off, show a `ListTile(title: Text('All tasks muted'), leading: Icon(Icons.warning_amber_rounded, color: colorScheme.error))` as the first expanded item.

11.4. Create `app/lib/features/settings/presentation/widgets/eod_summary_row.dart`:
   - `Column` with a `ListTile` (leading: `Icons.schedule_rounded`, title: `l.settingsEodToggleLabel`, trailing: `Switch`).
   - Below, if enabled: a `ListTile` with `ActionChip` for time and a caption `l.settingsEodThresholdNote`.

## 12. Settings screen — full composition

12.1. Expand `settings_screen.dart` to its full layout per `requirements.md` §3.8:

   - Read `categorySchedulesProvider`, `taskTogglesProvider`, `eodSettingsProvider`.
   - Build Section A (Notifications): global `Switch` header + Web banner (if `kIsWeb`) + `EodSummaryRow` + 8 `CategoryScheduleTile`s.
   - Build Section B (About): `FutureBuilder` on `PackageInfo.fromPlatform()` for version string.

12.2. Global `Switch` wiring:
   - Off → `ref.read(notificationServiceProvider).cancelAll()`.
   - On → `ref.read(notificationSchedulerProvider).syncAll()`.

12.3. Web-only banner:
   ```dart
   if (kIsWeb)
     Card(child: Padding(
       padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 12, 8),
       child: Row(children: [
         const Icon(Icons.info_outline_rounded),
         const SizedBox(width: 8),
         Expanded(child: Text(l.settingsWebNotificationNote)),
       ]),
     )),
   ```
   Add a second banner for `"Notifications blocked in browser settings"` only when `kIsWeb && permissionDenied` (check via a `FutureProvider` that calls `requestPermission()` silently and returns the result).

12.4. Inject `AppLocalizations` into `appLocalizationsProvider` inside `SettingsScreen.build` (or a shared `AppLocalizationsInjector` widget at the root level):
   ```dart
   WidgetsBinding.instance.addPostFrameCallback((_) {
     ref.read(appLocalizationsProvider.notifier).state =
         AppLocalizations.of(context);
   });
   ```

12.5. Add remaining ARB keys (`settingsNotificationsTitle`, `settingsNotificationsGlobalToggleLabel`, `settingsCategoryScheduleTimeLabel`, `settingsEodToggleLabel`, `settingsEodTimeLabel`, `settingsEodThresholdNote`, `settingsWebNotificationNote`, `settingsAboutTitle`, `settingsVersionLabel`, `notifCategoryBody`, `notifEodBody`, `settingsTaskNotifToggleA11y`) to both locale files.
12.6. From `/app`: `flutter pub get` — re-runs `gen-l10n`. Confirm all new accessors resolve in the IDE.

## 13. Mandatory test — `notification_settings_repository_test.dart`

13.1. Create `app/test/features/settings/notification_settings_repository_test.dart`. Test structure:

   ```dart
   void main() {
     late AppDatabase db;
     late NotificationSettingsRepository repo;
     late AppSettingsRepository settingsRepo;

     setUp(() async {
       db = AppDatabase(NativeDatabase.memory());
       // Run migration to v2 by opening the database
       await db.customStatement('SELECT 1'); // triggers onCreate
       repo = NotificationSettingsRepository(db);
       settingsRepo = AppSettingsRepository(db);
     });

     tearDown(() => db.close());

     test('migration seeds 8 category rows', () async {
       expect(await repo.watchCategorySchedules().first, hasLength(8));
     });
     test('migration seeds 34 task rows', () async {
       expect(await repo.watchTaskToggles().first, hasLength(34));
     });
     test('toggle category off persists', () async {
       await repo.setCategoryEnabled(TaskCategory.fajr, false);
       final s = await repo.watchCategorySchedules().first;
       expect(s.firstWhere((x) => x.category == TaskCategory.fajr).enabled, isFalse);
     });
     test('update category time persists', () async {
       await repo.setCategoryTime(TaskCategory.fajr, 6, 15);
       final s = await repo.watchCategorySchedules().first;
       final fajr = s.firstWhere((x) => x.category == TaskCategory.fajr);
       expect(fajr.hour, 6);
       expect(fajr.minute, 15);
     });
     test('toggle task off persists', () async {
       await repo.setTaskEnabled(1, false);
       final t = await repo.watchTaskToggles().first;
       expect(t.firstWhere((x) => x.taskId == 1).notificationsEnabled, isFalse);
     });
     test('EOD settings round-trip', () async {
       await settingsRepo.setEodEnabled(false);
       await settingsRepo.setEodTime(22, 0);
       final s = await settingsRepo.watchEodSettings().first;
       expect(s.enabled, isFalse);
       expect(s.hour, 22);
       expect(s.minute, 0);
     });
     test('onboarding flag: starts false, persists true', () async {
       expect(await settingsRepo.getNotificationOnboardingDone(), isFalse);
       await settingsRepo.setNotificationOnboardingDone(true);
       expect(await settingsRepo.getNotificationOnboardingDone(), isTrue);
     });
   }
   ```

13.2. From `/app`: `flutter test test/features/settings/notification_settings_repository_test.dart` — all 7 cases must pass.

## 14. Platform integration — Windows runner setup

14.1. Open `app/windows/runner/main.cpp`. Add the `flutter_local_notifications` Windows notification activator boilerplate as specified in the [package README](https://pub.dev/packages/flutter_local_notifications):
   - Define a GUID for the app (generate once: e.g., via VS → Tools → Create GUID or an online tool).
   - Register the `NotificationActivator` COM class before `flutter_local_notifications` is initialized.

14.2. In `app/windows/runner/Runner.rc`, confirm the app name string resource reads `Muhasabah`.
14.3. From `/app`: `flutter build windows --debug` — must succeed without linker errors from `flutter_local_notifications`.
14.4. From `/app`: `flutter analyze` — clean.

## 15. Manual smoke — Windows

15.1. `flutter run -d windows`.
15.2. **Cold launch (fresh DB):** onboarding screen appears; bottom nav absent. Tap "Enable notifications" → onboarding marks done → shell opens.
15.3. Open Settings tab. Confirm 8 category tiles render with correct default times. EOD row shows 21:30. All toggles on.
15.4. Toggle Fajr **off**. Cold-restart. Confirm Fajr remains off.
15.5. Change Dhuhr time to **2 minutes from now**. Wait. Confirm a Windows notification appears in Action Center with title `"Dhuhr"` and body listing enabled Dhuhr tasks.
15.6. Expand Dhuhr tile. Toggle off 3 tasks. Set Dhuhr time to 2 minutes from now. Wait for next notification. Confirm the toggled-off tasks are absent from the body.
15.7. **EOD smoke (< 50 %):** complete < 50 % of today's tasks. Set EOD time to 2 minutes from now. Wait. EOD notification fires in Action Center with the `notifEodBody` copy and the correct percent.
15.8. **EOD smoke (≥ 50 %):** complete ≥ 50 % of tasks. Set EOD time to 2 minutes from now. EOD notification does **not** fire.
15.9. Toggle global notifications **off**. Confirm all scheduled notifications are cancelled (set a category 1 minute out; no notification arrives).

## 16. Manual smoke — Web

16.1. `flutter run -d chrome`.
16.2. **Cold launch:** onboarding screen appears. Click "Enable notifications" — browser permission banner appears.
16.3. Grant permission. Navigate to Settings. Set a category time 1 minute from now. Stay on the tab. Browser notification fires.
16.4. Confirm the `settingsWebNotificationNote` banner (`"Notifications require the app tab to be open."`) is visible in the Notifications section.
16.5. Open a fresh Chrome profile with notifications blocked for the domain. Confirm the Settings screen shows `"Notifications blocked in browser settings"` and the schedule UI is still shown (user can still configure times, they just won't fire until permission is granted).
16.6. **Tab close test:** start a 1-minute timer notification; close the tab before it fires; confirm no notification arrives after re-opening (timer was lost). This documents L1 — no action required; just verify the behaviour matches the documented limitation.

## 17. Localization — fill all new ARB keys (EN)

17.1. Open `app/l10n/app_en.arb`. Verify all 18 keys from `requirements.md` §3.12 are present and correctly valued.
17.2. From `/app`: `flutter pub get` — re-runs `gen-l10n`. Confirm `AppLocalizations.onboardingNotifTitle` etc. resolve.

## 18. Localization — Arabic placeholders

18.1. Open `app/l10n/app_ar.arb`. Add `TODO: …` values for every new key. Preserve `@key.placeholders` metadata identical to the English file for keyed/parameterized entries.

## 19. Lints, format, RTL guard

19.1. `dart format .`
19.2. `flutter analyze` — `No issues found!`
19.3. `dart format --output=none --set-exit-if-changed .` — exit 0.
19.4. **RTL guard:** `rg "EdgeInsets\.only\(left|right" app/lib/features/settings/ app/lib/features/notifications/` — zero hits.
19.5. **No raw hex guard:** `rg "Color\(0x" app/lib/features/settings/ app/lib/features/notifications/` — zero hits.
19.6. **Schema version guard:** `rg "schemaVersion" app/lib/core/database/app_database.dart` — single declaration `schemaVersion = 2`.
19.7. **Magic string guard:** `rg "notification_onboarding_done" app/lib/` — appears only in `AppSettingsRepository` (declaration) and its test. No bare string literals elsewhere.

## 20. Pre-merge — fill Arabic translations

20.1. Open `app/l10n/app_ar.arb`. Replace all `TODO:` placeholders with reviewed final Arabic copy.
20.2. `rg "TODO:" app/l10n/app_ar.arb` — must return **zero** matches.
20.3. Re-run group 19 (lints + format) and the locale-toggle smoke (Settings labels switch to Arabic).

## 21. CI

21.1. The mandatory test (group 13) runs under the existing `flutter test` invocation. **No workflow changes required.**
21.2. Confirm `api-lint` is still green — Phase 5 does not touch `/api`.

## 22. Wrap-up & handoff

22.1. Re-read `validation.md`; tick every acceptance check.
22.2. Update root `README.md` "Status" line:
   `Phase 5 ✅ — local notifications, settings screen, MVP shipped (Web + Windows)`
22.3. Add a "Specs" reference for this folder in `README.md` alongside Phase 0–4.
22.4. Open PR `feature/phase-5-local-notifications → master`. Paste a link to `specs/phase-5-2026-05-13-local-notifications/` in the PR description.
22.5. **PR description must include:**
   - Platform scope: "Validated on Web (Chrome) and Windows. Android/iOS deferred to Phase 6."
   - Schema note: "Drift schema v1 → v2; new tables: `category_notification_schedules`, `task_notification_toggles`, `app_settings`."
   - New dependencies: `flutter_local_notifications`, `flutter_timezone`, `package_info_plus`.
   - Phase 6 handoff flag (§22.6).
22.6. **Flag for Phase 6:** Android/iOS notification permission flows (`POST_NOTIFICATIONS` on Android 13+, `UNUserNotificationCenter` on iOS) should be added during Phase 6 onboarding. The `NativeNotificationService` already compiles for Android/iOS; only the permission and channel-creation paths need platform-specific additions.
22.7. **Flag for Phase 6:** The `app_settings` Drift table absorbs Phase 6 sync-preference keys (e.g., `sync_enabled`, `last_sync_at`) without a further migration — the open-ended key-value schema is ready.
22.8. Squash-merge once CI is green and all `validation.md` checks pass (including zero-TODO gate from group 20).
