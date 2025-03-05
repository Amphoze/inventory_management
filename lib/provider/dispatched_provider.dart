import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:inventory_management/Custom-Files/colors.dart';
import 'package:inventory_management/constants/constants.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../model/orders_model.dart';

class DispatchedProvider with ChangeNotifier {
  bool isLoading = false;
  bool selectAll = false;
  List<bool> selectedProducts = [];
  List<Order> orders0 = [];
  int currentPage = 1; // Ensure this starts at 1
  int totalPages = 1;
  final PageController pageController = PageController();
  final TextEditingController textEditingController = TextEditingController();
  Timer? debounce;

  // bool get selectAll => selectAll;
  // List<bool> get selectedProducts => selectedProducts;
  List<Order> get orders => orders0;
  // bool get isLoading => isLoading;

  // int get currentPage => currentPage;
  // int get totalPages => totalPages;
  // PageController get pageController => pageController;
  // TextEditingController get textEditingController => textEditingController;

  int get selectedCount => selectedProducts.where((isSelected) => isSelected).length;

  bool isRefreshingOrders = false;

  void setRefreshingOrders(bool value) {
    isRefreshingOrders = value;
    notifyListeners();
  }

  void toggleSelectAll(bool value) {
    selectAll = value;
    selectedProducts = List<bool>.generate(orders0.length, (index) => selectAll);
    notifyListeners();
  }

  bool isCancel = false;
  void setCancelStatus(bool status) {
    isCancel = status;
    notifyListeners();
  }

  Future<String> cancelOrders(BuildContext context, List<String> orderIds) async {
    String baseUrl = await Constants.getBaseUrl();
    String cancelOrderUrl = '$baseUrl/orders/cancel';
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

  Future<void> fetchOrdersWithStatus9() async {
    isLoading = true;
    setRefreshingOrders(true);
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken') ?? '';
    final warehouseId = prefs.getString('warehouseId') ?? '';

    String url = '${await Constants.getBaseUrl()}/orders?warehouse=$warehouseId&orderStatus=9&page=';

    try {
      final response = await http.get(Uri.parse('$url$currentPage'), headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        log("dispatch data: $data");
        List<Order> orders = (data['orders'] as List).map((order) => Order.fromJson(order)).toList();
        // initializeSelection();

        totalPages = data['totalPages']; // Get total pages from response
        orders0 = orders; // Set the orders for the current page

        Logger().e(orders);

        // Initialize selected products list
        selectedProducts = List<bool>.filled(orders0.length, false);

        // Logger().e(_selectedProducts);
        // Print the total number of orders fetched from the current page
        print('Total Orders Fetched from Page $currentPage: ${orders.length}');
      } else {
        // Handle non-success responses

        orders0 = [];
        totalPages = 1; // Reset total pages if there’s an error
      }
    } catch (e) {
      // Handle errors
      log(e.toString());
      orders0 = [];
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
  List<bool> selectedDispatchedItems = []; // Selection state for returned orders
  bool selectAllDispatched = false;

  void initializeSelection() {
    selectedProducts = List<bool>.filled(orders0.length, false);
    selectedDispatchedItems = List<bool>.filled(ordersDispatched.length, false);
  }

  // Handle individual row checkbox change for orders
  void handleRowCheckboxChange(int index, bool isSelected) {
    selectedProducts[index] = isSelected;
    notifyListeners();
  }

  // Handle individual row checkbox change for returned orders
  void handleRowCheckboxChangeForDispatched(String? orderId, bool isSelected) {
    int index = ordersDispatched.indexWhere((order) => order.orderId == orderId);
    if (index != -1) {
      selectedDispatchedItems[index] = isSelected;
      ordersDispatched[index].isSelected = isSelected;
      updateSelectAllStateForDispatched();
    }
    notifyListeners();
  }

  void updateSelectAllStateForDispatched() {
    selectAllDispatched = selectedDispatchedItems.every((item) => item);
    notifyListeners();
  }

  bool isDispatching = false;
  // bool get isDispatching => isDispatching;

  Future<void> returnSelectedOrders() async {
    isDispatching = true; // Set loading state
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken') ?? '';

    List<String> selectedOrderIds = [];

    // Collect the IDs of orders where trackingStatus is 'NA' (null or empty)
    for (int i = 0; i < selectedProducts.length; i++) {
      if (selectedProducts[i] && (orders0[i].trackingStatus?.isEmpty ?? true)) {
        selectedOrderIds.add(orders0[i].orderId);
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
          for (int i = 0; i < orders0.length; i++) {
            if (selectedProducts[i] && (orders0[i].trackingStatus?.isEmpty ?? true)) {
              orders0[i].trackingStatus = 'return'; // Update locally
            }
          }

          notifyListeners(); // Refresh UI
        } else {
          print('Failed to return orders: ${response.body}');
        }
      } catch (e) {
        print('Error: $e');
      } finally {
        isDispatching = false; // Reset loading state
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
        fetchOrdersWithStatus9();
      } else {
        searchOrders(query); // Trigger the search after the debounce period
      }
    });
  }

  Future<List<Order>> searchOrders(String query) async {
    if (query.isEmpty) {
      await fetchOrdersWithStatus9();
      return orders0;
    }

    isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken') ?? '';
    final warehouseId = prefs.getString('warehouseId') ?? '';

    final url = '${await Constants.getBaseUrl()}/orders?warehouse=$warehouseId&orderStatus=9&order_id=$query';

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

        orders0 = orders;
        print('Orders fetched: ${orders.length}');
      } else {
        print('Failed to load orders: ${response.statusCode}');
        orders0 = [];
      }
    } catch (error) {
      print('Error searching failed orders: $error');
      orders0 = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }

    return orders0;
  }

  Future<String> updateOrderTrackingStatus(BuildContext context, String id, String trackingStatus) async {
    String baseUrl = await Constants.getBaseUrl();
    String updateOrderUrl = '$baseUrl/orders/$id';
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
          SnackBar(content: Text(responseData['message'] ?? 'Failed to update tracking status')),
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
