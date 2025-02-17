import 'dart:convert';
import 'dart:developer';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:inventory_management/Api/auth_provider.dart';
import 'package:inventory_management/constants/constants.dart';
import 'package:logger/logger.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:url_launcher/url_launcher.dart';

import '../Api/inventory_api.dart';

class CreateOrdersProvider extends ChangeNotifier {
  static const int _pageSize = 50;
  List<List<dynamic>> _csvData = [];
  int _rowCount = 0;
  bool _isCreateEnabled = false;
  bool _isCreating = false;
  bool _isPickingFile = false;
  bool _isProcessingFile = false;
  PlatformFile? _selectedFile;
  int _currentPage = 0;

  String _progressMessage = '';
  double _progressPercentage = 0;
  String? _downloadLink;
  IO.Socket? _socket;

  List<List<dynamic>> get csvData => _csvData;
  int get rowCount => _rowCount;
  bool get isCreateEnabled => _isCreateEnabled;
  bool get isCreating => _isCreating;
  bool get isPickingFile => _isPickingFile;
  bool get isProcessingFile => _isProcessingFile;
  double get progressPercentage => _progressPercentage;
  String get progressMessage => _progressMessage;
  String? get downloadLink => _downloadLink;
  int get currentPage => _currentPage;

  CreateOrdersProvider() {
    _initializeSocket();
  }

  void _initializeSocket() {
    _socket = IO.io(
      'http://192.168.2.24:3000',
      IO.OptionBuilder().setTransports(['websocket']).disableAutoConnect().build(),
    );

    _socket?.onConnect((_) {
      debugPrint('Connected to Socket.IO');
    });

    _socket?.on('csv-file-uploading', (data) {
      Logger().e('Progress Data: ${data['progress']}');
      _progressPercentage = double.tryParse(data['progress'].toString()) ?? 0;
      notifyListeners();
    });

    _socket?.on('csv-file-uploading-err', (data) {
      _progressMessage = data['message'] ?? '';
      notifyListeners();
    });

    _socket?.on('csv-file-uploaded', (data) {
      _progressMessage = data['message'] ?? '';
      if (data['downloadLink'] != null) {
        _launchDownloadUrl(data['downloadLink']);
      }
      notifyListeners();
    });

    _socket?.connect();
  }

  Future<void> _launchDownloadUrl(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      debugPrint('Could not launch $url');
    }
  }

  void loadMoreData() {
    if ((_currentPage + 1) * _pageSize < _rowCount) {
      _currentPage++;
      notifyListeners();
    }
  }

  List<List<dynamic>> getPagedData() {
    if (_csvData.isEmpty) return [];

    const startIndex = 1;
    final endIndex = startIndex + (_currentPage + 1) * _pageSize;
    return _csvData.sublist(
      startIndex,
      endIndex.clamp(startIndex, _csvData.length),
    );
  }

  Future<void> pickAndReadCSV() async {
    _isPickingFile = true;
    _currentPage = 0;
    notifyListeners();

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null) {
        _selectedFile = result.files.first;
        _isProcessingFile = true;
        _isPickingFile = false;
        notifyListeners();

        await _processCSVInChunks(_selectedFile!.bytes!);
      } else {
        _isPickingFile = false;
        notifyListeners();
      }
    } catch (e) {
      log('Pick error: $e');
      _isPickingFile = false;
      _isProcessingFile = false;
      notifyListeners();
    }
  }

  Future<void> _processCSVInChunks(List<int> bytes) async {
    try {
      final csvString = String.fromCharCodes(bytes);
      final rawData = const CsvToListConverter().convert(csvString);

      _csvData = rawData.where((row) {
        return row.isNotEmpty && row.any((cell) => cell.toString().trim().isNotEmpty);
      }).toList();

      _rowCount = _csvData.isNotEmpty ? _csvData.length - 1 : 0;
      _isCreateEnabled = _rowCount > 0;
      _isProcessingFile = false;
      notifyListeners();
    } catch (e) {
      log('Error processing CSV: $e');
      _isProcessingFile = false;
      notifyListeners();
    }
  }

  Future<void> createOrders(BuildContext context) async {
    if (_selectedFile == null) return;

    _isCreating = true;
    notifyListeners();

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

      Logger().e('Create Csv Body: $responseBody, Status Code: ${response.statusCode}');

      if (response.statusCode != 200 && response.statusCode != 201) {
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
      _isCreating = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _socket?.disconnect();
    super.dispose();
  }
}
