import 'dart:convert';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:inventory_management/Custom-Files/utils.dart';
import 'package:inventory_management/constants/constants.dart';
import 'package:inventory_management/model/SubInventory.dart';
import 'package:provider/provider.dart';
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

    final url = Uri.parse('$baseUrl/inventory/warehouse?warehouse=$warehouseId&page=$page&limit=20'); // Adjust limit as needed

    log("fetchInventory url: $url");

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


  /// CREATE PRODUCT


  String? _selectedProductId;
  String? get selectedProductId => _selectedProductId;
  void setSelectedProductId(String value) {
    _selectedProductId = value;
    notifyListeners();
  }

  List<SubInventoryModel> _subInventories = [];
  List<SubInventoryModel> get subInventories => _subInventories;

  void addCreateInventoryModel() {
    SubInventoryModel subInventory = SubInventoryModel(
      warehouseId: null,
      warehouseName: null,
      thresholdQuantity: null,
      bin: InventoryBin(
        binName: null,
        binQuantity: null,
      ),
    );
    _fetchingBins.add(false);
    _bins.add([]);
    _subInventories.add(subInventory);
    notifyListeners();
  }

  void removeCreateInventoryModel(int index) {
    _fetchingBins.removeAt(index);
    _bins.removeAt(index);
    _subInventories.removeAt(index);
    notifyListeners();
  }

  void updateSubInventory({
    required int index,
    String? warehouseId,
    String? warehouseName,
    String? thresholdQuantity,
    InventoryBin? bin,
  }) {
    _subInventories[index] = _subInventories[index].copyWith(
      warehouseId: warehouseId,
      thresholdQuantity: thresholdQuantity,
      warehouseName: warehouseName,
      bin: bin,
    );

    notifyListeners();
  }

  List<List<String>> _bins = [];
  List<List<String>> get bins => _bins;
  void setBins(int index, List<String> value) {
    _bins[index] = value;
    notifyListeners();
    log('Bins are :- $bins');
    log('Fetching Bins Status :- $fetchingBins');
  }

  List<bool> _fetchingBins = [];
  List<bool> get fetchingBins => _fetchingBins;
  void setFetchingBins(int index, bool value) {
    _fetchingBins[index] = value;
    notifyListeners();
  }

  Future<void> fetchBins(BuildContext context, String warehouseId, int index) async {

    setFetchingBins(index, true);

    String baseUrl = await Constants.getBaseUrl();
    final url = Uri.parse('$baseUrl/bin/$warehouseId');

    try {

      final token = await Provider.of<AuthProvider>(context, listen: false).getToken();

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final res = json.decode(response.body);

      if (response.statusCode == 200 && res.containsKey('bins')) {
        final bin = List<String>.from(res['bins'].map((bin) => bin['binName'].toString()));
        setBins(index, bin);
      } else {
        setBins(index, []);
      }
    } catch (error) {
      setBins(index, []);
    } finally {
      setFetchingBins(index, false);
    }
  }

  bool _isCreatingInventory = false;
  bool get isCreatingInventory => _isCreatingInventory;
  void setCreatingInventory(bool value) {
    _isCreatingInventory = value;
    notifyListeners();
  }

  Future<void> createInventory(BuildContext context) async {
    try {

      if (selectedProductId == null) {
        Utils.showSnackBar(context, 'Please Select Product..!');
        return;
      }

      final body = {
        "product_id": selectedProductId,
        "subInventory": subInventories.map((subInventory) {

          final binQty = subInventory.bin.binQuantity ?? '';

          return {
            "warehouseId": subInventory.warehouseId,
            "thresholdQuantity": int.tryParse(subInventory.thresholdQuantity ?? '') ?? null,
            "bin": [{
              "binName": subInventory.bin.binName,
              "binQty": int.tryParse(binQty) ?? 1,
              "binPriority": subInventory.bin.binPriority,
            }]
          };
        }).toList(),
      };

      final payload = jsonEncode(body);

      log('Creating Inventory Payload :- $payload');

      try {
        final token = await Provider.of<AuthProvider>(context, listen: false).getToken();

        final response = await http.post(
          Uri.parse('${await Constants.getBaseUrl()}/inventory'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: payload,
        );

        final responseData = jsonDecode(response.body);

        log('Creating Inventory Response :- ${response.body}');

        if (response.statusCode == 201) {
          if (responseData['success'] == true) {
            Utils.showSnackBar(context, 'Inventory created successfully!', color: Colors.green);
            return;
          }
        }

        final message = responseData['error'] ?? 'Failed to create inventory..!';
        final details = responseData['details'] ?? 'Status Code: ${response.statusCode}';

        Utils.showSnackBar(context, message, details: details, color: Colors.red);
      } catch (e) {
        Utils.showSnackBar(context, 'Error occured while creating inventory..!', details: e.toString(), color: Colors.red);
      }

    } catch (e, s) {
      log('Error creating Inventory :- $e\n$s');
      Utils.showSnackBar(context, 'Error creating Inventory :- ${e.toString()}');
    }
  }

  void initCreateInventory() {
    _selectedProductId = null;
    _bins = [];
    _fetchingBins = [];
    _subInventories = [];
    addCreateInventoryModel();
  }
}


class SubInventoryModel {
  final String? warehouseId;
  final String? warehouseName;
  final String? thresholdQuantity;
  final InventoryBin bin;

  SubInventoryModel({
    required this.warehouseId,
    required this.warehouseName,
    required this.thresholdQuantity,
    required this.bin,
  });

  SubInventoryModel copyWith({
    String? warehouseId,
    String? warehouseName,
    String? thresholdQuantity,
    InventoryBin? bin,
  }) {
    return SubInventoryModel(
      warehouseId: warehouseId ?? this.warehouseId,
      warehouseName: warehouseName ?? this.warehouseName,
      thresholdQuantity: thresholdQuantity ?? this.thresholdQuantity,
      bin: bin ?? this.bin,
    );
  }
}

class InventoryBin {
  final String? binName;
  final String? binQuantity;
  final int binPriority;

  InventoryBin({
    required this.binName,
    required this.binQuantity,
    this.binPriority = 1,
  });

  InventoryBin copyWith({
    String? binName,
    String? binQuantity,
  }) {
    return InventoryBin(
      binName: binName ?? this.binName,
      binQuantity: binQuantity ?? this.binQuantity,
    );
  }

}
