import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'sync_service.dart';

/// Coordinates *when* the backend sync runs.
///
/// The checklist tap path only writes locally; this scheduler decides when to
/// flush `pending_sync_ops` to the backend:
///
/// - foreground heartbeat (every [_heartbeatPeriod])
/// - on app resume (pull deltas + restart heartbeat)
/// - on app pause/inactive/hidden/detached (flush before going away)
final class SyncScheduler extends WidgetsBindingObserver {
  SyncScheduler(this._sync);

  static const Duration _heartbeatPeriod = Duration(seconds: 30);

  final SyncService _sync;
  Timer? _heartbeat;
  bool _started = false;

  void start() {
    if (_started) {
      return;
    }
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    _startHeartbeat();
    unawaited(_sync.syncNow());
  }

  void _startHeartbeat() {
    _heartbeat?.cancel();
    _heartbeat = Timer.periodic(
      _heartbeatPeriod,
      (_) => unawaited(_sync.syncNow()),
    );
  }

  void _stopHeartbeat() {
    _heartbeat?.cancel();
    _heartbeat = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _startHeartbeat();
        unawaited(_sync.syncNow());
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        _stopHeartbeat();
        unawaited(_sync.syncNow());
    }
  }

  void dispose() {
    if (!_started) {
      return;
    }
    _stopHeartbeat();
    WidgetsBinding.instance.removeObserver(this);
    _started = false;
  }
}

final syncSchedulerProvider = Provider<SyncScheduler>((ref) {
  final scheduler = SyncScheduler(ref.watch(syncServiceProvider));
  ref.onDispose(scheduler.dispose);
  return scheduler;
});
