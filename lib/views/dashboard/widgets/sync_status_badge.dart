import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/sync_state.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/sync_provider.dart';

class SyncStatusBadge extends StatelessWidget {
  final VoidCallback onTap;

  const SyncStatusBadge({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final authProv = context.watch<AuthProvider>();
    final syncProv = context.watch<SyncProvider>();

    Color dotColor = Colors.grey;
    String statusText = 'Not Connected';
    Widget icon = const Icon(Icons.cloud_off_rounded, size: 14, color: Colors.grey);

    if (authProv.isSignedIn) {
      if (syncProv.status == SyncStatus.syncing) {
        dotColor = AppColors.info;
        statusText = 'Syncing...';
        icon = const SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.info),
        );
      } else if (syncProv.status == SyncStatus.error) {
        dotColor = AppColors.warning;
        statusText = 'Sync Error';
        icon = const Icon(Icons.sync_problem_rounded, size: 14, color: AppColors.warning);
      } else if (syncProv.pendingCount > 0) {
        dotColor = AppColors.accent;
        statusText = 'Sync Queued';
        icon = const Icon(Icons.cloud_upload_rounded, size: 14, color: AppColors.accent);
      } else {
        dotColor = AppColors.income;
        statusText = 'Drive Synced';
        icon = const Icon(Icons.cloud_done_rounded, size: 14, color: AppColors.income);
      }
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: dotColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: dotColor.withOpacity(0.3), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            const SizedBox(width: 6),
            Text(
              statusText,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: dotColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
