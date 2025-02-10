import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:inventory_management/constants/constants.dart';
import 'package:inventory_management/model/orders_model.dart'; // Ensure you have the Order model defined here
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RoutingProvider with ChangeNotifier {
  bool allSelected = false;

  // bool allSelectedFailed = false;
  int selectedItemsCount = 0;

  // int selectedFailedItemsCount = 0;
  List<bool> _selectedOrders = [];

  // List<bool> _selectedFailedOrders = [];
  List<Order> readyOrders = []; // List to store fetched ready orders
  // List<Order> failedOrders = []; // List to store fetched failed orders
  // int totalFailedPages = 1; // Default value 1
  String? _selectedCourier;
  String? _selectedPayment;
  String? _selectedFilter;
  String? _selectedMarketplace;
  String? _selectedOrderType;
  String? _selectedCustomerType;
  String _expectedDeliveryDate = '';
  String _paymentDateTime = '';
  String _normalDate = '';

  // List<Order> readyOrders = [];
  // List<Order> failedOrders = [];

  int currentPage = 1;
  int totalReadyPages = 1;
  int currentPageReady = 1;
  bool isLoading = false;

  // Public getters for selected orders
  // List<bool> get selectedFailedOrders => _selectedFailedOrders;
  List<bool> get selectedOrders => _selectedOrders;

  // final List<Order> _failedOrder = [];

  // List<Order> get failedOrder => _failedOrder;

  String? get selectedCourier => _selectedCourier;

  String? get selectedPayment => _selectedPayment;

  String? get selectedMarketplace => _selectedMarketplace;

  String? get selectedOrderType => _selectedOrderType;

  String? get selectedCustomerType => _selectedCustomerType;

  String? get selectedFilter => _selectedFilter;

  String get expectedDeliveryDate => _expectedDeliveryDate;

  String get paymentDateTime => _paymentDateTime;

  String get normalDate => _normalDate;

  bool isConfirm = false;
  bool isCancel = false;
  bool isUpdating = false;

  void setUpdating(bool status) {
    isUpdating = status;
    notifyListeners();
  }

  void setConfirmStatus(bool status) {
    isConfirm = status;
    notifyListeners();
  }

  void setCancelStatus(bool status) {
    isCancel = status;
    notifyListeners();
  }

  void updateDate(String date) {
    _normalDate = date;
    notifyListeners();
  }

  void updateExpectedDeliveryDate(String date) {
    _expectedDeliveryDate = date;
    notifyListeners();
  }

  void updatePaymentDateTime(String dateTime) {
    _paymentDateTime = dateTime;
    notifyListeners();
  }

  // Method to set the selected payment mode
  void selectPayment(String? paymentMode) {
    _selectedPayment = paymentMode;
    notifyListeners();
  }

  // Method to set an initial value for pre-filling
  void setInitialPaymentMode(String? paymentMode) {
    _selectedPayment =
        (paymentMode == null || paymentMode.isEmpty) ? null : paymentMode;
    notifyListeners();
  }

  // Method to set the selected filter
  void selectFilter(String? filter) {
    _selectedFilter = filter;
    notifyListeners();
  }

  // Method to set an initial value for pre-filling
  void setInitialFilter(String? filter) {
    _selectedFilter = (filter == null || filter.isEmpty) ? null : filter;
    notifyListeners();
  }

  // Method to set the selected Marketplace
  void selectMarketplace(String? marketplace) {
    _selectedMarketplace = marketplace;
    notifyListeners();
  }

  void selectOrderType(String? orderType) {
    _selectedOrderType = orderType;
    notifyListeners();
  }

  void selectCustomerType(String? customerType) {
    _selectedCustomerType = customerType;
    notifyListeners();
  }

  // Method to set an initial value for pre-filling
  void setInitialMarketplace(String? marketplace) {
    _selectedMarketplace =
        (marketplace == null || marketplace.isEmpty) ? null : marketplace;
    notifyListeners();
  }

  // Method to set the selected courier
  void selectCourier(String? courier) {
    _selectedCourier = courier;
    notifyListeners();
  }

  // Method to set an initial value for pre-filling
  void setInitialCourier(String? courier) {
    _selectedCourier = (courier == null || courier.isEmpty) ? null : courier;
    notifyListeners();
  }

  // New method to reset selections and counts
  void resetSelections() {
    allSelected = false;
    // allSelectedFailed = false;

    selectedOrders.fillRange(0, selectedOrders.length, false);
    // selectedFailedOrders.fillRange(0, selectedFailedOrders.length, false);

    // Reset counts
    selectedItemsCount = 0;
    // selectedFailedItemsCount = 0;

    notifyListeners();
  }

  Future<void> fetchOrders({int page = 1, DateTime? date}) async {
    log('date: $date');
    // Ensure the requested page number is valid
    if (page < 1 || page > totalReadyPages) {
      print('Invalid page number for orders: $page');
      return; // Exit if the page number is invalid
    }

    isLoading = true;
    notifyListeners();

    String readyOrdersUrl =
        '${await Constants.getBaseUrl()}/orders/getHoldOrders?page=$page';

    if (date != null) {
      String formattedDate = DateFormat('yyyy-MM-dd').format(date);
      readyOrdersUrl += '&date=$formattedDate';
    }

    log("routing url: $readyOrdersUrl");

    // Get the auth token
    final token = await _getToken();

    // Check if the token is valid
    if (token == null || token.isEmpty) {
      isLoading = false;
      notifyListeners();
      log('Token is missing. Please log in again.');
      return; // Stop execution if there's no token
    }

    try {
      // Fetch ready orders
      final response = await http.get(Uri.parse(readyOrdersUrl), headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      });

      log('status: ${response.statusCode}');
      // log('body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        readyOrders = (jsonData['orders'] as List)
            .map((order) => Order.fromJson(order))
            .toList();
        totalReadyPages = jsonData['totalPages'] ?? 1; // Update total pages
        currentPageReady = page; // Update the current page for ready orders

        log("routing orders: $readyOrders");

        // Reset selections
        resetSelections();
        _selectedOrders = List<bool>.filled(readyOrders.length, false);
        readyOrders = readyOrders;
      } else {
        throw Exception('Failed to load orders: ${response.body}');
      }
    } catch (e) {
      log('Error fetching orders: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<String> routeOrders(
      BuildContext context, List<String> orderIds) async {
    String baseUrl = await Constants.getBaseUrl();
    String url = '$baseUrl/orders/updateHoldOrders';
    final String? token = await _getToken();
    setConfirmStatus(true);
    notifyListeners();

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
    });

    log('route: $url');

    try {
      // Make the POST request to confirm the orders
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: body,
      );

      log('Response status: ${response.statusCode}');
      //print('Response body: ${response.body}');

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        // After successful confirmation, fetch updated orders and notify listeners
        await fetchOrders(); // Assuming fetchOrders is a function that reloads the orders
        resetSelections(); // Clear selected order IDs
        setConfirmStatus(false);
        notifyListeners(); // Notify the UI to rebuild

        return responseData['message'] + "$orderIds" ??
            'Orders Confirmed successfully';
      } else {
        return responseData['message'] ?? 'Failed to route orders';
      }
    } catch (error) {
      setConfirmStatus(false);
      notifyListeners();
      Logger().e('Error during API request: $error');
      return 'An error occurred: $error';
    } finally {
      setConfirmStatus(false);
      notifyListeners();
    }
  }

  void toggleSelectAllReady(bool isSelected) {
    allSelected = isSelected;
    selectedItemsCount = isSelected
        ? readyOrders.length
        : 0; // Update count based on selection state
    _selectedOrders = List<bool>.filled(
        readyOrders.length, isSelected); // Update selection list

    notifyListeners();
  }

  void toggleOrderSelectionReady(bool value, int index) {
    if (index >= 0 && index < _selectedOrders.length) {
      _selectedOrders[index] = value;
      selectedItemsCount = _selectedOrders
          .where((selected) => selected)
          .length; // Update count of selected items

      // Check if all selected
      allSelected = selectedItemsCount == readyOrders.length;

      notifyListeners();
    }
  }

  void _showSnackbar(BuildContext context, String message) {
    final snackBar = SnackBar(content: Text(message));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }

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

  void clearSearchResults() {
    readyOrders = readyOrders;
    notifyListeners();
  }

  Future<void> searchOrders(String orderId) async {
    final url = Uri.parse(
        '${await Constants.getBaseUrl()}/orders/getHoldOrders?order_id=$orderId');
    final token = await _getToken();
    if (token == null) return;

    try {
      isLoading = true;
      notifyListeners();

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        log('data: $data');
        readyOrders = [Order.fromJson(data)];
        // log('readyOrders: $readyOrders');
      } else {
        readyOrders = [];
      }
    } catch (e) {
      log('Search ready orders error: $e');
      readyOrders = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchOrdersByMarketplace(String marketplace, int page,
      {DateTime? date}) async {
    String baseUrl = await Constants.getBaseUrl();

    // Build URL with base parameters
    String url =
        '$baseUrl/orders/getHoldOrders?marketplace=$marketplace&page=$page';

    // Add date parameter if provided
    if (date != null || date == 'Select Date') {
      String formattedDate = DateFormat('yyyy-MM-dd').format(date!);
      url += '&date=$formattedDate';
    }

    log("url: $url");

    String? token =
        await _getToken(); // Assuming you have a method to get the token
    if (token == null) {
      print('Token is null, unable to fetch orders.');
      return;
    }

    try {
      isLoading = true;
      notifyListeners();

      // Clear checkboxes when a new page is fetched
      // clearSearchResults();

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

        Logger().e("length: ${orders.length}");

        readyOrders = orders;
        currentPageReady = page; // Track current page for B2B
        totalReadyPages =
            jsonResponse['totalPages']; // Assuming API returns total pages
        notifyListeners();
      } else if (response.statusCode == 401) {
        print('Unauthorized access - Token might be expired or invalid.');
      } else if (response.statusCode == 404) {
        readyOrders = [];
        notifyListeners();

        print('Orders not found - Check the filter type.');
      } else {
        throw Exception('Failed to load orders: ${response.statusCode}');
      }
    } catch (e) {
      log('Error fetching orders: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
