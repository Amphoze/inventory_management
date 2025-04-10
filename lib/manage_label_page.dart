import 'dart:developer';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:inventory_management/Api/auth_provider.dart';
import 'package:inventory_management/Custom-Files/colors.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:inventory_management/Api/inventory_api.dart';
import 'package:inventory_management/constants/constants.dart';

class ManageLabelPage extends StatefulWidget {
  const ManageLabelPage({super.key});

  @override
  State<ManageLabelPage> createState() => _ManageLabelPageState();
}

class _ManageLabelPageState extends State<ManageLabelPage> {
  List<List<dynamic>> _csvData = [];
  int _rowCount = 0;
  bool _isUploadEnabled = false;
  bool _isChangeUploading = false;
  bool _isAddUploading = false;
  bool _isSubtractUploading = false;
  int _currentUploadIndex = 0;

  Future<void> _pickAndReadCSV() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null) {
        final file = result.files.first;
        final String csvString = String.fromCharCodes(file.bytes!);

        setState(() {
          _csvData = const CsvToListConverter().convert(csvString);
          _rowCount = _csvData.isNotEmpty ? _csvData.length - 1 : 0;
          _isUploadEnabled = _rowCount > 0;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error reading CSV file: $e')),
      );
    }
  }

  Future<void> _uploadLabel(String type) async {
    if (_csvData.isEmpty) return;

    setState(() {
      // _isUploading = true;
      switch (type) {
        case 'change':
          _isChangeUploading = true;
          break;
        case 'add':
          _isAddUploading = true;
          break;
        case 'subtract':
          _isSubtractUploading = true;
          break;
        // default:
      }
      _currentUploadIndex = 0;
    });

    try {
      final token = await getToken();
      // final warehouseId = await getWarehouseId();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      for (int i = 1; i < _csvData.length; i++) {
        setState(() {
          _currentUploadIndex = i;
        });

        final sku = _csvData[i][0].toString();
        final quantity = num.parse(_csvData[i][1].toString());
        // log("${await ApiUrls.getBaseUrl()}/label?labelSku=$sku");
        log({
          "newTotal": quantity,
          "additionalInfo": {"reason": "Excel update"}
        }.toString());

        final response = await http.put(
          Uri.parse('${await Constants.getBaseUrl()}/label?labelSku=$sku'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: json.encode({
            "action": type,
            "quantityChanged": quantity,
            "reason": {"reason": "Excel update"}
          }),
        );
        log('response: ${response.body}');
        log('response code: ${response.statusCode}');

        // if (response.statusCode != 201) {
        //   throw Exception('Failed to upload SKU: $sku');
        // }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Upload completed successfully!')),
      );
    } catch (e) {
      log('error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error during upload: $e')),
      );
    } finally {
      setState(() {
        // _isUploading = false;
        switch (type) {
          case 'change':
            _isChangeUploading = false;
            break;
          case 'add':
            _isAddUploading = false;
            break;
          case 'subtract':
            _isSubtractUploading = false;
            break;
          // default:
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  'Manage Labels',
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _pickAndReadCSV,
                    child: const Text('Select CSV File'),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () => AuthProvider().downloadTemplate(
                      context, 'manage-label'), //////////////////////////////
                  child: const Text('Download Template'),
                ),
                const SizedBox(width: 16),
                if (_rowCount > 0)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        _isUploadEnabled && !_isChangeUploading
                            ? _uploadLabel('change')
                            : null;
                      },
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: Text(_isChangeUploading
                            ? 'Uploading...'
                            : 'Upload Label (for change)'),
                      ),
                    ),
                  ),
                const SizedBox(width: 16),
                if (_rowCount > 0)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        _isUploadEnabled && !_isAddUploading
                            ? _uploadLabel('add')
                            : null;
                      },
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(_isAddUploading
                            ? 'Uploading...'
                            : 'Upload Label (for add)'),
                      ),
                    ),
                  ),
                const SizedBox(width: 16),
                if (_rowCount > 0)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        _isUploadEnabled && !_isSubtractUploading
                            ? _uploadLabel('subtract')
                            : null;
                      },
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(_isSubtractUploading
                            ? 'Uploading...'
                            : 'Upload Label (for subtract)'),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (_rowCount > 0) Text('Number of items: $_rowCount'),
            if (_csvData.isNotEmpty) ...[
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      // headingRowColor: WidgetStateProperty.all(
                      //     AppColors.primaryBlue.withValues(alpha: 0.1)),
                      headingTextStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryBlue,
                      ),
                      border: TableBorder.all(
                        color: Colors.grey.shade300,
                        width: 1,
                      ),
                      columns: const [
                        DataColumn(
                          label: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text('Label SKU'),
                          ),
                        ),
                        DataColumn(
                          label: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text('Quantity'),
                          ),
                        ),
                      ],
                      rows: _csvData.skip(1).map((row) {
                        return DataRow(
                          cells: [
                            DataCell(Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text(row[0].toString()),
                            )),
                            DataCell(Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text(row[1].toString()),
                            )),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ],
            if (_isChangeUploading ||
                _isAddUploading ||
                _isSubtractUploading) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: _currentUploadIndex / _csvData.length,
              ),
              const SizedBox(height: 8),
              Text(
                  'Uploading item $_currentUploadIndex of ${_csvData.length - 1}'),
            ],
          ],
        ),
      ),
    );
  }
}
