enum SyncStatus {
  idle,
  syncing,
  success,
  error;

  bool get isSyncing => this == SyncStatus.syncing;
  bool get isSuccess => this == SyncStatus.success;
  bool get isError => this == SyncStatus.error;
}

class SyncState {
  final SyncStatus status;
  final DateTime? lastSyncedAt;
  final String? message;
  final int pendingCount;
  final bool isAutoSyncEnabled;

  const SyncState({
    this.status = SyncStatus.idle,
    this.lastSyncedAt,
    this.message,
    this.pendingCount = 0,
    this.isAutoSyncEnabled = true,
  });

  SyncState copyWith({
    SyncStatus? status,
    DateTime? lastSyncedAt,
    String? message,
    int? pendingCount,
    bool? isAutoSyncEnabled,
  }) {
    return SyncState(
      status: status ?? this.status,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      message: message,
      pendingCount: pendingCount ?? this.pendingCount,
      isAutoSyncEnabled: isAutoSyncEnabled ?? this.isAutoSyncEnabled,
    );
  }
}
