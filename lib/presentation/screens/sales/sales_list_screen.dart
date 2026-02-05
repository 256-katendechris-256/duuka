import 'dart:io';

import 'package:excel/excel.dart' as excel_lib;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/models.dart';
import '../../../data/models/product_return.dart';
import '../../widgets/common/duuka_app_bar.dart';
import '../../widgets/common/empty_state.dart';
import '../../providers/auth_provider.dart';
import '../../providers/business_provider.dart';
import '../../providers/sale_provider.dart';
import '../../providers/return_provider.dart';

class SalesListScreen extends ConsumerStatefulWidget {
  const SalesListScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SalesListScreen> createState() => _SalesListScreenState();
}

class _SalesListScreenState extends ConsumerState<SalesListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedFilter = 'All';
  bool _isExporting = false;
  bool _isSearching = false;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  final List<String> _filters = ['All', 'Today', 'This Week', 'This Month'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showExportDialog(List<Sale> sales) async {
    if (sales.isEmpty) {
      context.showErrorSnackBar('No sales to export');
      return;
    }

    final filteredSales = _filterSales(sales);
    if (filteredSales.isEmpty) {
      context.showErrorSnackBar('No sales found for selected filter');
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: DuukaColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
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
            Padding(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Export Sales',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w700,
                      color: DuukaColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    '${filteredSales.length} sales will be exported ($_selectedFilter)',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: DuukaColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 20.h),

                  // Export Options
                  _ExportOption(
                    icon: Icons.picture_as_pdf,
                    title: 'Export as PDF',
                    subtitle: 'Printable sales report',
                    onTap: () {
                      Navigator.pop(context);
                      _exportToPDF(filteredSales);
                    },
                  ),
                  SizedBox(height: 12.h),
                  _ExportOption(
                    icon: Icons.grid_on,
                    title: 'Export as Excel',
                    subtitle: 'Microsoft Excel spreadsheet',
                    onTap: () {
                      Navigator.pop(context);
                      _exportToExcel(filteredSales);
                    },
                  ),
                  SizedBox(height: 20.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportToPDF(List<Sale> sales) async {
    setState(() => _isExporting = true);

    try {
      final pdf = pw.Document();
      final businessName = ref.read(businessNotifierProvider).valueOrNull?.name ?? 'My Business';

      // Calculate totals
      final totalSales = sales.fold<double>(0, (sum, s) => sum + s.total);
      final totalProfit = sales.fold<double>(0, (sum, s) => sum + s.totalProfit);
      final totalBalance = sales.fold<double>(0, (sum, s) => sum + s.balance);
      final paidCount = sales.where((s) => s.paymentStatus == PaymentStatus.paid).length;
      final creditCount = sales.where((s) => s.paymentStatus != PaymentStatus.paid).length;

      // Build PDF
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Sales Report',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    businessName,
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue700,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Period: $_selectedFilter',
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                  pw.Text(
                    'Generated: ${DuukaFormatters.dateTime(DateTime.now())}',
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                ],
              ),
              pw.Divider(thickness: 2, color: PdfColors.blue700),
              pw.SizedBox(height: 16),
            ],
          ),
          footer: (context) => pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                '$businessName - Powered by Duuka',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
              ),
              pw.Text(
                'Page ${context.pageNumber} of ${context.pagesCount}',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
              ),
            ],
          ),
          build: (context) => [
            // Summary Section
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue50,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Summary',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 12),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      _buildPdfSummaryItem('Total Sales', DuukaFormatters.currency(totalSales)),
                      _buildPdfSummaryItem('Total Profit', DuukaFormatters.currency(totalProfit)),
                      _buildPdfSummaryItem('Outstanding', DuukaFormatters.currency(totalBalance)),
                    ],
                  ),
                  pw.SizedBox(height: 8),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      _buildPdfSummaryItem('Transactions', '${sales.length}'),
                      _buildPdfSummaryItem('Paid', '$paidCount'),
                      _buildPdfSummaryItem('Credit', '$creditCount'),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 24),

            // Sales Table
            pw.Text(
              'Sales Details',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 12),

            pw.TableHelper.fromTextArray(
              context: context,
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 10,
                color: PdfColors.white,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.blue700,
              ),
              cellStyle: const pw.TextStyle(fontSize: 9),
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.center,
                2: pw.Alignment.centerLeft,
                3: pw.Alignment.centerRight,
                4: pw.Alignment.centerRight,
                5: pw.Alignment.center,
              },
              headerAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.center,
                2: pw.Alignment.centerLeft,
                3: pw.Alignment.centerRight,
                4: pw.Alignment.centerRight,
                5: pw.Alignment.center,
              },
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              headers: ['Receipt #', 'Date', 'Customer', 'Total', 'Profit', 'Status'],
              data: sales.map((sale) => [
                sale.receiptNumber,
                DuukaFormatters.date(sale.createdAt),
                sale.customerName ?? 'Walk-in',
                DuukaFormatters.currency(sale.total),
                DuukaFormatters.currency(sale.totalProfit),
                _getPaymentStatusText(sale.paymentStatus),
              ]).toList(),
            ),

            pw.SizedBox(height: 24),

            // Items Breakdown (if not too many sales)
            if (sales.length <= 20) ...[
              pw.Text(
                'Items Breakdown',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 12),

              ...sales.map((sale) => pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 12),
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          '#${sale.receiptNumber}',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
                        ),
                        pw.Text(
                          DuukaFormatters.dateTime(sale.createdAt),
                          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                        ),
                      ],
                    ),
                    pw.Divider(color: PdfColors.grey300),
                    ...sale.items.map((item) => pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 2),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Expanded(
                            child: pw.Text(
                              '${item.productName} x${item.formattedQuantity}',
                              style: const pw.TextStyle(fontSize: 10),
                            ),
                          ),
                          pw.Text(
                            DuukaFormatters.currency(item.total),
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                        ],
                      ),
                    )),
                    pw.Divider(color: PdfColors.grey300),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Total',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
                        ),
                        pw.Text(
                          DuukaFormatters.currency(sale.total),
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              )),
            ],
          ],
        ),
      );

      // Save file
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${directory.path}/sales_report_$timestamp.pdf');
      await file.writeAsBytes(await pdf.save());

      // Share file
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Duuka Sales Report',
        text: 'Sales report from Duuka - $_selectedFilter',
      );

      if (mounted) {
        context.showSuccessSnackBar('PDF exported successfully!');
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Failed to export: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  pw.Widget _buildPdfSummaryItem(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          value,
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
      ],
    );
  }

  Future<void> _exportToExcel(List<Sale> sales) async {
    setState(() => _isExporting = true);

    try {
      final excel = excel_lib.Excel.createExcel();
      final businessName = ref.read(businessNotifierProvider).valueOrNull?.name ?? 'My Business';

      // Sales Summary Sheet
      final summarySheet = excel['Summary'];
      excel.setDefaultSheet('Summary');

      // Style for headers
      final headerStyle = excel_lib.CellStyle(
        bold: true,
        backgroundColorHex: excel_lib.ExcelColor.blue100,
        horizontalAlign: excel_lib.HorizontalAlign.Center,
      );

      // Summary content
      summarySheet.cell(excel_lib.CellIndex.indexByString('A1')).value = excel_lib.TextCellValue('$businessName - Sales Export Report');
      summarySheet.cell(excel_lib.CellIndex.indexByString('A1')).cellStyle = excel_lib.CellStyle(bold: true, fontSize: 16);
      
      summarySheet.cell(excel_lib.CellIndex.indexByString('A3')).value = excel_lib.TextCellValue('Period:');
      summarySheet.cell(excel_lib.CellIndex.indexByString('B3')).value = excel_lib.TextCellValue(_selectedFilter);
      
      summarySheet.cell(excel_lib.CellIndex.indexByString('A4')).value = excel_lib.TextCellValue('Generated:');
      summarySheet.cell(excel_lib.CellIndex.indexByString('B4')).value = excel_lib.TextCellValue(DuukaFormatters.dateTime(DateTime.now()));
      
      summarySheet.cell(excel_lib.CellIndex.indexByString('A5')).value = excel_lib.TextCellValue('Total Transactions:');
      summarySheet.cell(excel_lib.CellIndex.indexByString('B5')).value = excel_lib.IntCellValue(sales.length);

      final totalSales = sales.fold<double>(0, (sum, s) => sum + s.total);
      final totalProfit = sales.fold<double>(0, (sum, s) => sum + s.totalProfit);
      final totalBalance = sales.fold<double>(0, (sum, s) => sum + s.balance);
      final paidCount = sales.where((s) => s.paymentStatus == PaymentStatus.paid).length;
      final creditCount = sales.where((s) => s.paymentStatus != PaymentStatus.paid).length;

      summarySheet.cell(excel_lib.CellIndex.indexByString('A7')).value = excel_lib.TextCellValue('Financial Summary');
      summarySheet.cell(excel_lib.CellIndex.indexByString('A7')).cellStyle = excel_lib.CellStyle(bold: true);
      
      summarySheet.cell(excel_lib.CellIndex.indexByString('A8')).value = excel_lib.TextCellValue('Total Sales:');
      summarySheet.cell(excel_lib.CellIndex.indexByString('B8')).value = excel_lib.DoubleCellValue(totalSales);
      
      summarySheet.cell(excel_lib.CellIndex.indexByString('A9')).value = excel_lib.TextCellValue('Total Profit:');
      summarySheet.cell(excel_lib.CellIndex.indexByString('B9')).value = excel_lib.DoubleCellValue(totalProfit);
      
      summarySheet.cell(excel_lib.CellIndex.indexByString('A10')).value = excel_lib.TextCellValue('Outstanding Balance:');
      summarySheet.cell(excel_lib.CellIndex.indexByString('B10')).value = excel_lib.DoubleCellValue(totalBalance);
      
      summarySheet.cell(excel_lib.CellIndex.indexByString('A12')).value = excel_lib.TextCellValue('Payment Status');
      summarySheet.cell(excel_lib.CellIndex.indexByString('A12')).cellStyle = excel_lib.CellStyle(bold: true);
      
      summarySheet.cell(excel_lib.CellIndex.indexByString('A13')).value = excel_lib.TextCellValue('Paid Transactions:');
      summarySheet.cell(excel_lib.CellIndex.indexByString('B13')).value = excel_lib.IntCellValue(paidCount);
      
      summarySheet.cell(excel_lib.CellIndex.indexByString('A14')).value = excel_lib.TextCellValue('Credit Transactions:');
      summarySheet.cell(excel_lib.CellIndex.indexByString('B14')).value = excel_lib.IntCellValue(creditCount);

      // Sales Details Sheet
      final salesSheet = excel['Sales'];

      // Headers
      final headers = [
        'Receipt #',
        'Date',
        'Time',
        'Customer',
        'Items Count',
        'Subtotal',
        'Discount',
        'Total',
        'Amount Paid',
        'Balance',
        'Payment Method',
        'Payment Status',
        'Profit',
      ];

      for (var i = 0; i < headers.length; i++) {
        salesSheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0)).value = excel_lib.TextCellValue(headers[i]);
        salesSheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0)).cellStyle = headerStyle;
      }

      // Data rows
      for (var rowIndex = 0; rowIndex < sales.length; rowIndex++) {
        final sale = sales[rowIndex];
        final row = rowIndex + 1;

        salesSheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value = excel_lib.TextCellValue(sale.receiptNumber);
        salesSheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).value = excel_lib.TextCellValue(DuukaFormatters.date(sale.createdAt));
        salesSheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row)).value = excel_lib.TextCellValue(DuukaFormatters.time(sale.createdAt));
        salesSheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row)).value = excel_lib.TextCellValue(sale.customerName ?? 'Walk-in');
        salesSheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row)).value = excel_lib.IntCellValue(sale.items.length);
        salesSheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row)).value = excel_lib.DoubleCellValue(sale.subtotal);
        salesSheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row)).value = excel_lib.DoubleCellValue(sale.discount);
        salesSheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: row)).value = excel_lib.DoubleCellValue(sale.total);
        salesSheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: row)).value = excel_lib.DoubleCellValue(sale.amountPaid);
        salesSheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: row)).value = excel_lib.DoubleCellValue(sale.balance);
        salesSheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: row)).value = excel_lib.TextCellValue(_getPaymentMethodText(sale.paymentMethod));
        salesSheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 11, rowIndex: row)).value = excel_lib.TextCellValue(_getPaymentStatusText(sale.paymentStatus));
        salesSheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 12, rowIndex: row)).value = excel_lib.DoubleCellValue(sale.totalProfit);
      }

      // Items Details Sheet
      final itemsSheet = excel['Items'];

      final itemHeaders = [
        'Receipt #',
        'Date',
        'Product Name',
        'Quantity',
        'Unit Price',
        'Cost Price',
        'Total',
        'Profit',
      ];

      for (var i = 0; i < itemHeaders.length; i++) {
        itemsSheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0)).value = excel_lib.TextCellValue(itemHeaders[i]);
        itemsSheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0)).cellStyle = headerStyle;
      }

      var itemRow = 1;
      for (final sale in sales) {
        for (final item in sale.items) {
          itemsSheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: itemRow)).value = excel_lib.TextCellValue(sale.receiptNumber);
          itemsSheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: itemRow)).value = excel_lib.TextCellValue(DuukaFormatters.date(sale.createdAt));
          itemsSheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: itemRow)).value = excel_lib.TextCellValue(item.productName);
          itemsSheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: itemRow)).value = excel_lib.DoubleCellValue(item.quantity);
          itemsSheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: itemRow)).value = excel_lib.DoubleCellValue(item.unitPrice);
          itemsSheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: itemRow)).value = excel_lib.DoubleCellValue(item.costPrice);
          itemsSheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: itemRow)).value = excel_lib.DoubleCellValue(item.total);
          itemsSheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: itemRow)).value = excel_lib.DoubleCellValue(item.profit);
          itemRow++;
        }
      }

      // Remove default sheet
      excel.delete('Sheet1');

      // Save file
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${directory.path}/sales_export_$timestamp.xlsx');
      final bytes = excel.encode();
      if (bytes != null) {
        await file.writeAsBytes(bytes);

        // Share file
        await Share.shareXFiles(
          [XFile(file.path)],
          subject: '$businessName Sales Export',
          text: 'Sales export from $businessName - $_selectedFilter',
        );

        if (mounted) {
          context.showSuccessSnackBar('Sales exported successfully!');
        }
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Failed to export: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  String _getPaymentMethodText(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.mobileMoney:
        return 'Mobile Money';
      case PaymentMethod.credit:
        return 'Credit';
    }
  }

  String _getPaymentStatusText(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.paid:
        return 'Paid';
      case PaymentStatus.partial:
        return 'Partial';
      case PaymentStatus.unpaid:
        return 'Unpaid';
    }
  }

  @override
  Widget build(BuildContext context) {
    final salesAsync = ref.watch(salesProvider);
    final returnsAsync = ref.watch(returnsProvider);
    final authState = ref.watch(authProvider);
    final isOwner = authState.user?.role == UserRole.owner;

    return Scaffold(
      backgroundColor: DuukaColors.background,
      appBar: DuukaAppBar(
        title: _isSearching ? '' : 'Sales History',
        onBackPressed: () {
          if (_isSearching) {
            setState(() {
              _isSearching = false;
              _searchQuery = '';
              _searchController.clear();
            });
          } else if (context.canPop()) {
            context.pop();
          } else {
            context.go('/home');
          }
        },
        titleWidget: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search by receipt #, customer...',
                  hintStyle: TextStyle(color: DuukaColors.textHint),
                  border: InputBorder.none,
                ),
                style: TextStyle(fontSize: 16.sp, color: DuukaColors.textPrimary),
                onChanged: (value) {
                  setState(() => _searchQuery = value.toLowerCase());
                },
              )
            : null,
        actions: [
          // Export button - Only visible to owners
          if (isOwner) ...[
            if (_isExporting)
              Padding(
                padding: EdgeInsets.only(right: 16.w),
                child: SizedBox(
                  width: 24.w,
                  height: 24.h,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: DuukaColors.primary,
                  ),
                ),
              )
            else
              IconButton(
                onPressed: () {
                  final sales = salesAsync.valueOrNull ?? [];
                  _showExportDialog(sales);
                },
                icon: Icon(Icons.download, size: 24.sp),
                tooltip: 'Export',
              ),
          ],
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          Container(
            color: DuukaColors.surface,
            padding: EdgeInsets.symmetric(vertical: 12.h),
            child: SizedBox(
              height: 36.h,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                itemCount: _filters.length,
                itemBuilder: (context, index) {
                  final filter = _filters[index];
                  final isSelected = _selectedFilter == filter;
                  return Padding(
                    padding: EdgeInsets.only(right: 8.w),
                    child: FilterChip(
                      label: Text(filter),
                      selected: isSelected,
                      onSelected: (_) {
                        setState(() {
                          _selectedFilter = filter;
                        });
                      },
                      backgroundColor: DuukaColors.surface,
                      selectedColor: DuukaColors.primaryBg,
                      labelStyle: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? DuukaColors.primary
                            : DuukaColors.textSecondary,
                      ),
                      side: BorderSide(
                        color: isSelected
                            ? DuukaColors.primary
                            : DuukaColors.border,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Payment Status Tabs
          Container(
            color: DuukaColors.surface,
            child: TabBar(
              controller: _tabController,
              labelColor: DuukaColors.primary,
              unselectedLabelColor: DuukaColors.textSecondary,
              indicatorColor: DuukaColors.primary,
              indicatorWeight: 3,
              labelPadding: EdgeInsets.symmetric(horizontal: 12.w),
              labelStyle: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
              ),
              tabs: [
                const Tab(text: 'All'),
                const Tab(text: 'Paid'),
                const Tab(text: 'Credit'),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Returns'),
                      if (returnsAsync.valueOrNull?.isNotEmpty == true) ...[
                        SizedBox(width: 3.w),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.h),
                          decoration: BoxDecoration(
                            color: DuukaColors.error,
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Text(
                            '${returnsAsync.valueOrNull?.length ?? 0}',
                            style: TextStyle(
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Sales List
          Expanded(
            child: salesAsync.when(
              data: (sales) {
                var filteredSales = _filterSales(sales);
                
                // Apply search filter
                if (_searchQuery.isNotEmpty) {
                  filteredSales = filteredSales.where((s) {
                    return s.receiptNumber.toLowerCase().contains(_searchQuery) ||
                        (s.customerName?.toLowerCase().contains(_searchQuery) ?? false) ||
                        s.items.any((i) => i.productName.toLowerCase().contains(_searchQuery));
                  }).toList();
                }

                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildSalesList(filteredSales),
                    _buildSalesList(filteredSales
                        .where((s) => s.paymentStatus == PaymentStatus.paid)
                        .toList()),
                    _buildSalesList(filteredSales
                        .where((s) =>
                            s.paymentStatus == PaymentStatus.unpaid ||
                            s.paymentStatus == PaymentStatus.partial)
                        .toList()),
                    _buildReturnsList(returnsAsync),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => EmptyState(
                icon: Icons.error_outline,
                title: 'Failed to load sales',
                description: error.toString(),
                actionLabel: 'Retry',
                onAction: () => ref.invalidate(salesProvider),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Search FAB (bottom left)
          Padding(
            padding: EdgeInsets.only(left: 32.w),
            child: FloatingActionButton(
              heroTag: 'search',
              onPressed: () {
                setState(() {
                  _isSearching = !_isSearching;
                  if (!_isSearching) {
                    _searchQuery = '';
                    _searchController.clear();
                  }
                });
              },
              backgroundColor: _isSearching ? DuukaColors.error : DuukaColors.surface,
              child: Icon(
                _isSearching ? Icons.close : Icons.search,
                color: _isSearching ? Colors.white : DuukaColors.primary,
              ),
            ),
          ),
          // New Sale FAB (bottom right)
          FloatingActionButton.extended(
            heroTag: 'newSale',
            onPressed: () => context.push('/sale'),
            backgroundColor: DuukaColors.primary,
            icon: Icon(Icons.add, color: Colors.white, size: 24.sp),
            label: Text(
              'New Sale',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildReturnsList(AsyncValue<List<ProductReturn>> returnsAsync) {
    return returnsAsync.when(
      data: (returns) {
        if (returns.isEmpty) {
          return EmptyState(
            icon: Icons.assignment_return_outlined,
            title: 'No Returns',
            description: 'Product returns will appear here',
          );
        }

        // Group returns by date
        final groupedReturns = <String, List<ProductReturn>>{};
        for (final ret in returns) {
          final dateKey = _getDateKey(ret.createdAt);
          groupedReturns.putIfAbsent(dateKey, () => []).add(ret);
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(returnsProvider);
          },
          child: ListView.builder(
            padding: EdgeInsets.only(bottom: 80.h),
            itemCount: groupedReturns.length,
            itemBuilder: (context, index) {
              final dateKey = groupedReturns.keys.elementAt(index);
              final dateReturns = groupedReturns[dateKey]!;
              final dateTotal = dateReturns.fold<double>(
                0.0,
                (sum, ret) => sum + ret.refundAmount,
              );

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date Header
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                    color: DuukaColors.background,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          dateKey,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                            color: DuukaColors.textPrimary,
                          ),
                        ),
                        Text(
                          '-${DuukaFormatters.currency(dateTotal)}',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                            color: DuukaColors.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Returns for this date
                  ...dateReturns.map((ret) => _ReturnListTile(
                        productReturn: ret,
                        onTap: () => context.push('/sales/${ret.saleId}'),
                      )),
                ],
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => EmptyState(
        icon: Icons.error_outline,
        title: 'Failed to load returns',
        description: error.toString(),
        actionLabel: 'Retry',
        onAction: () => ref.invalidate(returnsProvider),
      ),
    );
  }

  List<Sale> _filterSales(List<Sale> sales) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (_selectedFilter) {
      case 'Today':
        return sales.where((s) {
          final saleDate = DateTime(
            s.createdAt.year,
            s.createdAt.month,
            s.createdAt.day,
          );
          return saleDate.isAtSameMomentAs(today);
        }).toList();
      case 'This Week':
        final weekAgo = today.subtract(const Duration(days: 7));
        return sales.where((s) => s.createdAt.isAfter(weekAgo)).toList();
      case 'This Month':
        final monthStart = DateTime(now.year, now.month, 1);
        return sales.where((s) => s.createdAt.isAfter(monthStart)).toList();
      default:
        return sales;
    }
  }

  Widget _buildSalesList(List<Sale> sales) {
    if (sales.isEmpty) {
      return EmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'No sales found',
        description: 'Sales will appear here once you make them',
        actionLabel: 'New Sale',
        onAction: () => context.push('/sale'),
      );
    }

    // Group sales by date
    final groupedSales = <String, List<Sale>>{};
    for (final sale in sales) {
      final dateKey = _getDateKey(sale.createdAt);
      groupedSales.putIfAbsent(dateKey, () => []).add(sale);
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(salesProvider);
      },
      child: ListView.builder(
        padding: EdgeInsets.only(bottom: 80.h),
        itemCount: groupedSales.length,
        itemBuilder: (context, index) {
          final dateKey = groupedSales.keys.elementAt(index);
          final dateSales = groupedSales[dateKey]!;
          final dateTotal = dateSales.fold<double>(
            0.0,
            (sum, sale) => sum + sale.total,
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date Header
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                color: DuukaColors.background,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      dateKey,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: DuukaColors.textPrimary,
                      ),
                    ),
                    Text(
                      DuukaFormatters.currency(dateTotal),
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: DuukaColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              // Sales for this date
              ...dateSales.map((sale) => _SaleListTile(
                    sale: sale,
                    onTap: () => _showSaleDetails(sale),
                  )),
            ],
          );
        },
      ),
    );
  }

  String _getDateKey(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final saleDate = DateTime(date.year, date.month, date.day);

    if (saleDate.isAtSameMomentAs(today)) {
      return 'Today';
    } else if (saleDate.isAtSameMomentAs(yesterday)) {
      return 'Yesterday';
    } else {
      return DuukaFormatters.date(date);
    }
  }

  void _showSaleDetails(Sale sale) {
    context.push('/sales/${sale.id}');
  }
}

class _SaleListTile extends StatelessWidget {
  final Sale sale;
  final VoidCallback onTap;

  const _SaleListTile({
    required this.sale,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        color: DuukaColors.surface,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Row(
          children: [
            // Receipt icon with status color
            Container(
              width: 48.w,
              height: 48.h,
              decoration: BoxDecoration(
                color: _getStatusColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                Icons.receipt_outlined,
                color: _getStatusColor(),
                size: 24.sp,
              ),
            ),
            SizedBox(width: 12.w),

            // Sale info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '#${sale.receiptNumber}',
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w600,
                            color: DuukaColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _buildStatusBadge(),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14.sp,
                        color: DuukaColors.textSecondary,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        DuukaFormatters.time(sale.createdAt),
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w400,
                          color: DuukaColors.textSecondary,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Icon(
                        _getPaymentIcon(),
                        size: 14.sp,
                        color: DuukaColors.textSecondary,
                      ),
                      SizedBox(width: 4.w),
                      Flexible(
                        child: Text(
                          _getPaymentMethodName(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w400,
                            color: DuukaColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    '${sale.items.length} item${sale.items.length > 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w400,
                      color: DuukaColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 12.w),

            // Total
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  DuukaFormatters.currency(sale.total),
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: DuukaColors.textPrimary,
                  ),
                ),
                if (sale.balance > 0) ...[
                  SizedBox(height: 4.h),
                  Text(
                    'Bal: ${DuukaFormatters.currency(sale.balance)}',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w500,
                      color: DuukaColors.warning,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: _getStatusColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        _getStatusText(),
        style: TextStyle(
          fontSize: 10.sp,
          fontWeight: FontWeight.w600,
          color: _getStatusColor(),
        ),
      ),
    );
  }

  Color _getStatusColor() {
    switch (sale.paymentStatus) {
      case PaymentStatus.paid:
        return DuukaColors.success;
      case PaymentStatus.partial:
        return DuukaColors.warning;
      case PaymentStatus.unpaid:
        return DuukaColors.error;
    }
  }

  String _getStatusText() {
    switch (sale.paymentStatus) {
      case PaymentStatus.paid:
        return 'Paid';
      case PaymentStatus.partial:
        return 'Partial';
      case PaymentStatus.unpaid:
        return 'Credit';
    }
  }

  IconData _getPaymentIcon() {
    switch (sale.paymentMethod) {
      case PaymentMethod.cash:
        return Icons.payments_outlined;
      case PaymentMethod.mobileMoney:
        return Icons.phone_android;
      case PaymentMethod.credit:
        return Icons.credit_score;
    }
  }

  String _getPaymentMethodName() {
    switch (sale.paymentMethod) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.mobileMoney:
        return 'Mobile Money';
      case PaymentMethod.credit:
        return 'Credit';
    }
  }
}

class _SaleDetailsSheet extends StatelessWidget {
  final Sale sale;

  const _SaleDetailsSheet({required this.sale});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DuukaColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
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

          // Header
          Padding(
            padding: EdgeInsets.all(20.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sale Details',
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w700,
                        color: DuukaColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '#${sale.receiptNumber}',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: DuukaColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, size: 24.sp),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: DuukaColors.border),

          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date & Time
                  _buildInfoRow(
                    'Date & Time',
                    DuukaFormatters.dateTime(sale.createdAt),
                    Icons.calendar_today,
                  ),
                  SizedBox(height: 16.h),

                  // Customer
                  if (sale.customerName != null) ...[
                    _buildInfoRow(
                      'Customer',
                      sale.customerName!,
                      Icons.person_outline,
                    ),
                    SizedBox(height: 16.h),
                  ],

                  // Items
                  Text(
                    'Items',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: DuukaColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Container(
                    decoration: BoxDecoration(
                      color: DuukaColors.background,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Column(
                      children: sale.items.asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;
                        return Column(
                          children: [
                            Padding(
                              padding: EdgeInsets.all(12.w),
                              child: Row(
                                children: [
                                  Container(
                                    width: 28.w,
                                    height: 28.h,
                                    decoration: BoxDecoration(
                                      color: DuukaColors.primaryBg,
                                      borderRadius: BorderRadius.circular(6.r),
                                    ),
                                    child: Center(
                                      child: Text(
                                        item.isMeasurable ? item.formattedQuantity : '${item.quantity.toInt()}x',
                                        style: TextStyle(
                                          fontSize: 11.sp,
                                          fontWeight: FontWeight.w600,
                                          color: DuukaColors.primary,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 12.w),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.productName,
                                          style: TextStyle(
                                            fontSize: 14.sp,
                                            fontWeight: FontWeight.w500,
                                            color: DuukaColors.textPrimary,
                                          ),
                                        ),
                                        Text(
                                          '@ ${DuukaFormatters.currency(item.unitPrice)}',
                                          style: TextStyle(
                                            fontSize: 12.sp,
                                            fontWeight: FontWeight.w400,
                                            color: DuukaColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    DuukaFormatters.currency(item.total),
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w600,
                                      color: DuukaColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (index < sale.items.length - 1)
                              Divider(
                                height: 1,
                                color: DuukaColors.border,
                                indent: 12.w,
                                endIndent: 12.w,
                              ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                  SizedBox(height: 20.h),

                  // Summary
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: DuukaColors.background,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Column(
                      children: [
                        _buildSummaryRow('Subtotal', sale.subtotal),
                        if (sale.discount > 0) ...[
                          SizedBox(height: 8.h),
                          _buildSummaryRow('Discount', -sale.discount,
                              valueColor: DuukaColors.error),
                        ],
                        SizedBox(height: 8.h),
                        Divider(color: DuukaColors.border),
                        SizedBox(height: 8.h),
                        _buildSummaryRow('Total', sale.total, isTotal: true),
                        SizedBox(height: 8.h),
                        _buildSummaryRow('Paid', sale.amountPaid),
                        if (sale.balance > 0) ...[
                          SizedBox(height: 8.h),
                          _buildSummaryRow('Balance', sale.balance,
                              valueColor: DuukaColors.warning),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(height: 20.h),

                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            context.push('/sale/receipt', extra: sale);
                          },
                          icon: Icon(Icons.receipt_long, size: 20.sp),
                          label: const Text('View Receipt'),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            side: BorderSide(color: DuukaColors.primary),
                            foregroundColor: DuukaColors.primary,
                          ),
                        ),
                      ),
                      if (sale.paymentStatus != PaymentStatus.paid) ...[
                        SizedBox(width: 12.w),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              // TODO: Record payment
                              Navigator.pop(context);
                            },
                            icon: Icon(Icons.payment, size: 20.sp),
                            label: const Text('Record Payment'),
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                              backgroundColor: DuukaColors.primary,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 20.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20.sp, color: DuukaColors.textSecondary),
        SizedBox(width: 12.w),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w400,
                color: DuukaColors.textSecondary,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: DuukaColors.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, double amount,
      {bool isTotal = false, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16.sp : 14.sp,
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w400,
            color: DuukaColors.textPrimary,
          ),
        ),
        Text(
          amount < 0
              ? '-${DuukaFormatters.currency(amount.abs())}'
              : DuukaFormatters.currency(amount),
          style: TextStyle(
            fontSize: isTotal ? 18.sp : 14.sp,
            fontWeight: FontWeight.w700,
            color: valueColor ??
                (isTotal ? DuukaColors.primary : DuukaColors.textPrimary),
          ),
        ),
      ],
    );
  }
}

class _ExportOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ExportOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: DuukaColors.background,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: DuukaColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 48.w,
              height: 48.h,
              decoration: BoxDecoration(
                color: DuukaColors.primaryBg,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                icon,
                color: DuukaColors.primary,
                size: 24.sp,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: DuukaColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: DuukaColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: DuukaColors.textSecondary,
              size: 24.sp,
            ),
          ],
        ),
      ),
    );
  }
}

class _ReturnListTile extends StatelessWidget {
  final ProductReturn productReturn;
  final VoidCallback onTap;

  const _ReturnListTile({
    required this.productReturn,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        color: DuukaColors.surface,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Row(
          children: [
            // Return icon
            Container(
              width: 48.w,
              height: 48.h,
              decoration: BoxDecoration(
                color: DuukaColors.warningBg,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                Icons.assignment_return,
                color: DuukaColors.warning,
                size: 24.sp,
              ),
            ),
            SizedBox(width: 12.w),

            // Return details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    productReturn.productName,
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: DuukaColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      Text(
                        productReturn.formattedQuantity,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: DuukaColors.textSecondary,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: DuukaColors.background,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(
                          productReturn.reason.label,
                          style: TextStyle(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w500,
                            color: DuukaColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Refund amount
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '-${DuukaFormatters.currency(productReturn.refundAmount)}',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    color: DuukaColors.error,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  DuukaFormatters.time(productReturn.createdAt),
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: DuukaColors.textHint,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
