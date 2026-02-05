import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../data/models/models.dart';
import '../../../data/services/data_export_import_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/business_provider.dart';
import '../../providers/sync_provider.dart';
import '../../widgets/common/duuka_app_bar.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _lowStockAlerts = true;
  bool _dailySummary = false;
  bool _biometricEnabled = false;

  // Export/Import state
  final _exportService = DataExportImportService();
  bool _isExporting = false;
  bool _isImporting = false;

  @override
  Widget build(BuildContext context) {
    final businessAsync = ref.watch(businessNotifierProvider);
    final authState = ref.watch(authProvider);
    final isOwner = authState.user?.role == UserRole.owner;
    final isManager = authState.user?.role == UserRole.manager;
    final canViewBusinessSettings = isOwner || isManager;

    return Scaffold(
      backgroundColor: DuukaColors.background,
      appBar: DuukaAppBar(
        title: 'Settings',
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Business Profile Section (Owner & Manager only)
            if (canViewBusinessSettings) ...[
              _buildSectionHeader('Business Profile'),
              if (isOwner) // Only owner can edit business info
                _SettingsTile(
                  icon: Icons.store,
                  title: 'Business Information',
                  subtitle: businessAsync.when(
                    data: (business) => business?.name ?? 'Set up your business',
                    loading: () => 'Loading...',
                    error: (_, __) => 'Tap to set up',
                  ),
                  onTap: () => _showBusinessInfoDialog(),
                ),
              if (isOwner) // Only owner can manage team
                _SettingsTile(
                  icon: Icons.people,
                  title: 'Team Management',
                  subtitle: 'Invite staff and manage permissions',
                  onTap: () => context.push('/team'),
                ),
              _SettingsTile(
                icon: Icons.receipt_long,
                title: 'Receipt Settings',
                subtitle: 'Customize receipt appearance',
                onTap: () => _showReceiptSettings(),
              ),
              _SettingsTile(
                icon: Icons.category,
                title: 'Product Categories',
                subtitle: 'Manage product categories',
                onTap: () => _showCategoriesManager(),
              ),
            ],

            // Notifications Section
            _buildSectionHeader('Notifications'),
            _SettingsSwitch(
              icon: Icons.notifications,
              title: 'Push Notifications',
              subtitle: 'Receive app notifications',
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() => _notificationsEnabled = value);
              },
            ),
            _SettingsSwitch(
              icon: Icons.inventory_2,
              title: 'Low Stock Alerts',
              subtitle: 'Get notified when stock is low',
              value: _lowStockAlerts,
              onChanged: (value) {
                setState(() => _lowStockAlerts = value);
              },
            ),
            _SettingsSwitch(
              icon: Icons.summarize,
              title: 'Daily Summary',
              subtitle: 'Receive daily sales summary',
              value: _dailySummary,
              onChanged: (value) {
                setState(() => _dailySummary = value);
              },
            ),

            // Data & Sync Section (Owner only)
            if (isOwner) ...[
              _buildSectionHeader('Data & Sync'),
              _SettingsTile(
                icon: Icons.cloud_sync,
                title: 'Sync Status',
                subtitle: 'All data synced',
                trailing: Container(
                  width: 8.w,
                  height: 8.h,
                  decoration: const BoxDecoration(
                    color: DuukaColors.success,
                    shape: BoxShape.circle,
                  ),
                ),
                onTap: () => _showSyncStatus(),
              ),
              _SettingsTile(
                icon: Icons.cloud_download,
                title: 'Restore from Cloud',
                subtitle: 'Restore all data from Supabase',
                onTap: () => _showRestoreFromCloudDialog(),
              ),
              _SettingsTile(
                icon: Icons.backup,
                title: 'Backup Data',
                subtitle: 'Export your data',
                onTap: () => _showBackupOptions(),
              ),
              _SettingsTile(
                icon: Icons.download,
                title: 'Import Data',
                subtitle: 'Import from backup',
                onTap: () => _showImportOptions(),
              ),
            ],

            // Security Section
            _buildSectionHeader('Security'),
            _SettingsSwitch(
              icon: Icons.fingerprint,
              title: 'Biometric Login',
              subtitle: 'Use fingerprint or face ID',
              value: _biometricEnabled,
              onChanged: (value) {
                setState(() => _biometricEnabled = value);
              },
            ),
            _SettingsTile(
              icon: Icons.lock,
              title: 'Change PIN',
              subtitle: 'Update your security PIN',
              onTap: () => _showChangePinDialog(),
            ),

            // Support Section
            _buildSectionHeader('Support'),
            _SettingsTile(
              icon: Icons.help_outline,
              title: 'Help & FAQ',
              subtitle: 'Get help using Duuka',
              onTap: () => _showHelpScreen(),
            ),
            _SettingsTile(
              icon: Icons.feedback_outlined,
              title: 'Send Feedback',
              subtitle: 'Tell us how we can improve',
              onTap: () => _showFeedbackDialog(),
            ),
            _SettingsTile(
              icon: Icons.info_outline,
              title: 'About Duuka',
              subtitle: 'Version 1.0.0',
              onTap: () => _showAboutDialog(),
            ),

            // Logout Section
            SizedBox(height: 16.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showLogoutConfirmation(),
                  icon: Icon(Icons.logout, color: DuukaColors.error, size: 20.sp),
                  label: Text(
                    'Logout',
                    style: TextStyle(
                      color: DuukaColors.error,
                      fontWeight: FontWeight.w600,
                      fontSize: 14.sp,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: DuukaColors.error),
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 32.h),

            // App Info
            Center(
              child: Column(
                children: [
                  Text(
                    'Duuka',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: DuukaColors.primary,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Version 1.0.0',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: DuukaColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    '© 2025 Duuka. All rights reserved.',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: DuukaColors.textHint,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 100.h),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 24.h, 16.w, 8.h),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13.sp,
          fontWeight: FontWeight.w600,
          color: DuukaColors.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  void _showBusinessInfoDialog() {
    final businessAsync = ref.read(businessNotifierProvider);
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final addressController = TextEditingController();

    businessAsync.whenData((business) {
      nameController.text = business?.name ?? '';
      phoneController.text = business?.phone ?? '';
      addressController.text = business?.address ?? '';
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: DuukaColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: DuukaColors.border,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              SizedBox(height: 20.h),
              Text(
                'Business Information',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w700,
                  color: DuukaColors.textPrimary,
                ),
              ),
              SizedBox(height: 20.h),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Business Name',
                  prefixIcon: Icon(Icons.store, size: 20.sp),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone, size: 20.sp),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              TextField(
                controller: addressController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Business Address',
                  prefixIcon: Icon(Icons.location_on, size: 20.sp),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
              SizedBox(height: 24.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final currentBusiness = ref.read(businessNotifierProvider).value;
                    if (currentBusiness != null) {
                      currentBusiness.name = nameController.text.trim();
                      currentBusiness.phone = phoneController.text.trim();
                      currentBusiness.address = addressController.text.trim();
                      currentBusiness.updatedAt = DateTime.now();
                      await ref.read(businessNotifierProvider.notifier).updateBusiness(currentBusiness);
                    }
                    if (mounted) Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DuukaColors.primary,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: Text(
                    'Save Changes',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }

  void _showReceiptSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: DuukaColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: DuukaColors.border,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              'Receipt Settings',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 20.h),
            ListTile(
              leading: Icon(Icons.store, color: DuukaColors.primary),
              title: const Text('Show Business Logo'),
              trailing: Switch(
                value: true,
                onChanged: (value) {},
                activeColor: DuukaColors.primary,
              ),
            ),
            ListTile(
              leading: Icon(Icons.phone, color: DuukaColors.primary),
              title: const Text('Show Contact Info'),
              trailing: Switch(
                value: true,
                onChanged: (value) {},
                activeColor: DuukaColors.primary,
              ),
            ),
            ListTile(
              leading: Icon(Icons.message, color: DuukaColors.primary),
              title: const Text('Custom Footer Message'),
              subtitle: const Text('Thank you for shopping with us!'),
              onTap: () {},
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  void _showCategoriesManager() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Categories manager coming soon')),
    );
  }

  void _showSyncStatus() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.cloud_done, color: DuukaColors.success),
            SizedBox(width: 8.w),
            const Text('Sync Status'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSyncRow('Products', 'Synced', true),
            SizedBox(height: 8.h),
            _buildSyncRow('Sales', 'Synced', true),
            SizedBox(height: 8.h),
            _buildSyncRow('Customers', 'Synced', true),
            SizedBox(height: 8.h),
            _buildSyncRow('Expenses', 'Synced', true),
            SizedBox(height: 16.h),
            Text(
              'Last synced: Just now',
              style: TextStyle(
                fontSize: 12.sp,
                color: DuukaColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Syncing data...')),
              );
              // Actually trigger sync with retry of failed items
              await ref.read(syncProvider.notifier).clearFailedAndRetry();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: DuukaColors.primary,
            ),
            child: const Text('Sync Now', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncRow(String label, String status, bool isSynced) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Row(
          children: [
            Icon(
              isSynced ? Icons.check_circle : Icons.pending,
              size: 16.sp,
              color: isSynced ? DuukaColors.success : DuukaColors.warning,
            ),
            SizedBox(width: 4.w),
            Text(
              status,
              style: TextStyle(
                color: isSynced ? DuukaColors.success : DuukaColors.warning,
                fontSize: 12.sp,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showBackupOptions() async {
    // Get collection counts
    final counts = await _exportService.getCollectionCounts();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _ExportDataSheet(
        counts: counts,
        onExport: _handleExport,
      ),
    );
  }

  void _showImportOptions() async {
    try {
      // Pick file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );

      if (result == null || result.files.single.path == null) return;

      final file = File(result.files.single.path!);

      if (!mounted) return;

      // Preview import
      context.showInfoSnackBar('Analyzing file...');
      final preview = await _exportService.previewImport(file);

      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();

      // Show import preview dialog
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (context) => _ImportPreviewSheet(
          file: file,
          preview: preview,
          onImport: _handleImport,
        ),
      );
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Failed to read file: $e');
      }
    }
  }

  Future<void> _handleExport(
    List<DataCollection> collections,
    ExportFormat format,
  ) async {
    if (collections.isEmpty) {
      context.showErrorSnackBar('Please select at least one collection');
      return;
    }

    setState(() => _isExporting = true);

    try {
      File file;
      final businessName = ref.read(businessNotifierProvider).valueOrNull?.name ?? 'My Business';

      if (format == ExportFormat.excel) {
        context.showInfoSnackBar('Exporting to Excel...');
        file = await _exportService.exportToExcel(collections, businessName: businessName);
      } else {
        context.showInfoSnackBar('Generating PDF...');
        file = await _exportService.exportToPDF(collections, businessName: businessName);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();

      // Share file
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: '$businessName Data Export',
        text: 'Backup from $businessName',
      );

      if (mounted) {
        Navigator.pop(context); // Close export dialog
        context.showSuccessSnackBar(
          format == ExportFormat.excel
              ? 'Excel export complete!'
              : 'PDF export complete!',
        );
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Export failed: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _handleImport(File file, ImportMode mode) async {
    // Close preview dialog
    Navigator.pop(context);

    setState(() => _isImporting = true);

    try {
      context.showInfoSnackBar('Importing data...');

      // For now, since import is not fully implemented, show a message
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();

      context.showInfoSnackBar(
        'Import functionality is being finalized. Export feature is ready to use!',
      );
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Import failed: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isImporting = false);
      }
    }
  }

  void _showChangePinDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('PIN change coming soon')),
    );
  }

  void _showHelpScreen() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: DuukaColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  children: [
                    Container(
                      width: 40.w,
                      height: 4.h,
                      decoration: BoxDecoration(
                        color: DuukaColors.border,
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'Help & FAQ',
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  children: [
                    _buildFaqItem(
                      'How do I add a new product?',
                      'Go to Inventory > Tap the + button > Fill in product details > Save.',
                    ),
                    _buildFaqItem(
                      'How do I record a sale?',
                      'Tap "New Sale" on the home screen > Select products > Go to cart > Complete checkout.',
                    ),
                    _buildFaqItem(
                      'How do I handle credit sales?',
                      'During checkout, select "Credit" as payment method > Choose customer > Set payment date.',
                    ),
                    _buildFaqItem(
                      'How do I track expenses?',
                      'Go to Expenses from home > Tap + to add new expense > Fill details > Save.',
                    ),
                    _buildFaqItem(
                      'How do I view reports?',
                      'Tap Reports in the bottom navigation to see sales, profit, and inventory reports.',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return ExpansionTile(
      title: Text(
        question,
        style: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
          child: Text(
            answer,
            style: TextStyle(
              fontSize: 13.sp,
              color: DuukaColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  void _showFeedbackDialog() {
    final feedbackController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: DuukaColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: DuukaColors.border,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              SizedBox(height: 20.h),
              Text(
                'Send Feedback',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 16.h),
              TextField(
                controller: feedbackController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Tell us what you think...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Thank you for your feedback!'),
                        backgroundColor: DuukaColors.success,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DuukaColors.primary,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: Text(
                    'Submit Feedback',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: DuukaColors.primaryBg,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(Icons.store, color: DuukaColors.primary, size: 24.sp),
            ),
            SizedBox(width: 12.w),
            const Text('Duuka'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Version 1.0.0',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'Duuka is a simple and powerful POS solution designed for small businesses in Africa.',
              style: TextStyle(
                fontSize: 13.sp,
                color: DuukaColors.textSecondary,
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              '© 2025 Duuka. All rights reserved.',
              style: TextStyle(
                fontSize: 11.sp,
                color: DuukaColors.textHint,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  bool _isRestoring = false;

  void _showRestoreFromCloudDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.cloud_download, color: DuukaColors.primary),
            SizedBox(width: 12.w),
            const Text('Restore from Cloud'),
          ],
        ),
        content: const Text(
          'This will restore all your products, customers, sales, and expenses from the cloud.\n\nExisting local data will be kept.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performRestore();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: DuukaColors.primary,
            ),
            child: const Text('Restore', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _performRestore() async {
    if (_isRestoring) return;

    setState(() => _isRestoring = true);

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            SizedBox(width: 20.w),
            const Text('Restoring data...'),
          ],
        ),
      ),
    );

    try {
      final success = await ref.read(authProvider.notifier).restoreDataFromCloud();

      if (mounted) Navigator.pop(context); // Close loading dialog

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? 'Data restored successfully!'
                : 'Restore failed. Check logs for details.'),
            backgroundColor: success ? DuukaColors.success : DuukaColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // Close loading dialog
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: DuukaColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isRestoring = false);
    }
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _handleLogout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: DuukaColors.error,
            ),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout() async {
    final user = ref.read(authProvider).user;
    final isLocalUser = user?.uid?.startsWith('local_') == true;

    if (isLocalUser) {
      await ref.read(authProvider.notifier).signOut();
      if (mounted) {
        context.go('/pin/login');
      }
      return;
    }

    await ref.read(authProvider.notifier).signOut(clearLocalAuth: true);
    if (mounted) {
      context.go('/login');
    }
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: DuukaColors.surface,
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: DuukaColors.primaryBg,
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(icon, size: 20.sp, color: DuukaColors.primary),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: DuukaColors.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12.sp,
            color: DuukaColors.textSecondary,
          ),
        ),
        trailing: trailing ?? Icon(Icons.chevron_right, color: DuukaColors.textSecondary),
        onTap: onTap,
      ),
    );
  }
}

class _SettingsSwitch extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsSwitch({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: DuukaColors.surface,
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: DuukaColors.primaryBg,
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(icon, size: 20.sp, color: DuukaColors.primary),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: DuukaColors.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12.sp,
            color: DuukaColors.textSecondary,
          ),
        ),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: DuukaColors.primary,
        ),
      ),
    );
  }
}

// Export Data Sheet Widget
class _ExportDataSheet extends StatefulWidget {
  final Map<DataCollection, int> counts;
  final Function(List<DataCollection>, ExportFormat) onExport;

  const _ExportDataSheet({
    required this.counts,
    required this.onExport,
  });

  @override
  State<_ExportDataSheet> createState() => _ExportDataSheetState();
}

class _ExportDataSheetState extends State<_ExportDataSheet> {
  final _selectedCollections = <DataCollection>{};
  bool _selectAll = false;

  @override
  void initState() {
    super.initState();
    // Pre-select collections with data (except sensitive ones)
    for (final entry in widget.counts.entries) {
      if (entry.value > 0 &&
          entry.key != DataCollection.users &&
          entry.key != DataCollection.syncQueue) {
        _selectedCollections.add(entry.key);
      }
    }
    _updateSelectAll();
  }

  void _updateSelectAll() {
    final availableCollections = widget.counts.entries
        .where((e) => e.value > 0)
        .map((e) => e.key)
        .toList();
    _selectAll = _selectedCollections.length == availableCollections.length;
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selectAll) {
        _selectedCollections.clear();
      } else {
        for (final entry in widget.counts.entries) {
          if (entry.value > 0) {
            _selectedCollections.add(entry.key);
          }
        }
      }
      _updateSelectAll();
    });
  }

  String _getCollectionName(DataCollection collection) {
    switch (collection) {
      case DataCollection.products:
        return 'Products';
      case DataCollection.customers:
        return 'Customers';
      case DataCollection.sales:
        return 'Sales';
      case DataCollection.credits:
        return 'Credit Transactions';
      case DataCollection.creditPayments:
        return 'Credit Payments';
      case DataCollection.expenses:
        return 'Expenses';
      case DataCollection.business:
        return 'Business Profile';
      case DataCollection.users:
        return 'User Accounts';
      case DataCollection.syncQueue:
        return 'Sync Queue';
    }
  }

  IconData _getCollectionIcon(DataCollection collection) {
    switch (collection) {
      case DataCollection.products:
        return Icons.inventory_2;
      case DataCollection.customers:
        return Icons.people;
      case DataCollection.sales:
        return Icons.shopping_cart;
      case DataCollection.credits:
        return Icons.credit_card;
      case DataCollection.creditPayments:
        return Icons.payment;
      case DataCollection.expenses:
        return Icons.receipt_long;
      case DataCollection.business:
        return Icons.store;
      case DataCollection.users:
        return Icons.person;
      case DataCollection.syncQueue:
        return Icons.sync;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DuukaColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: EdgeInsets.only(top: 12.h),
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: DuukaColors.border,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(
                  'Export Data',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                    color: DuukaColors.textPrimary,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Select data to export',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: DuukaColors.textSecondary,
                  ),
                ),
                SizedBox(height: 20.h),

                // Select All button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      onPressed: _toggleSelectAll,
                      icon: Icon(
                        _selectAll ? Icons.deselect : Icons.select_all,
                        size: 18.sp,
                      ),
                      label: Text(_selectAll ? 'Deselect All' : 'Select All'),
                    ),
                    Text(
                      '${_selectedCollections.length} selected',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: DuukaColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),

                // Collection checkboxes
                ...DataCollection.values.map((collection) {
                  final count = widget.counts[collection] ?? 0;
                  final isEmpty = count == 0;

                  return CheckboxListTile(
                    enabled: !isEmpty,
                    value: _selectedCollections.contains(collection),
                    onChanged: isEmpty
                        ? null
                        : (value) {
                            setState(() {
                              if (value == true) {
                                _selectedCollections.add(collection);
                              } else {
                                _selectedCollections.remove(collection);
                              }
                              _updateSelectAll();
                            });
                          },
                    activeColor: DuukaColors.primary,
                    contentPadding: EdgeInsets.zero,
                    title: Row(
                      children: [
                        Icon(
                          _getCollectionIcon(collection),
                          size: 18.sp,
                          color: isEmpty
                              ? DuukaColors.textHint
                              : DuukaColors.primary,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          _getCollectionName(collection),
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: isEmpty
                                ? DuukaColors.textHint
                                : DuukaColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    subtitle: Text(
                      isEmpty ? '(empty)' : '$count records',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: DuukaColors.textSecondary,
                      ),
                    ),
                  );
                }).toList(),

                SizedBox(height: 20.h),

                // Export format buttons
                Text(
                  'Export Format',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: DuukaColors.textPrimary,
                  ),
                ),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => widget.onExport(
                          _selectedCollections.toList(),
                          ExportFormat.excel,
                        ),
                        icon: Icon(Icons.table_chart, size: 20.sp),
                        label: const Text('Excel\nBackup'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: DuukaColors.success,
                          side: BorderSide(color: DuukaColors.success),
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => widget.onExport(
                          _selectedCollections.toList(),
                          ExportFormat.pdf,
                        ),
                        icon: Icon(Icons.picture_as_pdf, size: 20.sp),
                        label: const Text('PDF\nReport'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: DuukaColors.error,
                          side: BorderSide(color: DuukaColors.error),
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),

                // Warning
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: DuukaColors.warningBg,
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: DuukaColors.warning.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: DuukaColors.warning,
                        size: 20.sp,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'The export file contains sensitive business data. Share securely.',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: DuukaColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Import Preview Sheet Widget
class _ImportPreviewSheet extends StatefulWidget {
  final File file;
  final ImportPreview preview;
  final Function(File, ImportMode) onImport;

  const _ImportPreviewSheet({
    required this.file,
    required this.preview,
    required this.onImport,
  });

  @override
  State<_ImportPreviewSheet> createState() => _ImportPreviewSheetState();
}

class _ImportPreviewSheetState extends State<_ImportPreviewSheet> {
  ImportMode _selectedMode = ImportMode.merge;

  String _getCollectionName(DataCollection collection) {
    switch (collection) {
      case DataCollection.products:
        return 'Products';
      case DataCollection.customers:
        return 'Customers';
      case DataCollection.sales:
        return 'Sales';
      case DataCollection.credits:
        return 'Credit Transactions';
      case DataCollection.creditPayments:
        return 'Credit Payments';
      case DataCollection.expenses:
        return 'Expenses';
      case DataCollection.business:
        return 'Business Profile';
      case DataCollection.users:
        return 'User Accounts';
      case DataCollection.syncQueue:
        return 'Sync Queue';
    }
  }

  @override
  Widget build(BuildContext context) {
    final fileName = widget.file.path.split(Platform.pathSeparator).last;

    return Container(
      decoration: BoxDecoration(
        color: DuukaColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: EdgeInsets.only(top: 12.h),
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: DuukaColors.border,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(
                  'Import Preview',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                    color: DuukaColors.textPrimary,
                  ),
                ),
                SizedBox(height: 8.h),
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: DuukaColors.primaryBg,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.table_chart,
                        color: DuukaColors.primary,
                        size: 20.sp,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          fileName,
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: DuukaColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20.h),

                // Data found
                Text(
                  'Data Found',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: DuukaColors.textPrimary,
                  ),
                ),
                SizedBox(height: 12.h),

                ...widget.preview.collectionCounts.entries.map((entry) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: 8.h),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _getCollectionName(entry.key),
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: DuukaColors.textPrimary,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            color: DuukaColors.successBg,
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Text(
                            '${entry.value} records',
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: DuukaColors.success,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),

                SizedBox(height: 20.h),

                // Import mode
                Text(
                  'Import Mode',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: DuukaColors.textPrimary,
                  ),
                ),
                SizedBox(height: 12.h),

                RadioListTile<ImportMode>(
                  value: ImportMode.replace,
                  groupValue: _selectedMode,
                  onChanged: (value) {
                    setState(() => _selectedMode = value!);
                  },
                  activeColor: DuukaColors.primary,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Replace All'),
                  subtitle: const Text('Clear existing data first'),
                ),

                RadioListTile<ImportMode>(
                  value: ImportMode.merge,
                  groupValue: _selectedMode,
                  onChanged: (value) {
                    setState(() => _selectedMode = value!);
                  },
                  activeColor: DuukaColors.primary,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Merge with Existing'),
                  subtitle: const Text('Keep existing, add new'),
                ),

                SizedBox(height: 16.h),

                // Warnings
                if (widget.preview.warnings.isNotEmpty) ...[
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: DuukaColors.warningBg,
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: DuukaColors.warning.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: widget.preview.warnings
                          .map((warning) => Padding(
                                padding: EdgeInsets.only(bottom: 4.h),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.warning_amber_rounded,
                                      color: DuukaColors.warning,
                                      size: 16.sp,
                                    ),
                                    SizedBox(width: 8.w),
                                    Expanded(
                                      child: Text(
                                        warning,
                                        style: TextStyle(
                                          fontSize: 11.sp,
                                          color: DuukaColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                  SizedBox(height: 16.h),
                ],

                // Danger warning
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: DuukaColors.errorBg,
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: DuukaColors.error.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: DuukaColors.error,
                        size: 20.sp,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'This action cannot be undone. Make sure you have a backup.',
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                            color: DuukaColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 20.h),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          widget.onImport(widget.file, _selectedMode);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: DuukaColors.primary,
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        child: Text(
                          'Import',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      ],
    ),
  );
  }
}
