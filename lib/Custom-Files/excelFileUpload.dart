import 'dart:developer';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:excel/excel.dart' as excel;
import 'package:file_picker/file_picker.dart';
import 'package:inventory_management/Custom-Files/colors.dart';
import 'package:inventory_management/provider/label_data_provider.dart';
// import 'package:path/path.dart';
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
      FilePickerResult? result = await FilePicker.platform
          .pickFiles(type: FileType.custom, allowedExtensions: ['xlsx']);

      if (result != null && result.files.single.bytes != null) {
        labelDataProvider.setLoadingDataGroups(true);

        final Uint8List bytes = result.files.single.bytes!;
        var excelFile = excel.Excel.decodeBytes(bytes);

        if (excelFile.tables.containsKey(widget.sheetName)) {
          List<List<dynamic>> rows =
              excelFile.tables[widget.sheetName]?.rows ?? [];

          if (rows.isNotEmpty) {
            List<String> headers =
                rows.first.map((cell) => cell?.value.toString() ?? '').toList();

            List<Map<String, String>> tempDataGroups = [];
            for (var row in rows.skip(1)) {
              if (_isRowEmptyOrInvalid(row)) continue;

              Map<String, String> dataMap = {};
              bool hasValidValue = false;

              for (int i = 0; i < headers.length; i++) {
                var cellValue = row.length > i && row[i] != null
                    ? _cleanCellValue(row[i])
                    : null;

                if (cellValue != null) {
                  hasValidValue = true;
                }

                dataMap[headers[i]] = cellValue ?? '';
              }

              if (hasValidValue) {
                tempDataGroups.add(dataMap);
                print('Uploaded data: $dataMap'); // Log uploaded data
              }
            }

            widget.onUploadSuccess(tempDataGroups);
            _showMessage(context, 'Excel file uploaded successfully!');
            print('------------------------------');
          } else {
            labelDataProvider.setLoadingDataGroups(false);
            _showMessage(
                context, 'The uploaded sheet is empty. Please check your file.',
                isError: true);
            print('------------------------------');
          }
        } else {
          labelDataProvider.setLoadingDataGroups(false);

          _showMessage(context,
              'Couldn\'t find "${widget.sheetName}" in the uploaded file. Please ensure it exists.',
              isError: true);
          print('------------------------------');
        }
      } else {
        labelDataProvider.setLoadingDataGroups(false);

        _showMessage(
            context, 'Please upload an Excel file (.xlsx) only. Try again.',
            isError: true);
        print('------------------------------');
      }
    } catch (e) {
      labelDataProvider.setLoadingDataGroups(false);
      log('error: $e');

      widget.onError('An unexpected error occurred: ${e.toString()}');
      _showMessage(context, 'An unexpected error occurred. Please try again.',
          isError: true);
      print('------------------------------');
    } finally {
      labelDataProvider.setLoadingDataGroups(false);
    }
  }

  void _showMessage(BuildContext context, String message,
      {bool isError = false}) {
    print(message);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.cardsred : AppColors.primaryGreen,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  bool _isRowEmptyOrInvalid(List<dynamic> row) {
    for (var cell in row) {
      var cellValue = cell?.toString().trim() ?? '';
      if (cellValue.isNotEmpty && cellValue.toLowerCase() != 'n/a') {
        return false;
      }
    }
    return true;
  }

  String? _cleanCellValue(dynamic cell) {
    if (cell == null) {
      return null;
    }
    if (cell is String) {
      return cell.isNotEmpty ? cell.trim() : null;
    } else if (cell is Map) {
      return cell.toString().isNotEmpty ? cell.toString().trim() : null;
    } else if (cell.toString().contains('Data(')) {
      var cleanedValue = cell.toString().replaceAllMapped(
            RegExp(r'Data\((.*?),.*\)'),
            (match) => match.group(1) ?? '',
          );
      return cleanedValue.isNotEmpty ? cleanedValue : null;
    }
    return cell.toString().isNotEmpty ? cell.toString().trim() : null;
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => _pickFile(context),
      child: const Text('Upload Excel File'),
    );
  }
}
