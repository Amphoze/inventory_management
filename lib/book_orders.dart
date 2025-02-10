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

class BookOrders extends StatefulWidget {
  const BookOrders({super.key});

  @override
  State<BookOrders> createState() => _BookOrdersState();
}

class _BookOrdersState extends State<BookOrders> {
  static const int _pageSize = 50;
  List<List<dynamic>> _csvData = [];
  List<Map<String, dynamic>> _failedOrders = [];
  int _rowCount = 0;
  bool _isBookEnabled = false;
  bool _isBooking = false;
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
        setState(() {
          _isProcessingFile = true;
          _isPickingFile = false;
        });

        final file = result.files.first;
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
        _isBookEnabled = _rowCount > 0;
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

  Future<void> _bookOrders() async {
    if (_selectedFile == null) return;

    setState(() {
      _isBooking = true;
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
        Uri.parse('${await Constants.getBaseUrl()}/orders/bookOrdersByCsv'),
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
        final message = jsonData['message'];
        final updatedOrders = jsonData['updatedOrders'] as List<dynamic>;
        final failedOrders = jsonData['failedOrders'] as List<dynamic>;

        setState(() {
          _failedOrders = failedOrders
              .map((order) => {
                    'order_id': order.toString(),
                    'error': 'Failed to book order',
                  })
              .toList();
        });

        if (updatedOrders.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$message')),
          );
        }

        if (failedOrders.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Some orders failed. Check the failed orders table below.')),
          );
        }
      } else {
        log('Failed to upload CSV: ${response.statusCode}\n$responseBody');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error during upload: $responseBody')),
        );
      }
    } catch (e) {
      log('Error during order booking: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error during upload: $e')),
      );
    } finally {
      setState(() {
        _isBooking = false;
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
                  onPressed: _isPickingFile || _isProcessingFile ? null : () => AuthProvider().downloadTemplate(context, 'bookOrder'),
                  child: const Text('Download Template'),
                ),
                const SizedBox(width: 16),
                if (_rowCount > 0)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isBookEnabled && !_isBooking && !_isPickingFile && !_isProcessingFile ? _bookOrders : null,
                      child: Text(_isBooking ? 'Booking...' : 'Book Orders'),
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
            if (_isBooking) ...[
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
                        ),
                      ),
                      DataColumn(
                        label: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text('Error Message'),
                        ),
                      ),
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
