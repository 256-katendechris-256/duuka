import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../providers/sync_provider.dart';

/// Sync status indicator showing synced, syncing, pending, or offline state
class SyncStatusIndicator extends ConsumerWidget {
  const SyncStatusIndicator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncProvider);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: _getBackgroundColor(syncState.status),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildIndicator(syncState),
          SizedBox(width: 6.w),
          Text(
            _getStatusText(syncState),
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              color: _getTextColor(syncState.status),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicator(SyncState state) {
    switch (state.status) {
      case SyncStatusType.synced:
        return Container(
          width: 8.w,
          height: 8.h,
          decoration: BoxDecoration(
            color: DuukaColors.success,
            shape: BoxShape.circle,
          ),
        );

      case SyncStatusType.syncing:
        return SizedBox(
          width: 12.w,
          height: 12.h,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(DuukaColors.warning),
          ),
        );

      case SyncStatusType.offline:
        return Container(
          width: 8.w,
          height: 8.h,
          decoration: BoxDecoration(
            color: state.hasPending ? DuukaColors.warning : DuukaColors.textHint,
            shape: BoxShape.circle,
          ),
        );

      case SyncStatusType.error:
        return Container(
          width: 8.w,
          height: 8.h,
          decoration: BoxDecoration(
            color: DuukaColors.error,
            shape: BoxShape.circle,
          ),
        );
    }
  }

  String _getStatusText(SyncState state) {
    switch (state.status) {
      case SyncStatusType.synced:
        return 'Synced';

      case SyncStatusType.syncing:
        return 'Syncing...';

      case SyncStatusType.offline:
        if (state.hasPending) {
          return '${state.pendingCount} pending';
        }
        return 'Offline';

      case SyncStatusType.error:
        return 'Sync failed';
    }
  }

  Color _getBackgroundColor(SyncStatusType status) {
    switch (status) {
      case SyncStatusType.synced:
        return DuukaColors.successBg;
      case SyncStatusType.syncing:
        return DuukaColors.warningBg;
      case SyncStatusType.offline:
        return DuukaColors.background;
      case SyncStatusType.error:
        return DuukaColors.errorBg;
    }
  }

  Color _getTextColor(SyncStatusType status) {
    switch (status) {
      case SyncStatusType.synced:
        return DuukaColors.success;
      case SyncStatusType.syncing:
        return DuukaColors.warning;
      case SyncStatusType.offline:
        return DuukaColors.textSecondary;
      case SyncStatusType.error:
        return DuukaColors.error;
    }
  }
}
