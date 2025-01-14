import 'package:flutter/material.dart';
import 'package:inventory_management/model/Inventory.dart';
import 'package:inventory_management/Api/inventory_service.dart';
import 'package:inventory_management/Api/auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ManagementProvider with ChangeNotifier {
  final InventoryService inventoryService =
      InventoryService(); // Inventory Service instance
  final AuthProvider authProvider = AuthProvider(); // AuthProvider instance

  int selectedPage = 1;
  int numberofPages = 10;
  int firstVal = 1;
  int lastVal = 5;
  int jump = 5;
  int totalItems = 0; // Total items for inventory
  bool isLoading = false; // Loading indicator for UI

  List<InventoryModel> inventoryList = []; // List to hold inventory data
  String? token;

  // Getters
  // int get selectedPage => selectedPage;
  // int get numberofPages => numberofPages;
  // int get firstVal => firstVal;
  // int get lastVal => lastVal;
  // int get jump => jump;
  // List<InventoryModel> get inventoryList =>
  //     inventoryList; // Public getter for inventoryList
  // bool get isLoading => isLoading;

  ManagementProvider() {
    initialize();
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken'); // Fetch token from SharedPreferences
  }

  // Initialize token and fetch inventory
  Future<void> initialize() async {
    token = await getToken(); // Fetch the token from SharedPreferences
    if (token != null) {
      fetchInventory(); // Fetch inventory data if token is available
    } else {
      print('Token not found or is empty');
    }
  }

  // Method to update the selected page
  void upDateSelectedPage(int val) {
    selectedPage = val;
    firstVal = (val - 1) * jump + 1;
    lastVal = firstVal + jump - 1;
    notifyListeners();
    fetchInventory(); // Fetch inventory when page is updated
  }

  // Method to update jump size for pagination
  void upDateJump(int val) {
    jump = val;
    updateNumberOfPages((totalItems / jump)
        .ceil()); // Update the number of pages based on new jump size
    selectedPage = 1; // Reset to page 1 when jump changes
    notifyListeners();
    fetchInventory(); // Refetch inventory when jump changes
  }

  // Method to update the number of pages
  void updateNumberOfPages(int val) {
    numberofPages = val;
    notifyListeners();
  }

  // Method to fetch inventory data from API with pagination support
  Future<void> fetchInventory() async {
    if (token == null) {
      print("Token is null, cannot fetch inventory.");
      return;
    }

    isLoading = true;
    notifyListeners(); // Notify listeners to show loading state

    try {
      // Make the API call to fetch inventory
      final response =
          await inventoryService.getInventory(token!, selectedPage, jump);

      print('Full Response from API: $response');

      // Check if the response contains 'inventories' key
      if (response['data'] != null &&
          response['data'].containsKey('inventories')) {
        List<dynamic>? inventories =
            response['data']['inventories'] as List<dynamic>?;

        // Check if inventories list is null or empty
        if (inventories == null || inventories.isEmpty) {
          print('Error: inventories is null or an empty list');
          inventoryList = [];
        } else {
          // Parse the inventory list into _inventoryList
          inventoryList = inventories.map<InventoryModel>((json) {
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
        totalItems =
            response['totalPages'] != null ? response['totalPages'] * jump : 0;

        // Update the number of pages
        updateNumberOfPages(response['totalPages'] ?? 1);

        print('Inventory List Updated: ${inventoryList.length} items');
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
      isLoading = false;
      notifyListeners();
    }
  }

  // Method to set the token manually (optional)
  void setToken(String token) {
    token = token;
    notifyListeners();
  }
}
