import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../providers/sync_provider.dart';

/// Icon-only sync indicator for the header bar.
/// Shows a cloud icon with a colored badge for status.
/// Tappable: shows a snackbar with details or triggers retry.
class SyncStatusIndicator extends ConsumerWidget {
  const SyncStatusIndicator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncProvider);

    return GestureDetector(
      onTap: () => _onTap(context, ref, syncState),
      child: SizedBox(
        width: 32.w,
        height: 32.h,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Icon
            syncState.isSyncing
                ? SizedBox(
                    width: 20.w,
                    height: 20.h,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white.withOpacity(0.9),
                      ),
                    ),
                  )
                : Icon(
                    _getIcon(syncState),
                    size: 22.sp,
                    color: Colors.white.withOpacity(0.9),
                  ),
            // Status dot badge (top-right)
            Positioned(
              top: 2,
              right: 2,
              child: Container(
                width: 9.w,
                height: 9.h,
                decoration: BoxDecoration(
                  color: _getDotColor(syncState),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: DuukaColors.primary,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onTap(BuildContext context, WidgetRef ref, SyncState syncState) {
    if (syncState.isSyncing) {
      final msg = syncState.totalToSync > 0
          ? 'Syncing ${syncState.syncedInBatch}/${syncState.totalToSync}...'
          : 'Syncing ${syncState.pendingCount} items...';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), duration: const Duration(seconds: 1)),
      );
      return;
    }
    if (syncState.hasError || syncState.hasPending) {
      ref.read(syncProvider.notifier).clearFailedAndRetry();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(syncState.hasError
              ? 'Retrying ${syncState.pendingCount} failed items...'
              : 'Syncing ${syncState.pendingCount} pending items...'),
          duration: const Duration(seconds: 1),
        ),
      );
    } else if (syncState.status == SyncStatusType.synced) {
      ref.read(syncProvider.notifier).sync();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All synced'), duration: Duration(seconds: 1)),
      );
    }
  }

  IconData _getIcon(SyncState state) {
    switch (state.status) {
      case SyncStatusType.synced:
        return Icons.cloud_done_outlined;
      case SyncStatusType.syncing:
        return Icons.cloud_sync_outlined;
      case SyncStatusType.offline:
        return Icons.cloud_off_outlined;
      case SyncStatusType.error:
        return Icons.cloud_off_outlined;
    }
  }

  Color _getDotColor(SyncState state) {
    switch (state.status) {
      case SyncStatusType.synced:
        return DuukaColors.success;
      case SyncStatusType.syncing:
        return DuukaColors.warning;
      case SyncStatusType.offline:
        return state.hasPending ? DuukaColors.warning : DuukaColors.textHint;
      case SyncStatusType.error:
        return DuukaColors.error;
    }
  }
}

/// Full sync card for the home screen with detailed info and actions
class SyncCard extends ConsumerWidget {
  const SyncCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncProvider);

    // Don't show the card if everything is synced and no issues
    if (syncState.isSynced && !syncState.hasPending && !syncState.hasError) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: DuukaColors.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: _getBorderColor(syncState.status),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getIcon(syncState),
                size: 20.sp,
                color: _getIconColor(syncState.status),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  _getTitle(syncState),
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: DuukaColors.textPrimary,
                  ),
                ),
              ),
              if (syncState.isSyncing)
                SizedBox(
                  width: 16.w,
                  height: 16.h,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            _getDescription(syncState),
            style: TextStyle(
              fontSize: 12.sp,
              color: DuukaColors.textSecondary,
            ),
          ),
          if (syncState.isSyncing && syncState.totalToSync > 0) ...[
            SizedBox(height: 10.h),
            ClipRRect(
              borderRadius: BorderRadius.circular(4.r),
              child: LinearProgressIndicator(
                value: syncState.progress,
                backgroundColor: DuukaColors.border,
                valueColor: const AlwaysStoppedAnimation<Color>(DuukaColors.primary),
                minHeight: 4.h,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              '${syncState.syncedInBatch} of ${syncState.totalToSync} items synced',
              style: TextStyle(fontSize: 11.sp, color: DuukaColors.textHint),
            ),
          ],
          if (!syncState.isSyncing && syncState.lastSyncTime != null) ...[
            SizedBox(height: 4.h),
            Text(
              'Last sync: ${DuukaFormatters.relativeTime(syncState.lastSyncTime!)}',
              style: TextStyle(
                fontSize: 11.sp,
                color: DuukaColors.textHint,
              ),
            ),
          ],
          if (syncState.hasError || (syncState.hasPending && !syncState.isSyncing)) ...[
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ref.read(syncProvider.notifier).clearFailedAndRetry();
                    },
                    icon: Icon(Icons.refresh, size: 16.sp),
                    label: const Text('Retry Sync'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: DuukaColors.primary,
                      side: const BorderSide(color: DuukaColors.primary),
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      textStyle: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  IconData _getIcon(SyncState state) {
    switch (state.status) {
      case SyncStatusType.synced:
        return Icons.cloud_done_outlined;
      case SyncStatusType.syncing:
        return Icons.cloud_sync_outlined;
      case SyncStatusType.offline:
        return Icons.cloud_off_outlined;
      case SyncStatusType.error:
        return Icons.cloud_off_outlined;
    }
  }

  String _getTitle(SyncState state) {
    switch (state.status) {
      case SyncStatusType.synced:
        return 'All synced';
      case SyncStatusType.syncing:
        return 'Syncing ${state.pendingCount} items...';
      case SyncStatusType.offline:
        if (state.hasPending) return '${state.pendingCount} items waiting to sync';
        return 'You\'re offline';
      case SyncStatusType.error:
        return 'Sync needs attention';
    }
  }

  String _getDescription(SyncState state) {
    switch (state.status) {
      case SyncStatusType.synced:
        return 'Your data is up to date';
      case SyncStatusType.syncing:
        return 'Uploading changes to cloud...';
      case SyncStatusType.offline:
        if (state.hasPending) return 'Changes will sync when you\'re back online';
        return 'Connect to the internet to sync';
      case SyncStatusType.error:
        return state.error ?? 'Some items failed to sync. Tap retry to try again.';
    }
  }

  Color _getBorderColor(SyncStatusType status) {
    switch (status) {
      case SyncStatusType.synced:
        return DuukaColors.border;
      case SyncStatusType.syncing:
        return DuukaColors.warningLight;
      case SyncStatusType.offline:
        return DuukaColors.border;
      case SyncStatusType.error:
        return DuukaColors.errorLight;
    }
  }

  Color _getIconColor(SyncStatusType status) {
    switch (status) {
      case SyncStatusType.synced:
        return DuukaColors.success;
      case SyncStatusType.syncing:
        return DuukaColors.warning;
      case SyncStatusType.offline:
        return DuukaColors.textHint;
      case SyncStatusType.error:
        return DuukaColors.error;
    }
  }
}
