import 'package:flutter/material.dart';
import 'package:inventory_management/model/Inventory.dart';
import 'package:inventory_management/Api/inventory_service.dart';
import 'package:inventory_management/Api/auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ManagementProvider extends ChangeNotifier {
  final InventoryService _inventoryService =
      InventoryService(); // Inventory Service instance
  final AuthProvider _authProvider = AuthProvider(); // AuthProvider instance

  int _selectedPage = 1;
  int _numberofPages = 10;
  int _firstVal = 1;
  int _lastVal = 5;
  int _jump = 5;
  int _totalItems = 0; // Total items for inventory
  bool _isLoading = false; // Loading indicator for UI

  List<InventoryModel> _inventoryList = []; // List to hold inventory data
  String? _token;

  // Getters
  int get selectedPage => _selectedPage;
  int get numberofPages => _numberofPages;
  int get firstVal => _firstVal;
  int get lastVal => _lastVal;
  int get jump => _jump;
  List<InventoryModel> get inventoryList =>
      _inventoryList; // Public getter for inventoryList
  bool get isLoading => _isLoading;

  ManagementProvider() {
    _initialize();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken'); // Fetch token from SharedPreferences
  }

  // Initialize token and fetch inventory
  Future<void> _initialize() async {
    _token = await _getToken(); // Fetch the token from SharedPreferences
    if (_token != null) {
      fetchInventory(); // Fetch inventory data if token is available
    } else {
      print('Token not found or is empty');
    }
  }

  // Method to update the selected page
  void upDateSelectedPage(int val) {
    _selectedPage = val;
    _firstVal = (val - 1) * _jump + 1;
    _lastVal = _firstVal + _jump - 1;
    notifyListeners();
    fetchInventory(); // Fetch inventory when page is updated
  }

  // Method to update jump size for pagination
  void upDateJump(int val) {
    _jump = val;
    updateNumberOfPages((_totalItems / _jump)
        .ceil()); // Update the number of pages based on new jump size
    _selectedPage = 1; // Reset to page 1 when jump changes
    notifyListeners();
    fetchInventory(); // Refetch inventory when jump changes
  }

  // Method to update the number of pages
  void updateNumberOfPages(int val) {
    _numberofPages = val;
    notifyListeners();
  }

  // Method to fetch inventory data from API with pagination support
  Future<void> fetchInventory() async {
    if (_token == null) {
      print("Token is null, cannot fetch inventory.");
      return;
    }

    _isLoading = true;
    notifyListeners(); // Notify listeners to show loading state

    try {
      // Make the API call to fetch inventory
      final response =
          await _inventoryService.getInventory(_token!, _selectedPage, _jump);

      print('Full Response from API: $response');

      // Check if the response contains 'inventories' key
      if (response['data'] != null &&
          response['data'].containsKey('inventories')) {
        List<dynamic>? inventories =
            response['data']['inventories'] as List<dynamic>?;

        // Check if inventories list is null or empty
        if (inventories == null || inventories.isEmpty) {
          print('Error: inventories is null or an empty list');
          _inventoryList = [];
        } else {
          // Parse the inventory list into _inventoryList
          _inventoryList = inventories.map<InventoryModel>((json) {
            final inventory =
                InventoryModel.fromJson(json as Map<String, dynamic>);

            // Ensure subInventory is not null, assign an empty list if it is
            inventory.subInventory ??= [];

            // Log if product_id is null
            if (inventory.product == null) {
              print(
                  'Warning: product_id is null for inventory with id: ${inventory.id}');
            }

            return inventory;
          }).toList();
        }

        // Set totalItems based on the totalPages value from the response
        _totalItems =
            response['totalPages'] != null ? response['totalPages'] * _jump : 0;

        // Update the number of pages
        updateNumberOfPages(response['totalPages'] ?? 1);

        print('Inventory List Updated: ${_inventoryList.length} items');
      } else {
        throw Exception('Missing inventories key in the response');
      }

      // Notify listeners after successfully fetching data
      notifyListeners();
      print('Notified Listeners');
    } catch (e) {
      // Handle any errors that occur during the fetch
      print('Error fetching inventory: $e');
    } finally {
      // Set loading state to false and notify listeners
      _isLoading = false;
      notifyListeners();
    }
  }

  // Method to set the token manually (optional)
  void setToken(String token) {
    _token = token;
    notifyListeners();
  }
}
