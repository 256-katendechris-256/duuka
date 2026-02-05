import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart' as excel_lib;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/models.dart';
import '../../widgets/common/duuka_app_bar.dart';
import '../../widgets/common/duuka_button.dart';
import '../../providers/product_provider.dart';

class BulkUploadScreen extends ConsumerStatefulWidget {
  const BulkUploadScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<BulkUploadScreen> createState() => _BulkUploadScreenState();
}

class _BulkUploadScreenState extends ConsumerState<BulkUploadScreen> {
  File? _selectedFile;
  String? _fileType; // 'csv' or 'excel'
  List<List<dynamic>>? _parsedData;
  List<String> _errors = [];
  bool _isLoading = false;
  int _successCount = 0;
  int _errorCount = 0;

  // Column indices based on template
  static const int _colName = 0;
  static const int _colSize = 1;
  static const int _colColor = 2;
  static const int _colCategory = 3;
  static const int _colBarcode = 4;
  static const int _colCostPrice = 5;
  static const int _colSellPrice = 6;
  static const int _colQuantity = 7;
  static const int _colReorderLevel = 8;
  static const int _colUnit = 9;

  Future<void> _downloadTemplate() async {
    try {
      // Show option to download CSV or Excel
      final format = await showModalBottomSheet<String>(
        context: context,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        builder: (context) => Container(
          padding: EdgeInsets.all(16.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Choose Template Format',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: DuukaColors.textPrimary,
                ),
              ),
              SizedBox(height: 20.h),
              ListTile(
                leading: Icon(Icons.table_chart, color: DuukaColors.success, size: 28.sp),
                title: const Text('Excel (.xlsx)'),
                subtitle: const Text('Recommended for most users'),
                onTap: () => Navigator.pop(context, 'excel'),
              ),
              ListTile(
                leading: Icon(Icons.description, color: DuukaColors.info, size: 28.sp),
                title: const Text('CSV (.csv)'),
                subtitle: const Text('Plain text format'),
                onTap: () => Navigator.pop(context, 'csv'),
              ),
              SizedBox(height: 16.h),
            ],
          ),
        ),
      );

      if (format == null) return;

      if (format == 'excel') {
        await _downloadExcelTemplate();
      } else {
        await _downloadCSVTemplate();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: DuukaColors.error,
          ),
        );
      }
    }
  }

  Future<void> _downloadExcelTemplate() async {
    final excel = excel_lib.Excel.createExcel();
    final sheet = excel['Products'];
    
    // Remove default sheet
    excel.delete('Sheet1');

    // Add header row with styling
    final headers = ['Name*', 'Size', 'Color', 'Category', 'Barcode', 'Cost Price*', 'Sell Price*', 'Quantity*', 'Reorder Level', 'Unit'];
    for (var i = 0; i < headers.length; i++) {
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0)).value = excel_lib.TextCellValue(headers[i]);
    }

    // Add sample data rows
    final sampleData = [
      ['Coca Cola', '500ml', '', 'Beverages', '123456789', '1500', '2000', '100', '10', 'pcs'],
      ['T-Shirt', 'L', '#1E88E5', 'Clothing', '', '15000', '25000', '50', '5', 'pcs'],
      ['Blue Band', '250g', '', 'Cooking Essentials', '', '3000', '3500', '50', '5', 'pcs'],
      ['Nike Shoes', '42', '#000000', 'Footwear', '', '80000', '120000', '20', '3', 'pairs'],
    ];

    for (var rowIndex = 0; rowIndex < sampleData.length; rowIndex++) {
      for (var colIndex = 0; colIndex < sampleData[rowIndex].length; colIndex++) {
        sheet.cell(excel_lib.CellIndex.indexByColumnRow(
          columnIndex: colIndex,
          rowIndex: rowIndex + 1,
        )).value = excel_lib.TextCellValue(sampleData[rowIndex][colIndex]);
      }
    }

    // Set column widths for better readability
    sheet.setColumnWidth(0, 20); // Name
    sheet.setColumnWidth(1, 10); // Size
    sheet.setColumnWidth(2, 10); // Color
    sheet.setColumnWidth(3, 18); // Category
    sheet.setColumnWidth(4, 15); // Barcode
    sheet.setColumnWidth(5, 12); // Cost Price
    sheet.setColumnWidth(6, 12); // Sell Price
    sheet.setColumnWidth(7, 10); // Quantity
    sheet.setColumnWidth(8, 14); // Reorder Level
    sheet.setColumnWidth(9, 8);  // Unit

    // Save file
    final tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/duuka_product_template.xlsx';
    final fileBytes = excel.save();
    if (fileBytes != null) {
      final file = File(filePath);
      await file.writeAsBytes(fileBytes);

      await Share.shareXFiles(
        [XFile(filePath)],
        subject: 'Duuka Product Upload Template (Excel)',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Excel template ready to share'),
            backgroundColor: DuukaColors.success,
          ),
        );
      }
    }
  }

  Future<void> _downloadCSVTemplate() async {
    final csvData = [
      ['Name*', 'Size', 'Color', 'Category', 'Barcode', 'Cost Price*', 'Sell Price*', 'Quantity*', 'Reorder Level', 'Unit'],
      ['Coca Cola', '500ml', '', 'Beverages', '123456789', '1500', '2000', '100', '10', 'pcs'],
      ['T-Shirt', 'L', '#1E88E5', 'Clothing', '', '15000', '25000', '50', '5', 'pcs'],
      ['Blue Band', '250g', '', 'Cooking Essentials', '', '3000', '3500', '50', '5', 'pcs'],
    ];

    final csv = const ListToCsvConverter().convert(csvData);
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/duuka_product_template.csv');
    await file.writeAsString(csv);

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Duuka Product Upload Template (CSV)',
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('CSV template ready to share'),
          backgroundColor: DuukaColors.success,
        ),
      );
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'xlsx', 'xls'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final extension = result.files.single.extension?.toLowerCase();

        setState(() {
          _selectedFile = file;
          _fileType = extension;
          _parsedData = null;
          _errors = [];
          _successCount = 0;
          _errorCount = 0;
        });

        if (extension == 'csv') {
          await _parseCSV(file);
        } else if (extension == 'xlsx' || extension == 'xls') {
          await _parseExcel(file);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error reading file: ${e.toString()}'),
            backgroundColor: DuukaColors.error,
          ),
        );
      }
    }
  }

  Future<void> _parseCSV(File file) async {
    try {
      final csvString = await file.readAsString();

      if (csvString.trim().isEmpty) {
        setState(() {
          _errors = ['CSV file is empty'];
        });
        return;
      }

      // Try to detect the delimiter (comma, semicolon, or tab)
      String delimiter = ',';
      final firstLine = csvString.split('\n').first;

      // Count occurrences of potential delimiters in first line
      final commaCount = ','.allMatches(firstLine).length;
      final semicolonCount = ';'.allMatches(firstLine).length;
      final tabCount = '\t'.allMatches(firstLine).length;

      // Use the delimiter that appears most frequently
      if (semicolonCount > commaCount && semicolonCount > tabCount) {
        delimiter = ';';
      } else if (tabCount > commaCount && tabCount > semicolonCount) {
        delimiter = '\t';
      }

      final csvData = CsvToListConverter(
        fieldDelimiter: delimiter,
        eol: '\n',
        shouldParseNumbers: false, // Keep everything as strings for validation
      ).convert(csvString);

      // Filter out empty rows
      final filteredData = csvData.where((row) {
        return row.isNotEmpty && !row.every((cell) => cell.toString().trim().isEmpty);
      }).toList();

      if (filteredData.isEmpty) {
        setState(() {
          _errors = ['No data found in CSV file. Please check the file content.'];
        });
        return;
      }

      if (filteredData.length < 2) {
        setState(() {
          _errors = [
            'File must have a header row and at least one data row.',
            'Found ${filteredData.length} row(s). First row: ${filteredData.isNotEmpty ? filteredData.first.take(3).join(", ") : "empty"}...',
          ];
        });
        return;
      }

      setState(() {
        _parsedData = filteredData;
      });

      _validateData();
    } catch (e) {
      setState(() {
        _errors = ['Error parsing CSV: ${e.toString()}'];
      });
    }
  }

  Future<void> _parseExcel(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final excel = excel_lib.Excel.decodeBytes(bytes);

      // Get the first sheet
      final sheetName = excel.tables.keys.first;
      final sheet = excel.tables[sheetName];

      if (sheet == null || sheet.rows.isEmpty) {
        setState(() {
          _errors = ['Excel file is empty'];
        });
        return;
      }

      // Convert Excel rows to List<List<dynamic>>
      final data = <List<dynamic>>[];
      for (final row in sheet.rows) {
        final rowData = row.map((cell) {
          if (cell == null || cell.value == null) return '';
          return cell.value.toString();
        }).toList();

        // Skip completely empty rows
        if (rowData.every((cell) => cell.toString().trim().isEmpty)) continue;

        data.add(rowData);
      }

      setState(() {
        _parsedData = data;
      });

      _validateData();
    } catch (e) {
      final errorMsg = e.toString().toLowerCase();

      // Check for common Excel parsing errors and provide helpful messages
      if (errorMsg.contains('damaged') || errorMsg.contains('styles') || errorMsg.contains('corrupt')) {
        setState(() {
          _errors = ['Excel file has incompatible formatting'];
        });
        // Show helpful dialog
        if (mounted) {
          _showExcelFormatHelpDialog();
        }
      } else {
        setState(() {
          _errors = ['Error parsing Excel file: ${e.toString()}'];
        });
      }
    }
  }

  void _showExcelFormatHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: DuukaColors.warning, size: 28.sp),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                'Excel Format Issue',
                style: TextStyle(fontSize: 18.sp),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This Excel file has styling/formatting that cannot be read. This often happens with files from Google Sheets or newer Excel versions.',
                style: TextStyle(fontSize: 13.sp, color: DuukaColors.textSecondary),
              ),
              SizedBox(height: 16.h),
              Text(
                'Quick Fix:',
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8.h),
              _buildHelpStep('1', 'Open your file in Excel or Google Sheets'),
              _buildHelpStep('2', 'Go to File → Save As (or Download as)'),
              _buildHelpStep('3', 'Choose CSV format (.csv)'),
              _buildHelpStep('4', 'Upload the CSV file here'),
              SizedBox(height: 16.h),
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: DuukaColors.infoBg,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: DuukaColors.info, size: 20.sp),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        'CSV files work more reliably for data import',
                        style: TextStyle(fontSize: 12.sp, color: DuukaColors.info),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _pickFile(); // Let user pick a different file
            },
            icon: const Icon(Icons.upload_file, size: 18),
            label: const Text('Select Different File'),
            style: ElevatedButton.styleFrom(
              backgroundColor: DuukaColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpStep(String number, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20.w,
            height: 20.h,
            decoration: BoxDecoration(
              color: DuukaColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: DuukaColors.primary,
                ),
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13.sp, color: DuukaColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  void _validateData() {
    if (_parsedData == null || _parsedData!.isEmpty) {
      setState(() {
        _errors = ['File is empty'];
      });
      return;
    }

    final errors = <String>[];

    // Check headers
    if (_parsedData!.length < 2) {
      errors.add('File must have header row and at least one data row');
      errors.add('Found ${_parsedData!.length} row(s)');
      if (_parsedData!.isNotEmpty) {
        final firstRow = _parsedData!.first;
        errors.add('First row preview: ${firstRow.take(4).map((c) => c.toString().isEmpty ? "(empty)" : c).join(" | ")}');
      }
      setState(() {
        _errors = errors;
      });
      return;
    }

    // Show detected headers for debugging
    final headers = _parsedData!.first;
    debugPrint('Detected headers: $headers');
    debugPrint('Total rows (including header): ${_parsedData!.length}');

    // Validate data rows (skip header)
    for (var i = 1; i < _parsedData!.length; i++) {
      final row = _parsedData![i];
      final rowNum = i + 1;

      // Ensure row has enough columns (pad if necessary)
      while (row.length < 10) {
        row.add('');
      }

      // Validate required fields
      if (row[_colName].toString().trim().isEmpty) {
        errors.add('Row $rowNum: Product name is required');
      }

      // Validate cost price
      final costPrice = row[_colCostPrice].toString().trim();
      if (costPrice.isEmpty || double.tryParse(costPrice) == null) {
        errors.add('Row $rowNum: Valid cost price is required');
      }

      // Validate sell price
      final sellPrice = row[_colSellPrice].toString().trim();
      if (sellPrice.isEmpty || double.tryParse(sellPrice) == null) {
        errors.add('Row $rowNum: Valid sell price is required');
      }

      // Validate quantity
      final quantity = row[_colQuantity].toString().trim();
      if (quantity.isEmpty || int.tryParse(quantity) == null) {
        errors.add('Row $rowNum: Valid quantity is required');
      }
    }

    setState(() {
      _errors = errors;
    });
  }

  Future<void> _uploadProducts() async {
    if (_parsedData == null || _parsedData!.length < 2) return;
    if (_errors.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fix errors before uploading'),
          backgroundColor: DuukaColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _successCount = 0;
      _errorCount = 0;
    });

    final productNotifier = ref.read(productsProvider.notifier);

    // Skip header row
    for (var i = 1; i < _parsedData!.length; i++) {
      final row = _parsedData![i];

      try {
        // Ensure row has enough columns
        while (row.length < 10) {
          row.add('');
        }

        final product = Product()
          ..name = row[_colName].toString().trim()
          ..size = row[_colSize].toString().trim().isEmpty ? null : row[_colSize].toString().trim()
          ..color = row[_colColor].toString().trim().isEmpty ? null : row[_colColor].toString().trim()
          ..category = row[_colCategory].toString().trim().isEmpty ? null : row[_colCategory].toString().trim()
          ..barcode = row[_colBarcode].toString().trim().isEmpty ? null : row[_colBarcode].toString().trim()
          ..costPrice = double.parse(row[_colCostPrice].toString())
          ..sellPrice = double.parse(row[_colSellPrice].toString())
          ..quantity = int.parse(row[_colQuantity].toString())
          ..reorderLevel = row[_colReorderLevel].toString().isNotEmpty
              ? int.parse(row[_colReorderLevel].toString())
              : 5
          ..unit = row[_colUnit].toString().isNotEmpty
              ? row[_colUnit].toString().trim()
              : 'pcs'
          ..createdAt = DateTime.now()
          ..updatedAt = DateTime.now();

        final success = await productNotifier.addProduct(product);

        if (success) {
          setState(() => _successCount++);
        } else {
          setState(() => _errorCount++);
        }
      } catch (e) {
        setState(() => _errorCount++);
        print('Error uploading row $i: $e');
      }
    }

    setState(() => _isLoading = false);

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          title: Row(
            children: [
              Icon(
                _errorCount == 0 ? Icons.check_circle : Icons.info,
                color: _errorCount == 0 ? DuukaColors.success : DuukaColors.warning,
                size: 28.sp,
              ),
              SizedBox(width: 8.w),
              const Text('Upload Complete'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.check, color: DuukaColors.success, size: 20.sp),
                  SizedBox(width: 8.w),
                  Text('Successfully added: $_successCount products'),
                ],
              ),
              if (_errorCount > 0) ...[
                SizedBox(height: 8.h),
                Row(
                  children: [
                    Icon(Icons.close, color: DuukaColors.error, size: 20.sp),
                    SizedBox(width: 8.w),
                    Text(
                      'Failed: $_errorCount products',
                      style: const TextStyle(color: DuukaColors.error),
                    ),
                  ],
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                if (_successCount > 0) {
                  context.pop();
                }
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DuukaColors.background,
      appBar: const DuukaAppBar(
        title: 'Bulk Upload Products',
      ),
      body: ListView(
        padding: EdgeInsets.all(16.w),
        children: [
          // Instructions Card
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: DuukaColors.infoBg,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: DuukaColors.info.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: DuukaColors.info,
                      size: 20.sp,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'How to use Bulk Upload',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: DuukaColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                _buildInstruction('1', 'Download the CSV template'),
                _buildInstruction('2', 'Fill in your product details'),
                _buildInstruction('3', 'Upload the completed Excel or CSV file'),
                SizedBox(height: 4.h),
                Text(
                  'Required fields: Name, Cost Price, Sell Price, Quantity',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w500,
                    color: DuukaColors.error,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Optional fields: Size, Color (hex e.g. #FF5733), Category, Barcode, Reorder Level, Unit',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w400,
                    color: DuukaColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 24.h),

          // Download Template Button
          DuukaButton.secondary(
            label: 'Download Template',
            icon: Icons.download,
            onPressed: _downloadTemplate,
          ),
          SizedBox(height: 16.h),

          // Pick File Button
          DuukaButton.primary(
            label: _selectedFile == null ? 'Select Excel or CSV File' : 'Change File',
            icon: Icons.upload_file,
            onPressed: _pickFile,
          ),
          SizedBox(height: 24.h),

          // Selected File Info
          if (_selectedFile != null) ...[
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: DuukaColors.surface,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: DuukaColors.border, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _fileType == 'xlsx' || _fileType == 'xls' 
                            ? Icons.table_chart 
                            : Icons.description,
                        color: _fileType == 'xlsx' || _fileType == 'xls'
                            ? DuukaColors.success
                            : DuukaColors.info,
                        size: 24.sp,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedFile!.path.split(RegExp(r'[/\\]')).last,
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: DuukaColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              _fileType == 'xlsx' || _fileType == 'xls' 
                                  ? 'Excel Spreadsheet' 
                                  : 'CSV File',
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w400,
                                color: DuukaColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (_parsedData != null && _parsedData!.length > 1) ...[
                    SizedBox(height: 12.h),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: DuukaColors.primaryBg,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        '${_parsedData!.length - 1} products found',
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: DuukaColors.primary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: 16.h),
          ],

          // Errors
          if (_errors.isNotEmpty) ...[
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: DuukaColors.errorBg,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: DuukaColors.error.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: DuukaColors.error,
                        size: 20.sp,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'Validation Errors',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: DuukaColors.error,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  ..._errors.map((error) => Padding(
                        padding: EdgeInsets.only(bottom: 4.h),
                        child: Text(
                          '• $error',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w400,
                            color: DuukaColors.textPrimary,
                          ),
                        ),
                      )),
                ],
              ),
            ),
            SizedBox(height: 16.h),
          ],

          // Upload Button
          if (_selectedFile != null && _errors.isEmpty) ...[
            DuukaButton.primary(
              label: _isLoading ? 'Uploading...' : 'Upload Products',
              onPressed: _isLoading ? null : _uploadProducts,
              isLoading: _isLoading,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInstruction(String number, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20.w,
            height: 20.h,
            decoration: BoxDecoration(
              color: DuukaColors.info,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w400,
                color: DuukaColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
