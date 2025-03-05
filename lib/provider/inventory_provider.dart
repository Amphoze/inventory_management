import 'dart:convert';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:inventory_management/constants/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Api/auth_provider.dart';
import 'package:flutter/material.dart';

class InventoryProvider with ChangeNotifier {
  List<Map<String, dynamic>> _inventory = [];
  int _currentPage = 1;
  int _rowsPerPage = 20;
  int _totalPages = 1;
  bool _isLoading = false;
  String? errorMessage;
  String selectedSearchBy = 'productSku';

  List<Map<String, dynamic>> get inventory => _inventory;
  int get currentPage => _currentPage;
  int get rowsPerPage => _rowsPerPage;
  int get totalPages => _totalPages;
  bool get isLoading => _isLoading;

  void setSelectedSearchBy(String value) {
    selectedSearchBy = value;
    notifyListeners();
  }

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void updateCurrentPage(int page) {
    _currentPage = page;
    notifyListeners();
  }

  void goToPage(int page) {
    if (page >= 1 && page <= totalPages) {
      fetchInventory(page: page);
    }
  }

  void jumpToPage(int page) {
    if (page >= 1 && page <= totalPages) {
      fetchInventory(page: page);
    }
  }

  Map<String, dynamic>? inventoryDetail;
  List<dynamic> inventoryD = [];

