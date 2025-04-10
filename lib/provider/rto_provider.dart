import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:inventory_management/constants/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../model/orders_model.dart';

class RtoProvider with ChangeNotifier {
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

  int get selectedCount => selectedProducts.where((isSelected) => isSelected).length;
  List<Order> get orders => _orders;

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

  Future<void> fetchOrdersWithStatus11() async {
    isLoading = true;
    setRefreshingOrders(true);
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken') ?? '';
    final warehouseId = prefs.getString('warehouseId') ?? '';

    String url = '${await Constants.getBaseUrl()}/orders?warehouse=$warehouseId&orderStatus=11&page=';

    try {
      final response = await http.get(Uri.parse('$url$currentPage'), headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        log("cancel data: $data");
        List<Order> orderss = (data['orders'] as List).map((order) => Order.fromJson(order)).toList();
        initializeSelection();

        totalPages = data['totalPages']; // Get total pages from response
        _orders = orderss; // Set the orders for the current page
        totalOrders = data['totalOrders']; // Get total orders from response
        selectedProducts = List<bool>.filled(orders.length, false); // Set directly
        selectAll = false;
      } else {
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
    fetchOrdersWithStatus11();
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
    selectedProducts = List<bool>.filled(orders.length, false);
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
  // bool get isCancelling => isCancelling;

  Future<void> returnSelectedOrders() async {
    isCancelling = true; // Set loading state
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken') ?? '';

    List<String> selectedOrderIds = [];

    // Collect the IDs of orders where trackingStatus is 'NA' (null or empty)
    for (int i = 0; i < selectedProducts.length; i++) {
      if (selectedProducts[i] && (orders[i].trackingStatus?.isEmpty ?? true)) {
        selectedOrderIds.add(orders[i].orderId);
      }
    }

    if (selectedOrderIds.isNotEmpty) {
      String url = '${await Constants.getBaseUrl()}/orders/return';

      try {
        final body = json.encode({
          'orderIds': selectedOrderIds,
          // This should send 'return' as the tracking status
        });


        final response = await http.post(
          Uri.parse(url),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: body,
        );

        print('Response status: ${response.statusCode}');

        if (response.statusCode == 200) {
          for (int i = 0; i < orders.length; i++) {
            if (selectedProducts[i] && (orders[i].trackingStatus?.isEmpty ?? true)) {
              orders[i].trackingStatus = 'return'; // Update locally
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
      if (query.isEmpty) {
        // If query is empty, reload all orders
        fetchOrdersWithStatus11();
      } else {
        searchOrders(query); // Trigger the search after the debounce period
      }
    });
  }

  Future<List<Order>> searchOrders(String query) async {
    if (query.isEmpty) {
      await fetchOrdersWithStatus11();
      return orders;
    }

    isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken') ?? '';
    final warehouseId = prefs.getString('warehouseId') ?? '';

    final url = '${await Constants.getBaseUrl()}/orders?warehouse=$warehouseId&orderStatus=11&order_id=$query';

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

        List<Order> orders = (jsonData['orders'] as List).map((order) => Order.fromJson(order)).toList();

        _orders = orders;
        selectedProducts = List<bool>.filled(orders.length, false); // Reset to match orders
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
