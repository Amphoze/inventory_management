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

class CreateOrdersByCSV extends StatefulWidget {
  const CreateOrdersByCSV({super.key});

  @override
  State<CreateOrdersByCSV> createState() => _CreateOrdersByCSVState();
}

class _CreateOrdersByCSVState extends State<CreateOrdersByCSV> {
  List<List<dynamic>> _csvData = [];
  List<Map<String, dynamic>> _failedOrders = [];

  int _rowCount = 0;
  bool _isCreateEnabled = false;
  bool _isCreating = false;
  PlatformFile? _selectedFile;

  Future<void> _pickAndReadCSV() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'csv'
        ],
      );

      if (result != null) {
        final file = result.files.first;
        _selectedFile = file;
        final String csvString = String.fromCharCodes(file.bytes!);

        setState(() {
          // Parse CSV and filter out rows that are empty or contain only white spaces
          final rawData = const CsvToListConverter().convert(csvString);
          _csvData = rawData.where((row) {
            return row.isNotEmpty && row.any((cell) => cell.toString().trim().isNotEmpty);
          }).toList();

          _rowCount = _csvData.isNotEmpty ? _csvData.length - 1 : 0; // Exclude header row
          _isCreateEnabled = _rowCount > 0;
          _failedOrders = []; // Clear failed orders when a new file is selected
        });
      }
    } catch (e) {
      log('pick error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error reading CSV file: $e')),
      );
    }
  }

  Future<void> _createOrders() async {
    if (_selectedFile == null) return;

    setState(() {
      _isCreating = true;
      _failedOrders = [];
    });

    try {
      final token = await getToken();
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Authentication token not found')),
        );
        return;
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${await ApiUrls.getBaseUrl()}/orders/createOrderByCsv'),
      );

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          _selectedFile!.bytes ?? [],
          filename: _selectedFile!.name ?? 'file.csv',
        ),
      );

      request.headers.addAll({
        'Authorization': 'Bearer $token',
      });

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final jsonData = jsonDecode(responseBody);

      log('Response Body: $responseBody, Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        if (jsonData['message'] == 'Orders processed' && jsonData.containsKey('results')) {
          final results = jsonData['results'] as List;
          bool hasFailedOrders = false;

          for (var result in results) {
            if (result['status'] == 400) {
              hasFailedOrders = true;
              final orderId = result['order_id']?.toString().trim();
              final errorMessage = result['data']?['error']?.toString().trim();

              if ((orderId?.isNotEmpty ?? false) || (errorMessage?.isNotEmpty ?? false)) {
                _failedOrders.add({
                  'order_id': orderId ?? 'Unknown Order ID',
                  'error': errorMessage ?? 'Unknown error',
                });
              }
            }
          }

          setState(() {}); // Trigger rebuild to show failed orders table

          if (!hasFailedOrders) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('All orders created successfully!')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Some orders failed. Check the failed orders table below.')),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unexpected response format')),
          );
        }
      } else {
        throw Exception('Failed to upload CSV: ${response.statusCode}\n$responseBody');
      }
    } catch (e) {
      log('Error during order confirmation: $e', error: e, stackTrace: StackTrace.current);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error during upload: $e')),
      );
    } finally {
      setState(() {
        _isCreating = false;
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
                  onPressed: () => AuthProvider().downloadTemplate(context, 'create'),
                  child: const Text('Download Template'),
                ),
                const SizedBox(width: 16),
                if (_rowCount > 0)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isCreateEnabled && !_isCreating ? _createOrders : null,
                      child: Text(_isCreating ? 'Creating...' : 'Create Orders'),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (_rowCount > 0) Text('Number of items: $_rowCount'),
            if (_csvData.isNotEmpty) ...[
              const SizedBox(height: 16),
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      flex: 3,
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
                            // columns: const [
                            //   DataColumn(label: Padding(padding: EdgeInsets.symmetric(horizontal: 8.0), child: Text('Order ID'))),
                            //   DataColumn(label: Padding(padding: EdgeInsets.symmetric(horizontal: 8.0), child: Text('Customer First Name'))),
                            //   DataColumn(label: Padding(padding: EdgeInsets.symmetric(horizontal: 8.0), child: Text('Customer Last Name'))),
                            //   DataColumn(label: Padding(padding: EdgeInsets.symmetric(horizontal: 8.0), child: Text('Customer Email'))),
                            //   DataColumn(label: Padding(padding: EdgeInsets.symmetric(horizontal: 8.0), child: Text('Customer GSTIN'))),
                            //   DataColumn(label: Padding(padding: EdgeInsets.symmetric(horizontal: 8.0), child: Text('Customer Phone'))),
                            //   DataColumn(label: Padding(padding: EdgeInsets.symmetric(horizontal: 8.0), child: Text('Billing First Name'))),
                            //   DataColumn(label: Padding(padding: EdgeInsets.symmetric(horizontal: 8.0), child: Text('Billing Last Name'))),
                            //   DataColumn(label: Padding(padding: EdgeInsets.symmetric(horizontal: 8.0), child: Text('Billing Email'))),
                            //   DataColumn(label: Padding(padding: EdgeInsets.symmetric(horizontal: 8.0), child: Text('Billing Address 1'))),
                            //   DataColumn(label: Padding(padding: EdgeInsets.symmetric(horizontal: 8.0), child: Text('Billing Address 2'))),
                            //   DataColumn(label: Padding(padding: EdgeInsets.symmetric(horizontal: 8.0), child: Text('Billing Phone'))),
                            //   DataColumn(label: Padding(padding: EdgeInsets.symmetric(horizontal: 8.0), child: Text('Billing City'))),
                            //   DataColumn(label: Padding(padding: EdgeInsets.symmetric(horizontal: 8.0), child: Text('Billing Pincode'))),
                            //   DataColumn(label: Padding(padding: EdgeInsets.symmetric(horizontal: 8.0), child: Text('Billing State'))),
                            //   DataColumn(label: Padding(padding: EdgeInsets.symmetric(horizontal: 8.0), child: Text('Billing State Code'))),
                            //   DataColumn(label: Padding(padding: EdgeInsets.symmetric(horizontal: 8.0), child: Text('Billing Country'))),
                            //   DataColumn(label: Padding(padding: EdgeInsets.symmetric(horizontal: 8.0), child: Text('Billing Country Code'))),
                            //   DataColumn(label: Padding(padding: EdgeInsets.symmetric(horizontal: 8.0), child: Text('Shipping First Name'))),
                            //   DataColumn(label: Padding(padding: EdgeInsets.symmetric(horizontal: 8.0), child: Text('Shipping Last Name'))),
                            //   DataColumn(label: Padding(padding: EdgeInsets.symmetric(horizontal: 8.0), child: Text('Shipping Email'))),
                            //   DataColumn(label: Padding(padding: EdgeInsets.symmetric(horizontal: 8.0), child: Text('Shipping Address 1'))),
                            //   DataColumn(label: Padding(padding: EdgeInsets.symmetric(horizontal: 8.0), child: Text('Shipping Address 2'))),
                            //   DataColumn(label: Padding(padding: EdgeInsets.symmetric(horizontal: 8.0), child: Text('Shipping Phone'))),
                            //   DataColumn(label: Padding(padding: EdgeInsets.symmetric(horizontal: 8.0), child: Text('Shipping City'))),
                            //   DataColumn(label: Padding(padding: EdgeInsets.symmetric(horizontal: 8.0), child: Text('Shipping Pincode'))),
                            //   DataColumn(label: Padding(padding: EdgeInsets.symmetric(horizontal: 8.0), child: Text('Shipping State'))),
                            //   DataColumn(label: Padding(padding: EdgeInsets.symmetric(horizontal: 8.0), child: Text('Shipping State Code'))),
                            //   DataColumn(label: Padding(padding: EdgeInsets.symmetric(horizontal: 8.0), child: Text('Shipping Country'))),
                            //   DataColumn(label: Padding(padding: EdgeInsets.symmetric(horizontal: 8.0), child: Text('Shipping Country Code'))),
                            //   DataColumn(label: Padding(padding: EdgeInsets.symmetric(horizontal: 8.0), child: Text('Payment Mode'))),
                            //   DataColumn(label: Padding(padding: EdgeInsets.symmetric(horizontal: 8.0), child: Text('Currency Code'))),
                            //   DataColumn(label: Padding(padding: EdgeInsets.symmetric(horizontal: 8.0), child: Text('Item Quantity'))),
                            //   DataColumn(label: Padding(padding: EdgeInsets.symmetric(horizontal: 8.0), child: Text('Item SKU'))),
                            //   DataColumn(label: Padding(padding: EdgeInsets.symmetric(horizontal: 8.0), child: Text('Item Amount'))),
                            //   DataColumn(label: Padding(padding: EdgeInsets.symmetric(horizontal: 8.0), child: Text('Total Amount'))),
                            //   DataColumn(label: Padding(padding: EdgeInsets.symmetric(horizontal: 8.0), child: Text('COD Amount'))),
                            //   DataColumn(label: Padding(padding: EdgeInsets.symmetric(horizontal: 8.0), child: Text('Coin'))),
                            //   DataColumn(label: Padding(padding: EdgeInsets.symmetric(horizontal: 8.0), child: Text('Prepaid Amount'))),
                            //   DataColumn(label: Padding(padding: EdgeInsets.symmetric(horizontal: 8.0), child: Text('Marketplace'))),
                            //   DataColumn(label: Padding(padding: EdgeInsets.symmetric(horizontal: 8.0), child: Text('Discount Code'))),
                            //   DataColumn(label: Padding(padding: EdgeInsets.symmetric(horizontal: 8.0), child: Text('Discount Scheme'))),
                            //   DataColumn(label: Padding(padding: EdgeInsets.symmetric(horizontal: 8.0), child: Text('Discount Amount'))),
                            //   DataColumn(label: Padding(padding: EdgeInsets.symmetric(horizontal: 8.0), child: Text('Source'))),
                            //   DataColumn(label: Padding(padding: EdgeInsets.symmetric(horizontal: 8.0), child: Text('Agent'))),
                            // ],
                            columns: _csvData.isNotEmpty
                                ? _csvData.first
                                    .map((column) => DataColumn(
                                          label: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                            child: Text(column.toString()),
                                          ),
                                        ))
                                    .toList()
                                : [],
                            rows: _csvData.skip(1).map((row) {
                              return DataRow(
                                cells: List.generate(
                                  row.length,
                                  (index) => DataCell(
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                      child: Text(row[index].toString()),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                    if (_failedOrders.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Failed Orders',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        flex: 1,
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
                                )),
                                DataColumn(
                                    label: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                                  child: Text('Error Message'),
                                )),
                              ],
                              rows: _failedOrders.where((order) => (order['order_id']?.toString().trim().isNotEmpty ?? false) || (order['error']?.toString().trim().isNotEmpty ?? false)).map((order) {
                                return DataRow(
                                  cells: [
                                    DataCell(Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                      child: Text(order['order_id'].toString()),
                                    )),
                                    DataCell(Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                      child: Text(order['error'].toString()),
                                    )),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            if (_isCreating) ...[
              const SizedBox(height: 16),
              const LinearProgressIndicator(),
            ],
          ],
        ),
      ),
    );
  }
}
