import 'dart:ui';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color dotColor = Colors.grey;
    String statusText = 'Drive Offline';
    Widget icon = const Icon(Icons.cloud_off_rounded, size: 13, color: Colors.grey);

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
        icon = const Icon(Icons.sync_problem_rounded, size: 13, color: AppColors.warning);
      } else if (syncProv.pendingCount > 0) {
        dotColor = AppColors.accent;
        statusText = 'Sync Queued';
        icon = const Icon(Icons.cloud_upload_rounded, size: 13, color: AppColors.accent);
      } else {
        dotColor = AppColors.income;
        statusText = 'Drive Synced';
        icon = const Icon(Icons.cloud_done_rounded, size: 13, color: AppColors.income);
      }
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: dotColor.withOpacity(isDark ? 0.12 : 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: dotColor.withOpacity(isDark ? 0.35 : 0.45),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  icon,
                  const SizedBox(width: 5),
                  Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: dotColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
