import 'dart:convert';
import 'dart:developer';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:inventory_management/Api/auth_provider.dart';
import 'package:inventory_management/Api/inventory_api.dart';
import 'package:inventory_management/Custom-Files/colors.dart';
import 'package:inventory_management/constants/constants.dart';
import 'package:url_launcher/url_launcher.dart';

class ConfirmOrders extends StatefulWidget {
  const ConfirmOrders({super.key});

  @override
  State<ConfirmOrders> createState() => _ConfirmOrdersState();
}

class _ConfirmOrdersState extends State<ConfirmOrders> {
  static const int _pageSize = 50;
  List<List<dynamic>> _csvData = [];

  // List<Map<String, dynamic>> _failedOrders = [];
  int _rowCount = 0;
  bool _isConfirmEnabled = false;
  bool _isConfirming = false;
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
        allowedExtensions: ['csv'],
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
        _isConfirmEnabled = _rowCount > 0;
        // _failedOrders = [];
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

  Future<void> _confirmOrders() async {
    if (_selectedFile == null) return;

    setState(() {
      _isConfirming = true;
    });

    try {
      final token = await getToken();
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Authentication token not found')),
        );
        setState(() {
          _isConfirming = false;
        });
        return;
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${await Constants.getBaseUrl()}/orders/confirmCsv'),
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

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final jsonData = jsonDecode(responseBody);

      log('Response Body: $responseBody, Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(jsonData['message'])),
        );

        try {
          await launchUrl(Uri.parse(jsonData['downloadUrl'].toString()));
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error downloading file: $e')),
          );
        }
      } else {
        log('Failed to upload CSV: ${response.statusCode}\n$responseBody');
        if (jsonData['downloadUrl'] != null && jsonData['downloadUrl'].toString().isNotEmpty) {
          try {
            await launchUrl(Uri.parse(jsonData['downloadUrl'].toString()));
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error downloading file: $e')),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(jsonData['message'] ?? 'Unknown error from API')),
          );
        }
      }
    } catch (e, stackTrace) {
      log('Error during order confirmation: $e', error: e, stackTrace: stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error during upload: $e')),
      );
    } finally {
      setState(() {
        _isConfirming = false;
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
                  onPressed: _isPickingFile || _isProcessingFile ? null : () => AuthProvider().downloadTemplate(context, 'confirm'),
                  child: const Text('Download Template'),
                ),
                const SizedBox(width: 16),
                if (_rowCount > 0)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isConfirmEnabled && !_isConfirming && !_isPickingFile && !_isProcessingFile ? _confirmOrders : null,
                      child: Text(_isConfirming ? 'Confirming...' : 'Confirm Orders'),
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
                    // if (_failedOrders.isEmpty) Expanded(child: _buildDataTable()) else _buildFailedOrdersTable(),
                    Expanded(
                      // flex: 2,
                      child: _buildDataTable(),
                    ),
                    // if (_failedOrders.isNotEmpty) _buildFailedOrdersTable(),
                  ],
                ),
              ),
            ],
            if (_isConfirming) ...[
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

// Widget _buildFailedOrdersTable() {
//   return Expanded(
//     flex: 1,
//     child: Column(
//       children: [
//         const SizedBox(height: 16),
//         const Text(
//           'Failed Orders',
//           style: TextStyle(
//             fontSize: 18,
//             fontWeight: FontWeight.bold,
//             color: AppColors.primaryBlue,
//           ),
//         ),
//         const SizedBox(height: 8),
//         Expanded(
//           child: Scrollbar(
//             thumbVisibility: true,
//             child: SingleChildScrollView(
//               scrollDirection: Axis.vertical,
//               child: SingleChildScrollView(
//                 scrollDirection: Axis.horizontal,
//                 child: DataTable(
//                   headingTextStyle: const TextStyle(
//                     fontWeight: FontWeight.bold,
//                     color: AppColors.primaryBlue,
//                   ),
//                   border: TableBorder.all(
//                     color: Colors.grey.shade300,
//                     width: 1,
//                   ),
//                   columns: const [
//                     DataColumn(
//                       label: Padding(
//                         padding: EdgeInsets.symmetric(horizontal: 8.0),
//                         child: Text('Order ID'),
//                       ),
//                     ),
//                     DataColumn(
//                       label: Padding(
//                         padding: EdgeInsets.symmetric(horizontal: 8.0),
//                         child: Text('Error Message'),
//                       ),
//                     ),
//                   ],
//                   rows: _failedOrders.where((order) => (order['order_id']?.toString().trim().isNotEmpty ?? false) || (order['error']?.toString().trim().isNotEmpty ?? false)).map((order) {
//                     return DataRow(
//                       cells: [
//                         DataCell(Padding(
//                           padding: const EdgeInsets.symmetric(horizontal: 8.0),
//                           child: Text(order['order_id'].toString()),
//                         )),
//                         DataCell(Padding(
//                           padding: const EdgeInsets.symmetric(horizontal: 8.0),
//                           child: Text(order['error'].toString()),
//                         )),
//                       ],
//                     );
//                   }).toList(),
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ],
//     ),
//   );
// }
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

// class ConfirmOrders extends StatefulWidget {
//   const ConfirmOrders({super.key});

//   @override
//   State<ConfirmOrders> createState() => _ConfirmOrdersState();
// }

