import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/models.dart';
import '../../providers/invoice_provider.dart';
import '../../widgets/common/duuka_app_bar.dart';
import '../../widgets/common/empty_state.dart';

class InvoicesListScreen extends ConsumerStatefulWidget {
  const InvoicesListScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<InvoicesListScreen> createState() => _InvoicesListScreenState();
}

class _InvoicesListScreenState extends ConsumerState<InvoicesListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: DuukaAppBar(
        title: 'Invoices',
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => context.push('/invoice/create'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: EdgeInsets.all(16.w),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
              decoration: InputDecoration(
                hintText: 'Search invoices...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
            ),
          ),
          // Tabs
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'All'),
              Tab(text: 'Draft'),
              Tab(text: 'Pending'),
              Tab(text: 'Paid'),
              Tab(text: 'Overdue'),
            ],
          ),
          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAllInvoices(context),
                _buildDraftInvoices(context),
                _buildPendingInvoices(context),
                _buildPaidInvoices(context),
                _buildOverdueInvoices(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllInvoices(BuildContext context) {
    return ref.watch(invoicesProvider).when(
          data: (invoices) {
            if (invoices.isEmpty) {
              return const EmptyState(
                title: 'No Invoices',
                description: 'Create your first invoice',
              );
            }
            
            final filtered = _searchQuery.isEmpty
                ? invoices
                : invoices
                    .where((inv) =>
                        inv.invoiceNumber.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                        (inv.customerName?.toLowerCase() ?? '')
                            .contains(_searchQuery.toLowerCase()))
                    .toList();

            if (filtered.isEmpty) {
              return const EmptyState(
                title: 'No Results',
                description: 'Try a different search',
              );
            }

            return ListView.builder(
              padding: EdgeInsets.all(16.w),
              itemCount: filtered.length,
              itemBuilder: (context, index) =>
                  _buildInvoiceCard(context, filtered[index]),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Text('Error: $error'),
          ),
        );
  }

  Widget _buildDraftInvoices(BuildContext context) {
    return ref.watch(draftInvoicesProvider).when(
          data: (invoices) => invoices.isEmpty
              ? const EmptyState(
                  title: 'No Draft Invoices',
                  description: 'Create a new invoice',
                )
              : ListView.builder(
                  padding: EdgeInsets.all(16.w),
                  itemCount: invoices.length,
                  itemBuilder: (context, index) =>
                      _buildInvoiceCard(context, invoices[index]),
                ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Text('Error: $error'),
          ),
        );
  }

  Widget _buildPendingInvoices(BuildContext context) {
    return ref.watch(pendingInvoicesProvider).when(
          data: (invoices) => invoices.isEmpty
              ? const EmptyState(
                  title: 'No Pending Invoices',
                  description: 'All invoices are paid!',
                )
              : ListView.builder(
                  padding: EdgeInsets.all(16.w),
                  itemCount: invoices.length,
                  itemBuilder: (context, index) =>
                      _buildInvoiceCard(context, invoices[index]),
                ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Text('Error: $error'),
          ),
        );
  }

  Widget _buildPaidInvoices(BuildContext context) {
    return ref.watch(paidInvoicesProvider).when(
          data: (invoices) => invoices.isEmpty
              ? const EmptyState(
                  title: 'No Paid Invoices',
                  description: 'Send invoices to customers',
                )
              : ListView.builder(
                  padding: EdgeInsets.all(16.w),
                  itemCount: invoices.length,
                  itemBuilder: (context, index) =>
                      _buildInvoiceCard(context, invoices[index]),
                ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Text('Error: $error'),
          ),
        );
  }

  Widget _buildOverdueInvoices(BuildContext context) {
    return ref.watch(overdueInvoicesProvider).when(
          data: (invoices) => invoices.isEmpty
              ? const EmptyState(
                  title: 'No Overdue Invoices',
                  description: 'Great! All payments are on time',
                )
              : ListView.builder(
                  padding: EdgeInsets.all(16.w),
                  itemCount: invoices.length,
                  itemBuilder: (context, index) =>
                      _buildInvoiceCard(context, invoices[index]),
                ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Text('Error: $error'),
          ),
        );
  }

  Widget _buildInvoiceCard(BuildContext context, Invoice invoice) {
    final statusColor = _getStatusColor(invoice.status);
    final statusLabel = invoice.status.name.toUpperCase();

    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      child: ListTile(
        leading: Container(
          width: 50.w,
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Center(
            child: Text(
              invoice.invoiceNumber.split('-').last,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        title: Text(
          invoice.customerName ?? 'Unknown',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.sp),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4.h),
            Text(
              invoice.invoiceNumber,
              style: TextStyle(fontSize: 12.sp, color: Colors.grey),
            ),
            Text(
              Formatters.formatDate(invoice.createdAt),
              style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              Formatters.formatCurrency(invoice.total),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14.sp,
                color: AppColors.primary,
              ),
            ),
            SizedBox(height: 4.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4.r),
              ),
              child: Text(
                statusLabel,
                style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
        onTap: () =>
            context.push('/invoice/${invoice.id}'),
      ),
    );
  }

  Color _getStatusColor(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.draft:
        return Colors.grey;
      case InvoiceStatus.sent:
      case InvoiceStatus.partial:
        return Colors.orange;
      case InvoiceStatus.paid:
        return Colors.green;
      case InvoiceStatus.overdue:
        return Colors.red;
      case InvoiceStatus.cancelled:
        return Colors.grey[600]!;
    }
  }
}
