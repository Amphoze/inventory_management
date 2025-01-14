import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:inventory_management/Api/auth_provider.dart';
import 'package:inventory_management/Custom-Files/colors.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:inventory_management/Api/inventory_api.dart';
import 'package:inventory_management/constants/constants.dart';

class ConfirmOrders extends StatefulWidget {
  const ConfirmOrders({super.key});

  @override
  State<ConfirmOrders> createState() => _ConfirmOrdersState();
}

class _ConfirmOrdersState extends State<ConfirmOrders> {
  List<List<dynamic>> _csvData = [];
  int _rowCount = 0;
  bool _isConfirmEnabled = false;
  bool _isConfirming = false;
  PlatformFile? _selectedFile;
  String? warehouse;
  int _currentConfirmIndex = 0;
  bool _isChangeUploading = false;

  Future<void> _pickAndReadCSV() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null) {
        final file = result.files.first;
        _selectedFile = file; // Store the selected file
        final String csvString = String.fromCharCodes(file.bytes!);

        setState(() {
          _csvData = const CsvToListConverter().convert(csvString);
          _rowCount = _csvData.isNotEmpty ? _csvData.length - 1 : 0;
          _isConfirmEnabled = _rowCount > 0;
          _currentConfirmIndex = 0;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error reading CSV file: $e')),
      );
    }
  }

  Future<void> _confirmOrders() async {
    if (_selectedFile == null) return;

    setState(() {
      _isConfirming = true;
      _isChangeUploading = true;
      _currentConfirmIndex = 0;
    });

    try {
      final token = await getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${await ApiUrls.getBaseUrl()}/orders/confirmCsv'),
      );

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          _selectedFile!.bytes!,
          filename: _selectedFile!.name,
        ),
      );

      request.headers.addAll({
        'Authorization': 'Bearer $token',
      });

      final streamedResponse = await request.send();

      final responseBytes = <int>[];
      final totalBytes = _selectedFile!.size;
      var uploadedBytes = 0;

      await for (var chunk in streamedResponse.stream) {
        responseBytes.addAll(chunk);
        uploadedBytes += chunk.length;

        setState(() {
          _currentConfirmIndex =
              ((uploadedBytes / totalBytes) * _csvData.length).round();
        });
      }

      final responseBody = utf8.decode(responseBytes);

      if (streamedResponse.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Upload completed successfully!')),
        );
      } else {
        throw Exception(
            'Failed to upload CSV: ${streamedResponse.statusCode}\n$responseBody');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error during upload: $e')),
      );
    } finally {
      setState(() {
        _isConfirming = false;
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
                      AuthProvider().downloadTemplate(context, 'confirm'),
                  child: const Text('Download Template'),
                ),
                const SizedBox(width: 16),
                if (_rowCount > 0)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isConfirmEnabled && !_isConfirming
                          ? _confirmOrders
                          : null,
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: Text(
                            _isConfirming ? 'Confirming...' : 'Confirm Orders'),
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
                            child: Text('Order ID'),
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
                value: _currentConfirmIndex / _csvData.length,
              ),
              const SizedBox(height: 8),
              Text(
                  'Confirming Order $_currentConfirmIndex of ${_csvData.length - 1}'),
            ],
          ],
        ),
      ),
    );
  }
}
