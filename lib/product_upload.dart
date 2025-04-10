import 'dart:developer';
import 'package:http_parser/http_parser.dart';
import 'package:flutter/material.dart';
import 'package:inventory_management/Custom-Files/utils.dart';
import 'package:inventory_management/constants/constants.dart';
import 'package:inventory_management/provider/product_data_provider.dart';
import 'package:provider/provider.dart';
import 'package:inventory_management/Custom-Files/colors.dart';
import 'package:inventory_management/Api/auth_provider.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

class ProductDataDisplay extends StatefulWidget {
  const ProductDataDisplay({super.key});

  @override
  ProductDataDisplayState createState() => ProductDataDisplayState();
}

class ProductDataDisplayState extends State<ProductDataDisplay> {
  List<Map<String, dynamic>> failedProducts = [];
  bool showFailedProducts = false;
  bool downloadingTemplate = false;
  bool isUploading = false;
  bool hasData = false;

  Future<void> _pickCsv(BuildContext context) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result == null || result.files.isEmpty) {
        _showMessage(context, 'No file selected', isError: true);
        return;
      }

      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null) {
        _showMessage(context, 'Error reading file', isError: true);
        return;
      }

      final csvString = utf8.decode(bytes);
      final csvLines = csvString.split('\n');
      final headers = csvLines[0].split(',').map((h) => h.trim()).toList();

      List<Map<String, String>> csvData = [];
      for (int i = 1; i < csvLines.length; i++) {
        if (csvLines[i].trim().isEmpty) continue;
        final values = csvLines[i].split(',');
        Map<String, String> row = {};
        for (int j = 0; j < headers.length && j < values.length; j++) {
          row[headers[j]] = values[j].trim();
        }
        csvData.add(row);
      }

      setState(() {
        hasData = true;
        failedProducts = [];
      });
      Provider.of<ProductDataProvider>(context, listen: false).setDataGroups(csvData);
      _showMessage(context, 'CSV file loaded successfully');
    } catch (e) {
      _showMessage(context, 'Error: ${e.toString()}', isError: true);
    }
  }

  Future<void> _uploadProducts(BuildContext context) async {
    final productDataProvider = Provider.of<ProductDataProvider>(context, listen: false);

    if (productDataProvider.dataGroups.isEmpty) {
      _showMessage(context, 'No data to upload', isError: true);
      return;
    }

    setState(() => isUploading = true);

    try {
      final authProvider = AuthProvider();
      final uri = Uri.parse('${await Constants.getBaseUrl()}/products/create-by-csv');

      var request = http.MultipartRequest('POST', uri)
        ..files.add(http.MultipartFile.fromBytes(
          'file',
          utf8.encode([(productDataProvider.dataGroups[0].keys.join(','))] // Headers
              .followedBy(productDataProvider.dataGroups.map((row) => row.values.map((v) => v ?? '').join(',')))
              .join('\n')),
          filename: 'upload.csv',
          contentType: MediaType('text', 'csv'), // Explicitly set MIME type
        ))
        ..headers.addAll({
          'Authorization': 'Bearer ${await authProvider.getToken()}',
        });

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      log("product create response: $responseBody");
      final jsonResponse = json.decode(responseBody);

      if (response.statusCode == 200 || response.statusCode == 207) {
        if (jsonResponse['insertedCount'] != null && jsonResponse['insertedCount'] > 0) {
          _showMessage(context, '${jsonResponse['insertedCount']} products uploaded successfully!');
          Provider.of<ProductDataProvider>(context, listen: false).reset();
          setState(() => hasData = false);
        }

        if (jsonResponse['failedCount'] != null && jsonResponse['failedCount'] > 0) {
          setState(() {
            showFailedProducts = true;
            failedProducts.add({
              'sku': 'N/A',
              'reason': '${jsonResponse['failedCount']} products failed to upload',
              'timestamp': DateFormat('yyyy-MM-dd - kk:mm').format(DateTime.now()),
            });
          });

          if (jsonResponse['failedFileUrl'] != null) {
            final url = jsonResponse['failedFileUrl'];
            if (await canLaunch(url)) {
              await launch(url);
            } else {
              _showMessage(context, 'Could not launch failed file URL', isError: true);
            }
          }
        }
      } else {
        _showMessage(context, jsonResponse['error'] ?? 'Failed to upload products', isError: true);
      }
    } catch (e, s) {
      log("Error while uploading products: $e\n\n$s");
      _showMessage(context, 'Error: ${e.toString()}', isError: true);
    } finally {
      setState(() => isUploading = false);
    }
  }

  void _showMessage(BuildContext context, String message, {bool isError = false}) {
    Utils.showSnackBar(context, message, color: isError ? AppColors.cardsred : AppColors.primaryGreen, seconds: 5);
  }

  void _clearFailedProducts() {
    setState(() {
      failedProducts.clear();
      showFailedProducts = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final productDataProvider = Provider.of<ProductDataProvider>(context);
    final double screenWidth = MediaQuery.of(context).size.width;
    final double baseTextSize = screenWidth > 1200 ? 16.0 : (screenWidth > 800 ? 14.0 : 12.0);

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Upload Products',
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton(
                  onPressed: isUploading ? null : () => _pickCsv(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Select CSV'),
                ),
                const SizedBox(width: 16),
                if (hasData) ...[
                  isUploading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: isUploading ? null : () => _uploadProducts(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryGreen,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text('Upload Products'),
                        ),
                  const SizedBox(width: 16),
                ],
                ElevatedButton(
                  onPressed: downloadingTemplate
                      ? null
                      : () async {
                          setState(() => downloadingTemplate = true);
                          await AuthProvider().downloadTemplate(context, 'product');
                          setState(() => downloadingTemplate = false);
                        },
                  child: downloadingTemplate
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Download Template'),
                ),
                // const SizedBox(width: 16),
                // ElevatedButton(
                //   onPressed: failedProducts.isEmpty
                //       ? null
                //       : () => setState(() => showFailedProducts = !showFailedProducts),
                //   style: ElevatedButton.styleFrom(
                //     backgroundColor: Colors.redAccent,
                //     shape: RoundedRectangleBorder(
                //       borderRadius: BorderRadius.circular(10),
                //     ),
                //   ),
                //   child: const Text('Failed Products'),
                // ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: productDataProvider.dataGroups.isEmpty
                  ? const Center(child: Text('No data available. Please select a CSV file.'))
                  : SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: _buildDataTable(productDataProvider.dataGroups, baseTextSize),
                      ),
                    ),
            ),
            if (showFailedProducts && failedProducts.isNotEmpty) ...[
              const Divider(),
              ExpansionTile(
                title: const Text(
                  'Failed Products',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                initiallyExpanded: true,
                children: [
                  SizedBox(
                    height: 200,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: failedProducts.length,
                      itemBuilder: (context, index) {
                        final failedProduct = failedProducts[index];
                        return ListTile(
                          title: Text('SKU: ${failedProduct['sku']}'),
                          subtitle: Text(
                            'Reason: ${failedProduct['reason']}\nFailed at: ${failedProduct['timestamp']}',
                            style: const TextStyle(color: Colors.red),
                          ),
                        );
                      },
                    ),
                  ),
                  TextButton(
                    onPressed: _clearFailedProducts,
                    child: const Text('Clear Failed Products'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDataTable(List<Map<String, String>> dataGroups, double baseTextSize) {
    if (dataGroups.isEmpty) return const SizedBox.shrink();

    Set<String> allHeaders = {};
    for (var data in dataGroups) {
      allHeaders.addAll(data.keys);
    }
    List<String> headers = allHeaders.toList();

    return DataTable(
      columnSpacing: 16.0,
      dataRowHeight: 48.0,
      headingRowHeight: 56.0,
      border: TableBorder.all(color: AppColors.grey),
      columns: headers
          .map((header) => DataColumn(
                label: Text(
                  header,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: baseTextSize,
                  ),
                ),
              ))
          .toList(),
      rows: dataGroups
          .map((data) => DataRow(
                cells: headers
                    .map((header) => DataCell(
                          Text(
                            data[header] ?? '',
                            style: TextStyle(fontSize: baseTextSize),
                          ),
                        ))
                    .toList(),
              ))
          .toList(),
    );
  }
}
