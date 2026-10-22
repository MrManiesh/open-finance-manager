import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import '../database/database_helper.dart';
import '../preferences_service.dart';
import 'google_auth_service.dart';
import '../../models/sync_state.dart';

class DriveSyncService {
  static final DriveSyncService instance = DriveSyncService._internal();

  DriveSyncService._internal();

  static const String folderName = 'Open Finance Manager';
  static const String backupFileName = 'open_finance_vault.json';

  Timer? _debounceTimer;
  final StreamController<SyncState> _syncStateController =
      StreamController<SyncState>.broadcast();

  Stream<SyncState> get syncStateStream => _syncStateController.stream;

  SyncState _currentState = const SyncState();
  SyncState get currentState => _currentState;

  void _updateState(SyncState newState) {
    _currentState = newState;
    _syncStateController.add(newState);
  }

  void init() {
    final lastTimeStr = PreferencesService.getLastSyncTime();
    DateTime? lastTime;
    if (lastTimeStr != null) {
      try {
        lastTime = DateTime.parse(lastTimeStr);
      } catch (_) {}
    }
    _currentState = SyncState(
      status: SyncStatus.idle,
      lastSyncedAt: lastTime,
      isAutoSyncEnabled: PreferencesService.isAutoSyncEnabled(),
    );
  }

  /// Triggers debounced auto-sync whenever any transaction or group changes
  void notifyDataChanged() {
    if (!PreferencesService.isAutoSyncEnabled()) return;

    _updateState(_currentState.copyWith(
      pendingCount: _currentState.pendingCount + 1,
      status: SyncStatus.idle,
    ));

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 3), () {
      debugPrint('Auto-sync triggered due to recent change');
      syncNow();
    });
  }

  Future<bool> syncNow() async {
    final authClient = await GoogleAuthService.instance.getAuthenticatedClient();
    if (authClient == null) {
      _updateState(_currentState.copyWith(
        status: SyncStatus.error,
        message: 'Google account not connected. Sign in to enable Drive sync.',
      ));
      return false;
    }

    _updateState(_currentState.copyWith(
      status: SyncStatus.syncing,
      message: 'Syncing with Google Drive...',
    ));

    try {
      final driveApi = drive.DriveApi(authClient);

      // 1. Ensure folder exists in Drive
      final folderId = await _getOrCreateAppFolder(driveApi);

      // 2. Export local data
      final localData = await DatabaseHelper.instance.exportFullDatabaseToJson();
      final localJsonString = jsonEncode(localData);

      // 3. Search for existing backup file
      final fileList = await driveApi.files.list(
        q: "name = '$backupFileName' and '$folderId' in parents and trashed = false",
        spaces: 'drive',
        $fields: 'files(id, name, modifiedTime)',
      );

      final files = fileList.files;
      if (files != null && files.isNotEmpty) {
        final existingFile = files.first;

        // Download existing remote content to perform a merge
        try {
          final drive.Media media = await driveApi.files.get(
            existingFile.id!,
            downloadOptions: drive.DownloadOptions.fullMedia,
          ) as drive.Media;

          final remoteBytes = await media.stream.fold<List<int>>(
            [],
            (previous, element) => previous..addAll(element),
          );
          final remoteString = utf8.decode(remoteBytes);
          final Map<String, dynamic> remoteData = jsonDecode(remoteString);

          // Merge remote data into local database so we don't overwrite changes made on another device
          await DatabaseHelper.instance.importFullDatabaseFromJson(remoteData, overwrite: false);
        } catch (e) {
          debugPrint('Error reading remote file for merge: $e');
        }

        // Now re-export merged dataset and upload update
        final mergedData = await DatabaseHelper.instance.exportFullDatabaseToJson();
        final mergedJsonString = jsonEncode(mergedData);
        final mediaStream = Stream.value(utf8.encode(mergedJsonString));
        final uploadMedia = drive.Media(mediaStream, utf8.encode(mergedJsonString).length);

        final updateFile = drive.File();
        await driveApi.files.update(
          updateFile,
          existingFile.id!,
          uploadMedia: uploadMedia,
        );
      } else {
        // Create new backup file in folder
        final newFile = drive.File()
          ..name = backupFileName
          ..parents = [folderId]
          ..mimeType = 'application/json';

        final mediaStream = Stream.value(utf8.encode(localJsonString));
        final uploadMedia = drive.Media(mediaStream, utf8.encode(localJsonString).length);

        await driveApi.files.create(
          newFile,
          uploadMedia: uploadMedia,
        );
      }

      final now = DateTime.now();
      await PreferencesService.setLastSyncTime(now.toIso8601String());

      _updateState(_currentState.copyWith(
        status: SyncStatus.success,
        lastSyncedAt: now,
        pendingCount: 0,
        message: 'Successfully synced with Google Drive',
      ));
      return true;
    } catch (e) {
      debugPrint('Sync failed: $e');
      _updateState(_currentState.copyWith(
        status: SyncStatus.error,
        message: 'Sync failed: ${e.toString()}',
      ));
      return false;
    }
  }

  Future<String> _getOrCreateAppFolder(drive.DriveApi driveApi) async {
    final search = await driveApi.files.list(
      q: "mimeType = 'application/vnd.google-apps.folder' and name = '$folderName' and trashed = false",
      spaces: 'drive',
      $fields: 'files(id, name)',
    );

    if (search.files != null && search.files!.isNotEmpty) {
      return search.files!.first.id!;
    }

    final folder = drive.File()
      ..name = folderName
      ..mimeType = 'application/vnd.google-apps.folder';

    final createdFolder = await driveApi.files.create(folder);
    return createdFolder.id!;
  }

  void dispose() {
    _debounceTimer?.cancel();
    _syncStateController.close();
  }
}
