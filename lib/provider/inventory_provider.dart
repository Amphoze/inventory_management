// import 'package:flutter/material.dart';
// import 'package:inventory_management/Api/inventory_api.dart'; // Import the API service
//
// class InventoryProvider extends ChangeNotifier {
//   List<Map<String, dynamic>> _inventory = [];
//
//   bool _isLoading = false;
//   String? _errorMessage;
//
//   // New properties for pagination
//   int _currentPage = 0;
//   final int _rowsPerPage = 20;
//
//   List<Map<String, dynamic>> get inventory => _inventory;
//
//   bool get isLoading => _isLoading;
//   String? get errorMessage => _errorMessage;
//
//   // New getters for pagination
//   int get currentPage => _currentPage;
//   int get totalPages => (_inventory.length / _rowsPerPage).ceil();
//
//   //final inventryApi= InventoryApi();
//
//
//
//   Future<void> fetchInventory() async {
//     _isLoading = true;
//     notifyListeners();
//
//     try {
//       final response =
//       await getAllInventory();
//       //await getInventoryByPage(page: page,limit:_rowsPerPage); // Call the API
//       if (response['success']) {
//         _inventory = response['data']['inventories'];
//        // _currentPage = page-1;
//       } else {
//         log('Error: ${response['message']}');
//         // Handle the API error message and show an error snackbar or fallback UI
//       }
//     } catch (e) {
//       log('Failed to fetch data: $e');
//       // Handle error, e.g., show a Snackbar with error details
//     } finally {
//       _isLoading = false;
//       notifyListeners(); // Notify listeners when loading finishes
//     }
//   }
//
//   List<Map<String, dynamic>> getPaginatedData() {
//     final int startIndex = _currentPage * _rowsPerPage;
//     final int endIndex = startIndex + _rowsPerPage;
//     return _inventory.sublist(
//       startIndex,
//       endIndex > _inventory.length ? _inventory.length : endIndex,
//     );
//   }
//
//   void goToPage(int page) {
//     _currentPage = page;
//     notifyListeners(); // Notify listeners when the current page changes
//   }
//
//   void _nextPage() {
//     final totalPages = (inventory.length / _rowsPerPage).ceil();
//
//     if (_currentPage < totalPages - 1) {
//       _currentPage++;
//       notifyListeners();
//     }
//   }
//
//
// }
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../Api/auth_provider.dart';
import 'package:flutter/material.dart';

class InventoryProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _inventory = [];
  int _currentPage = 1;
  final int _rowsPerPage = 20;
  int _totalPages = 1;
  bool _isLoading = false;
  String? _errorMessage;

  final String _baseUrl =
      'https://inventory-management-backend-s37u.onrender.com';

  // Getters
  List<Map<String, dynamic>> get inventory => _inventory;
  int get totalPages => _totalPages;
  int get currentPage => _currentPage;
  //int get totalPages => (_inventory.length / _rowsPerPage).ceil();
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Toggle loading state
  void toggleLoading() {
    _isLoading = !_isLoading;
    notifyListeners();
  }

  // Update current page
  void updateCurrentPage(int page) {
    _currentPage = page;
    notifyListeners();
  }

  Map<String, dynamic>? _inventoryDetail;
  Map<String, dynamic>? get inventoryDetail => _inventoryDetail;
  List<dynamic> inventoryD = [];
  //bool isLoading = false;

  Future<void> fetchInventoryById(String inventoryId) async {
    //_isLoading=true;
    _errorMessage = null; // Reset error message
    _inventoryDetail = null; // Reset the inventory detail
    notifyListeners();

    final url =
        Uri.parse('$_baseUrl/inventory/$inventoryId'); // URL for fetching by ID

    try {
      final token =
          await AuthProvider().getToken(); // Get the authentication token
      if (token == null) {
        _errorMessage = 'No token found';
        notifyListeners();
        return;
      }

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      // Print the raw response for debugging purposes
      // log('Response Status Code: ${response.statusCode}');
      // log('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Check if the data contains what you're expecting
        if (data != null && data is Map<String, dynamic>) {
          log('Parsed Data: $data'); // Log parsed data for debugging

          _inventoryDetail = data; // Store the fetched inventory detail
          notifyListeners();
        } else {
          _errorMessage =
              'No data found for this inventory ID or unexpected response structure';
          log('Data structure issue: $data');
        }
      } else {
        _errorMessage =
            'Failed to fetch inventory. Status code: ${response.statusCode}';
      }
    } catch (error) {
      _errorMessage = 'An error occurred: $error';
      log('Error: $error');
    } finally {
      notifyListeners();
    }
  }

  Future<void> fetchInventory({int page = 1}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final url = Uri.parse(
        '$_baseUrl/inventory?page=$page&limit=20'); // Adjust limit as needed

    try {
      final token = await AuthProvider().getToken();
      if (token == null) {
        _errorMessage = 'No token found';
        _isLoading = false;
        notifyListeners();
        return;
      }

      final response = await http.get(
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
          List<Map<String, dynamic>> fetchedInventory =
              List<Map<String, dynamic>>.from(data['data']['inventories'])
                  .map((item) {
            final inventoryId = item['_id'] ?? '';
            final product = item['product_id'] ?? {};
            final category = product['category'] ?? {};
            final brand = product['brand'] ?? {};
            final boxsize = product['boxSize'] ?? {};

            return {
              'COMPANY NAME': 'KATYAYANI ORGANICS',
              'CATEGORY': category['name']?.toString() ?? '-',
              'IMAGE': product['shopifyImage']?.toString() ?? '-',
              'BRAND': brand['name']?.toString() ?? '-',
              'SKU': product['sku']?.toString() ?? '-',
              'PRODUCT NAME': product['displayName']?.toString() ?? '-',
              'MRP': product['mrp']?.toString() ?? '-',
              'BOXSIZE': boxsize['box_name']?.toString() ?? '_',
              'QUANTITY': item['total']?.toString() ?? '0',
              'FLIPKART': product['flipkart']?.toString() ?? '-',
              'SNAPDEAL': product['snapdeal']?.toString() ?? '-',
              'AMAZON.IN': product['amazon']?.toString() ?? '-',
              'inventoryLogs': item['inventoryLogs'] ?? [],
              'inventoryId': inventoryId ?? '',
            };
          }).toList();

          _inventory = fetchedInventory;
          _totalPages = data['data']['totalPages'] ?? 1;
          _currentPage = page;
          notifyListeners();
        } else {
          _errorMessage = 'Unexpected response format';
          log('Unexpected response format: $data');
        }
      } else {
        _errorMessage =
            'Failed to fetch inventory. Status code: ${response.statusCode}';
        log('Failed to fetch inventory: ${response.statusCode}');
      }
    } catch (error) {
      _errorMessage = 'An error occurred: $error';
      log('An error occurred: $error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Go to a specific page
  void goToPage(int page) {
    if (page >= 1 && page <= _totalPages) {
      fetchInventory(page: page);
    }
  }

  void jumpToPage(int page) {
    if (page >= 1 && page <= _totalPages) {
      fetchInventory(page: page);
    }
  }

  final List<Map<String, dynamic>> _replicationInventory = [];

  Future<Map<String, dynamic>> searchByInventory(String query) async {
    log(query);

    // Determine if the query is a SKU or a display name
    final isSku = query.startsWith("K-"); // Assuming SKUs start with 'K-'
    final url = Uri.parse(
        '$_baseUrl/inventory?${isSku ? "sku" : "displayName"}=$query');

    try {
      final token = await AuthProvider().getToken();
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data.containsKey('data')) {
          // Process fetched inventory data
          final fetchedInventory =
              List<Map<String, dynamic>>.from(data["data"]['inventories'])
                  .map((item) {
            final product = item['product_id'] ?? {};
            final category = product['category'] ?? {};
            final brand = product['brand'] ?? {};
            final boxsize = product['boxSize'] ?? {};
            final inventoryId = item['_id'] ?? '';

            log(inventoryId);

            return {
              'COMPANY NAME': 'KATYAYANI ORGANICS',
              'CATEGORY': category['name']?.toString() ?? '-',
              'IMAGE': product['shopifyImage']?.toString() ?? '-',
              'BRAND': brand['name']?.toString() ?? '-',
              'SKU': product['sku']?.toString() ?? '-',
              'PRODUCT NAME': product['displayName']?.toString() ?? '-',
              'MRP': product['mrp']?.toString() ?? '-',
              'BOXSIZE': boxsize['box_name']?.toString() ?? '-',
              'QUANTITY': item['total']?.toString() ?? '0',
              'FLIPKART': product['flipkart']?.toString() ?? '-',
              'SNAPDEAL': product['snapdeal']?.toString() ?? '-',
              'AMAZON.IN': product['amazon']?.toString() ?? '-',
              'inventoryLogs': item['inventoryLogs'] ?? [],
              'inventoryId': inventoryId,
            };
          }).toList();

          return {'success': true, 'data': fetchedInventory};
        } else {
          log('Unexpected response format: $data');
          return {'success': false, 'message': 'Unexpected response format'};
        }
      } else {
        return {
          'success': false,
          'message':
              'Failed to fetch inventory with status code: ${response.statusCode}'
        };
      }
    } catch (error) {
      return {'success': false, 'message': 'An error occurred: $error'};
    }
  }

  bool _isLoadings = false;

  bool get isLoadings => _isLoadings;

  void setLoading(bool loading) {
    _isLoadings = loading;
    notifyListeners();
  }

  Future<void> filterInventory(String query) async {
    setLoading(true);
    try {
      if (query.isEmpty) {
        _inventory = List<Map<String, dynamic>>.from(
            _replicationInventory); // Load all inventory
      } else {
        final result = await searchByInventory(query);
        if (result['success']) {
          _inventory = result["data"];
          log(result['data']['inventoryId']);
        } else {
          log(result['message']);
        }
      }
    } finally {
      setLoading(false);
    }
    notifyListeners();
  }

  void cancelInventorySearch() {
    // Reset the inventory information to the original state
    _inventory = List<Map<String, dynamic>>.from(_replicationInventory);
    notifyListeners(); // Notify listeners about the change
  }

  Future<void> updateInventoryQuantity(String inventoryId, int newQuantity,
      String warehousId, String reason) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    log("Id $inventoryId");

    final url = Uri.parse('$_baseUrl/inventory/$inventoryId');
    log("Id 1: $inventoryId");

    try {
      final token = await AuthProvider().getToken();
      if (token == null) {
        _errorMessage = 'No token found';
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
          "action": "change",
          'newTotal': newQuantity,
          'warehouseId': warehousId,
          'additionalInfo': {'reason': reason},
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        log('Inventory updated: $data');

        final index =
            _inventory.indexWhere((item) => item['_id'] == inventoryId);
        if (index != -1) {
          _inventory[index]['QUANTITY'] = newQuantity.toString();
          notifyListeners();
        }
      } else {
        // Print error details for better debugging
        _errorMessage =
            'Failed to update inventory. Status code: ${response.statusCode}. Response: ${response.body}';
        log(_errorMessage.toString());
      }
    } catch (error) {
      _errorMessage = 'An error occurred: $error';
      log('An error occurred: $error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