  Future<void> fetchInventory({int page = 1}) async {
    String baseUrl = await Constants.getBaseUrl();
    setLoading(true);
    errorMessage = null;

    final pref = await SharedPreferences.getInstance();
    final warehouseId = pref.getString('warehouseId');

    log('ye hai id: $warehouseId');

    final url = Uri.parse('$baseUrl/inventory/warehouse?warehouse=$warehouseId&page=$page&limit=20'); // Adjust limit as needed

    try {
      final token = await AuthProvider().getToken();
      if (token == null) {
        errorMessage = 'No token found';
        setLoading(false);
        notifyListeners();
        return;
      }

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data.containsKey('data')) {
          // Process inventory data with default values
          List<Map<String, dynamic>> fetchedInventory = List<Map<String, dynamic>>.from(data['data']['inventories']).map((item) {
            final inventoryId = item['_id'].toString() ?? '';
            final product = item['product_id'] ?? {};
            final category = product['category'] ?? {};
            final brand = product['brand'] ?? {};
            final boxsize = product['boxSize'] ?? {};
            final subInventories = item['subInventory'] ?? [];
            // log('subInventories: $subInventories');
            List<dynamic> subData = subInventories.map((subInventory) {
              return {
                'warehouseId': subInventory['warehouseId']?['_id'] ?? '',
                'warehouseName': subInventory['warehouseId']?['name'] ?? '',
                'thresholdQuantity': subInventory['thresholdQuantity'] ?? 0,
                'quantity': subInventory['quantity'] ?? 0
              };
            }).toList();
            // log('subData: $subData');

            final thresholdQuantity = subData.firstWhere((element) => element['warehouseId'] == warehouseId)['thresholdQuantity'];

            final quantity = subData.firstWhere((element) => element['warehouseId'] == warehouseId)['quantity'];

            return {
              'COMPANY NAME': 'KATYAYANI ORGANICS',
              'CATEGORY': category['name']?.toString() ?? '-',
              'IMAGE': product['shopifyImage']?.toString() ?? '-',
              'BRAND': brand['name']?.toString() ?? '-',
              'SKU': product['sku']?.toString() ?? '-',
              'LABEL SKU':
                  product['label'] != null && product['label']['labelSku'] != null ? product['label']['labelSku']?.toString() : '-',
              'PRODUCT NAME': product['displayName']?.toString() ?? '-',
              'MRP': product['mrp']?.toString() ?? '-',
              'BOXSIZE': boxsize['box_name']?.toString() ?? '_',
              'QUANTITY': quantity?.toString() ?? '0',
              'SKU QUANTITY': subData.toList(),
              'THRESHOLD QUANTITY': thresholdQuantity?.toString() ?? '0',
              'THRESHOLD': subData.toList(),
              'inventoryLogs': item['inventoryLogs'] ?? [],
              'inventoryId': inventoryId,
            };
          }).toList();

          // log('bhaai: $inventory');
          // log('fetchedInventory: $fetchedInventory');

          _inventory = fetchedInventory.reversed.toList();
          _totalPages = data['data']['totalPages'] ?? 1;
          _currentPage = page;
          notifyListeners();
        } else {
          errorMessage = 'Unexpected response format';
          log('Unexpected response format: $data');
        }
      } else {
        errorMessage = 'Failed to fetch inventory. Status code: ${response.statusCode}';
        log('Failed to fetch inventory: ${response.statusCode}');
      }
    } catch (error, s) {
      errorMessage = 'An error occurred: $error';
      log('fetchInventory error: $error $s');
    } finally {
      setLoading(false);
    }
  }

  final List<Map<String, dynamic>> replicationInventory = [];

  Future<Map<String, dynamic>> searchByInventory(String query, String searchBy) async {
    String baseUrl = await Constants.getBaseUrl();
    log(query);

    final pref = await SharedPreferences.getInstance();
    final warehouseId = pref.getString('warehouseId');

    String url = '$baseUrl/inventory/warehouse?warehouse=$warehouseId&$searchBy=$query';

    log('searchByInventory url: $url');

    try {
      final token = await AuthProvider().getToken();
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data.containsKey('data')) {
          // Process fetched inventory data
          final fetchedInventory = List<Map<String, dynamic>>.from(data["data"]['inventories']).map((item) {
            final product = item['product_id'] ?? {};
            final category = product['category'] ?? {};
            final brand = product['brand'] ?? {};
            final boxsize = product['boxSize'] ?? {};
            final inventoryId = item['_id'].toString() ?? '';
            final subInventories = item['subInventory'] ?? [];
            List<dynamic> subData = subInventories.map((subInventory) {
              return {
                'warehouseId': subInventory['warehouseId']?['_id'] ?? '',
                'warehouseName': subInventory['warehouseId']?['name'] ?? '',
                'thresholdQuantity': subInventory['thresholdQuantity'] ?? 0,
                'quantity': subInventory['quantity'] ?? 0
              };
            }).toList();

            log('inventoryId: $inventoryId');

            final thresholdQuantity = subData.firstWhere((element) => element['warehouseId'] == warehouseId)['thresholdQuantity'];

            final quantity = subData.firstWhere((element) => element['warehouseId'] == warehouseId)['quantity'];

            return {
              'COMPANY NAME': 'KATYAYANI ORGANICS',
              'CATEGORY': category['name']?.toString() ?? '-',
              'IMAGE': product['shopifyImage']?.toString() ?? '-',
              'BRAND': brand['name']?.toString() ?? '-',
              'SKU': product['sku']?.toString() ?? '-',
              'LABEL SKU':
                  product['label'] != null && product['label']['labelSku'] != null ? product['label']['labelSku']?.toString() : '-',
              'PRODUCT NAME': product['displayName']?.toString() ?? '-',
              'MRP': product['mrp']?.toString() ?? '-',
              'BOXSIZE': boxsize['box_name']?.toString() ?? '-',
              'QUANTITY': quantity?.toString() ?? '0',
              'SKU QUANTITY': subData.toList(),
              'THRESHOLD QUANTITY': thresholdQuantity?.toString() ?? '0',
              'THRESHOLD': subData.toList(),
              'inventoryLogs': item['inventoryLogs'] ?? [],
              'inventoryId': inventoryId,
            };
          }).toList();

          log('fetchedInventory: $fetchedInventory');

          return {'success': true, 'data': fetchedInventory};
        } else {
          log('Unexpected response format: $data');
          return {'success': false, 'message': 'Unexpected response format'};
        }
      } else {
        return {'success': false, 'message': 'Failed to fetch inventory with status code: ${response.statusCode}'};
      }
    } catch (error, s) {
      log('searchByInventory error: $error $s');
      return {'success': false, 'message': 'An error occurred: $error'};
    }
  }

  Future<void> filterInventory(String query, String searchBy) async {
    setLoading(true);
    try {
      final result = await searchByInventory(query, searchBy);
      if (result['success']) {
        _inventory = result["data"];
        // log(result['data']['inventoryId']);
      } else {
        _inventory = [];
        log(result['message']);
      }
    } catch (e, s) {
      _inventory = [];
      log('filterInventory error: $e $s');
    } finally {
      setLoading(false);
    }
  }

  void cancelInventorySearch() {
    // Reset the inventory information to the original state
    _inventory = List<Map<String, dynamic>>.from(replicationInventory);
    notifyListeners(); // Notify listeners about the change
  }

  Future<void> updateInventoryQuantity(String inventoryId, int newQuantity, String warehousId, String reason) async {
    String baseUrl = await Constants.getBaseUrl();
    _isLoading = true;
    errorMessage = null;
    notifyListeners();
    log("Id $inventoryId");

    final url = Uri.parse('$baseUrl/inventory/$inventoryId');
    log("Id 1: $inventoryId");

    try {
      final token = await AuthProvider().getToken();
      if (token == null) {
        errorMessage = 'No token found';
        _isLoading = false;
        notifyListeners();
        return;
      }

      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'quantityChange': newQuantity,
          // 'newTotal': newQuantity,
          'warehouseId': warehousId,
          'additionalInfo': {'reason': reason},
          'action': 'change'
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        log('Inventory updated: $data');

        final index = inventory.indexWhere((item) => item['_id'] == inventoryId);
        if (index != -1) {
          inventory[index]['QUANTITY'] = newQuantity.toString();
          notifyListeners();
        }
      } else {
        // // print error details for better debugging
        errorMessage = 'Failed to update inventory. Status code: ${response.statusCode}. Response: ${response.body}';
        log(errorMessage.toString());
      }
    } catch (error) {
      errorMessage = 'An error occurred: $error';
      log('An error occurred: $error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateThresholdQuantity(
    String sku,
    int newQuantity,
  ) async {
    String baseUrl = await Constants.getBaseUrl();
    _isLoading = true;
    errorMessage = null;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final warehouseId = prefs.getString('warehouseId') ?? '';

    log("Id $warehouseId");

    final url = Uri.parse('$baseUrl/inventory?sku=$sku');
    log("Id 1: $warehouseId");

    try {
      final token = await AuthProvider().getToken();
      if (token == null) {
        errorMessage = 'No token found';
        _isLoading = false;
        notifyListeners();
        return;
      }

      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          "warehouseId": warehouseId,
          "thresholdQuantity": newQuantity,
          "action": "threshold",
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        log('Inventory updated: $data');

        final index = inventory.indexWhere((item) => item['_id'] == warehouseId);
        if (index != -1) {
          inventory[index]['QUANTITY'] = newQuantity.toString();
          notifyListeners();
        }
      } else {
        // // print error details for better debugging
        errorMessage = 'Failed to update inventory. Status code: ${response.statusCode}. Response: ${response.body}';
        log(errorMessage.toString());
      }
    } catch (error) {
      errorMessage = 'An error occurred: $error';
      log('An error occurred: $error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> getInventoryItems() async {
    String baseUrl = await Constants.getBaseUrl();
    final prefs = await SharedPreferences.getInstance();
    final warehouseId = prefs.getString('warehouseId') ?? '';

    // _isLoading = true;
    errorMessage = null;
    notifyListeners();

    final url = Uri.parse('$baseUrl/inventory/download?warehouseId=$warehouseId');

    try {
      final token = await AuthProvider().getToken();
      if (token == null) {
        errorMessage = 'No token found';
        // _isLoading = false;
        notifyListeners();
        return null;
      }

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data.containsKey('downloadUrl')) {
          return data['downloadUrl'];
        } else {
          errorMessage = 'Download URL not found in response';
          log('Unexpected response format: $data');
          return null;
        }
      } else {
        errorMessage = 'Failed to get download URL. Status code: ${response.statusCode}';
        log('Failed to get download URL: ${response.statusCode}');
        return null;
      }
    } catch (error) {
      errorMessage = 'An error occurred: $error';
      log('An error occurred: $error');
      return null;
    }
    // finally {
    //   _isLoading = false;
    //   notifyListeners();
    // }
  }
}
