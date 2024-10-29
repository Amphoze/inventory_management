import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:inventory_management/model/orders_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BookProvider with ChangeNotifier {
  final TextEditingController searchController = TextEditingController();

  // Store selected states for B2B and B2C orders
  List<bool> selectedB2BItems = List.generate(40, (index) => false);
  List<bool> selectedB2CItems = List.generate(40, (index) => false);

  // Select all flags for B2B and B2C
  bool selectAllB2B = false;
  bool selectAllB2C = false;

  // Loading states for B2B and B2C orders
  bool isLoadingB2B = false;
  bool isLoadingB2C = false;

  // Sort option for orders
  String? _sortOption;
  String? get sortOption => _sortOption;

  // Lists for storing fetched orders
  List<Order> ordersB2B = [];
  List<Order> ordersB2C = [];

  // Pagination
  int currentPageB2B = 1;
  int currentPageB2C = 1;
  int totalPagesB2B = 0;
  int totalPagesB2C = 0;

  // Set the sort option and notify listeners
  void setSortOption(String? option) {
    _sortOption = option;
    notifyListeners();
  }

  Future<void> fetchPaginatedOrdersB2B(int page) async {
    await fetchOrders('B2B', page);
  }

  Future<void> fetchPaginatedOrdersB2C(int page) async {
    await fetchOrders('B2C', page);
  }

  // Fetch orders based on type (B2B or B2C)
  Future<void> fetchOrders(String type, int page) async {
    String? token = await _getToken();
    if (token == null) {
      print('Token is null, unable to fetch orders.');
      return;
    }

    String url =
        'https://inventory-management-backend-s37u.onrender.com/orders?filter=$type&orderStatus=3&page=$page';

    try {
      // Set loading state based on order type
      if (type == 'B2B') {
        isLoadingB2B = true;
      } else {
        isLoadingB2C = true;
      }
      notifyListeners();

      // Clear checkboxes when a new page is fetched
      clearAllSelections();

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      // Log response for debugging
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        List<Order> orders = (jsonResponse['orders'] as List)
            .map((orderJson) => Order.fromJson(orderJson))
            .toList();

        // Store fetched orders and update pagination state
        if (type == 'B2B') {
          ordersB2B = orders;
          currentPageB2B = page; // Track current page for B2B
          totalPagesB2B =
              jsonResponse['totalPages']; // Assuming API returns total pages
        } else {
          ordersB2C = orders;
          currentPageB2C = page; // Track current page for B2C
          totalPagesB2C =
              jsonResponse['totalPages']; // Assuming API returns total pages
        }
      } else if (response.statusCode == 401) {
        print('Unauthorized access - Token might be expired or invalid.');
      } else if (response.statusCode == 404) {
        print('Orders not found - Check the filter type.');
      } else {
        throw Exception('Failed to load orders: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching $type orders: $e');
    } finally {
      // Reset loading states
      if (type == 'B2B') {
        isLoadingB2B = false;
      } else {
        isLoadingB2C = false;
      }
      notifyListeners();
    }
  }

  // Function to book orders
  Future<String> bookOrders(
      BuildContext context, List<String> orderIds, String lowerCase) async {
    const String baseUrl =
        'https://inventory-management-backend-s37u.onrender.com';
    const String bookOrderUrl = '$baseUrl/orders/book';
    final String? token = await _getToken();

    if (token == null) {
      return 'No auth token found';
    }

    // Headers for the API request
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    // Request body containing the order IDs
    final body = json.encode({
      'orderIds': orderIds,
      'service': lowerCase,
    });
    ;
    log(body);

    try {
      // Make the POST request to book the orders
      final response = await http.post(
        Uri.parse(bookOrderUrl),
        headers: headers,
        body: body,
      );

      // Log response status and body
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      // Parse the response
      final responseData = json.decode(response.body);

      // Check if the response is successful
      if (response.statusCode == 200) {
        // Optionally, you can also clear the selected orders here
        clearAllSelections();

        // Notify listeners after successful booking
        notifyListeners();
        return responseData['message'] ?? 'Orders booked successfully';
      } else {
        // If the API returns an error, return the error message
        return responseData['message'] ?? 'Failed to book orders';
      }
    } catch (error) {
      print('Error during API request: $error');
      return 'An error occurred: $error';
    }
  }

  // Get the auth token from SharedPreferences
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }

  // Update search query and notify listeners
  void onSearchChanged() {
    print('Search query: ${searchController.text}');
    notifyListeners();
  }

  // Handle individual row checkbox change
  void handleRowCheckboxChange(String? orderId, bool isSelected, bool isB2B) {
    int index;
    if (isB2B) {
      index = ordersB2B.indexWhere((order) => order.orderId == orderId);
      if (index != -1) {
        selectedB2BItems[index] = isSelected;
        ordersB2B[index].isSelected = isSelected;
      }
    } else {
      index = ordersB2C.indexWhere((order) => order.orderId == orderId);
      if (index != -1) {
        selectedB2CItems[index] = isSelected;
        ordersB2C[index].isSelected = isSelected;
      }
    }
    _updateSelectAllState(isB2B);
    notifyListeners();
  }

  // Update the select all state based on selected items
  void _updateSelectAllState(bool isB2B) {
    if (isB2B) {
      selectAllB2B = selectedB2BItems.every((item) => item);
    } else {
      selectAllB2C = selectedB2CItems.every((item) => item);
    }
    notifyListeners();
  }

  // Toggle select all checkboxes
  void toggleSelectAll(bool isB2B, bool? value) {
    if (isB2B) {
      selectAllB2B = value!;
      selectedB2BItems.fillRange(0, selectedB2BItems.length, selectAllB2B);
      // Update the selection state for B2B orders
      for (int i = 0; i < ordersB2B.length; i++) {
        ordersB2B[i].isSelected = selectAllB2B;
      }
    } else {
      selectAllB2C = value!;
      selectedB2CItems.fillRange(0, selectedB2CItems.length, selectAllB2C);
      // Update the selection state for B2C orders
      for (int i = 0; i < ordersB2C.length; i++) {
        ordersB2C[i].isSelected = selectAllB2C;
      }
    }
    notifyListeners();
  }

  // Clear all checkboxes when the page is changed
  void clearAllSelections() {
    selectedB2BItems.fillRange(0, selectedB2BItems.length, false);
    selectedB2CItems.fillRange(0, selectedB2CItems.length, false);
    selectAllB2B = false;
    selectAllB2C = false;
    notifyListeners();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}
