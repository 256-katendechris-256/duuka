import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/constants/app_colors.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/number_to_words.dart';
import '../../../data/models/models.dart';
import '../../providers/invoice_provider.dart';
import '../../providers/business_provider.dart';
import '../../widgets/common/duuka_app_bar.dart';
import '../../widgets/common/duuka_button.dart';

class InvoiceDetailScreen extends ConsumerStatefulWidget {
  final int invoiceId;

  const InvoiceDetailScreen({
    super.key,
    required this.invoiceId,
  });

  @override
  ConsumerState<InvoiceDetailScreen> createState() =>
      _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends ConsumerState<InvoiceDetailScreen> {
  final _paymentAmountController = TextEditingController();
  InvoicePaymentMethod _selectedPaymentMethod = InvoicePaymentMethod.cash;
  final _paymentRefController = TextEditingController();
  bool _isSharing = false;

  @override
  void dispose() {
    _paymentAmountController.dispose();
    _paymentRefController.dispose();
    super.dispose();
  }

  Future<void> _shareInvoiceAsPdf(Invoice invoice, Business? business) async {
    setState(() => _isSharing = true);

    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header with business info
                _buildPdfHeader(business, invoice),
                pw.SizedBox(height: 30),

                // Customer and Invoice details side by side
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Bill To
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('BILL TO',
                              style: pw.TextStyle(
                                fontSize: 10,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.grey700,
                              )),
                          pw.SizedBox(height: 5),
                          pw.Text(invoice.customerName ?? 'N/A',
                              style: pw.TextStyle(
                                fontSize: 14,
                                fontWeight: pw.FontWeight.bold,
                              )),
                          if (invoice.customerPhone != null)
                            pw.Text(invoice.customerPhone!,
                                style: const pw.TextStyle(fontSize: 11)),
                        ],
                      ),
                    ),
                    // Invoice Details
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          _buildPdfDetailRow('Invoice Number:', invoice.invoiceNumber),
                          _buildPdfDetailRow('Issue Date:', DuukaFormatters.date(invoice.issuedAt)),
                          if (invoice.dueAt != null)
                            _buildPdfDetailRow('Due Date:', DuukaFormatters.date(invoice.dueAt!)),
                          _buildPdfDetailRow('Status:', invoice.status.label.toUpperCase()),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 30),

                // Items Table
                _buildPdfItemsTable(invoice),
                pw.SizedBox(height: 20),

                // Summary
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Container(
                      width: 250,
                      child: pw.Column(
                        children: [
                          _buildPdfSummaryRow('Subtotal', DuukaFormatters.currency(invoice.subtotal)),
                          if (invoice.discount > 0)
                            _buildPdfSummaryRow(
                              'Discount (${invoice.discountPercent > 0 ? '${invoice.discountPercent.toStringAsFixed(0)}%' : 'Fixed'})',
                              '-${DuukaFormatters.currency(invoice.discount)}',
                              isNegative: true,
                            ),
                          if (invoice.taxAmount > 0)
                            _buildPdfSummaryRow('Tax/VAT', DuukaFormatters.currency(invoice.taxAmount)),
                          pw.Divider(),
                          _buildPdfSummaryRow('Total', DuukaFormatters.currency(invoice.total), isTotal: true),
                          _buildPdfSummaryRow('Amount Paid', DuukaFormatters.currency(invoice.amountPaid)),
                          if (invoice.remainingBalance > 0)
                            _buildPdfSummaryRow('Balance Due', DuukaFormatters.currency(invoice.remainingBalance), isTotal: true),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),

                // Amount in Words
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    border: pw.Border.all(color: PdfColors.grey300),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Amount in Words:',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.grey700,
                          )),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        NumberToWords.convert(invoice.total),
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),

                // Payment History
                if (invoice.payments.isNotEmpty) ...[
                  pw.Text('Payment History',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      )),
                  pw.SizedBox(height: 10),
                  ...invoice.payments.map((payment) => pw.Container(
                        margin: const pw.EdgeInsets.only(bottom: 5),
                        padding: const pw.EdgeInsets.all(8),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.green50,
                          border: pw.Border.all(color: PdfColors.green200),
                        ),
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              '${payment.method.name.toUpperCase()} - ${DuukaFormatters.dateTime(payment.paidAt)}',
                              style: const pw.TextStyle(fontSize: 10),
                            ),
                            pw.Text(
                              DuukaFormatters.currency(payment.amount),
                              style: pw.TextStyle(
                                fontSize: 10,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.green700,
                              ),
                            ),
                          ],
                        ),
                      )),
                  pw.SizedBox(height: 20),
                ],

                // Notes
                if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[
                  pw.Text('Notes:',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey700,
                      )),
                  pw.SizedBox(height: 5),
                  pw.Text(invoice.notes!, style: const pw.TextStyle(fontSize: 10)),
                  pw.SizedBox(height: 20),
                ],

                pw.Spacer(),

                // Footer
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text('Thank you for your business!',
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                          )),
                      pw.SizedBox(height: 5),
                      pw.Text('Please make payment by the due date',
                          style: const pw.TextStyle(
                            fontSize: 10,
                            color: PdfColors.grey600,
                          )),
                      pw.SizedBox(height: 10),
                      pw.Text('Powered by Duuka',
                          style: const pw.TextStyle(
                            fontSize: 9,
                            color: PdfColors.grey500,
                          )),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );

      // Save PDF to temporary directory
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/invoice_${invoice.invoiceNumber.replaceAll('/', '-')}.pdf');
      await file.writeAsBytes(await pdf.save());

      // Share the PDF
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Invoice ${invoice.invoiceNumber}',
        text: 'Invoice from ${business?.name ?? ""}',
      );

      // Mark as sent if still in draft
      if (invoice.status == InvoiceStatus.draft) {
        await ref.read(invoicesProvider.notifier).markAsSent(invoice);
        ref.invalidate(invoiceByIdProvider(id: widget.invoiceId));
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Failed to share invoice: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  pw.Widget _buildPdfHeader(Business? business, Invoice invoice) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#1E3A5F'),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                business?.name ?? 'My Business',
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
              if (business?.phone != null && business!.phone!.isNotEmpty)
                pw.Text(
                  business.phone!,
                  style: const pw.TextStyle(fontSize: 11, color: PdfColors.white),
                ),
              if (business?.area != null || business?.district != null)
                pw.Text(
                  [business?.area, business?.district]
                      .where((s) => s != null && s.isNotEmpty)
                      .join(', '),
                  style: const pw.TextStyle(fontSize: 11, color: PdfColors.white),
                ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'INVOICE',
                style: pw.TextStyle(
                  fontSize: 28,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: pw.BoxDecoration(
                  color: _getPdfStatusColor(invoice.status),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text(
                  invoice.status.label.toUpperCase(),
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPdfDetailRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          pw.SizedBox(width: 10),
          pw.Text(value, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  pw.Widget _buildPdfItemsTable(Invoice invoice) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(4),
        1: const pw.FlexColumnWidth(1.5),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FlexColumnWidth(2),
      },
      children: [
        // Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('Description', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('Qty', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11), textAlign: pw.TextAlign.center),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('Unit Price', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11), textAlign: pw.TextAlign.right),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11), textAlign: pw.TextAlign.right),
            ),
          ],
        ),
        // Items
        ...invoice.items.map((item) => pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(item.productName, style: const pw.TextStyle(fontSize: 10)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(
                    '${item.quantity.toStringAsFixed(item.quantity.truncateToDouble() == item.quantity ? 0 : 1)} ${item.unit}',
                    style: const pw.TextStyle(fontSize: 10),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(
                    DuukaFormatters.currency(item.unitPrice),
                    style: const pw.TextStyle(fontSize: 10),
                    textAlign: pw.TextAlign.right,
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(
                    DuukaFormatters.currency(item.total),
                    style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                    textAlign: pw.TextAlign.right,
                  ),
                ),
              ],
            )),
      ],
    );
  }

  pw.Widget _buildPdfSummaryRow(String label, String value, {bool isTotal = false, bool isNegative = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: isTotal ? 12 : 10,
              fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: isTotal ? 12 : 10,
              fontWeight: pw.FontWeight.bold,
              color: isNegative ? PdfColors.red : (isTotal ? PdfColor.fromHex('#1E3A5F') : PdfColors.black),
            ),
          ),
        ],
      ),
    );
  }

  PdfColor _getPdfStatusColor(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.draft:
        return PdfColors.grey;
      case InvoiceStatus.sent:
      case InvoiceStatus.partial:
        return PdfColors.orange;
      case InvoiceStatus.paid:
        return PdfColors.green;
      case InvoiceStatus.overdue:
        return PdfColors.red;
      case InvoiceStatus.cancelled:
        return PdfColors.grey600;
    }
  }

  @override
  Widget build(BuildContext context) {
    final businessAsync = ref.watch(businessNotifierProvider);

    return ref.watch(invoiceByIdProvider(id: widget.invoiceId)).when(
          data: (invoice) {
            if (invoice == null) {
              return Scaffold(
                appBar: const DuukaAppBar(title: 'Invoice'),
                body: const Center(child: Text('Invoice not found')),
              );
            }

            return Scaffold(
              backgroundColor: DuukaColors.background,
              appBar: DuukaAppBar(
                title: 'Invoice ${invoice.invoiceNumber}',
                actions: [
                  PopupMenuButton(
                    itemBuilder: (context) => [
                      if (invoice.status != InvoiceStatus.paid &&
                          invoice.status != InvoiceStatus.cancelled)
                        PopupMenuItem(
                          child: const Text('Record Payment'),
                          onTap: () => Future.delayed(
                            Duration.zero,
                            () => _showPaymentDialog(context, invoice),
                          ),
                        ),
                      if (invoice.status == InvoiceStatus.draft)
                        PopupMenuItem(
                          child: const Text('Delete'),
                          onTap: () => Future.delayed(
                            Duration.zero,
                            () => _showDeleteDialog(context, invoice),
                          ),
                        ),
                      if (invoice.status != InvoiceStatus.draft &&
                          invoice.status != InvoiceStatus.cancelled)
                        PopupMenuItem(
                          child: const Text('Cancel Invoice'),
                          onTap: () => Future.delayed(
                            Duration.zero,
                            () => _cancelInvoice(context, invoice),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              body: Column(
                children: [
                  // Invoice content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(16.w),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12.r),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Invoice header with business info
                            _buildInvoiceHeader(businessAsync.valueOrNull, invoice),

                            // Customer and Invoice info
                            Padding(
                              padding: EdgeInsets.all(20.w),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Bill To Section
                                  _buildBillToSection(invoice),
                                  SizedBox(height: 20.h),

                                  // Invoice Details
                                  _buildInvoiceDetails(invoice),
                                ],
                              ),
                            ),

                            // Dashed divider
                            _buildDashedDivider(),

                            // Items table
                            _buildItemsTable(invoice),

                            // Dashed divider
                            _buildDashedDivider(),

                            // Summary
                            _buildSummary(invoice),

                            // Amount in Words
                            _buildAmountInWords(invoice),

                            // Payment History
                            if (invoice.payments.isNotEmpty) ...[
                              _buildDashedDivider(),
                              _buildPaymentHistory(invoice),
                            ],

                            // Notes
                            if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[
                              _buildDashedDivider(),
                              Padding(
                                padding: EdgeInsets.all(20.w),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Notes',
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w600,
                                        color: DuukaColors.textSecondary,
                                      ),
                                    ),
                                    SizedBox(height: 8.h),
                                    Text(
                                      invoice.notes!,
                                      style: TextStyle(
                                        fontSize: 13.sp,
                                        color: DuukaColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            // Footer
                            _buildFooter(),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Action buttons
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: DuukaColors.surface,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      child: Row(
                        children: [
                          // Share/Send button
                          Expanded(
                            child: DuukaButton.secondary(
                              label: invoice.status == InvoiceStatus.draft
                                  ? 'Send Invoice'
                                  : 'Share Invoice',
                              icon: Icons.picture_as_pdf,
                              onPressed: _isSharing
                                  ? null
                                  : () => _shareInvoiceAsPdf(invoice, businessAsync.valueOrNull),
                              isLoading: _isSharing,
                            ),
                          ),
                          if (invoice.canRecordPayment) ...[
                            SizedBox(width: 12.w),
                            // Record Payment button
                            Expanded(
                              child: DuukaButton.primary(
                                label: 'Record Payment',
                                icon: Icons.payments,
                                onPressed: () => _showPaymentDialog(context, invoice),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => Scaffold(
            appBar: const DuukaAppBar(title: 'Invoice'),
            body: const Center(child: CircularProgressIndicator()),
          ),
          error: (error, stack) => Scaffold(
            appBar: const DuukaAppBar(title: 'Invoice'),
            body: Center(child: Text('Error: $error')),
          ),
        );
  }

  Widget _buildInvoiceHeader(Business? business, Invoice invoice) {
    final statusColor = _getStatusColor(invoice.status);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: DuukaColors.primary,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(12.r),
        ),
      ),
      child: Column(
        children: [
          // Business name
          Text(
            business?.name ?? 'My Business',
            style: TextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4.h),

          // Business contact info
          if (business?.phone != null && business!.phone!.isNotEmpty)
            Text(
              business.phone!,
              style: TextStyle(
                fontSize: 13.sp,
                color: Colors.white.withOpacity(0.9),
              ),
            ),

          // Business location
          if (business?.area != null || business?.district != null)
            Text(
              [business?.area, business?.district]
                  .where((s) => s != null && s.isNotEmpty)
                  .join(', '),
              style: TextStyle(
                fontSize: 13.sp,
                color: Colors.white.withOpacity(0.9),
              ),
            ),

          SizedBox(height: 16.h),

          // Invoice label and number
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Text(
              'INVOICE ${invoice.invoiceNumber}',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),

          SizedBox(height: 16.h),

          // Status badge
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Text(
              invoice.status.label.toUpperCase(),
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillToSection(Invoice invoice) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: DuukaColors.background,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'BILL TO',
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: DuukaColors.textSecondary,
              letterSpacing: 1,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            invoice.customerName ?? 'N/A',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: DuukaColors.textPrimary,
            ),
          ),
          if (invoice.customerPhone != null) ...[
            SizedBox(height: 4.h),
            Row(
              children: [
                Icon(Icons.phone, size: 14.sp, color: DuukaColors.textSecondary),
                SizedBox(width: 6.w),
                Text(
                  invoice.customerPhone!,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: DuukaColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInvoiceDetails(Invoice invoice) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailItem('Issue Date', DuukaFormatters.date(invoice.issuedAt)),
              SizedBox(height: 12.h),
              if (invoice.dueAt != null)
                _buildDetailItem('Due Date', DuukaFormatters.date(invoice.dueAt!)),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Total Amount',
                style: TextStyle(
                  fontSize: 11.sp,
                  color: DuukaColors.textSecondary,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                DuukaFormatters.currency(invoice.total),
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: DuukaColors.primary,
                ),
              ),
              SizedBox(height: 8.h),
              if (invoice.remainingBalance > 0)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: DuukaColors.warningBg,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Text(
                    'Balance: ${DuukaFormatters.currency(invoice.remainingBalance)}',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: DuukaColors.warning,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11.sp,
            color: DuukaColors.textSecondary,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w500,
            color: DuukaColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildDashedDivider() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        children: List.generate(
          30,
          (index) => Expanded(
            child: Container(
              height: 1,
              color: index.isEven ? DuukaColors.border : Colors.transparent,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItemsTable(Invoice invoice) {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Items',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: DuukaColors.textSecondary,
            ),
          ),
          SizedBox(height: 12.h),
          // Table
          Table(
            columnWidths: const {
              0: FlexColumnWidth(3),
              1: FlexColumnWidth(1.2),
              2: FlexColumnWidth(1.8),
              3: FlexColumnWidth(1.8),
            },
            children: [
              // Header
              TableRow(
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: DuukaColors.border, width: 2)),
                ),
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    child: Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: DuukaColors.textSecondary,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    child: Text(
                      'Qty',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: DuukaColors.textSecondary,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    child: Text(
                      'Price',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: DuukaColors.textSecondary,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    child: Text(
                      'Total',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: DuukaColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              // Rows
              ...invoice.items.map((item) => TableRow(
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: DuukaColors.divider)),
                    ),
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 10.h),
                        child: Text(
                          item.productName,
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                            color: DuukaColors.textPrimary,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 10.h),
                        child: Text(
                          '${item.quantity.toStringAsFixed(item.quantity.truncateToDouble() == item.quantity ? 0 : 1)}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: DuukaColors.textPrimary,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 10.h),
                        child: Text(
                          DuukaFormatters.currencyCompact(item.unitPrice),
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: DuukaColors.textPrimary,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 10.h),
                        child: Text(
                          DuukaFormatters.currencyCompact(item.total),
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                            color: DuukaColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(Invoice invoice) {
    return Padding(
      padding: EdgeInsets.all(20.w),
      child: Column(
        children: [
          _buildSummaryRow('Subtotal', invoice.subtotal),
          if (invoice.discountPercent > 0 || invoice.discount > 0) ...[
            SizedBox(height: 8.h),
            _buildSummaryRow(
              'Discount (${invoice.discountPercent > 0 ? '${invoice.discountPercent.toStringAsFixed(0)}%' : 'Fixed'})',
              -invoice.discount,
              valueColor: DuukaColors.error,
            ),
          ],
          if (invoice.taxAmount > 0) ...[
            SizedBox(height: 8.h),
            _buildSummaryRow('Tax/VAT', invoice.taxAmount),
          ],
          SizedBox(height: 12.h),
          Divider(color: DuukaColors.border),
          SizedBox(height: 12.h),
          _buildSummaryRow('Total', invoice.total, isTotal: true),
          SizedBox(height: 8.h),
          _buildSummaryRow(
            'Amount Paid',
            invoice.amountPaid,
            valueColor: DuukaColors.success,
          ),
          if (invoice.remainingBalance > 0) ...[
            SizedBox(height: 8.h),
            _buildSummaryRow(
              'Balance Due',
              invoice.remainingBalance,
              isTotal: true,
              valueColor: DuukaColors.warning,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAmountInWords(Invoice invoice) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: DuukaColors.infoBg,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: DuukaColors.info.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Amount in Words:',
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: FontWeight.w600,
                color: DuukaColors.textSecondary,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              NumberToWords.convert(invoice.total),
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: DuukaColors.primary,
              ),
            ),
          ],
        ),
      ),
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
            fontSize: isTotal ? 15.sp : 13.sp,
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w400,
            color: DuukaColors.textPrimary,
          ),
        ),
        Text(
          amount < 0
              ? '-${DuukaFormatters.currency(amount.abs())}'
              : DuukaFormatters.currency(amount),
          style: TextStyle(
            fontSize: isTotal ? 16.sp : 13.sp,
            fontWeight: FontWeight.w700,
            color: valueColor ?? (isTotal ? DuukaColors.primary : DuukaColors.textPrimary),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentHistory(Invoice invoice) {
    return Padding(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment History',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: DuukaColors.textSecondary,
            ),
          ),
          SizedBox(height: 12.h),
          ...invoice.payments.map((payment) => Container(
                margin: EdgeInsets.only(bottom: 8.h),
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: DuukaColors.successBg,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getPaymentMethodLabel(payment.method),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12.sp,
                            color: DuukaColors.success,
                          ),
                        ),
                        Text(
                          DuukaFormatters.dateTime(payment.paidAt),
                          style: TextStyle(fontSize: 11.sp, color: DuukaColors.textSecondary),
                        ),
                      ],
                    ),
                    Text(
                      DuukaFormatters.currency(payment.amount),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14.sp,
                        color: DuukaColors.success,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: EdgeInsets.all(20.w),
      child: Column(
        children: [
          Text(
            'Thank you for your business!',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: DuukaColors.textPrimary,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Please make payment by the due date',
            style: TextStyle(
              fontSize: 12.sp,
              color: DuukaColors.textSecondary,
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'Powered by Duuka',
            style: TextStyle(
              fontSize: 11.sp,
              color: DuukaColors.textHint,
            ),
          ),
        ],
      ),
    );
  }

  void _showPaymentDialog(BuildContext context, Invoice invoice) {
    _paymentAmountController.clear();
    _paymentRefController.clear();
    _selectedPaymentMethod = InvoicePaymentMethod.cash;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Record Payment'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Balance info
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: DuukaColors.infoBg,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Balance Due:',
                        style: TextStyle(fontSize: 13.sp),
                      ),
                      Text(
                        DuukaFormatters.currency(invoice.remainingBalance),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.sp,
                          color: DuukaColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16.h),
                TextField(
                  controller: _paymentAmountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Amount',
                    hintText: 'Enter amount paid',
                    prefixText: 'UGX ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                DropdownButtonFormField<InvoicePaymentMethod>(
                  value: _selectedPaymentMethod,
                  decoration: InputDecoration(
                    labelText: 'Payment Method',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  items: InvoicePaymentMethod.values.map((method) {
                    return DropdownMenuItem(
                      value: method,
                      child: Text(_getPaymentMethodLabel(method)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() => _selectedPaymentMethod = value!);
                  },
                ),
                SizedBox(height: 16.h),
                TextField(
                  controller: _paymentRefController,
                  decoration: InputDecoration(
                    labelText: 'Reference (Optional)',
                    hintText: 'e.g., Transaction ID',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final amount = double.tryParse(_paymentAmountController.text);
                if (amount == null || amount <= 0) {
                  context.showErrorSnackBar('Enter valid amount');
                  return;
                }

                if (amount > invoice.remainingBalance) {
                  context.showErrorSnackBar(
                    'Amount exceeds balance: ${DuukaFormatters.currency(invoice.remainingBalance)}',
                  );
                  return;
                }

                try {
                  await ref.read(invoicesProvider.notifier).recordPayment(
                        invoice: invoice,
                        amount: amount,
                        method: _selectedPaymentMethod,
                        reference: _paymentRefController.text.isEmpty
                            ? null
                            : _paymentRefController.text,
                      );

                  // Invalidate to refresh the invoice data
                  ref.invalidate(invoiceByIdProvider(id: widget.invoiceId));

                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                  }
                  if (context.mounted) {
                    context.showSuccessSnackBar('Payment recorded successfully');
                  }
                } catch (e) {
                  if (context.mounted) {
                    context.showErrorSnackBar('Failed to record payment: $e');
                  }
                }
              },
              child: const Text('Record Payment'),
            ),
          ],
        ),
      ),
    );
  }

  void _cancelInvoice(BuildContext context, Invoice invoice) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel Invoice'),
        content: const Text('Are you sure you want to cancel this invoice?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () async {
              await ref.read(invoicesProvider.notifier).cancel(invoice);
              ref.invalidate(invoiceByIdProvider(id: widget.invoiceId));
              if (dialogContext.mounted) {
                Navigator.of(dialogContext).pop();
              }
              if (context.mounted) {
                context.showSuccessSnackBar('Invoice cancelled');
              }
            },
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, Invoice invoice) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Invoice'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await ref.read(invoicesProvider.notifier).delete(invoice.id);
              if (dialogContext.mounted) {
                Navigator.of(dialogContext).pop();
              }
              if (context.mounted) {
                context.showSuccessSnackBar('Invoice deleted');
                context.pop();
              }
            },
            child: const Text('Delete'),
          ),
        ],
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

  String _getPaymentMethodLabel(InvoicePaymentMethod method) {
    switch (method) {
      case InvoicePaymentMethod.cash:
        return 'Cash';
      case InvoicePaymentMethod.mobileMoney:
        return 'Mobile Money';
      case InvoicePaymentMethod.bankTransfer:
        return 'Bank Transfer';
      case InvoicePaymentMethod.other:
        return 'Other';
    }
  }
}
