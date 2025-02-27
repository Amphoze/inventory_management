import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:inventory_management/constants/constants.dart';
import 'package:inventory_management/model/orders_model.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';

class ReturnEntryProvider with ChangeNotifier {
  bool _isLoading = false;
  int selectedItemsCount = 0;
  List<Order> _orders = [];
  List<PlatformFile> _goodImages = [];
  List<PlatformFile> _badImages = [];
  Timer? _debounce;

  List<Order> get orders => _orders;
  bool get isLoading => _isLoading;
  List<PlatformFile> get goodImages => _goodImages;
  List<PlatformFile> get badImages => _badImages;

  bool isRefreshingOrders = false;

  void setRefreshingOrders(bool value) {
    isRefreshingOrders = value;
    notifyListeners();
  }

  Future<void> pickImages({required bool isGood}) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
      withData: true,
    );
    if (result != null) {
      if (isGood) {
        _goodImages.addAll(result.files);
      } else {
        _badImages.addAll(result.files);
      }
      notifyListeners();
    }
  }

  void removeImage(int index, {required bool isGood}) {
    if (isGood) {
      _goodImages.removeAt(index);
    } else {
      _badImages.removeAt(index);
    }
    notifyListeners();
  }

  void clearImages({required bool isGood}) {
    if (isGood) {
      _goodImages.clear();
    } else {
      _badImages.clear();
    }
    notifyListeners();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }

  String formatDate(DateTime date) {
    String year = date.year.toString();
    String month = date.month.toString().padLeft(2, '0');
    String day = date.day.toString().padLeft(2, '0');
    return '$day-$month-$year';
  }

  void onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.isEmpty) {
        _orders = [];
        notifyListeners();
      } else {
        searchOrders(query);
      }
    });
  }

  void showSnackBar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        backgroundColor: color,
      ),
    );
  }

  void showMessageDialog(BuildContext context, String message, Color color) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(message, style: TextStyle(color: color)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Ok')),
        ],
      ),
    );
  }

  Future<void> searchOrders(String orderId) async {
    String encodedOrderId = Uri.encodeComponent(orderId);
    final url = '${await Constants.getBaseUrl()}/orders?order_id=$encodedOrderId';
    log('search all orders url: $url');
    final mainUrl = Uri.parse(url);
    final token = await _getToken();

    try {
      _isLoading = true;
      notifyListeners();

      final response = await http.get(
        mainUrl,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _orders = [Order.fromJson(data)];
        Logger().e('return orders: $_orders');
      } else {
        _orders = [];
      }
    } catch (e, s) {
      log('catched error: $e $s');
      _orders = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> submitQualityCheck(
      BuildContext context,
      String orderId,
      List<Map<String, dynamic>> itemsList,
      ) async {
    for (var item in itemsList) {
      final goodQty = int.tryParse(item['goodQty'].text) ?? 0;
      final badQty = int.tryParse(item['badQty'].text) ?? 0;
      if (goodQty + badQty > item['total']) {
        showMessageDialog(context, 'Good + Bad quantity cannot exceed total for ${item['sku']}', Colors.red);
        return {'success': false, 'message': 'Validation failed'};
      }
    }

    List<Map<String, dynamic>> qualityCheckResults = itemsList
        .map((item) => {
      "productSku": item['sku'],
      "bad": int.tryParse(item['badQty'].text) ?? 0,
      "good": int.tryParse(item['goodQty'].text) ?? 0,
    })
        .toList();

    Map<String, dynamic> requestBody = {
      "qualityCheckResults": qualityCheckResults,
      "goodImages": _goodImages,
      "badImages": _badImages,
    };

    return await qualityCheck(orderId, requestBody);
  }

  Future<Map<String, dynamic>> qualityCheck(String orderId, Map<String, dynamic> body) async {
    final url = '${await Constants.getBaseUrl()}/orders/qualityCheck/$orderId';
    log('quality check post api: $url');
    final mainUrl = Uri.parse(url);
    final token = await _getToken();

    if (token == null || token.isEmpty) {
      return {'success': false, 'message': 'Authentication failed'};
    }

    try {
      _isLoading = true;
      notifyListeners();

      var request = http.MultipartRequest('POST', mainUrl)
        ..headers['Authorization'] = 'Bearer $token';

      request.fields['qualityCheckResults'] = jsonEncode(body['qualityCheckResults']);

      // Add good images
      if (body['goodImages'] is List && (body['goodImages'] as List).isNotEmpty) {
        for (PlatformFile file in body['goodImages']) {
          if (file.bytes != null) {
            var multipartFile = http.MultipartFile.fromBytes(
              'goodImages',
              file.bytes!,
              filename: file.name,
              contentType: MediaType('image', file.extension ?? 'jpg'),
            );
            request.files.add(multipartFile);
          }
        }
      }

      // Add bad images
      if (body['badImages'] is List && (body['badImages'] as List).isNotEmpty) {
        for (PlatformFile file in body['badImages']) {
          if (file.bytes != null) {
            var multipartFile = http.MultipartFile.fromBytes(
              'badImages',
              file.bytes!,
              filename: file.name,
              contentType: MediaType('image', file.extension ?? 'jpg'),
            );
            request.files.add(multipartFile);
          }
        }
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);

      Logger().e('return orders body: $data');
      if (response.statusCode == 200) {
        Logger().e('return orders: $data');
        clearImages(isGood: true);
        clearImages(isGood: false);
        return {'success': true, 'message': data['message']};
      } else {
        Logger().e('return orders error: ${response.statusCode}');
        return {'success': false, 'message': data['message'] ?? 'Failed to submit quality check'};
      }
    } catch (e, s) {
      log('catched error: $e $s');
      return {'success': false, 'message': 'An error occurred while uploading: $e'};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}