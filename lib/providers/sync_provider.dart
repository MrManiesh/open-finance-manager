import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/sync_state.dart';
import '../services/drive/drive_sync_service.dart';
import '../services/preferences_service.dart';

class SyncProvider extends ChangeNotifier {
  late SyncState _state;
  StreamSubscription<SyncState>? _subscription;

  SyncState get state => _state;
  SyncStatus get status => _state.status;
  DateTime? get lastSyncedAt => _state.lastSyncedAt;
  bool get isAutoSyncEnabled => _state.isAutoSyncEnabled;
  int get pendingCount => _state.pendingCount;
  String? get message => _state.message;

  SyncProvider() {
    _state = DriveSyncService.instance.currentState;
    _subscription = DriveSyncService.instance.syncStateStream.listen((newState) {
      _state = newState;
      notifyListeners();
    });
  }

  Future<void> toggleAutoSync(bool enabled) async {
    await PreferencesService.setAutoSyncEnabled(enabled);
    _state = _state.copyWith(isAutoSyncEnabled: enabled);
    notifyListeners();
  }

  Future<bool> triggerManualSync() async {
    return await DriveSyncService.instance.syncNow();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
