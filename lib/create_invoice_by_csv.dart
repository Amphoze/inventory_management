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
import 'package:logger/logger.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:url_launcher/url_launcher.dart';

class CreateInvoiceByCSV extends StatefulWidget {
  const CreateInvoiceByCSV({super.key});

  @override
  State<CreateInvoiceByCSV> createState() => _CreateInvoiceByCSVState();
}

class _CreateInvoiceByCSVState extends State<CreateInvoiceByCSV> {
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
    // Check if socket is already initialized
    if (_socket != null && _socket!.connected) {
      log('Socket already connected. Skipping initialization.');
      return;
    }

    try {
      final baseUrl = await Constants.getBaseUrl();
      log('Base URL in _initializeSocket: $baseUrl');
      final email = await AuthProvider().getEmail();


      // Initialize socket if not already initialized
      _socket ??= IO.io(
        baseUrl,
        IO.OptionBuilder().setTransports(['websocket']).disableAutoConnect().setQuery({'email': email}).build(),
      );

      // On successful connection
      _socket?.onConnect((_) {
        debugPrint('Connected to Socket.IO');
        _showSnackbar('Connected to server', Colors.green);
      });

      // On error during file upload
      _socket?.off('csv-file-uploading-err'); // Clear previous listeners
      _socket?.on('csv-file-uploading-err', (data) {
        debugPrint('Error Data: $data');
        setState(() {
          _progressMessage = data['message'] ?? 'An error occurred';
        });
        _showSnackbar(_progressMessage, Colors.red);
      });

      // On file upload progress
      _socket?.off('csv-file-uploading');
      _socket?.on('csv-file-uploading', (data) {
        Logger().e('Data progress: ${data['progress']}');
        if (data['progress'] != null) {
          double newProgress = double.tryParse(data['progress'].toString()) ?? 0;
          _progressNotifier.value = newProgress;
        }
      });

      // On successful file upload - Use `.once()` to trigger only once
      _socket?.off('csv-file-uploaded');
      _socket?.once('csv-file-uploaded', (data) {
        log('CSV file uploaded: $data');
        setState(() {
          _progressMessage = data['message'] ?? 'File uploaded successfully';
          _isCreating = false;
          _csvData = [];
          _rowCount = 0;
          _isCreateEnabled = false;
          _selectedFile = null;
        });
        _showSnackbar(_progressMessage, Colors.green);

        // Launch download URL if available
        if (data['downloadUrl'] != null) {
          log('Download link: ${data['downloadUrl']}');
          _launchDownloadUrl(data['downloadUrl']);
        }
      });

      _socket?.connect();
    } catch (e) {
      log('Error in _initializeSocket: $e');
      _showSnackbar('Failed to connect to server', Colors.red);
    }
  }

// Helper function to show snackbars
  void _showSnackbar(String message, Color color) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  void initState() {
    _initializeSocket();
    _verticalScrollController.addListener(_scrollListener);
    super.initState();
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

  Future<void> _createInvoice() async {
    if (_selectedFile == null) return;

    Logger().e('1');

    setState(() {
      _isCreating = true;
      // _failedOrders = [];
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
        Uri.parse('${await Constants.getBaseUrl()}/orders/invoiceCsv'),
      );

      Logger().e('2');

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
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(content: Text("${jsonData['message']}")),
        // );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${jsonData['message']}")),
        );
        log('Failed to upload CSV: ${response.statusCode}\n$responseBody');
      }
    } catch (e) {
      log('Error: $e', error: e, stackTrace: StackTrace.current);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
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
                  'Create Invoice',
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
                  onPressed: _isPickingFile || _isProcessingFile ? null : () => AuthProvider().downloadTemplate(context, 'confirmOrder'),
                  child: const Text('Download Template'),
                ),
                const SizedBox(width: 16),
                if (_rowCount > 0)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isCreateEnabled && !_isCreating && !_isPickingFile && !_isProcessingFile ? _createInvoice : null,
                      child: const Text('Create Invoice'),
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
              ValueListenableBuilder<double>(
                valueListenable: _progressNotifier,
                builder: (context, value, child) {
                  return Text.rich(
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
                  );
                },
              ),
              const SizedBox(height: 50),
              Expanded(
                // flex: 2,
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