// class _ConfirmOrdersState extends State<ConfirmOrders> {
//   List<List<dynamic>> _csvData = [];
//   List<Map<String, String>> _failedOrders = [];
//   int _rowCount = 0;
//   bool _isCreating = false;
//   bool _isPickingFile = false;
//   bool _isProcessingFile = false;
//   PlatformFile? _selectedFile;
//   int _processedOrders = 0;
//   final ScrollController _horizontalScrollController = ScrollController();
//   final ScrollController _verticalScrollController = ScrollController();

//   @override
//   void dispose() {
//     _horizontalScrollController.dispose();
//     _verticalScrollController.dispose();
//     super.dispose();
//   }

//   Map<String, dynamic> _createErrorResponse(int status, String orderId, String error) => {
//         'status': status,
//         'order_id': orderId,
//         'data': {
//           'message': error // Changed 'error' to 'message' to match usage
//         }
//       };

//   Future<void> _pickAndReadCSV() async {
//     if (_isCreating) return;

//     setState(() {
//       _isPickingFile = true;
//       _processedOrders = 0;
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

//       if (result == null) {
//         setState(() => _isPickingFile = false);
//         return;
//       }

//       setState(() {
//         _isProcessingFile = true;
//         _isPickingFile = false;
//         _selectedFile = result.files.first;
//       });

//       if (_selectedFile?.bytes == null) {
//         throw Exception('Selected file is empty');
//       }

//       final String csvString = String.fromCharCodes(_selectedFile!.bytes!);
//       final csvData = const CsvToListConverter().convert(csvString);

//       if (csvData.isEmpty) {
//         throw Exception('CSV file is empty');
//       }

//       setState(() {
//         _csvData = csvData;
//         _rowCount = csvData.length - 1;
//       });
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

//   Future<Map<String, dynamic>> _confirmOrder(List<dynamic> row) async {
//     final orderId = row[0].toString();
//     try {
//       if (orderId.isEmpty) {
//         return _createErrorResponse(400, orderId, 'Order ID is required');
//       }

//       final pref = await SharedPreferences.getInstance();
//       final token = pref.getString('authToken');
//       if (token == null) {
//         return _createErrorResponse(401, orderId, 'Authentication token not found');
//       }

//       final baseUrl = await Constants.getBaseUrl();
//       final uri = Uri.parse('$baseUrl/orders/confirm');

//       final response = await http.post(
//         uri,
//         headers: {
//           "Content-Type": "application/json",
//           'Authorization': 'Bearer $token',
//         },
//         body: jsonEncode({
//           'orderIds': [
//             orderId
//           ]
//         }),
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
//       log('Error confirming order: $e');
//       return _createErrorResponse(400, orderId, e.toString());
//     }
//   }

//   Future<void> _confirmOrders() async {
//     if (_selectedFile == null || _isCreating || _csvData.isEmpty) return;

//     setState(() {
//       _isCreating = true;
//       _failedOrders = [];
//       _processedOrders = 0;
//     });

//     try {
//       bool hasFailedOrders = false;

//       for (int i = 1; i < _csvData.length; i++) {
//         final result = await _confirmOrder(_csvData[i]);

//         if (result['status'] != 200) {
//           hasFailedOrders = true;
//           _failedOrders.add({
//             'order_id': result['order_id'],
//             'error': result['data']['message'].toString(),
//           });
//         }

//         setState(() {
//           _processedOrders = i;
//         });
//       }

//       if (mounted) {
//         _showCompletionMessage(hasFailedOrders);
//       }
//     } catch (e) {
//       log('Error processing CSV', error: e, stackTrace: StackTrace.current);
//       if (mounted) {
//         _showErrorSnackBar('Error processing CSV: ${e.toString()}');
//       }
//     } finally {
//       setState(() {
//         _isCreating = false;
//       });
//     }
//   }

//   void _showCompletionMessage(bool hasFailedOrders) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(hasFailedOrders ? 'Some orders failed. Check the failed orders table below.' : 'All orders confirmed successfully!'),
//       ),
//     );
//   }

//   void _showErrorSnackBar(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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
//           onPressed: _isPickingFile || _isProcessingFile ? null : () => AuthProvider().downloadTemplate(context, 'confirm'),
//           child: const Text('Download Template'),
//         ),
//         const SizedBox(width: 16),
//         if (_rowCount > 0)
//           Expanded(
//             child: ElevatedButton(
//               onPressed: _isCreating || _isPickingFile || _isProcessingFile ? null : _confirmOrders,
//               child: Text(_isCreating ? 'Confirming...' : 'Confirm Orders'),
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
//           value: _processedOrders / (_csvData.length - 1),
//         ),
//         const SizedBox(height: 8),
//         Text('Processing Order: $_processedOrders of ${_csvData.length - 1}'),
//       ],
//     );
//   }

//   Widget _buildDataTable() {
//     if (_csvData.isEmpty) return const SizedBox();

//     final headers = _csvData.first;
//     final data = _csvData.skip(1).toList();

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
//                         label: Padding(
//                           padding: EdgeInsets.symmetric(horizontal: 8.0),
//                           child: Text('Order ID'),
//                         ),
//                       ),
//                       DataColumn(
//                         label: Padding(
//                           padding: EdgeInsets.symmetric(horizontal: 8.0),
//                           child: Text('Error Message'),
//                         ),
//                       ),
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
