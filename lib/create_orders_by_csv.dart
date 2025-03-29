import 'dart:developer';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:inventory_management/Api/auth_provider.dart';
import 'package:inventory_management/Custom-Files/colors.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:inventory_management/Api/inventory_api.dart';
import 'package:inventory_management/Custom-Files/utils.dart';
import 'package:inventory_management/constants/constants.dart';
import 'package:logger/logger.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:url_launcher/url_launcher.dart';

class CreateOrdersByCSV extends StatefulWidget {
  const CreateOrdersByCSV({super.key});

  @override
  State<CreateOrdersByCSV> createState() => _CreateOrdersByCSVState();
}

class _CreateOrdersByCSVState extends State<CreateOrdersByCSV> {
  static const int _pageSize = 50;
  List<List<dynamic>> _csvData = [];
  int _rowCount = 0;
  bool _isCreateEnabled = false;
  bool _isCreating = false;
  bool _isPickingFile = false;
  bool _isProcessingFile = false;
  PlatformFile? _selectedFile;
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();
  int _currentPage = 0;

  String _progressMessage = '';

  final ValueNotifier<double> _progressNotifier = ValueNotifier<double>(0);

  IO.Socket? _socket;

  void _initializeSocket() async {
    if (_socket != null && _socket!.connected) {
      log('Socket already connected. Skipping initialization.');
      return;
    }

    try {
      final baseUrl = await Constants.getBaseUrl();
      log('Base URL in _initializeSocket: $baseUrl');
      final email = await AuthProvider().getEmail();

      _socket ??= IO.io(
        baseUrl,
        IO.OptionBuilder().setTransports(['websocket']).disableAutoConnect().setQuery({'email': email}).build(),
      );

      _socket?.onConnect((_) {
        Utils.showSnackBar(context, 'Connected to server', color: Colors.green);
        log('Connected to server: ${_socket?.id}');
      });

      // _socket?.off('csv-file-uploading-err');
      _socket?.on('csv-file-uploading-err', (data) {
        Logger().e('CSV file uploading error: $data');
        setState(() {
          _progressMessage = data['message'] ?? 'An error occurred';
        });
        Utils.showSnackBar(context, _progressMessage, color: Colors.red);
      });

      // _socket?.off('csv-file-uploading');
      _socket?.on('csv-file-uploading', (data) {

        Logger().e('CSV file uploading: $data');

        if (data['progress'] != null) {
          double newProgress = double.tryParse(data['progress'].toString()) ?? 0;
          _progressNotifier.value = newProgress;
        }
      });

      // _socket?.off('csv-file-uploaded');
      _socket?.once('csv-file-uploaded', (data) {

        Logger().e('CSV file uploaded: $data');

        setState(() {
          _progressMessage = data['message'] ?? 'File uploaded successfully';
          _isCreating = false;
          _csvData = [];
          _rowCount = 0;
          _isCreateEnabled = false;
          _selectedFile = null;
        });

        Utils.showSnackBar(context, _progressMessage, color: Colors.green);

        if (data['downloadLink'] != null) {
          log('Download link: ${data['downloadLink']}');
          _launchDownloadUrl(data['downloadLink']);
        }
      });

      _socket?.connect();
    } catch (e) {

      log('Error in initialising socket: $e');

      Utils.showSnackBar(context, 'Failed to connect to server', color: Colors.red);
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeSocket();
    _verticalScrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _socket?.disconnect();
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    super.dispose();
  }

  Future<void> _launchDownloadUrl(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
      log('Download URL launched: $url');
    } else {
      debugPrint('Could not launch $url');
    }
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

    const startIndex = 1;
    final endIndex = startIndex + (_currentPage + 1) * _pageSize;
    return _csvData.sublist(
      startIndex,
      endIndex.clamp(startIndex, _csvData.length),
    );
  }

