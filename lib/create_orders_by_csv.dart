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
  static const int _pageSize = 50; // Number of rows to display per page
  List<List<dynamic>> _csvData = [];
  List<Map<String, dynamic>> _failedOrders = [];
  int _rowCount = 0;
  bool _isCreateEnabled = false;
  bool _isCreating = false;
  bool _isPickingFile = false;
  bool _isProcessingFile = false;
  PlatformFile? _selectedFile;
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _verticalScrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_verticalScrollController.position.pixels == _verticalScrollController.position.maxScrollExtent) {
      _loadMoreData();
    }
  }

  void _loadMoreData() {
    if ((_currentPage + 1) * _pageSize < _rowCount) {
      setState(() {
        _currentPage++;
      });
    }
  }

  List<List<dynamic>> _getPagedData() {
    if (_csvData.isEmpty) return [];

    const startIndex = 1; // Skip header row
    final endIndex = startIndex + (_currentPage + 1) * _pageSize;
    return _csvData.sublist(
      startIndex,
      endIndex.clamp(startIndex, _csvData.length),
    );
  }

  Future<void> _pickAndReadCSV() async {
    setState(() {
      _isPickingFile = true;
      _currentPage = 0;
    });

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'csv'
        ],
      );

      if (result != null) {
        final file = result.files.first;

        // Check file size (200 KB = 200 * 1024 bytes)
        if (file.size > 200 * 1024) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File size exceeds 200 KB. Please select a smaller file.')),
          );
          setState(() {
            _isPickingFile = false;
          });
          return;
        }

        setState(() {
          _isProcessingFile = true;
          _isPickingFile = false;
        });

        _selectedFile = file;
        await _processCSVInChunks(file.bytes!);
      } else {
        setState(() {
          _isPickingFile = false;
        });
      }
    } catch (e) {
      log('pick error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error reading CSV file: $e')),
      );
      setState(() {
        _isPickingFile = false;
        _isProcessingFile = false;
      });
    }
  }

  Future<void> _processCSVInChunks(List<int> bytes) async {
    try {
      final csvString = String.fromCharCodes(bytes);
      final rawData = const CsvToListConverter().convert(csvString);

      final filteredData = rawData.where((row) {
        return row.isNotEmpty && row.any((cell) => cell.toString().trim().isNotEmpty);
      }).toList();

      setState(() {
        _csvData = filteredData;
        _rowCount = _csvData.isNotEmpty ? _csvData.length - 1 : 0;
        _isCreateEnabled = _rowCount > 0;
        _failedOrders = [];
        _isProcessingFile = false;
      });
    } catch (e) {
      log('Error processing CSV: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error processing CSV file: $e')),
      );
      setState(() {
        _isProcessingFile = false;
      });
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
        Uri.parse('${await Constants.getBaseUrl()}/orders/createOrderByCsv'),
      );

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          _selectedFile!.bytes ?? [],
          filename: _selectedFile!.name,
        ),
      );

      request.headers.addAll({
        'Authorization': 'Bearer $token',
      });

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final jsonData = jsonDecode(responseBody);

      log('Create Csv Body: $responseBody, Status Code: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (jsonData['message'] == 'Orders processed' && jsonData.containsKey('results')) {
          final results = jsonData['results'] as List;
          bool hasFailedOrders = false;

          for (var result in results) {
            if (result['status'] != 201) {
              setState(() {
                hasFailedOrders = true;
              });
              final orderId = result['order_id']?.toString().trim();
              final errorMessage = result['data']?['error']?.toString().trim();

              if ((orderId?.isNotEmpty ?? false) || (errorMessage?.isNotEmpty ?? false)) {
                _failedOrders.add({
                  'order_id': orderId ?? 'Unknown Order ID',
                  'error': errorMessage ?? '',
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
        log('Failed to upload CSV: ${response.statusCode}\n$responseBody');
      }
    } catch (e) {
      log('Error during order creation: $e', error: e, stackTrace: StackTrace.current);
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
                    onPressed: _isPickingFile || _isProcessingFile ? null : _pickAndReadCSV,
                    child: Text(_isPickingFile
                        ? 'Selecting File...'
                        : _isProcessingFile
                            ? 'Processing File...'
                            : 'Select CSV File'),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _isPickingFile || _isProcessingFile ? null : () => AuthProvider().downloadTemplate(context, 'create'),
                  child: const Text('Download Template'),
                ),
                const SizedBox(width: 16),
                if (_rowCount > 0)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isCreateEnabled && !_isCreating && !_isPickingFile && !_isProcessingFile ? _createOrders : null,
                      child: Text(_isCreating ? 'Creating...' : 'Create Orders'),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isPickingFile || _isProcessingFile) ...[
              const LinearProgressIndicator(),
              const SizedBox(height: 8),
              Text(_isPickingFile ? 'Selecting file...' : 'Processing file...'),
              const SizedBox(height: 16),
            ],
            if (_rowCount > 0) ...[
              Text('Number of items: $_rowCount'),
              const SizedBox(height: 16),
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _buildDataTable(),
                    ),
                    if (_failedOrders.isNotEmpty) _buildFailedOrdersTable(),
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

  Widget _buildDataTable() {
    if (_csvData.isEmpty) return const SizedBox();

    final headers = _csvData.first;
    final pagedData = _getPagedData();

    return Scrollbar(
      controller: _verticalScrollController,
      thumbVisibility: true,
      child: Scrollbar(
        controller: _horizontalScrollController,
        thumbVisibility: true,
        notificationPredicate: (notification) => notification.depth == 1,
        child: SingleChildScrollView(
          controller: _verticalScrollController,
          child: SingleChildScrollView(
            controller: _horizontalScrollController,
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
              columns: headers
                  .map((header) => DataColumn(
                        label: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(header.toString()),
                        ),
                      ))
                  .toList(),
              rows: pagedData.map((row) {
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
    );
  }

  Widget _buildFailedOrdersTable() {
    return Expanded(
      flex: 1,
      child: Column(
        children: [
          const SizedBox(height: 16),
          Text(
            'Failed Orders: ${_failedOrders.length}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryBlue,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Scrollbar(
              thumbVisibility: true,
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
          ),
        ],
      ),
    );
  }
}

// import 'dart:developer';
// import 'package:csv/csv.dart';
// import 'package:flutter/material.dart';
// import 'package:inventory_management/Api/auth_provider.dart';
// import 'package:inventory_management/Custom-Files/colors.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'package:inventory_management/constants/constants.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// class CreateOrdersByCSV extends StatefulWidget {
//   const CreateOrdersByCSV({super.key});

//   @override
//   State<CreateOrdersByCSV> createState() => _CreateOrdersByCSVState();
// }

// class _CreateOrdersByCSVState extends State<CreateOrdersByCSV> {
//   List<List<dynamic>> _csvData = [];
//   List<Map<String, String>> _failedOrders = [];
//   int _rowCount = 0;
//   bool _isCreating = false;
//   bool _isPickingFile = false;
//   bool _isProcessingFile = false;
//   PlatformFile? _selectedFile;
//   int _processedOrders = 0;
//   int totalOrders = 0;
//   final ScrollController _horizontalScrollController = ScrollController();
//   final ScrollController _verticalScrollController = ScrollController();

//   @override
//   void dispose() {
//     _horizontalScrollController.dispose();
//     _verticalScrollController.dispose();
//     super.dispose();
//   }

//   Future<void> _pickAndReadCSV() async {
//     if (_isCreating) return;

//     setState(() {
//       _isPickingFile = true;
//       _processedOrders = 0;
//       totalOrders = 0;
//       _csvData = [];
//       _failedOrders = [];
//     });

//     try {
//       final result = await FilePicker.platform.pickFiles(
//         type: FileType.custom,
//         allowedExtensions: [
//           'csv'
//         ],
//       );

//       if (result != null) {
//         setState(() {
//           _isProcessingFile = true;
//           _isPickingFile = false;
//           _selectedFile = result.files.first;
//         });

//         if (_selectedFile?.bytes == null) {
//           throw Exception('Selected file is empty');
//         }

//         final String csvString = String.fromCharCodes(_selectedFile!.bytes!);
//         final csvData = const CsvToListConverter().convert(csvString);

//         if (csvData.isEmpty) {
//           throw Exception('CSV file is empty');
//         }

//         setState(() {
//           _csvData = csvData;
//           _rowCount = csvData.length - 1; // Subtract header row
//           totalOrders = _rowCount;
//         });
//       }
//     } catch (e) {
//       log('Error reading CSV file', error: e, stackTrace: StackTrace.current);
//       _showErrorSnackBar('Error reading CSV file: ${e.toString()}');
//     } finally {
//       setState(() {
//         _isPickingFile = false;
//         _isProcessingFile = false;
//       });
//     }
//   }

//   Future<Map<String, dynamic>> _createOrder(List<dynamic> row) async {
//     final orderId = row[1].toString();
//     try {
//       if (orderId.isEmpty) {
//         return _createErrorResponse(400, orderId, 'Order ID is required');
//       }

//       // final token = await getToken();
//       final pref = await SharedPreferences.getInstance();
//       final token = pref.getString('authToken');
//       if (token == null) {
//         return _createErrorResponse(401, orderId, 'Authentication token not found');
//       }

//       final orderData = {
//         "date": row[0].toString().split('-').reversed.join('-'),
//         "order_id": orderId,
//         "customer": _createCustomerData(row),
//         "billing_addr": _createAddressData(row, 7),
//         "shipping_addr": _createAddressData(row, 19),
//         "payment_mode": row[31].toString(),
//         "currency_code": row[32].toString(),
//         "items": [
//           _createItemData(row)
//         ],
//         "total_amt": _parseIntSafely(row[36]),
//         "cod_amount": _parseIntSafely(row[37]),
//         "source": row[44].toString(),
//         "agent": row[45].toString(),
//         "marketplace": row[40].toString(),
//         "discount_code": row[41].toString(),
//         "discount_scheme": row[42].toString(),
//         "discount_amount": _parseIntSafely(row[43]),
//         "coin": _parseIntSafely(row[38]),
//         "prepaid_amount": _parseIntSafely(row[39]),
//       };

//       final baseUrl = await Constants.getBaseUrl();
//       final response = await http.post(
//         Uri.parse('$baseUrl/orders'),
//         headers: {
//           "Content-Type": "application/json",
//           'Authorization': 'Bearer $token',
//         },
//         body: jsonEncode(orderData),
//       );

//       final responseBody = jsonDecode(response.body);
//       log('Order API Response for $orderId: ${response.statusCode} - $responseBody');

//       if (response.statusCode != 200 && response.statusCode != 201) {
//         return _createErrorResponse(response.statusCode, orderId, responseBody['error'] ?? 'Unknown error');
//       }

//       return {
//         'status': 200,
//         'order_id': orderId,
//         'data': responseBody
//       };
//     } catch (e) {
//       log('Error creating order', error: e, stackTrace: StackTrace.current);
//       return _createErrorResponse(400, orderId, e.toString());
//     }
//   }

//   Map<String, dynamic> _createCustomerData(List<dynamic> row) => {
//         "first_name": row[2].toString(),
//         "last_name": row[3].toString(),
//         "email": row[4].toString(),
//         "gstin": row[5].toString(),
//         "phone": row[6].toString(),
//       };

//   Map<String, dynamic> _createAddressData(List<dynamic> row, int startIndex) => {
//         "first_name": row[startIndex].toString(),
//         "last_name": row[startIndex + 1].toString(),
//         "email": row[startIndex + 2].toString(),
//         "address1": row[startIndex + 3].toString(),
//         "address2": row[startIndex + 4].toString(),
//         "phone": row[startIndex + 5].toString(),
//         "city": row[startIndex + 6].toString(),
//         "pincode": row[startIndex + 7].toString(),
//         "state": row[startIndex + 8].toString(),
//         "state_code": row[startIndex + 9].toString(),
//         "country": row[startIndex + 10].toString(),
//         "country_code": row[startIndex + 11].toString(),
//       };

//   Map<String, dynamic> _createItemData(List<dynamic> row) => {
//         "qty": _parseIntSafely(row[33]),
//         "sku": row[34].toString(),
//         "amount": _parseIntSafely(row[35]),
//       };

//   Map<String, dynamic> _createErrorResponse(int status, String orderId, String error) => {
//         'status': status,
//         'order_id': orderId,
//         'data': {
//           'error': error
//         }
//       };

//   int _parseIntSafely(dynamic value) => int.tryParse(value.toString()) ?? 0;

//   void _showErrorSnackBar(String message) {
//     if (!mounted) return;
//     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
//   }

//   Future<void> _createOrders() async {
//     if (_selectedFile == null || _isCreating) return;

//     setState(() {
//       _isCreating = true;
//       _failedOrders = [];
//       _processedOrders = 0;
//     });

//     try {
//       bool hasFailedOrders = false;

//       // Skip header row
//       for (int i = 1; i < _csvData.length; i++) {
//         final result = await _createOrder(_csvData[i]);

//         if (result['status'] != 200) {
//           hasFailedOrders = true;
//           _failedOrders.add({
//             'order_id': result['order_id'],
//             'error': result['data']['error'].toString(),
//           });
//         }

//         setState(() {
//           _processedOrders = i;
//         });
//       }

//       _showCompletionMessage(hasFailedOrders);
//     } catch (e) {
//       log('Error processing CSV', error: e, stackTrace: StackTrace.current);
//       _showErrorSnackBar('Error processing CSV: ${e.toString()}');
//     } finally {
//       setState(() {
//         _isCreating = false;
//       });
//     }
//   }

//   void _showCompletionMessage(bool hasFailedOrders) {
//     if (!mounted) return;
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(hasFailedOrders ? 'Some orders failed. Check the failed orders table below.' : 'All orders created successfully!'),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColors.white,
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           children: [
//             _buildActionButtons(),
//             const SizedBox(height: 16),
//             if (_isPickingFile || _isProcessingFile) _buildProgressIndicator(),
//             if (_rowCount > 0) ...[
//               Text('Number of items: $_rowCount'),
//               const SizedBox(height: 16),
//               Expanded(
//                 child: Column(
//                   children: [
//                     Expanded(
//                       flex: 2,
//                       child: _buildDataTable(),
//                     ),
//                     if (_failedOrders.isNotEmpty) _buildFailedOrdersTable(),
//                   ],
//                 ),
//               ),
//             ],
//             if (_isCreating) _buildCreationProgress(),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildActionButtons() {
//     return Row(
//       children: [
//         Expanded(
//           child: ElevatedButton(
//             onPressed: _isPickingFile || _isProcessingFile ? null : _pickAndReadCSV,
//             child: Text(_isPickingFile
//                 ? 'Selecting File...'
//                 : _isProcessingFile
//                     ? 'Processing File...'
//                     : 'Select CSV File'),
//           ),
//         ),
//         const SizedBox(width: 16),
//         ElevatedButton(
//           onPressed: _isPickingFile || _isProcessingFile ? null : () => AuthProvider().downloadTemplate(context, 'create'),
//           child: const Text('Download Template'),
//         ),
//         const SizedBox(width: 16),
//         if (_rowCount > 0)
//           Expanded(
//             child: ElevatedButton(
//               onPressed: _isCreating || _isPickingFile || _isProcessingFile ? null : _createOrders,
//               child: Text(_isCreating ? 'Creating...' : 'Create Orders'),
//             ),
//           ),
//       ],
//     );
//   }

//   Widget _buildProgressIndicator() {
//     return Column(
//       children: [
//         const LinearProgressIndicator(),
//         const SizedBox(height: 8),
//         Text(_isPickingFile ? 'Selecting file...' : 'Processing file...'),
//         const SizedBox(height: 16),
//       ],
//     );
//   }

//   Widget _buildCreationProgress() {
//     return Column(
//       children: [
//         const SizedBox(height: 16),
//         LinearProgressIndicator(
//           value: _processedOrders / _csvData.length,
//         ),
//         const SizedBox(height: 8),
//         Text('Creating Order: $_processedOrders of ${_csvData.length - 1}'),
//       ],
//     );
//   }

//   Widget _buildDataTable() {
//     if (_csvData.isEmpty) return const SizedBox();

//     final headers = _csvData.first;
//     final data = _csvData.skip(1).toList(); // Skip the header row when getting data

//     return Scrollbar(
//       controller: _verticalScrollController,
//       thumbVisibility: true,
//       child: Scrollbar(
//         controller: _horizontalScrollController,
//         thumbVisibility: true,
//         notificationPredicate: (notification) => notification.depth == 1,
//         child: SingleChildScrollView(
//           controller: _verticalScrollController,
//           child: SingleChildScrollView(
//             controller: _horizontalScrollController,
//             scrollDirection: Axis.horizontal,
//             child: DataTable(
//               headingTextStyle: const TextStyle(
//                 fontWeight: FontWeight.bold,
//                 color: AppColors.primaryBlue,
//               ),
//               border: TableBorder.all(
//                 color: Colors.grey.shade300,
//                 width: 1,
//               ),
//               columns: headers
//                   .map((header) => DataColumn(
//                         label: Padding(
//                           padding: const EdgeInsets.symmetric(horizontal: 8.0),
//                           child: Text(header.toString()),
//                         ),
//                       ))
//                   .toList(),
//               rows: data.map((row) {
//                 return DataRow(
//                   cells: List.generate(
//                     row.length,
//                     (index) => DataCell(
//                       Padding(
//                         padding: const EdgeInsets.symmetric(horizontal: 8.0),
//                         child: Text(row[index].toString()),
//                       ),
//                     ),
//                   ),
//                 );
//               }).toList(),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildFailedOrdersTable() {
//     return Expanded(
//       flex: 1,
//       child: Column(
//         children: [
//           const SizedBox(height: 16),
//           Text(
//             'Failed Orders: ${_failedOrders.length}',
//             style: const TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//               color: AppColors.primaryBlue,
//             ),
//           ),
//           const SizedBox(height: 8),
//           Expanded(
//             child: Scrollbar(
//               thumbVisibility: true,
//               child: SingleChildScrollView(
//                 scrollDirection: Axis.vertical,
//                 child: SingleChildScrollView(
//                   scrollDirection: Axis.horizontal,
//                   child: DataTable(
//                     headingTextStyle: const TextStyle(
//                       fontWeight: FontWeight.bold,
//                       color: AppColors.primaryBlue,
//                     ),
//                     border: TableBorder.all(
//                       color: Colors.grey.shade300,
//                       width: 1,
//                     ),
//                     columns: const [
//                       DataColumn(
//                           label: Padding(
//                         padding: EdgeInsets.symmetric(horizontal: 8.0),
//                         child: Text('Order ID'),
//                       )),
//                       DataColumn(
//                           label: Padding(
//                         padding: EdgeInsets.symmetric(horizontal: 8.0),
//                         child: Text('Error Message'),
//                       )),
//                     ],
//                     rows: _failedOrders.where((order) => (order['order_id']?.toString().trim().isNotEmpty ?? false) || (order['error']?.toString().trim().isNotEmpty ?? false)).map((order) {
//                       return DataRow(
//                         cells: [
//                           DataCell(Padding(
//                             padding: const EdgeInsets.symmetric(horizontal: 8.0),
//                             child: Text(order['order_id'].toString()),
//                           )),
//                           DataCell(Padding(
//                             padding: const EdgeInsets.symmetric(horizontal: 8.0),
//                             child: Text(order['error'].toString()),
//                           )),
//                         ],
//                       );
//                     }).toList(),
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
