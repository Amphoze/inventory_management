import 'dart:developer';

import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:inventory_management/Api/auth_provider.dart';
import 'package:inventory_management/Custom-Files/colors.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:inventory_management/Api/inventory_api.dart';
import 'dart:html' as html;

import 'package:inventory_management/constants/constants.dart';

class ComboUpload extends StatefulWidget {
  const ComboUpload({super.key});

  @override
  State<ComboUpload> createState() => _ComboUploadState();
}

class _ComboUploadState extends State<ComboUpload> {
  List<List<dynamic>> _csvData = [];
  int _rowCount = 0;
  bool _isUploadEnabled = false;
  bool _isUploading = false;
  int _currentUploadIndex = 0;
  bool _isPicking = false;
  List<String> errorComboSku = [];
  bool _isUploaded = false;

  Future<void> _pickAndReadCSV() async {
    setState(() {
      _isPicking = true;
    });
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
    } finally {
      setState(() {
        _isPicking = false;
      });
    }
  }

  Future<void> _uploadCombo() async {
    if (_csvData.isEmpty) return;

    setState(() {
      _isUploading = true;
      _currentUploadIndex = 0;
    });

    try {
      final token = await getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      for (int i = 1; i < _csvData.length; i++) {
        setState(() {
          _currentUploadIndex = i;
        });

        final comboSku = _csvData[i][0].toString();
        final products = _csvData[i][1]
            .toString()
            .split(',')
            .map((product) => {"product": product})
            .toList();
        log(products.toString());
        final name = _csvData[i][2].toString();
        log(name);
        final mrp = num.parse(_csvData[i][3].toString());
        log(mrp.toString());
        final cost = num.parse(_csvData[i][4].toString());
        log(cost.toString());
        log("${await Constants.getBaseUrl()}/combo?sku=$comboSku");
        log({
          "comboSku": comboSku,
          "name": name,
          "mrp": mrp,
          "cost": cost,
          "products": products,
        }.toString());

        final response = await http.post(
          Uri.parse('${await Constants.getBaseUrl()}/combo'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: json.encode({
            "comboSku": comboSku,
            "name": name,
            "mrp": mrp,
            "cost": cost,
            "products": products,
          }),
        );
        log(response.statusCode.toString());

        if (response.statusCode != 201) {
          errorComboSku.add(comboSku);
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Upload completed successfully!')),
      );

      setState(() {
        _isUploaded = true;
      });
      log(errorComboSku.toString());
    } catch (e) {
      log(e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error during upload: $e')),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  // Future<void> _uploadInventory() async {
  //   if (_csvData.isEmpty) return;
  //   setState(() {
  //     _isUploading = true;
  //     _currentUploadIndex = 0;
  //   });
  //   try {
  //     final token = await getToken();
  //     if (token == null) {
  //       throw Exception('No authentication token found');
  //     }
  //     for (int i = 1; i < _csvData.length; i++) {
  //       setState(() {
  //         _currentUploadIndex = i;
  //       });
  //       final sku = _csvData[i][0].toString();
  //       final quantity = num.parse(_csvData[i][1].toString());
  //       log("${await ApiUrls.getBaseUrl()}/combo?sku=$sku");
  //       log({
  //         "newTotal": quantity,
  //         "warehouseId": "66fceb5163c6d5c106cfa809",
  //         "additionalInfo": {"reason": "Excel update"}
  //       }.toString());
  //       final response = await http.put(
  //         Uri.parse(
  //             '${await ApiUrls.getBaseUrl()}/combo?sku=$sku'),
  //         headers: {
  //           'Content-Type': 'application/json',
  //           'Authorization': 'Bearer $token',
  //         },
  //         body: json.encode({
  //           "newTotal": quantity,
  //           "warehouseId": "66fceb5163c6d5c106cfa809",
  //           "additionalInfo": {"reason": "Excel update"}
  //         }),
  //       );
  //       log(response.statusCode.toString());
  //       if (response.statusCode != 200) {
  //         throw Exception('Failed to upload SKU: $sku');
  //       }
  //       await Future.delayed(const Duration(milliseconds: 100));
  //     }
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Upload completed successfully!')),
  //     );
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Error during upload: $e')),
  //     );
  //   } finally {
  //     setState(() {
  //       _isUploading = false;
  //     });
  //   }
  // }

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
                      AuthProvider().downloadTemplate(context, 'combo'),
                  child: const Text('Download Template'),
                ),
                const SizedBox(width: 16),
                if (_rowCount > 0)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isUploadEnabled && !_isUploading
                          ? _uploadCombo
                          : null,
                      child:
                          Text(_isUploading ? 'Uploading...' : 'Upload Combo'),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isPicking)
              const CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
              ),
            const SizedBox(height: 16),
            if (_isUploaded)
              // Text('Number of items '),
              Text.rich(
                TextSpan(children: [
                  const TextSpan(text: 'Number of items '),
                  const TextSpan(
                    text: '(not uploaded): ',
                    style: TextStyle(color: Colors.red),
                  ),
                  TextSpan(
                    text: '${errorComboSku.length}',
                  ),
                ]),
              ),
            const SizedBox(height: 16),
            if (_isUploaded && errorComboSku.isNotEmpty)
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DataTable(
                          headingRowColor: WidgetStateProperty.all(
                              AppColors.primaryBlue.withOpacity(0.1)),
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
                                child: Text('Combo SKU'),
                              ),
                            ),
                          ],
                          rows: errorComboSku.map((sku) {
                            return DataRow(
                              cells: [
                                DataCell(Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0),
                                  child: Text(sku),
                                )),
                              ],
                            );
                          }).toList(),
                        ),
                        const SizedBox(width: 16),
                        Tooltip(
                          message: 'Copy Error SKU',
                          child: ElevatedButton(
                            style: ButtonStyle(
                              shape: const WidgetStatePropertyAll(
                                CircleBorder(), // Make the button circular
                              ),
                              padding: const WidgetStatePropertyAll(
                                  EdgeInsets.all(10)),
                              backgroundColor:
                                  WidgetStateProperty.all(Colors.grey[100]),
                            ),
                            onPressed: () {
                              final String content = errorComboSku.join('\n');
                              html.window.navigator.clipboard!
                                  .writeText(content);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Contents copied to clipboard!')),
                              );
                            },
                            child: Icon(
                              Icons.copy,
                              color: Colors.grey[500],
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (!_isUploaded && _rowCount > 0)
              Text('Number of items : $_rowCount'),
            if (!_isUploaded && _csvData.isNotEmpty) ...[
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(
                          AppColors.primaryBlue.withOpacity(0.1)),
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
                            child: Text('Combo SKU'),
                          ),
                        ),
                        DataColumn(
                          label: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text('Products'),
                          ),
                        ),
                        DataColumn(
                          label: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text('Name'),
                          ),
                        ),
                        DataColumn(
                          label: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text('MRP'),
                          ),
                        ),
                        DataColumn(
                          label: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text('Cost'),
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
                            DataCell(Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text(row[2].toString()),
                            )),
                            DataCell(Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text(row[3].toString()),
                            )),
                            DataCell(Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text(row[4].toString()),
                            )),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ],
            if (_isUploading) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: _currentUploadIndex / _csvData.length,
              ),
              const SizedBox(height: 8),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text:
                          'Uploading item $_currentUploadIndex of ${_csvData.length - 1}...',
                    ),
                    const TextSpan(
                      text: '     (Do not close this window)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    // You can add more TextSpan children here if needed
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
