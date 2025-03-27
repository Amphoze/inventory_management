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
import 'package:shared_preferences/shared_preferences.dart';

class ThresholdUpload extends StatefulWidget {
  const ThresholdUpload({super.key});

  @override
  State<ThresholdUpload> createState() => _ThresholdUploadState();
}

class _ThresholdUploadState extends State<ThresholdUpload> {
  List<List<dynamic>> _csvData = [];
  int _rowCount = 0;
  bool _isUploadEnabled = false;
  bool _isChangeUploading = false;
  int _currentUploadIndex = 0;
  String? warehouse;

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

  Future<void> _uploadThreshold() async {
    if (_csvData.isEmpty) return;

    setState(() {
      _isChangeUploading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    // _isAuthenticated = prefs.getString('authToken') != null;
    warehouse = prefs.getString('warehouseId');

    try {
      final token = await getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      for (int i = 1; i < _csvData.length; i++) {
        setState(() {
          _currentUploadIndex = i;
        });

        final sku = _csvData[i][0].toString();
        final quantity = num.parse(_csvData[i][1].toString());

        final response = await http.put(
          Uri.parse('${await Constants.getBaseUrl()}/inventory?sku=$sku'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: json.encode({
            "warehouseId": warehouse,
            "thresholdQuantity": quantity,
            "action": "threshold",
          }),
        );
        log(response.statusCode.toString());
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Upload completed successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error during upload: $e')),
      );
    } finally {
      setState(() {
        _isChangeUploading = false;
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
                  'Upload Threshold',
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
                  onPressed: () =>
                      AuthProvider().downloadTemplate(context, 'inventory'),
                  child: const Text('Download Template'),
                ),
                const SizedBox(width: 16),
                if (_rowCount > 0)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        _isUploadEnabled && !_isChangeUploading
                            ? _uploadThreshold()
                            : null;
                      },
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: Text(_isChangeUploading
                            ? 'Uploading...'
                            : 'Upload Threshold (for change)'),
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
                            child: Text('SKU'),
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
            if (_isChangeUploading) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: _currentUploadIndex / _csvData.length,
              ),
              const SizedBox(height: 8),
              Text(
                  'Uploading theshold $_currentUploadIndex of ${_csvData.length - 1}'),
            ],
          ],
        ),
      ),
    );
  }
}
