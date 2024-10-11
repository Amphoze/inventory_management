import 'package:flutter/material.dart';
import 'package:inventory_management/model/orders_model.dart'; // Ensure you have the Order model defined here
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class OrdersProvider with ChangeNotifier {
  bool allSelectedReady = false;
  bool allSelectedFailed = false;
  int selectedReadyItemsCount = 0;
  int selectedFailedItemsCount = 0;
  List<bool> _selectedReadyOrders = [];
  List<bool> _selectedFailedOrders = [];
  List<Order> readyOrders = []; // List to store fetched ready orders
  List<Order> failedOrders = []; // List to store fetched failed orders

  int currentPage = 1;
  int totalPages = 1;

  // Loading state
  bool isLoading = false;

  // Public getters for selected orders
  List<bool> get selectedFailedOrders => _selectedFailedOrders;
  List<bool> get selectedReadyOrders => _selectedReadyOrders;

  List<Order> _failedOrder = [];

  List<Order> get failedOrder => _failedOrder;

  // New method to reset selections and counts
  void resetSelections() {
    allSelectedReady = false;
    allSelectedFailed = false;

    selectedReadyOrders.fillRange(0, selectedReadyOrders.length, false);
    selectedFailedOrders.fillRange(0, selectedFailedOrders.length, false);

    // Reset counts
    selectedReadyItemsCount = 0;
    selectedFailedItemsCount = 0;

    notifyListeners();
  }

  Future<void> fetchOrders() async {
    isLoading = true; // Set loading state to true
    notifyListeners(); // Notify listeners about loading state

    final String failedOrdersUrlBase =
        'https://inventory-management-backend-s37u.onrender.com/orders?orderStatus=0&page=';
    final String readyOrdersUrlBase =
        'https://inventory-management-backend-s37u.onrender.com/orders?orderStatus=1&page=';

    int page = 1; // Start fetching from page 1
    bool hasMoreFailedOrders =
        true; // Flag to check if more failed orders exist
    bool hasMoreReadyOrders = true; // Flag to check if more ready orders exist

    failedOrders.clear(); // Clear existing orders before fetching
    readyOrders.clear(); // Clear existing orders before fetching

    try {
      // Fetch failed orders
      while (hasMoreFailedOrders) {
        final response = await http.get(Uri.parse('$failedOrdersUrlBase$page'));

        if (response.statusCode == 200) {
          final Map<String, dynamic> jsonData = json.decode(response.body);
          final List<dynamic> ordersJson = jsonData['orders'];

          if (ordersJson.isEmpty) {
            hasMoreFailedOrders = false; // No more failed orders to fetch
          } else {
            failedOrders.addAll(ordersJson
                .map((orderJson) => Order.fromJson(orderJson))
                .toList());
            page++; // Go to the next page
          }
        } else {
          print('No More Pages for Failed Orders');
          hasMoreFailedOrders = false; // Stop fetching on error
        }
      }

      // Reset the page counter for ready orders
      page = 1;

      // Fetch ready orders
      while (hasMoreReadyOrders) {
        final response = await http.get(Uri.parse('$readyOrdersUrlBase$page'));

        if (response.statusCode == 200) {
          final Map<String, dynamic> jsonData = json.decode(response.body);
          final List<dynamic> ordersJson = jsonData['orders'];

          if (ordersJson.isEmpty) {
            hasMoreReadyOrders = false; // No more ready orders to fetch
          } else {
            readyOrders.addAll(ordersJson
                .map((orderJson) => Order.fromJson(orderJson))
                .toList());
            page++; // Go to the next page
          }
        } else {
          print('No More Pages in Ready to confirm');
          hasMoreReadyOrders = false; // Stop fetching on error
        }
      }

      // Initialize selection states
      _selectedFailedOrders = List<bool>.filled(failedOrders.length, false);
      _selectedReadyOrders = List<bool>.filled(readyOrders.length, false);

      // Reset counts
      selectedFailedItemsCount = 0;
      selectedReadyItemsCount = 0;

      notifyListeners(); // Notify listeners of changes
    } catch (e) {
      print('Error fetching orders: $e'); // Log any exception
    } finally {
      isLoading = false; // Set loading state to false
      notifyListeners(); // Notify listeners about loading state
    }
  }

  Future<String> confirmOrders(
      BuildContext context, List<String> orderIds) async {
    const String baseUrl =
        'https://inventory-management-backend-s37u.onrender.com';
    const String confirmOrderUrl = '$baseUrl/orders/confirm';
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
    });

    try {
      // Make the POST request to confirm the orders
      final response = await http.post(
        Uri.parse(confirmOrderUrl),
        headers: headers,
        body: body,
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        // After successful confirmation, fetch updated orders and notify listeners
        await fetchOrders(); // Assuming fetchOrders is a function that reloads the orders
        resetSelections(); // Clear selected order IDs
        notifyListeners(); // Notify the UI to rebuild

        return responseData['message'] ?? 'Orders confirmed successfully';
      } else {
        return responseData['message'] ?? 'Failed to confirm orders';
      }
    } catch (error) {
      print('Error during API request: $error');
      return 'An error occurred: $error';
    }
  }

  void toggleSelectAllReady(bool isSelected) {
    allSelectedReady = isSelected;
    selectedReadyItemsCount = isSelected
        ? readyOrders.length
        : 0; // Update count based on selection state
    _selectedReadyOrders = List<bool>.filled(
        readyOrders.length, isSelected); // Update selection list

    notifyListeners();
  }

  void toggleSelectAllFailed(bool isSelected) {
    allSelectedFailed = isSelected;
    selectedFailedItemsCount = isSelected
        ? failedOrders.length
        : 0; // Update count based on selection state
    _selectedFailedOrders = List<bool>.filled(
        failedOrders.length, isSelected); // Update selection list

    notifyListeners();
  }

  void toggleOrderSelectionFailed(bool value, int index) {
    if (index >= 0 && index < _selectedFailedOrders.length) {
      _selectedFailedOrders[index] = value;
      selectedFailedItemsCount = _selectedFailedOrders
          .where((selected) => selected)
          .length; // Update count of selected items

      // Check if all selected
      allSelectedFailed = selectedFailedItemsCount == failedOrders.length;

      notifyListeners();
    }
  }

  void toggleOrderSelectionReady(bool value, int index) {
    if (index >= 0 && index < _selectedReadyOrders.length) {
      _selectedReadyOrders[index] = value;
      selectedReadyItemsCount = _selectedReadyOrders
          .where((selected) => selected)
          .length; // Update count of selected items

      // Check if all selected
      allSelectedReady = selectedReadyItemsCount == readyOrders.length;

      notifyListeners();
    }
  }

  // Update status for failed orders
  Future<void> updateFailedOrders(BuildContext context) async {
    final List<String> failedOrderIds = failedOrders
        .asMap()
        .entries
        .where((entry) => _selectedFailedOrders[entry.key])
        .map((entry) => entry.value.orderId!)
        .toList();

    if (failedOrderIds.isEmpty) {
      _showSnackbar(context, 'No orders selected to update.');
      return;
    }

    for (String orderId in failedOrderIds) {
      await updateOrderStatus(
          context, orderId, 1); // Update status to 1 for failed orders
    }

    // Reload orders after updating
    await fetchOrders(); // Refresh the orders after update

    // Reset checkbox states
    allSelectedFailed = false; // Reset "Select All" checkbox
    _selectedFailedOrders =
        List<bool>.filled(failedOrders.length, false); // Reset selection list
    selectedFailedItemsCount = 0; // Reset selected items count

    notifyListeners(); // Notify listeners to update UI
  }

