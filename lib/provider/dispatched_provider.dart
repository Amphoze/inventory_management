import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:inventory_management/Custom-Files/colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../model/orders_model.dart';

class DispatchedProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool _selectAll = false;
  List<bool> _selectedProducts = [];
  List<Order> _orders = [];
  int _currentPage = 1; // Ensure this starts at 1
  int _totalPages = 1;
  final PageController _pageController = PageController();
  final TextEditingController _textEditingController = TextEditingController();
  Timer? _debounce;

  bool get selectAll => _selectAll;
  List<bool> get selectedProducts => _selectedProducts;
  List<Order> get orders => _orders;
  bool get isLoading => _isLoading;

  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  PageController get pageController => _pageController;
  TextEditingController get textEditingController => _textEditingController;

  int get selectedCount =>
      _selectedProducts.where((isSelected) => isSelected).length;

  bool isRefreshingOrders = false;

  void setRefreshingOrders(bool value) {
    isRefreshingOrders = value;
    notifyListeners();
  }

  void toggleSelectAll(bool value) {
    _selectAll = value;
    _selectedProducts =
        List<bool>.generate(_orders.length, (index) => _selectAll);
    notifyListeners();
  }

  bool isCancel = false;
  void setCancelStatus(bool status) {
    isCancel = status;
    notifyListeners();
  }

  Future<String> cancelOrders(
      BuildContext context, List<String> orderIds) async {
    const String baseUrl =
        'https://inventory-management-backend-s37u.onrender.com';
    const String cancelOrderUrl = '$baseUrl/orders/cancel';
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken') ?? '';
    setCancelStatus(true);
    notifyListeners();

    // Headers for the API request
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    // Request body containing the order IDs
    final body = json.encode({
      'orderIds': orderIds,
    });

    try {
      // Make the POST request to confirm the orders
      final response = await http.post(
        Uri.parse(cancelOrderUrl),
        headers: headers,
        body: body,
      );

      print('Response status: ${response.statusCode}');
      //print('Response body: ${response.body}');

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        // After successful confirmation, fetch updated orders and notify listeners
        await fetchOrdersWithStatus9(); // Assuming fetchOrders is a function that reloads the orders
        // resetSelections(); // Clear selected order IDs
        setCancelStatus(false);
        notifyListeners(); // Notify the UI to rebuild

        return responseData['message'] ?? 'Orders confirmed successfully';
      } else {
        return responseData['message'] ?? 'Failed to confirm orders';
      }
    } catch (error) {
      setCancelStatus(false);
      notifyListeners();
      print('Error during API request: $error');
      return 'An error occurred: $error';
    }
  }

  Future<void> fetchOrdersWithStatus9() async {
    _isLoading = true;
    setRefreshingOrders(true);
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken') ?? '';
    const url =
        'https://inventory-management-backend-s37u.onrender.com/orders?orderStatus=9&page=';

    try {
      final response = await http.get(Uri.parse('$url$_currentPage'), headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        log("dispatch data: $data");
        List<Order> orders = (data['orders'] as List)
            .map((order) => Order.fromJson(order))
            .toList();
        initializeSelection();

        _totalPages = data['totalPages']; // Get total pages from response
        _orders = orders; // Set the orders for the current page

        // Logger().e(orders);

        // Initialize selected products list
        _selectedProducts = List<bool>.filled(_orders.length, false);

        // Logger().e(_selectedProducts);
        // Print the total number of orders fetched from the current page
        print('Total Orders Fetched from Page $_currentPage: ${orders.length}');
      } else {
        // Handle non-success responses
        _orders = [];
        _totalPages = 1; // Reset total pages if there’s an error
      }
    } catch (e) {
      // Handle errors
      _orders = [];
      _totalPages = 1; // Reset total pages if there’s an error
    } finally {
      _isLoading = false;
      setRefreshingOrders(false);
      notifyListeners();
    }
  }

  void goToPage(int page) {
    if (page < 1 || page > _totalPages) return;
    _currentPage = page;
    print('Current page set to: $_currentPage'); // Debugging line
    fetchOrdersWithStatus9();
    notifyListeners();
  }

  // Format date
  String formatDate(DateTime date) {
    String year = date.year.toString();
    String month = date.month.toString().padLeft(2, '0');
    String day = date.day.toString().padLeft(2, '0');
    return '$day-$month-$year';
  }

  List<Order> ordersDispatched = []; // List of returned orders
  List<bool> selectedDispatchedItems =
      []; // Selection state for returned orders
  bool selectAllDispatched = false;

  void initializeSelection() {
    _selectedProducts = List<bool>.filled(_orders.length, false);
    selectedDispatchedItems = List<bool>.filled(ordersDispatched.length, false);
  }

  // Handle individual row checkbox change for orders
  void handleRowCheckboxChange(int index, bool isSelected) {
    _selectedProducts[index] = isSelected;
    notifyListeners();
  }

  // Handle individual row checkbox change for returned orders
  void handleRowCheckboxChangeForDispatched(String? orderId, bool isSelected) {
    int index =
        ordersDispatched.indexWhere((order) => order.orderId == orderId);
    if (index != -1) {
      selectedDispatchedItems[index] = isSelected;
      ordersDispatched[index].isSelected = isSelected;
      _updateSelectAllStateForDispatched();
    }
    notifyListeners();
  }

  void _updateSelectAllStateForDispatched() {
    selectAllDispatched = selectedDispatchedItems.every((item) => item);
    notifyListeners();
  }

  bool _isDispatching = false;
  bool get isDispatching => _isDispatching;

  Future<void> returnSelectedOrders() async {
    _isDispatching = true; // Set loading state
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken') ?? '';

    List<String> selectedOrderIds = [];

    // Collect the IDs of orders where trackingStatus is 'NA' (null or empty)
    for (int i = 0; i < _selectedProducts.length; i++) {
      if (_selectedProducts[i] &&
          (_orders[i].trackingStatus?.isEmpty ?? true)) {
        selectedOrderIds.add(_orders[i].orderId);
      }
    }

    if (selectedOrderIds.isNotEmpty) {
      const url =
          'https://inventory-management-backend-s37u.onrender.com/orders/return';

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
            if (_selectedProducts[i] &&
                (_orders[i].trackingStatus?.isEmpty ?? true)) {
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
        _isDispatching = false; // Reset loading state
        notifyListeners();
      }
    } else {
      print('No valid orders selected for return.');
    }
  }

  void onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.isEmpty) {
        // If query is empty, reload all orders
        fetchOrdersWithStatus9();
      } else {
        searchOrders(query); // Trigger the search after the debounce period
      }
    });
  }

  Future<List<Order>> searchOrders(String query) async {
    if (query.isEmpty) {
      await fetchOrdersWithStatus9();
      return _orders;
    }

    _isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken') ?? '';

    final url =
        'https://inventory-management-backend-s37u.onrender.com/orders?orderStatus=9&order_id=$query';

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

        List<Order> orders = [];
        if (jsonData != null) {
          orders.add(Order.fromJson(jsonData));
        } else {
          print('No data found in response.');
        }

        _orders = orders;
        print('Orders fetched: ${orders.length}');
      } else {
        print('Failed to load orders: ${response.statusCode}');
        _orders = [];
      }
    } catch (error) {
      print('Error searching failed orders: $error');
      _orders = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    return _orders;
  }

  Future<String> updateOrderTrackingStatus(
      BuildContext context, String id, String trackingStatus) async {
    const String baseUrl =
        'https://inventory-management-backend-s37u.onrender.com';
    final String updateOrderUrl = '$baseUrl/orders/$id';
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken') ?? '';

    // Headers for the API request
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    // Request body containing the tracking status
    final body = json.encode({
      'tracking_status': trackingStatus,
    });

    try {
      // Make the PUT request to update the order tracking status
      final response = await http.put(
        Uri.parse(updateOrderUrl),
        headers: headers,
        body: body,
      );

      print('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        // Show success snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              backgroundColor: AppColors.green,
              content: Text(
                'Tracking status successfully updated to "$trackingStatus"',
              )),
        );
        return 'Tracking status updated successfully';
      } else {
        final responseData = json.decode(response.body);
        // Show failure snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(responseData['message'] ??
                  'Failed to update tracking status')),
        );
        return responseData['message'] ?? 'Failed to update tracking status';
      }
    } catch (error) {
      print('Error during API request: $error');
      // Show error snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $error')),
      );
      return 'An error occurred: $error';
    }
  }
}
