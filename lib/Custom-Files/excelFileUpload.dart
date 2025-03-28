import 'dart:developer';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:excel/excel.dart' as excel;
import 'package:file_picker/file_picker.dart';
import 'package:inventory_management/Custom-Files/colors.dart';
import 'package:inventory_management/provider/label_data_provider.dart';
import 'package:provider/provider.dart';

class ExcelFileUploader extends StatefulWidget {
  final String sheetName;
  final Function(List<Map<String, String>>) onUploadSuccess;
  final Function(String) onError;

  const ExcelFileUploader({
    super.key,
    required this.sheetName,
    required this.onUploadSuccess,
    required this.onError,
  });

  @override
  State<ExcelFileUploader> createState() => _ExcelFileUploaderState();
}

class _ExcelFileUploaderState extends State<ExcelFileUploader> {

  Future<void> _pickFile(BuildContext context) async {

    final labelDataProvider = context.read<LabelDataProvider>();

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'xlsx'
        ],
      );

      if (result == null || result.files.single.bytes == null) {
        _showMessage(context, 'No file selected or invalid file.', isError: true);
        return;
      }

      labelDataProvider.setLoadingDataGroups(true);

      final Uint8List bytes = result.files.single.bytes!;
      var excelFile = excel.Excel.decodeBytes(bytes);

      // if (!excelFile.tables.containsKey(widget.sheetName)) {
      //   _showMessage(context, 'Sheet "${widget.sheetName}" not found in the uploaded file.', isError: true);
      //   return;
      // }

      var sheet = excelFile.sheets.values.toList();

      // var sheet = excelFile.tables[widget.sheetName]!;

      if (sheet.isEmpty) {
        _showMessage(context, 'Sheet not found in the uploaded file.', isError: true);
        return;
      }

      List<List<dynamic>> rows = sheet.first.rows;

      if (rows.isEmpty) {
        _showMessage(context, 'The uploaded sheet is empty.', isError: true);
        return;
      }

      // Parse headers and ensure they're strings
      List<String> headers = rows.first.map((cell) {
        if (cell == null) return '';
        if (cell is excel.Data) {
          var value = cell.value;
          if (value == null) return '';
          return value.toString().trim();
        }
        return cell.toString().trim();
      }).toList();

      List<Map<String, String>> tempDataGroups = [];

      // Process data rows
      for (var row in rows.skip(1)) {
        if (_isRowEmptyOrInvalid(row)) continue;

        Map<String, String> dataMap = {};
        bool hasValidValue = false;

        for (int i = 0; i < headers.length; i++) {
          String? cellValue;
          if (row.length > i) {
            var cell = row[i];
            if (cell is excel.Data) {
              cellValue = _processExcelData(cell);
            } else {
              cellValue = _cleanCellValue(cell);
            }
          }

          if (cellValue != null && cellValue.isNotEmpty) {
            hasValidValue = true;
          }
          dataMap[headers[i]] = cellValue ?? '';
        }

        if (hasValidValue) tempDataGroups.add(dataMap);
      }

      if (tempDataGroups.isNotEmpty) {
        widget.onUploadSuccess(tempDataGroups);
        _showMessage(context, 'Excel file loaded successfully.');
      } else {
        _showMessage(context, 'No valid data found in the sheet.', isError: true);
      }
    } catch (e) {
      log('Error parsing Excel file: $e');
      widget.onError('An error occurred: ${e.toString()}');
      _showMessage(context, 'An error occurred while processing the file.', isError: true);
    } finally {
      labelDataProvider.setLoadingDataGroups(false);
    }
  }

  String? _processExcelData(excel.Data cell) {
    var value = cell.value;
    if (value == null) return null;

    // Handle different data types
    if (value is DateTime) {
      return value.toString();
    } else if (value is num) {
      return value.toString();
    } else if (value is bool) {
      return value.toString();
    } else if (value.runtimeType.toString() == 'String') {
      // Important change here
      return value as String;
    }
    return value.toString().trim();
  }

  void _showMessage(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.cardsred : AppColors.primaryGreen,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  bool _isRowEmptyOrInvalid(List<dynamic> row) {
    return row.every((cell) {
      if (cell is excel.Data) {
        var value = cell.value;
        if (value == null) return true;
        var stringValue = value.toString().trim();
        return stringValue.isEmpty || stringValue.toLowerCase() == 'n/a';
      }
      return (cell?.toString().trim().isEmpty ?? true) || cell.toString().toLowerCase() == 'n/a';
    });
  }

  String? _cleanCellValue(dynamic cell) {
    if (cell == null) return null;
    if (cell is excel.Data) {
      return _processExcelData(cell);
    }
    var stringValue = cell.toString().trim();
    if (stringValue.isEmpty) return null;
    return stringValue;
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => _pickFile(context),
      child: const Text('Upload Excel File'),
    );
  }
}
