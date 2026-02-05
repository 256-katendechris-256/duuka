import 'dart:io';
import 'dart:convert';

import 'package:excel/excel.dart' as excel_lib;
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../datasources/local/database_service.dart';
import '../models/models.dart';
import '../../core/utils/formatters.dart';

enum DataCollection {
  products,
  customers,
  sales,
  credits,
  creditPayments,
  expenses,
  business,
  users,
  syncQueue,
}

enum ImportMode { replace, merge }

enum ExportFormat { excel, pdf }

class ImportResult {
  final int successCount;
  final int errorCount;
  final List<String> errors;
  final Map<DataCollection, int> collectionCounts;

  ImportResult({
    required this.successCount,
    required this.errorCount,
    required this.errors,
    required this.collectionCounts,
  });
}

class ExportPreview {
  final Map<DataCollection, int> collectionCounts;

  ExportPreview({required this.collectionCounts});
}

class ImportPreview {
  final Map<DataCollection, int> collectionCounts;
  final List<String> warnings;

  ImportPreview({
    required this.collectionCounts,
    required this.warnings,
  });
}

class DataExportImportService {
  final Isar _isar = DatabaseService.instance;

  // Get record counts for all collections
  Future<Map<DataCollection, int>> getCollectionCounts() async {
    final counts = <DataCollection, int>{};

    counts[DataCollection.products] = await _isar.products.count();
    counts[DataCollection.customers] = await _isar.customers.count();
    counts[DataCollection.sales] = await _isar.sales.count();
    counts[DataCollection.credits] = await _isar.creditTransactions.count();
    counts[DataCollection.creditPayments] = await _isar.creditPayments.count();
    counts[DataCollection.expenses] = await _isar.expenses.count();
    counts[DataCollection.business] = await _isar.business.count();
    counts[DataCollection.users] = await _isar.appUsers.count();
    counts[DataCollection.syncQueue] = await _isar.syncQueues.count();

    return counts;
  }

  // Export to Excel
  Future<File> exportToExcel(List<DataCollection> collections, {String? businessName}) async {
    final excel = excel_lib.Excel.createExcel();
    final name = businessName ?? 'My Business';

    // Create summary sheet
    await _createExcelSummarySheet(excel, collections, businessName: name);

    // Export each selected collection
    for (final collection in collections) {
      await _exportCollectionToExcel(excel, collection);
    }

    // Remove default sheet
    excel.delete('Sheet1');

    // Save file
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final safeName = name.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '_');
    final fileName = '${safeName}_backup_$timestamp.xlsx';
    final file = File('${directory.path}/$fileName');

    final bytes = excel.encode();
    if (bytes != null) {
      await file.writeAsBytes(bytes);
    }