  Future<void> _pickAndReadCSV() async {
    log('_pickAndReadCSV _progressMessage: $_progressMessage');
    setState(() {
      _isPickingFile = true;
      _currentPage = 0;
      _progressNotifier.value = 0;
      _progressMessage = '';
      log('_pickAndReadCSV _progressMessage: $_progressMessage');
    });

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
        // withReadStream: true,
        // readSequential: true,
        allowMultiple: false,
      );

      log('_pickAndReadCSV result: ${result?.count}');

      if (result != null) {
        final file = result.files.first;

        setState(() {
          _isProcessingFile = true;
          _isPickingFile = false;
          _selectedFile = file;
        });

        await _processCSVInChunks(file.bytes!);

      } else {
        setState(() {
          _isPickingFile = false;
        });
      }
    } catch (e, s) {
      log('Error picking file:- $e\n$s');
      Utils.showSnackBar(context, 'Error reading CSV file: $e', color: Colors.red);
      setState(() {
        _isPickingFile = false;
        _isProcessingFile = false;
      });
    }
  }

  Future<void> _processCSVInChunks(List<int> bytes) async {
    try {
      String csvString = String.fromCharCodes(bytes);
      final rawData = const CsvToListConverter().convert(csvString);

      final filteredData = rawData.where((row) {
        return row.isNotEmpty && row.any((cell) => cell.toString().trim().isNotEmpty);
      }).toList();

      log('filteredData: $filteredData');

      if (filteredData.length <= 1) {
        Utils.showSnackBar(context, 'Invalid CSV Format or Empty File. Please make sure the values for any order should not contain any extra spaces, tabs or multiple lines', color: Colors.red);
        setState(() {
          _isProcessingFile = false;
        });
        return;
      }

      setState(() {
        _csvData = filteredData;
        log('_csvData: $_csvData');

        log('Total Length of CSV Data is ${_csvData.length}');

        for (int i=0; i<_csvData.length; i++) {
          log('${i+1}) ${_csvData[i]}');
        }

        _rowCount = _csvData.isNotEmpty ? _csvData.length - 1 : 0;
        _isCreateEnabled = _rowCount > 0;
        _isProcessingFile = false;
      });

    } catch (e, s) {
      log('Error processing CSV: $e\n$s');
      Utils.showSnackBar(context, 'Error processing CSV file: $e', color: Colors.red);
      setState(() {
        _isProcessingFile = false;
      });
    }
  }

  Future<void> _createOrders() async {
    if (_selectedFile == null) return;

    setState(() {
      _isCreating = true;
      _progressNotifier.value = 0;
      _progressMessage = 'Uploading file...';
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

      Logger().e('3');

      request.headers.addAll({
        'Authorization': 'Bearer $token',
      });

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final jsonData = jsonDecode(responseBody);

      Logger().e('Create Csv Body: $responseBody, Status Code: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${jsonData['message']}")),
        );
        log('Failed to upload CSV: ${response.statusCode}\n$responseBody');
      }
    } catch (e) {
      log('Error during order creation: $e', error: e, stackTrace: StackTrace.current);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error during order creation: $e')),
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
            const Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  'Create Orders',
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
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
                      child: const Text('Create Orders'),
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
            Text('Number of Orders: $_rowCount'),
            if (_rowCount > 0) ...[
              const SizedBox(height: 16),
              ValueListenableBuilder<double>(
                valueListenable: _progressNotifier,
                builder: (context, value, child) {
                  return Column(
                    children: [
                      Text.rich(
                        TextSpan(
                          text: 'Progress: ',
                          children: [
                            TextSpan(
                              text: '${value.toStringAsFixed(2)}%',
                              style: const TextStyle(fontWeight: FontWeight.normal),
                            ),
                          ],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: value / 100,
                      )
                    ],
                  );
                },
              ),
              const SizedBox(height: 50),
              Expanded(
                child: _buildDataTable(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDataTable() {

    if (_csvData.isEmpty) return const SizedBox();

    log('_csvData after: $_csvData');

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
}
