import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:inventory_management/constants/constants.dart';
import 'package:inventory_management/model/orders_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BaApproveProvider with ChangeNotifier {
  bool _isLoading = false;
  bool _selectAll = false;
  List<bool> _selectedProducts = [];
  int selectedItemsCount = 0;
  List<Order> _orders = [];
  int _currentPage = 1;
  int _totalPages = 1;
  final PageController _pageController = PageController();
  final TextEditingController _textEditingController = TextEditingController();
  Timer? _debounce;
  final TextEditingController searchController = TextEditingController();

  bool get selectAll => _selectAll;
  List<bool> get selectedProducts => _selectedProducts;
  List<Order> get orders => _orders;
  bool get isLoading => _isLoading;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  PageController get pageController => _pageController;
  TextEditingController get textEditingController => _textEditingController;
  int get selectedCount => _selectedProducts.where((isSelected) => isSelected).length;

  bool isUpdatingOrder = false;
  bool isRefreshingOrders = false;
  bool isCancel = false;

  void resetOrderData() {
    _orders = [];
    _currentPage = 1;
    _totalPages = 1;
    notifyListeners();
  }

  void setCancelStatus(bool status) {
    isCancel = status;
    notifyListeners();
  }

  void setUpdatingOrder(bool value) {
    isUpdatingOrder = value;
    notifyListeners();
  }

  void setRefreshingOrders(bool value) {
    isRefreshingOrders = value;
    notifyListeners();
  }

  void handleRowCheckboxChange(int index, bool isSelected) {
    _selectedProducts[index] = isSelected;

    // If any individual checkbox is unchecked, deselect "Select All"
    if (!isSelected) {
      _selectAll = false;
    } else {
      // If all boxes are checked, select "Select All"
      _selectAll = _selectedProducts.every((element) => element);
    }

    notifyListeners();
  }

  void toggleSelectAll(bool value) {
    _selectAll = value;
    _selectedProducts = List<bool>.generate(_orders.length, (index) => _selectAll);
    notifyListeners();
  }

  void goToPage(int page) {
    if (page < 1 || page > _totalPages) return;
    _currentPage = page;
    print('Current page set to: $_currentPage'); // Debugging line
    fetchOrdersWithStatus2();
    notifyListeners();
  }

  // Format date
  String formatDate(DateTime date) {
    String year = date.year.toString();
    String month = date.month.toString().padLeft(2, '0');
    String day = date.day.toString().padLeft(2, '0');
    return '$day-$month-$year';
  }

  String formatDateTime(DateTime date) {
    String year = date.year.toString();
    String month = date.month.toString().padLeft(2, '0');
    String day = date.day.toString().padLeft(2, '0');
    String hour = date.hour.toString().padLeft(2, '0');
    String minute = date.minute.toString().padLeft(2, '0');
    String second = date.second.toString().padLeft(2, '0');

    return '$day-$month-$year $hour:$minute:$second';
  }

  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken') ?? '';
  }

  Future<String> cancelOrders(BuildContext context, List<String> orderIds) async {
    String baseUrl = await Constants.getBaseUrl();
    String cancelOrderUrl = '$baseUrl/orders/cancel';
    // final String? token = await _getToken();

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
        await fetchOrdersWithStatus2(); // Assuming fetchOrders is a function that reloads the orders
        setRefreshingOrders(false); // Clear selected order IDs
        setCancelStatus(false);
        notifyListeners(); // Notify the UI to rebuild

        return responseData['message'] ?? 'Orders cancelled successfully';
      } else {
        return responseData['message'] ?? 'Failed to cancel orders';
      }
    } catch (error) {
      setCancelStatus(false);
      notifyListeners();
      print('Error during API request: $error');
      return 'An error occurred: $error';
    }
  }

  Future<void> fetchOrdersWithStatus2({DateTime? date, String? market}) async {
    // if(searchController.text.trim().isNotEmpty) {
    //   searchOrders(searchController.text.trim());
    //   return;
    // }
    _isLoading = true;
    setRefreshingOrders(true);
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken') ?? '';
    final warehouseId = prefs.getString('warehouseId') ?? '';

    var url = '${await Constants.getBaseUrl()}/orders?warehouse=$warehouseId&orderStatus=2&ba_approve=false&page=$_currentPage';

    if (date != null) {
      String formattedDate = DateFormat('yyyy-MM-dd').format(date);
      url += '&date=$formattedDate';
    }
    if (market != 'All' && market != null) {
      url += '&marketplace=$market';
    }

    try {
      final response = await http.get(Uri.parse(url), headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<Order> orders = (data['orders'] as List).map((order) => Order.fromJson(order)).toList();

        log('orders: $orders');

        _totalPages = data['totalPages']; // Get total pages from response
        _orders = orders; // Set the orders for the current page

        // Initialize selected products list
        _selectedProducts = List<bool>.filled(_orders.length, false);

        // Print the total number of orders fetched from the current page
        print('Total Orders Fetched from Page $_currentPage: ${orders.length}');
      } else {
        resetOrderData();
      }
    } catch (e) {
      log('Error fetching orders: $e');
      resetOrderData();
    } finally {
      _isLoading = false;
      setRefreshingOrders(false);
      notifyListeners();
    }
  }

  void onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.isEmpty) {
        // If query is empty, reload all orders
        fetchOrdersWithStatus2();
      } else {
        searchOrders(query); // Trigger the search after the debounce period
      }
    });
  }

  Future<List<Order>> searchOrders(String query) async {
    // if (query.isEmpty) {
    //   await fetchOrdersWithStatus2();
    //   return _orders;
    // }

    _isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken') ?? '';
    final warehouseId = prefs.getString('warehouseId') ?? '';

    String encodedOrderId = Uri.encodeComponent(query.trim());

    final url = '${await Constants.getBaseUrl()}/orders?warehouse=$warehouseId&orderStatus=2&ba_approve=false&order_id=$encodedOrderId';

    print('Searching orders with term: $query');

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

        // List<Order> orders = [];
        // // print('Response data: $jsonData');
        // if (jsonData != null) {
        //   orders.add(Order.fromJson(jsonData));
        //   print('Response data: $jsonData');
        // } else {
        //   print('No data found in response.');
        // }

        _orders = (jsonData['orders'] as List).map((order) => Order.fromJson(order)).toList();
        print('Orders fetched: ${orders.length}');
      } else {
        print('Failed to load orders: ${response.statusCode}');
        resetOrderData();
      }
    } catch (error) {
      print('Error searching failed orders: $error');
      resetOrderData();
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    return _orders;
  }

  // New function to update status of selected orders
  Future<void> statusUpdate(BuildContext context) async {
    setUpdatingOrder(true);
    notifyListeners();
    final selectedOrderIds = _orders.asMap().entries.where((entry) => _selectedProducts[entry.key]).map((entry) => entry.value.orderId).toList();

    if (selectedOrderIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No orders selected to update')),
      );
      setUpdatingOrder(false);
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken') ?? '';
    String url = '${await Constants.getBaseUrl()}/orders/ba_approve';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'orderIds': selectedOrderIds
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Orders updated successfully')),
        );

        // Refresh the orders after updating status
        fetchOrdersWithStatus2();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update orders')),
        );
      }
    } catch (error) {
      print('Error updating order status: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error while updating orders')),
      );
    } finally {
      setUpdatingOrder(false);
      notifyListeners();
    }
  }

  Future<void> fetchOrdersByMarketplace(String marketplace, int orderStatus, int page, {DateTime? date}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken') ?? '';
    final warehouseId = prefs.getString('warehouseId') ?? '';

    String baseUrl = '${await Constants.getBaseUrl()}/orders';
    String url = '$baseUrl?warehouse=$warehouseId&orderStatus=$orderStatus&ba_approve=false&marketplace=$marketplace&page=$page';

    if (date != null) {
      String formattedDate = DateFormat('yyyy-MM-dd').format(date);
      url += '&date=$formattedDate';
    }

    try {
      _isLoading = true;
      notifyListeners();

      // Clear checkboxes when a new page is fetched
      // clearAllSelections();

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
        List<Order> orders = (jsonResponse['orders'] as List).map((orderJson) => Order.fromJson(orderJson)).toList();

        log("orders: $orders");

        _orders = orders;
        _currentPage = page; // Track current page for B2B
        _totalPages = jsonResponse['totalPages']; // Assuming API returns total pages
      } else {
        resetOrderData();
        throw Exception('Failed to load orders: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching orders: $e');
      resetOrderData();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
