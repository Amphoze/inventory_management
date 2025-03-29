import 'dart:convert';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:inventory_management/constants/constants.dart';
import 'package:logger/logger.dart';
import '../Api/auth_provider.dart';
import 'package:flutter/material.dart';

class OuterboxProvider with ChangeNotifier {
  List<Map<String, dynamic>> _boxsizes = [];
  int _currentPage = 1;
  int _totalPages = 1;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isFormVisible = false;
  String selectedSearchBy = 'outerPackage_name';
  // outerPackage_name, occupied_weight, outerPackage_sku, outerPackage_type

  // Getters
  bool get isFormVisible => _isFormVisible;
  List<Map<String, dynamic>> get boxsizes => _boxsizes;
  int get totalPages => _totalPages;
  int get currentPage => _currentPage;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void setSelectedSearchBy(String value) {
    selectedSearchBy = value;
    notifyListeners();
  }

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

  // Go to a specific page
  void goToPage(int page) {
    if (page >= 1 && page <= _totalPages) {
      fetchBoxsizes(page: page);
    }
  }

  void jumpToPage(int page) {
    if (page >= 1 && page <= _totalPages) {
      fetchBoxsizes(page: page);
    }
  }

  void toggleFormVisibility() {
    _isFormVisible = !_isFormVisible;
    notifyListeners();
  }

  Map<String, dynamic>? _inventoryDetail;
  Map<String, dynamic>? get inventoryDetail => _inventoryDetail;
  List<dynamic> inventoryD = [];

  Future<void> fetchBoxsizes({int page = 1}) async {
    String baseUrl = await Constants.getBaseUrl();
    Logger().e('fetchBoxsizes called');
    _isLoading = true;
    _errorMessage = null;
    Logger().e('fetchBoxsizes called');
    notifyListeners();

    final url = '$baseUrl/boxsize?page=$page'; // Adjust limit as needed
    

    try {
      final token = await AuthProvider().getToken();
      if (token == null) {
        _errorMessage = 'No token found';
        _isLoading = false;
        notifyListeners();
        return;
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final res = json.decode(response.body);
        if (res.containsKey('data')) {
          // Process inventory data with default values
          List<Map<String, dynamic>> fetchedBoxsizes =
              List<Map<String, dynamic>>.from(res['data']['boxsizes'])
                  .map((boxsize) {
            return {
              'ID': boxsize['_id']?.toString() ?? '-',
              'SKU': boxsize['outerPackage_sku']?.toString() ?? '-',
              'NAME': boxsize['outerPackage_name']?.toString() ?? '-',
              'DIMENSION': boxsize['dimension'] ?? {},
              'TYPE': boxsize['outerPackage_type']?.toString() ?? '-',
              'QUANTITY': boxsize['outerPackage_quantity']?.toString() ?? '0',
              'LOGS': boxsize['outerPackageLog'] ?? [],
              'WEIGHT': boxsize['occupied_weight']?.toString() ?? '0',
            };
          }).toList();

          log('bhaai: $_boxsizes');
          // log('fetchedInventory: $fetchedInventory');

          _boxsizes = fetchedBoxsizes.toList();
          _totalPages = res['data']['totalPages'] ?? 1;
          _currentPage = page;
          notifyListeners();
        } else {
          _errorMessage = 'Unexpected response format';
          log('Unexpected response format: $res');
        }
      } else {
        _errorMessage =
            'Failed to fetch inventory. Status code: ${response.statusCode}';
        log('Failed to fetch inventory: ${response.body}');
      }
    } catch (error) {
      _errorMessage = 'An error occurred: $error';
      log('An error occurred: $error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  final List<Map<String, dynamic>> _replicationBoxsize = [];

  Future<Map<String, dynamic>> searchBoxsize(String query) async {
    String baseUrl = await Constants.getBaseUrl();
    log(query);

    final url = Uri.parse('$baseUrl/boxsize?$selectedSearchBy=$query');

    log('url: $url');

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
          // Process inventory data with default values
          List<Map<String, dynamic>> fetchedBoxsizes =
              List<Map<String, dynamic>>.from(data['data']['boxsizes'])
                  .map((boxsize) {
            return {
              'DIMENSION': boxsize['dimension'] ?? {},
              'ID': boxsize['_id']?.toString() ?? '-',
              'SKU': boxsize['outerPackage_sku']?.toString() ?? '-',
              'NAME': boxsize['outerPackage_name']?.toString() ?? '-',
              'TYPE': boxsize['outerPackage_type']?.toString() ?? '-',
              'QTY': boxsize['outerPackage_quantity']?.toString() ?? '0',
              'WEIGHT': boxsize['occupied_weight']?.toString() ?? '0',
              'LOG': boxsize['outerPackageLog'] ?? [],
            };
          }).toList();

          // log('fetchedBoxsizes: $fetchedBoxsizes');

          return {'success': true, 'data': fetchedBoxsizes};
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
      log('An error occurred: $error');
      return {'success': false, 'message': 'An error occurred: $error'};
    }
  }

  Future<void> createBoxsize(Map<String, dynamic> boxsizeData) async {
    String baseUrl = await Constants.getBaseUrl();
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final url = Uri.parse('$baseUrl/boxsize');

    log('url: $url');

    try {
      final token = await AuthProvider().getToken();
      if (token == null) {
        _errorMessage = 'No token found';
        _isLoading = false;
        notifyListeners();
        return;
      }

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(boxsizeData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        log('Boxsize created: $data');
        await fetchBoxsizes(); // Refresh the list
      } else {
        _errorMessage = 'Failed to create boxsize: ${response.body}';
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

  bool _isLoadings = false;

  bool get isLoadings => _isLoadings;

  void setLoading(bool loading) {
    _isLoadings = loading;
    notifyListeners();
  }

  Future<void> filterBoxsize(String query) async {
    setLoading(true);
    try {
      if (query.isEmpty) {
        _boxsizes = List<Map<String, dynamic>>.from(
            _replicationBoxsize); // Load all inventory
      } else {
        final result = await searchBoxsize(query);
        if (result['success']) {
          _boxsizes = result["data"];
          // log(result['data']['inventoryId']);
        } else {
          log(result['message']);
        }
      }
    } finally {
      setLoading(false);
    }
    notifyListeners();
  }

  // void cancelBoxsizeSearch() {
  //   // Reset the inventory information to the original state
  //   _boxsizes = List<Map<String, dynamic>>.from(_replicationBoxsize);
  //   notifyListeners(); // Notify listeners about the change
  // }

  Future<void> updateBoxsizeQuantity(
      String id, int newQuantity, String reason) async {
        String baseUrl = await Constants.getBaseUrl();
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    log("Id $id");

    final url = Uri.parse('$baseUrl/inventory/$id');
    log("Id 1: $id");

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
          'newTotal': newQuantity,
          // 'warehouseId': warehousId,
          'additionalInfo': {'reason': reason},
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        log('Inventory updated: $data');

        final index = _boxsizes.indexWhere((item) => item['_id'] == id);
        if (index != -1) {
          _boxsizes[index]['QUANTITY'] = newQuantity.toString();
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