// Update status for ready-to-confirm orders
  Future<void> updateReadyToConfirmOrders(BuildContext context) async {
    final List<String> readyOrderIds = readyOrders
        .asMap()
        .entries
        .where((entry) => _selectedReadyOrders[entry.key])
        .map((entry) => entry.value.orderId!)
        .toList();

    if (readyOrderIds.isEmpty) {
      _showSnackbar(context, 'No orders selected to update.');
      return;
    }

    for (String orderId in readyOrderIds) {
      await updateOrderStatus(context, orderId,
          2); // Update status to 2 for ready-to-confirm orders
    }

    // Reload orders after updating
    await fetchOrders(); // Refresh the orders after update

    // Reset checkbox states
    allSelectedReady = false; // Reset "Select All" checkbox
    _selectedReadyOrders =
        List<bool>.filled(readyOrders.length, false); // Reset selection list
    selectedReadyItemsCount = 0; // Reset selected items count

    notifyListeners(); // Notify listeners to update UI
  }

  // Existing updateOrderStatus function
  Future<void> updateOrderStatus(
      BuildContext context, String orderId, int newStatus) async {
    final String? token = await _getToken();
    if (token == null) {
      _showSnackbar(context, 'No auth token found');
      return;
    }

    // Define the URL for the update with query parameters
    final String url =
        'https://inventory-management-backend-s37u.onrender.com/orders?orderId=$orderId&status=$newStatus';

    // Set up the headers for the request
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    try {
      // Make the PUT request
      final response = await http.put(
        Uri.parse(url),
        headers: headers,
      );

      if (response.statusCode == 200) {
        // Show snackbar and trigger fetchOrders in parallel
        _showSnackbar(context, 'Order status updated successfully');
        // Reload orders immediately after the snackbar is shown
        fetchOrders(); // Refresh the orders
      } else {
        final errorResponse = json.decode(response.body);
        String errorMessage =
            errorResponse['message'] ?? 'Failed to update order status';
        _showSnackbar(context, errorMessage);
        throw Exception(
            'Failed to update order status: ${response.statusCode} ${response.body}');
      }
    } catch (error) {
      _showSnackbar(
          context, 'An error occurred while updating the order status: $error');
      throw Exception(
          'An error occurred while updating the order status: $error');
    }
  }

  // Method to display a snackbar
  void _showSnackbar(BuildContext context, String message) {
    final snackBar = SnackBar(content: Text(message));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  // Method to get the token from shared preferences
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }

  // Format date
  String formatDate(DateTime date) {
    String year = date.year.toString();
    String month = date.month.toString().padLeft(2, '0');
    String day = date.day.toString().padLeft(2, '0');
    return '$day-$month-$year';
  }

  Future<List<Order>> searchFailedOrder(String searchTerm) async {
    final String? token = await _getToken(); // Retrieve the token

    if (token == null) {
      throw Exception('No auth token found');
    }

    // Modify the URL to just search by the searchTerm with status 0
    final url =
        'https://inventory-management-backend-s37u.onrender.com/orders?orderStatus=0&order_id=$searchTerm'; // Search term and status 0

    print('Searching failed orders with term: $searchTerm'); // Debugging print

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('Response status: ${response.statusCode}'); // Print the status code

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        print(
            'Response data: $jsonData'); // Print the entire JSON response for debugging

        // Check if the response is a single order object
        List<Order> orders = [];
        if (jsonData != null) {
          // Directly create an Order instance from the response
          orders.add(Order.fromJson(jsonData)); // Add the order to the list
        } else {
          print('No data found in response.'); // Handle null data
        }

        print(
            'Orders fetched: ${orders.length}'); // Print the number of fetched orders
        notifyListeners();

        return orders; // Return the list containing the single order
      } else {
        throw Exception('Failed to load orders: ${response.statusCode}');
      }
    } catch (error) {
      print('Error searching failed orders: $error'); // Print error details
      return [];
    }
  }

  Future<void> searchReadyToConfirmOrder(String searchTerm) async {
    final List<Order> results = await searchReadyToConfirmOrders(searchTerm);
    readyOrders = results; // Update the list of ready orders
    notifyListeners(); // Notify listeners to rebuild UI
  }

  Future<void> searchFailedOrders(String searchTerm) async {
    final List<Order> results = await searchFailedOrder(searchTerm);
    failedOrders = results; // Update the list of failed orders
    notifyListeners(); // Notify listeners to rebuild UI
  }

  Future<List<Order>> searchReadyToConfirmOrders(String searchTerm) async {
    final String? token = await _getToken(); // Retrieve the token

    if (token == null) {
      throw Exception('No auth token found');
    }

    final url =
        'https://inventory-management-backend-s37u.onrender.com/orders?order_id=$searchTerm'; // No status in URL

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        print(jsonData); // Print the entire JSON response to debug

        // Assuming the list is under a key like 'orders'
        final List<dynamic> ordersList =
            jsonData['orders']; // Adjust 'orders' to the actual key
        List<Order> orders =
            List<Order>.from(ordersList.map((item) => Order.fromJson(item)));
        print("Hello i am ${orders.toList()}");
        return orders;
      } else {
        throw Exception('Failed to load orders: ${response.statusCode}');
      }
    } catch (error) {
      print('Error searching ready-to-confirm orders: $error');
      return [];
    }
  }
}