    return file;
  }

  // Export to PDF
  Future<File> exportToPDF(List<DataCollection> collections, {String? businessName}) async {
    final pdf = pw.Document();
    final name = businessName ?? 'My Business';

    // Cover page
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => _buildPdfCoverPage(collections, businessName: name),
      ),
    );

    // Summary and data pages
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildPdfHeader(context, businessName: name),
        footer: (context) => _buildPdfFooter(context, businessName: name),
        build: (context) => _buildPdfContent(collections),
      ),
    );

    // Save file
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final safeName = name.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '_');
    final fileName = '${safeName}_report_$timestamp.pdf';
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  // Import from Excel
  Future<ImportResult> importFromExcel(
    File file,
    ImportMode mode,
    List<DataCollection> collections,
  ) async {
    final errors = <String>[];
    final collectionCounts = <DataCollection, int>{};
    int successCount = 0;
    int errorCount = 0;

    try {
      // Parse Excel file
      final bytes = await file.readAsBytes();
      final excel = excel_lib.Excel.decodeBytes(bytes);

      // Validate structure
      final validationErrors = _validateExcelStructure(excel, collections);
      if (validationErrors.isNotEmpty) {
        return ImportResult(
          successCount: 0,
          errorCount: 0,
          errors: validationErrors,
          collectionCounts: {},
        );
      }

      // ID remapping for relationships
      final idMaps = <DataCollection, Map<int, int>>{};

      // Replace mode: clear collections first
      if (mode == ImportMode.replace) {
        await _clearCollections(collections);
      }

      // Import in dependency order
      final orderedCollections = _getImportOrder(collections);

      for (final collection in orderedCollections) {
        try {
          final result = await _importCollection(
            excel,
            collection,
            mode,
            idMaps,
          );

          successCount += result.successCount;
          errorCount += result.errorCount;
          errors.addAll(result.errors);
          collectionCounts[collection] = result.successCount;

        } catch (e) {
          errors.add('Failed to import ${_getCollectionName(collection)}: $e');
          errorCount++;
        }
      }

      return ImportResult(
        successCount: successCount,
        errorCount: errorCount,
        errors: errors,
        collectionCounts: collectionCounts,
      );
    } catch (e) {
      return ImportResult(
        successCount: 0,
        errorCount: 0,
        errors: ['Failed to read Excel file: $e'],
        collectionCounts: {},
      );
    }
  }

  // Preview import data
  Future<ImportPreview> previewImport(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final excel = excel_lib.Excel.decodeBytes(bytes);

      final counts = <DataCollection, int>{};
      final warnings = <String>[];

      // Count records in each sheet
      for (final collection in DataCollection.values) {
        final sheetName = _getSheetName(collection);
        final sheet = excel.tables[sheetName];

        if (sheet != null && sheet.rows.isNotEmpty) {
          // Subtract 1 for header row
          final rowCount = sheet.rows.length - 1;
          if (rowCount > 0) {
            counts[collection] = rowCount;
          }
        }
      }

      // Add warnings
      if (counts.isEmpty) {
        warnings.add('No data found in file');
      }
      if (counts[DataCollection.users] != null) {
        warnings.add('User accounts will be imported. Ensure passwords are secure.');
      }

      return ImportPreview(
        collectionCounts: counts,
        warnings: warnings,
      );
    } catch (e) {
      throw Exception('Failed to preview file: $e');
    }
  }

  // ===== PRIVATE METHODS =====

  // Create Excel summary sheet
  Future<void> _createExcelSummarySheet(
    excel_lib.Excel excel,
    List<DataCollection> collections, {
    required String businessName,
  }) async {
    final sheet = excel['Summary'];
    excel.setDefaultSheet('Summary');

    final counts = await getCollectionCounts();

    // Title
    sheet.cell(excel_lib.CellIndex.indexByString('A1')).value =
        excel_lib.TextCellValue('$businessName - Data Export');
    sheet.cell(excel_lib.CellIndex.indexByString('A1')).cellStyle =
        excel_lib.CellStyle(bold: true, fontSize: 16);

    // Export info
    sheet.cell(excel_lib.CellIndex.indexByString('A3')).value =
        excel_lib.TextCellValue('Export Date:');
    sheet.cell(excel_lib.CellIndex.indexByString('B3')).value =
        excel_lib.TextCellValue(DuukaFormatters.dateTime(DateTime.now()));

    sheet.cell(excel_lib.CellIndex.indexByString('A4')).value =
        excel_lib.TextCellValue('Collections Exported:');
    sheet.cell(excel_lib.CellIndex.indexByString('B4')).value =
        excel_lib.IntCellValue(collections.length);

    // Record counts header
    sheet.cell(excel_lib.CellIndex.indexByString('A6')).value =
        excel_lib.TextCellValue('Collection');
    sheet.cell(excel_lib.CellIndex.indexByString('B6')).value =
        excel_lib.TextCellValue('Records');
    sheet.cell(excel_lib.CellIndex.indexByString('A6')).cellStyle =
        excel_lib.CellStyle(bold: true);
    sheet.cell(excel_lib.CellIndex.indexByString('B6')).cellStyle =
        excel_lib.CellStyle(bold: true);

    // Record counts
    var row = 7;
    for (final collection in collections) {
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value =
          excel_lib.TextCellValue(_getCollectionName(collection));
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).value =
          excel_lib.IntCellValue(counts[collection] ?? 0);
      row++;
    }

    // Set column widths
    sheet.setColumnWidth(0, 20);
    sheet.setColumnWidth(1, 15);
  }

  // Export a collection to Excel
  Future<void> _exportCollectionToExcel(
    excel_lib.Excel excel,
    DataCollection collection,
  ) async {
    switch (collection) {
      case DataCollection.products:
        await _exportProductsToExcel(excel);
        break;
      case DataCollection.customers:
        await _exportCustomersToExcel(excel);
        break;
      case DataCollection.sales:
        await _exportSalesToExcel(excel);
        break;
      case DataCollection.credits:
        await _exportCreditsToExcel(excel);
        break;
      case DataCollection.creditPayments:
        await _exportCreditPaymentsToExcel(excel);
        break;
      case DataCollection.expenses:
        await _exportExpensesToExcel(excel);
        break;
      case DataCollection.business:
        await _exportBusinessToExcel(excel);
        break;
      case DataCollection.users:
        await _exportUsersToExcel(excel);
        break;
      case DataCollection.syncQueue:
        await _exportSyncQueueToExcel(excel);
        break;
    }
  }

  // Export Products to Excel
  Future<void> _exportProductsToExcel(excel_lib.Excel excel) async {
    final sheet = excel['Products'];
    final products = await _isar.products.where().findAll();

    final headerStyle = excel_lib.CellStyle(
      bold: true,
      backgroundColorHex: excel_lib.ExcelColor.blue100,
    );

    // Headers
    final headers = [
      'ID', 'Name', 'Size', 'Color', 'Category', 'Barcode',
      'Cost Price', 'Sell Price', 'Stock Quantity', 'Reorder Level',
      'Is Measurable', 'Measurement Unit', 'Custom Unit', 'Photo Path',
      'Is Active', 'Created At', 'Updated At', 'Remote ID', 'Sync Status',
    ];

    for (var i = 0; i < headers.length; i++) {
      final cell = sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = excel_lib.TextCellValue(headers[i]);
      cell.cellStyle = headerStyle;
    }

    // Data rows
    for (var rowIndex = 0; rowIndex < products.length; rowIndex++) {
      final product = products[rowIndex];
      final row = rowIndex + 1;

      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value =
          excel_lib.IntCellValue(product.id);
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).value =
          excel_lib.TextCellValue(product.name);
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row)).value =
          excel_lib.TextCellValue(product.size ?? '');
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row)).value =
          excel_lib.TextCellValue(product.color ?? '');
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row)).value =
          excel_lib.TextCellValue(product.category ?? '');
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row)).value =
          excel_lib.TextCellValue(product.barcode ?? '');
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row)).value =
          excel_lib.DoubleCellValue(product.costPrice);
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: row)).value =
          excel_lib.DoubleCellValue(product.sellPrice);
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: row)).value =
          excel_lib.DoubleCellValue(product.stockQuantity);
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: row)).value =
          excel_lib.IntCellValue(product.reorderLevel);
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: row)).value =
          excel_lib.TextCellValue(product.isMeasurable.toString());
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 11, rowIndex: row)).value =
          excel_lib.TextCellValue(product.measurementUnit?.name ?? '');
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 12, rowIndex: row)).value =
          excel_lib.TextCellValue(product.customUnit ?? '');
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 13, rowIndex: row)).value =
          excel_lib.TextCellValue(product.photoPath ?? '');
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 14, rowIndex: row)).value =
          excel_lib.TextCellValue(product.isActive.toString());
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 15, rowIndex: row)).value =
          excel_lib.TextCellValue(product.createdAt.toIso8601String());
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 16, rowIndex: row)).value =
          excel_lib.TextCellValue(product.updatedAt.toIso8601String());
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 17, rowIndex: row)).value =
          excel_lib.TextCellValue(product.remoteId ?? '');
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 18, rowIndex: row)).value =
          excel_lib.TextCellValue(product.syncStatus.name);
    }

    // Set column widths
    sheet.setColumnWidth(1, 25); // Name
    sheet.setColumnWidth(4, 20); // Category
  }

  // Export Customers to Excel
  Future<void> _exportCustomersToExcel(excel_lib.Excel excel) async {
    final sheet = excel['Customers'];
    final customers = await _isar.customers.where().findAll();

    final headerStyle = excel_lib.CellStyle(
      bold: true,
      backgroundColorHex: excel_lib.ExcelColor.blue100,
    );

    // Headers
    final headers = [
      'ID', 'Name', 'Phone', 'Location', 'Notes',
      'Created At', 'Last Purchase At', 'Total Purchases', 'Total Spent',
    ];

    for (var i = 0; i < headers.length; i++) {
      final cell = sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = excel_lib.TextCellValue(headers[i]);
      cell.cellStyle = headerStyle;
    }

    // Data rows
    for (var rowIndex = 0; rowIndex < customers.length; rowIndex++) {
      final customer = customers[rowIndex];
      final row = rowIndex + 1;

      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value =
          excel_lib.IntCellValue(customer.id);
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).value =
          excel_lib.TextCellValue(customer.name);
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row)).value =
          excel_lib.TextCellValue(customer.phone);
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row)).value =
          excel_lib.TextCellValue(customer.location ?? '');
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row)).value =
          excel_lib.TextCellValue(customer.notes ?? '');
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row)).value =
          excel_lib.TextCellValue(customer.createdAt.toIso8601String());
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row)).value =
          excel_lib.TextCellValue(customer.lastPurchaseAt?.toIso8601String() ?? '');
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: row)).value =
          excel_lib.IntCellValue(customer.totalPurchases);
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: row)).value =
          excel_lib.DoubleCellValue(customer.totalSpent);
    }

    sheet.setColumnWidth(1, 25); // Name
    sheet.setColumnWidth(2, 15); // Phone
  }

  // Export Sales to Excel
  Future<void> _exportSalesToExcel(excel_lib.Excel excel) async {
    final sheet = excel['Sales'];
    final sales = await _isar.sales.where().findAll();

    final headerStyle = excel_lib.CellStyle(
      bold: true,
      backgroundColorHex: excel_lib.ExcelColor.blue100,
    );

    // Headers
    final headers = [
      'ID', 'Receipt Number', 'Customer ID', 'Customer Name', 'User ID', 'User Name',
      'Subtotal', 'Discount', 'Discount Percent', 'Total', 'Amount Paid', 'Balance',
      'Payment Method', 'Payment Status', 'Notes', 'Created At',
      'Remote ID', 'Sync Status', 'Items (JSON)',
    ];

    for (var i = 0; i < headers.length; i++) {
      final cell = sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = excel_lib.TextCellValue(headers[i]);
      cell.cellStyle = headerStyle;
    }

    // Data rows
    for (var rowIndex = 0; rowIndex < sales.length; rowIndex++) {
      final sale = sales[rowIndex];
      final row = rowIndex + 1;

      // Serialize items to JSON
      final itemsJson = jsonEncode(sale.items.map((item) => {
        'productId': item.productId,
        'productName': item.productName,
        'quantity': item.quantity,
        'unitPrice': item.unitPrice,
        'costPrice': item.costPrice,
        'total': item.total,
        'unit': item.unit,
        'isMeasurable': item.isMeasurable,
      }).toList());

      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value =
          excel_lib.IntCellValue(sale.id);
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).value =
          excel_lib.TextCellValue(sale.receiptNumber);
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row)).value =
          excel_lib.TextCellValue(sale.customerId?.toString() ?? '');
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row)).value =
          excel_lib.TextCellValue(sale.customerName ?? '');
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row)).value =
          excel_lib.IntCellValue(sale.userId);
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row)).value =
          excel_lib.TextCellValue(sale.userName ?? '');
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row)).value =
          excel_lib.DoubleCellValue(sale.subtotal);
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: row)).value =
          excel_lib.DoubleCellValue(sale.discount);
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: row)).value =
          excel_lib.DoubleCellValue(sale.discountPercent);
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: row)).value =
          excel_lib.DoubleCellValue(sale.total);
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: row)).value =
          excel_lib.DoubleCellValue(sale.amountPaid);
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 11, rowIndex: row)).value =
          excel_lib.DoubleCellValue(sale.balance);
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 12, rowIndex: row)).value =
          excel_lib.TextCellValue(sale.paymentMethod.name);
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 13, rowIndex: row)).value =
          excel_lib.TextCellValue(sale.paymentStatus.name);
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 14, rowIndex: row)).value =
          excel_lib.TextCellValue(sale.notes ?? '');
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 15, rowIndex: row)).value =
          excel_lib.TextCellValue(sale.createdAt.toIso8601String());
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 16, rowIndex: row)).value =
          excel_lib.TextCellValue(sale.remoteId ?? '');
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 17, rowIndex: row)).value =
          excel_lib.TextCellValue(sale.syncStatus.name);
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 18, rowIndex: row)).value =
          excel_lib.TextCellValue(itemsJson);
    }

    sheet.setColumnWidth(1, 18); // Receipt Number
    sheet.setColumnWidth(18, 40); // Items JSON
  }

  // Export Credits to Excel
  Future<void> _exportCreditsToExcel(excel_lib.Excel excel) async {
    final sheet = excel['Credits'];
    final credits = await _isar.creditTransactions.where().findAll();

    final headerStyle = excel_lib.CellStyle(
      bold: true,
      backgroundColorHex: excel_lib.ExcelColor.blue100,
    );

    // Headers
    final headers = [
      'ID', 'Customer ID', 'Customer Name', 'Customer Phone', 'Sale ID',
      'Type', 'Status', 'Total Amount', 'Amount Paid',
      'Agreed Payment Date', 'Product Name', 'Product ID', 'Product Quantity',
      'Notes', 'Created At', 'Cleared At', 'Collected At',
    ];

    for (var i = 0; i < headers.length; i++) {
      final cell = sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = excel_lib.TextCellValue(headers[i]);
      cell.cellStyle = headerStyle;
    }

    // Data rows
    for (var rowIndex = 0; rowIndex < credits.length; rowIndex++) {
      final credit = credits[rowIndex];
      final row = rowIndex + 1;

      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value =
          excel_lib.IntCellValue(credit.id);
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).value =
          excel_lib.IntCellValue(credit.customerId);
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row)).value =
          excel_lib.TextCellValue(credit.customerName);
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row)).value =
          excel_lib.TextCellValue(credit.customerPhone);
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row)).value =
          excel_lib.TextCellValue(credit.saleId?.toString() ?? '');
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row)).value =
          excel_lib.TextCellValue(credit.type.name);
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row)).value =
          excel_lib.TextCellValue(credit.status.name);
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: row)).value =
          excel_lib.DoubleCellValue(credit.totalAmount);
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: row)).value =
          excel_lib.DoubleCellValue(credit.amountPaid);
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: row)).value =
          excel_lib.TextCellValue(credit.agreedPaymentDate?.toIso8601String() ?? '');
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: row)).value =
          excel_lib.TextCellValue(credit.productName ?? '');
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 11, rowIndex: row)).value =
          excel_lib.TextCellValue(credit.productId?.toString() ?? '');
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 12, rowIndex: row)).value =
          excel_lib.TextCellValue(credit.productQuantity?.toString() ?? '');
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 13, rowIndex: row)).value =
          excel_lib.TextCellValue(credit.notes ?? '');
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 14, rowIndex: row)).value =
          excel_lib.TextCellValue(credit.createdAt.toIso8601String());
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 15, rowIndex: row)).value =
          excel_lib.TextCellValue(credit.clearedAt?.toIso8601String() ?? '');
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 16, rowIndex: row)).value =
          excel_lib.TextCellValue(credit.collectedAt?.toIso8601String() ?? '');
    }
  }

  // Export Credit Payments to Excel
  Future<void> _exportCreditPaymentsToExcel(excel_lib.Excel excel) async {
    final sheet = excel['Credit Payments'];
    final payments = await _isar.creditPayments.where().findAll();

    final headerStyle = excel_lib.CellStyle(
      bold: true,
      backgroundColorHex: excel_lib.ExcelColor.blue100,
    );

    // Headers
    final headers = [
      'ID', 'Credit Transaction ID', 'Amount', 'Paid At',
      'Payment Method', 'Notes', 'Receipt Number',
    ];

    for (var i = 0; i < headers.length; i++) {
      final cell = sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = excel_lib.TextCellValue(headers[i]);
      cell.cellStyle = headerStyle;
    }

    // Data rows
    for (var rowIndex = 0; rowIndex < payments.length; rowIndex++) {
      final payment = payments[rowIndex];
      final row = rowIndex + 1;

      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value =
          excel_lib.IntCellValue(payment.id);
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).value =
          excel_lib.IntCellValue(payment.creditTransactionId);
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row)).value =
          excel_lib.DoubleCellValue(payment.amount);
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row)).value =
          excel_lib.TextCellValue(payment.paidAt.toIso8601String());
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row)).value =
          excel_lib.TextCellValue(payment.paymentMethod);
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row)).value =
          excel_lib.TextCellValue(payment.notes ?? '');
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row)).value =
          excel_lib.TextCellValue(payment.receiptNumber ?? '');
    }
  }

  // Export Expenses to Excel
  Future<void> _exportExpensesToExcel(excel_lib.Excel excel) async {
    final sheet = excel['Expenses'];
    final expenses = await _isar.expenses.where().findAll();

    final headerStyle = excel_lib.CellStyle(
      bold: true,
      backgroundColorHex: excel_lib.ExcelColor.blue100,
    );

    // Headers
    final headers = [
      'ID', 'Description', 'Amount', 'Category', 'Date',
      'Notes', 'Receipt Path', 'Payment Method', 'Vendor',
      'Is Recurring', 'Created At', 'Sync Status',
    ];

    for (var i = 0; i < headers.length; i++) {
      final cell = sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = excel_lib.TextCellValue(headers[i]);
      cell.cellStyle = headerStyle;
    }

    // Data rows
    for (var rowIndex = 0; rowIndex < expenses.length; rowIndex++) {
      final expense = expenses[rowIndex];
      final row = rowIndex + 1;

      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value =
          excel_lib.IntCellValue(expense.id);
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).value =
          excel_lib.TextCellValue(expense.description);
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row)).value =
          excel_lib.DoubleCellValue(expense.amount);
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row)).value =
          excel_lib.TextCellValue(expense.category.name);
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row)).value =
          excel_lib.TextCellValue(expense.date.toIso8601String());
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row)).value =
          excel_lib.TextCellValue(expense.notes ?? '');
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row)).value =
          excel_lib.TextCellValue(expense.receiptPath ?? '');
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: row)).value =
          excel_lib.TextCellValue(expense.paymentMethod);
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: row)).value =
          excel_lib.TextCellValue(expense.vendor ?? '');
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: row)).value =
          excel_lib.TextCellValue(expense.isRecurring.toString());
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: row)).value =
          excel_lib.TextCellValue(expense.createdAt.toIso8601String());
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 11, rowIndex: row)).value =
          excel_lib.TextCellValue(expense.syncStatus.name);
    }

    sheet.setColumnWidth(1, 30); // Description
  }

  // Export Business to Excel
  Future<void> _exportBusinessToExcel(excel_lib.Excel excel) async {
    final sheet = excel['Business'];
    final businesses = await _isar.business.where().findAll();

    final headerStyle = excel_lib.CellStyle(
      bold: true,
      backgroundColorHex: excel_lib.ExcelColor.blue100,
    );

    // Headers
    final headers = [
      'ID', 'Name', 'Owner Name', 'Phone', 'Email', 'Address',
      'District', 'Area', 'TIN Number', 'Logo Path', 'Business Type',
      'Business Size', 'Plan', 'Plan Expiry Date', 'On Trial',
      'Created At', 'Updated At', 'Remote ID', 'Owner ID',
    ];

    for (var i = 0; i < headers.length; i++) {
      final cell = sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = excel_lib.TextCellValue(headers[i]);
      cell.cellStyle = headerStyle;
    }

    // Data rows
    for (var rowIndex = 0; rowIndex < businesses.length; rowIndex++) {
      final business = businesses[rowIndex];
      final row = rowIndex + 1;

      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value =
          excel_lib.IntCellValue(business.id);
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).value =
          excel_lib.TextCellValue(business.name);
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row)).value =
          excel_lib.TextCellValue(business.ownerName);
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row)).value =
          excel_lib.TextCellValue(business.phone ?? '');
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row)).value =
          excel_lib.TextCellValue(business.email ?? '');
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row)).value =
          excel_lib.TextCellValue(business.address ?? '');
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row)).value =
          excel_lib.TextCellValue(business.district ?? '');
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: row)).value =
          excel_lib.TextCellValue(business.area ?? '');
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: row)).value =
          excel_lib.TextCellValue(business.tinNumber ?? '');
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: row)).value =
          excel_lib.TextCellValue(business.logoPath ?? '');
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: row)).value =
          excel_lib.TextCellValue(business.businessType.name);
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 11, rowIndex: row)).value =
          excel_lib.TextCellValue(business.businessSize.name);
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 12, rowIndex: row)).value =
          excel_lib.TextCellValue(business.plan.name);
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 13, rowIndex: row)).value =
          excel_lib.TextCellValue(business.planExpiryDate?.toIso8601String() ?? '');
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 14, rowIndex: row)).value =
          excel_lib.TextCellValue(business.onTrial.toString());
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 15, rowIndex: row)).value =
          excel_lib.TextCellValue(business.createdAt.toIso8601String());
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 16, rowIndex: row)).value =
          excel_lib.TextCellValue(business.updatedAt.toIso8601String());
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 17, rowIndex: row)).value =
          excel_lib.TextCellValue(business.remoteId ?? '');
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 18, rowIndex: row)).value =
          excel_lib.TextCellValue(business.ownerId ?? '');
    }
  }

  // Export Users to Excel
  Future<void> _exportUsersToExcel(excel_lib.Excel excel) async {
    final sheet = excel['Users'];
    final users = await _isar.appUsers.where().findAll();

    final headerStyle = excel_lib.CellStyle(
      bold: true,
      backgroundColorHex: excel_lib.ExcelColor.blue100,
    );

    // Headers
    final headers = [
      'ID', 'UID', 'Phone', 'Name', 'Email', 'Photo URL',
      'Role', 'Business ID', 'Is Active', 'Created At',
      'Last Login At', 'Remote ID',
    ];

    for (var i = 0; i < headers.length; i++) {
      final cell = sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = excel_lib.TextCellValue(headers[i]);
      cell.cellStyle = headerStyle;
    }

    // Data rows
    for (var rowIndex = 0; rowIndex < users.length; rowIndex++) {
      final user = users[rowIndex];
      final row = rowIndex + 1;

      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value =
          excel_lib.IntCellValue(user.id);
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).value =
          excel_lib.TextCellValue(user.uid);
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row)).value =
          excel_lib.TextCellValue(user.phone);
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row)).value =
          excel_lib.TextCellValue(user.name ?? '');
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row)).value =
          excel_lib.TextCellValue(user.email ?? '');
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row)).value =
          excel_lib.TextCellValue(user.photoUrl ?? '');
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row)).value =
          excel_lib.TextCellValue(user.role.name);
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: row)).value =
          excel_lib.TextCellValue(user.businessId?.toString() ?? '');
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: row)).value =
          excel_lib.TextCellValue(user.isActive.toString());
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: row)).value =
          excel_lib.TextCellValue(user.createdAt.toIso8601String());
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: row)).value =
          excel_lib.TextCellValue(user.lastLoginAt?.toIso8601String() ?? '');
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 11, rowIndex: row)).value =
          excel_lib.TextCellValue(user.remoteId ?? '');
    }
  }

  // Export Sync Queue to Excel
  Future<void> _exportSyncQueueToExcel(excel_lib.Excel excel) async {
    final sheet = excel['Sync Queue'];
    final queue = await _isar.syncQueues.where().findAll();

    final headerStyle = excel_lib.CellStyle(
      bold: true,
      backgroundColorHex: excel_lib.ExcelColor.blue100,
    );

    // Headers
    final headers = [
      'ID', 'Operation', 'Collection Name', 'Local ID', 'Remote ID',
      'Payload', 'Retry Count', 'Error Message', 'Status',
      'Created At', 'Processed At',
    ];

    for (var i = 0; i < headers.length; i++) {
      final cell = sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = excel_lib.TextCellValue(headers[i]);
      cell.cellStyle = headerStyle;
    }

    // Data rows
    for (var rowIndex = 0; rowIndex < queue.length; rowIndex++) {
      final item = queue[rowIndex];
      final row = rowIndex + 1;

      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value =
          excel_lib.IntCellValue(item.id);
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).value =
          excel_lib.TextCellValue(item.operation.name);
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row)).value =
          excel_lib.TextCellValue(item.collectionName);
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row)).value =
          excel_lib.IntCellValue(item.localId);
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row)).value =
          excel_lib.TextCellValue(item.remoteId ?? '');
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row)).value =
          excel_lib.TextCellValue(item.payload ?? '');
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row)).value =
          excel_lib.IntCellValue(item.retryCount);
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: row)).value =
          excel_lib.TextCellValue(item.errorMessage ?? '');
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: row)).value =
          excel_lib.TextCellValue(item.status.name);
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: row)).value =
          excel_lib.TextCellValue(item.createdAt.toIso8601String());
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: row)).value =
          excel_lib.TextCellValue(item.processedAt?.toIso8601String() ?? '');
    }

    sheet.setColumnWidth(5, 40); // Payload
  }

  // PDF Cover Page
  pw.Widget _buildPdfCoverPage(List<DataCollection> collections, {required String businessName}) {
    return pw.Center(
      child: pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Text(
            businessName.toUpperCase(),
            style: pw.TextStyle(
              fontSize: 48,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue700,
            ),
          ),
          pw.SizedBox(height: 16),
          pw.Text(
            'Data Export Report',
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 32),
          pw.Text(
            'Generated: ${DuukaFormatters.dateTime(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 14),
          ),
          pw.SizedBox(height: 16),
          pw.Text(
            'Collections: ${collections.length}',
            style: const pw.TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  // PDF Header
  pw.Widget _buildPdfHeader(pw.Context context, {required String businessName}) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              '$businessName - Export Report',
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.Text(
              DuukaFormatters.date(DateTime.now()),
              style: const pw.TextStyle(fontSize: 12),
            ),
          ],
        ),
        pw.Divider(thickness: 2, color: PdfColors.blue700),
        pw.SizedBox(height: 8),
      ],
    );
  }

  // PDF Footer
  pw.Widget _buildPdfFooter(pw.Context context, {required String businessName}) {
    return pw.Row(
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
    );
  }

  // PDF Content
  List<pw.Widget> _buildPdfContent(List<DataCollection> collections) {
    final widgets = <pw.Widget>[];

    // Summary section
    widgets.add(
      pw.Text(
        'Summary',
        style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
      ),
    );
    widgets.add(pw.SizedBox(height: 12));

    // Note about limitation
    widgets.add(
      pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: PdfColors.blue50,
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Text(
          'This PDF report shows a summary of your data. For full data backup and restore, please use the Excel export format.',
          style: const pw.TextStyle(fontSize: 11, color: PdfColors.blue900),
        ),
      ),
    );
    widgets.add(pw.SizedBox(height: 16));

    // Collection counts will be added here when generated
    widgets.add(
      pw.Text(
        'Note: PDF export is for reporting only. Use Excel export for data backup.',
        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
      ),
    );

    return widgets;
  }

  // Validate Excel structure
  List<String> _validateExcelStructure(
    excel_lib.Excel excel,
    List<DataCollection> collections,
  ) {
    final errors = <String>[];

    for (final collection in collections) {
      final sheetName = _getSheetName(collection);
      if (!excel.tables.containsKey(sheetName)) {
        errors.add('Missing sheet: $sheetName');
      }
    }

    return errors;
  }

  // Clear collections
  Future<void> _clearCollections(List<DataCollection> collections) async {
    await _isar.writeTxn(() async {
      for (final collection in collections) {
        switch (collection) {
          case DataCollection.products:
            await _isar.products.clear();
            break;
          case DataCollection.customers:
            await _isar.customers.clear();
            break;
          case DataCollection.sales:
            await _isar.sales.clear();
            break;
          case DataCollection.credits:
            await _isar.creditTransactions.clear();
            break;
          case DataCollection.creditPayments:
            await _isar.creditPayments.clear();
            break;
          case DataCollection.expenses:
            await _isar.expenses.clear();
            break;
          case DataCollection.business:
            await _isar.business.clear();
            break;
          case DataCollection.users:
            await _isar.appUsers.clear();
            break;
          case DataCollection.syncQueue:
            await _isar.syncQueues.clear();
            break;
        }
      }
    });
  }

  // Get import order (respecting dependencies)
  List<DataCollection> _getImportOrder(List<DataCollection> collections) {
    final order = <DataCollection>[];

    // Independent collections first
    if (collections.contains(DataCollection.business)) order.add(DataCollection.business);
    if (collections.contains(DataCollection.users)) order.add(DataCollection.users);
    if (collections.contains(DataCollection.products)) order.add(DataCollection.products);
    if (collections.contains(DataCollection.customers)) order.add(DataCollection.customers);
    if (collections.contains(DataCollection.expenses)) order.add(DataCollection.expenses);

    // Dependent collections
    if (collections.contains(DataCollection.sales)) order.add(DataCollection.sales);
    if (collections.contains(DataCollection.credits)) order.add(DataCollection.credits);
    if (collections.contains(DataCollection.creditPayments)) order.add(DataCollection.creditPayments);

    // Sync queue last
    if (collections.contains(DataCollection.syncQueue)) order.add(DataCollection.syncQueue);

    return order;
  }

  // Import a collection (stub - will be implemented in next step)
  Future<ImportResult> _importCollection(
    excel_lib.Excel excel,
    DataCollection collection,
    ImportMode mode,
    Map<DataCollection, Map<int, int>> idMaps,
  ) async {
    // This will be implemented in the next step
    return ImportResult(
      successCount: 0,
      errorCount: 0,
      errors: [],
      collectionCounts: {},
    );
  }

  // Helper: Get sheet name for collection
  String _getSheetName(DataCollection collection) {
    switch (collection) {
      case DataCollection.products:
        return 'Products';
      case DataCollection.customers:
        return 'Customers';
      case DataCollection.sales:
        return 'Sales';
      case DataCollection.credits:
        return 'Credits';
      case DataCollection.creditPayments:
        return 'Credit Payments';
      case DataCollection.expenses:
        return 'Expenses';
      case DataCollection.business:
        return 'Business';
      case DataCollection.users:
        return 'Users';
      case DataCollection.syncQueue:
        return 'Sync Queue';
    }
  }

  // Helper: Get collection display name
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
}
