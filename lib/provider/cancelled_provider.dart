import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:inventory_management/constants/constants.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../model/orders_model.dart';

class CancelledProvider with ChangeNotifier {
  int totalOrders = 0;
  bool isLoading = false;
  bool selectAll = false;
  List<bool> selectedProducts = [];
  List<Order> _orders = [];
  int currentPage = 1; // Ensure this starts at 1
  int totalPages = 1;
  final PageController pageController = PageController();
  final TextEditingController textEditingController = TextEditingController();
  Timer? debounce;
  List<Order> get orders => _orders;

  int get selectedCount => selectedProducts.where((isSelected) => isSelected).length;

  bool isRefreshingOrders = false;

  void setRefreshingOrders(bool value) {
    isRefreshingOrders = value;
    notifyListeners();
  }

  void toggleSelectAll(bool value) {
    selectAll = value;
    selectedProducts = List<bool>.generate(_orders.length, (index) => selectAll);
    notifyListeners();
  }

  Future<void> fetchOrdersWithStatus10() async {
    isLoading = true;
    setRefreshingOrders(true);
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken') ?? '';
    final warehouseId = prefs.getString('warehouseId') ?? '';

    String url = '${await Constants.getBaseUrl()}/orders?warehouse=$warehouseId&orderStatus=10&page=$currentPage';

    try {
      final response = await http.get(Uri.parse(url), headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        log("cancel data: $data");
        List<Order> orders = (data['orders'] as List).map((order) => Order.fromJson(order)).toList();
        initializeSelection();

        totalPages = data['totalPages']; // Get total pages from response
        _orders = orders; // Set the orders for the current page
        totalOrders = data['totalOrders'] ?? 0; // Get total orders from response

        Logger().e(orders);

        selectedProducts = List<bool>.filled(_orders.length, false); // Set directly
        selectAll = false;

        Logger().e(selectedProducts);
        // Print the total number of orders fetched from the current page
        print('Total Orders Fetched from Page $currentPage: ${orders.length}');
      } else {
        // Handle non-success responses
        _orders = [];
        totalPages = 1; // Reset total pages if there’s an error
      }
    } catch (e) {
      // Handle errors
      _orders = [];
      totalPages = 1; // Reset total pages if there’s an error
    } finally {
      isLoading = false;
      setRefreshingOrders(false);
      notifyListeners();
    }
  }

  void goToPage(int page) {
    if (page < 1 || page > totalPages) return;
    currentPage = page;
    print('Current page set to: $currentPage'); // Debugging line
    fetchOrdersWithStatus10();
    notifyListeners();
  }

  // Format date
  String formatDate(DateTime date) {
    String year = date.year.toString();
    String month = date.month.toString().padLeft(2, '0');
    String day = date.day.toString().padLeft(2, '0');
    return '$day-$month-$year';
  }

  List<Order> orderscanceled = []; // List of returned orders
  List<bool> selectedcanceledItems = []; // Selection state for returned orders
  bool selectAllcanceled = false;

  void initializeSelection() {
    selectedProducts = List<bool>.filled(_orders.length, false);
    selectedcanceledItems = List<bool>.filled(orderscanceled.length, false);
  }

  void handleRowCheckboxChange(int index, bool isSelected) {
    selectedProducts[index] = isSelected;
    selectAll = selectedProducts.every((element) => element); // Check all visible orders
    notifyListeners();
  }


  void updateSelectAllStateForcanceled() {
    selectAllcanceled = selectedcanceledItems.every((item) => item);
    notifyListeners();
  }

  bool isCancelling = false;

  Future<void> returnSelectedOrders() async {
    isCancelling = true; // Set loading state
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken') ?? '';

    List<String> selectedOrderIds = [];

    // Collect the IDs of orders where trackingStatus is 'NA' (null or empty)
    for (int i = 0; i < selectedProducts.length; i++) {
      if (selectedProducts[i] && (_orders[i].trackingStatus?.isEmpty ?? true)) {
        selectedOrderIds.add(_orders[i].orderId);
      }
    }

    if (selectedOrderIds.isNotEmpty) {
      String url = '${await Constants.getBaseUrl()}/orders/return';

      try {
        final body = json.encode({
          'orderIds': selectedOrderIds,
          // This should send 'return' as the tracking status
        });

        //print('Request body: $body'); // Verify request body

        final response = await http.post(
          Uri.parse(url),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: body,
        );

        print('Response status: ${response.statusCode}');
        // print('Response body: ${response.body}'); // Check for errors in the response

        if (response.statusCode == 200) {
          print('Orders returned successfully!');
          // Update local order tracking status
          for (int i = 0; i < _orders.length; i++) {
            if (selectedProducts[i] && (_orders[i].trackingStatus?.isEmpty ?? true)) {
              _orders[i].trackingStatus = 'return'; // Update locally
            }
          }

          notifyListeners(); // Refresh UI
        } else {
          print('Failed to return orders: ${response.body}');
        }
      } catch (e) {
        print('Error: $e');
      } finally {
        isCancelling = false; // Reset loading state
        notifyListeners();
      }
    } else {
      print('No valid orders selected for return.');
    }
  }

  void onSearchChanged(String query) {
    if (debounce?.isActive ?? false) debounce!.cancel();
    debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.trim().isEmpty) {
        // If query is empty, reload all orders
        fetchOrdersWithStatus10();
      } else {
        searchOrders(query); // Trigger the search after the debounce period
      }
    });
  }

  Future<List<Order>> searchOrders(String query) async {
    if (query.isEmpty) {
      await fetchOrdersWithStatus10();
      return _orders;
    }

    isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken') ?? '';
    final warehouseId = prefs.getString('warehouseId') ?? '';

    final url = '${await Constants.getBaseUrl()}/orders?warehouse=$warehouseId&orderStatus=10&order_id=$query';

    print('Searching failed orders with term: $query');

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        print('Response data: $jsonData');

        // List<Order> orders = [];
        List<Order> orders = (jsonData['orders'] as List).map((order) => Order.fromJson(order)).toList();

        // if (jsonData != null) {
        //   orders.add(Order.fromJson(jsonData));
        // } else {
        //   print('No data found in response.');
        // }

        _orders = orders;
        selectedProducts = List<bool>.filled(_orders.length, false); // Reset to match _orders
        selectAll = false;
        print('Orders fetched: ${orders.length}');
      } else {
        print('Failed to load orders: ${response.statusCode}');
        _orders = [];
      }
    } catch (error) {
      print('Error searching failed orders: $error');
      _orders = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }

    return _orders;
  }
}
