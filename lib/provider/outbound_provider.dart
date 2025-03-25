import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:inventory_management/constants/constants.dart';
import 'package:inventory_management/model/orders_model.dart'; // Ensure you have the Order model defined here
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OutboundProvider with ChangeNotifier {
  bool allSelectedReady = false;
  int selectedReadyItemsCount = 0;

  List<bool> _selectedReadyOrders = [];
  List<Order> _outboundOrders = [];
  int _totalReadyPages = 1;
  int _currentPageReady = 1;
  String? _selectedPayment;
  String? _selectedFilter;
  String? _selectedOrderType;
  String? _selectedCustomerType;
  String _expectedDeliveryDate = '';
  String _paymentDateTime = '';
  String _normalDate = '';
  final String _sanitizedEmail = '';
  int? dispatchCount;
  int? rtoCount;
  int? allCount;
  late TextEditingController searchController;

  String selectedDate = 'Select Date';
  String selectedCourier = 'All';
  DateTime? picked;

  bool isLoading = false;

  List<bool> get selectedReadyOrders => _selectedReadyOrders;
  String? get selectedPayment => _selectedPayment;
  String? get selectedOrderType => _selectedOrderType;
  String? get selectedCustomerType => _selectedCustomerType;
  String? get selectedFilter => _selectedFilter;
  String get expectedDeliveryDate => _expectedDeliveryDate;
  String get paymentDateTime => _paymentDateTime;
  String get normalDate => _normalDate;
  String get sanitizedEmail => _sanitizedEmail;

  int get currentPageReady => _currentPageReady;
  List<Order> get outboundOrders => _outboundOrders;
  int get totalReadyPages => _totalReadyPages;

  bool isConfirm = false;
  bool isCancel = false;
  bool isUpdating = false;

  void resetOrderData() {
    _outboundOrders = [];
    _currentPageReady = 1;
    _totalReadyPages = 1;
    notifyListeners();
  }

  void resetFilter() {
    selectedCourier = 'All';
    selectedDate = 'Select Date';
    picked = null;
    notifyListeners();
  }

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

  void selectPayment(String? paymentMode) {
    _selectedPayment = paymentMode;
    notifyListeners();
  }

  void setInitialPaymentMode(String? paymentMode) {
    _selectedPayment = (paymentMode == null || paymentMode.isEmpty) ? null : paymentMode;
    notifyListeners();
  }

  void selectFilter(String? filter) {
    _selectedFilter = filter;
    notifyListeners();
  }

  void setInitialFilter(String? filter) {
    _selectedFilter = (filter == null || filter.isEmpty) ? null : filter;
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

  void resetSelections() {
    allSelectedReady = false;
    // allSelectedFailed = false;

    selectedReadyOrders.fillRange(0, selectedReadyOrders.length, false);
    // selectedFailedOrders.fillRange(0, selectedFailedOrders.length, false);

    // Reset counts
    selectedReadyItemsCount = 0;
    // selectedFailedItemsCount = 0;

    notifyListeners();
  }

  Future<bool> mergeOrders(BuildContext context, String mergeFrom, String mergeTo) async {
    String baseUrl = await Constants.getBaseUrl();
    String mergeOrderUrl = '$baseUrl/orders/mergeOrder';
    final String? token = await _getToken();

    if (token == null) {
      return false;
    }

    // Headers for the API request
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    // Request body containing the order IDs
    final body = json.encode({
      'mergeFrom': mergeFrom,
      'mergeTo': mergeTo,
    });

    try {
      // Make the POST request to confirm the orders
      final response = await http.post(
        Uri.parse(mergeOrderUrl),
        headers: headers,
        body: body,
      );

      log('Response status: ${response.statusCode}');
      log('data: ${response.body}');
      //print('Response body: ${response.body}');

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        _showSnackbar(context, '${responseData['message']}');
        return true;
      } else {
        _showSnackbar(context, '${responseData['message']}');
        return false;
      }
    } catch (error) {
      log('error in catch: $error');
      _showSnackbar(context, 'Response message: $error');
      return false;
    }
  }

  Future<void> updateOrder(String id, Map<String, dynamic> updatedData) async {
    // Get the auth token
    final token = await _getToken();

    // Check if the token is valid
    if (token == null || token.isEmpty) {
      isLoading = false;
      notifyListeners();
      print('Token is missing. Please log in again.');
      return;
    }

    final url = '${await Constants.getBaseUrl()}/orders/$id';
    try {
      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(updatedData),
      );

      log("response: ${response.statusCode}");

      if (response.statusCode == 200) {
        Logger().e('Order updated successfully');

        await fetchOrders();

        notifyListeners();
      } else if (response.statusCode == 400) {
        final responseBody = json.decode(response.body);
        if (responseBody['message'] == 'orderId and status are required.') {
          log('Error: Order ID and status are required.');
        }
      } else {
        log('Failed to update order: ${response.body}');
        return;
      }
    } catch (error) {
      log('Error updating order: $error');
      rethrow;
    }
    notifyListeners();
  }

  Future<void> fetchOrders({int page = 1}) async {
    searchController.clear();
    dispatchCount = rtoCount = allCount = null;
    if (page < 1 || page > totalReadyPages) {
      print('Invalid page number for ready orders: $page');
      return;
    }

    // if(searchController.text.trim().isNotEmpty) {
    //   searchOrdersByID(searchController.text.trim());
    //   return;
    // }

    isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final warehouseId = prefs.getString('warehouseId') ?? '';

    var readyOrdersUrl = '${await Constants.getBaseUrl()}/orders?isOutBound=false&page=$page';

    if (picked != null) {
      String formattedDate = DateFormat('yyyy-MM-dd').format(picked!);
      readyOrdersUrl += '&date=$formattedDate';
    }

    if (selectedCourier != 'All') {
      readyOrdersUrl += '&marketplace=$selectedCourier';
    } else {
      readyOrdersUrl += '&marketplace=Shopify,Woocommerce';
    }

    log("fetchOrders outbound: $readyOrdersUrl");

    final token = await _getToken();

    // Check if the token is valid
    if (token == null || token.isEmpty) {
      isLoading = false;
      notifyListeners();
      print('Token is missing. Please log in again.');
      return; // Stop execution if there's no token
    }

    try {
      // Fetch ready orders
      final responseReady = await http.get(Uri.parse(readyOrdersUrl), headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      });

      if (responseReady.statusCode == 200) {
        final jsonData = json.decode(responseReady.body);
        final orders = (jsonData['orders'] as List).map((order) => Order.fromJson(order)).toList();
        // outboundOrders = orders;
        _outboundOrders = orders;
        _totalReadyPages = jsonData['totalPages'] ?? 1; // Update total pages
        _currentPageReady = page; // Update the current page for ready orders

        // log("readyOrders: $readyOrders");

        // Reset selections
        resetSelections();
        _selectedReadyOrders = List<bool>.filled(outboundOrders.length, false);
        // outboundOrders = outboundOrders;
      } else {
        resetOrderData();
        log('Failed to load ready orders: ${responseReady.body}');
        throw Exception('Failed to load ready orders: ${responseReady.body}');
      }
    } catch (e) {
      resetOrderData();
      log('Error fetching ready orders: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<String> approveOrders(BuildContext context, List<String> orderIds) async {
    String baseUrl = await Constants.getBaseUrl();
    String confirmOrderUrl = '$baseUrl/orders/outBound';
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

    try {
      // Make the POST request to confirm the orders
      final response = await http.post(
        Uri.parse(confirmOrderUrl),
        headers: headers,
        body: body,
      );

      print('Response status: ${response.statusCode}');
      log('data: ${response.body}');
      //print('Response body: ${response.body}');

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        // After successful confirmation, fetch updated orders and notify listeners
        await fetchOrders(); // Assuming fetchOrders is a function that reloads the orders
        resetSelections(); // Clear selected order IDs
        setConfirmStatus(false);
        notifyListeners(); // Notify the UI to rebuild

        return responseData['message'] + "$orderIds" ?? 'Orders Confirmed successfully';
      } else {
        return responseData['message'] ?? 'Failed to confirm orders';
      }
    } catch (error) {
      setConfirmStatus(false);
      notifyListeners();
      Logger().e('Error during API request: $error');
      return 'An error occurred: $error';
    }
  }

  Future<String> cancelOrders(BuildContext context, List<String> orderIds) async {
    String baseUrl = await Constants.getBaseUrl();
    String cancelOrderUrl = '$baseUrl/orders?isOutBound=false';
    final String? token = await _getToken();
    setCancelStatus(true);
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
        await fetchOrders(); // Assuming fetchOrders is a function that reloads the orders
        resetSelections(); // Clear selected order IDs
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

  void toggleSelectAllReady(bool isSelected) {
    allSelectedReady = isSelected;
    selectedReadyItemsCount = isSelected ? outboundOrders.length : 0; // Update count based on selection state
    _selectedReadyOrders = List<bool>.filled(outboundOrders.length, isSelected); // Update selection list

    notifyListeners();
  }

  void toggleOrderSelectionReady(bool value, int index) {
    Logger().e('toggleOrderSelectionReady: $value, $index');
    if (index >= 0 && index < _selectedReadyOrders.length) {
      _selectedReadyOrders[index] = value;
      selectedReadyItemsCount = _selectedReadyOrders.where((selected) => selected).length; // Update count of selected items

      // Check if all selected
      allSelectedReady = selectedReadyItemsCount == outboundOrders.length;

      notifyListeners();
    }
  }

  // Update status for failed orders

// Update status for ready-to-confirm orders
  Future<void> updateOutboundOrders(BuildContext context) async {
    final List<String> readyOrderIds =
        outboundOrders.asMap().entries.where((entry) => _selectedReadyOrders[entry.key]).map((entry) => entry.value.orderId).toList();

    if (readyOrderIds.isEmpty) {
      _showSnackbar(context, 'No orders selected to update.');
      return;
    }

    for (String orderId in readyOrderIds) {
      await updateOrderStatus(context, orderId, 2); // Update status to 2 for ready-to-confirm orders
    }

    // Reload orders after updating
    await fetchOrders(); // Refresh the orders after update

    // Reset checkbox states
    allSelectedReady = false; // Reset "Select All" checkbox
    _selectedReadyOrders = List<bool>.filled(outboundOrders.length, false); // Reset selection list
    selectedReadyItemsCount = 0; // Reset selected items count

    notifyListeners(); // Notify listeners to update UI
  }

  // Existing updateOrderStatus function
  Future<void> updateOrderStatus(BuildContext context, String orderId, int newStatus) async {
    final String? token = await _getToken();
    if (token == null) {
      _showSnackbar(context, 'No auth token found');
      return;
    }

    // Define the URL for the update with query parameters
    final String url = '${await Constants.getBaseUrl()}/orders?order_id=$orderId&status=$newStatus';

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
        _showSnackbar(context, 'Order status updated successfully with $orderId');

        await fetchOrders(); // Refresh ready orders
      } else {
        final errorResponse = json.decode(response.body);
        String errorMessage = errorResponse['message'] ?? 'Failed to update order status';
        _showSnackbar(context, errorMessage);
        throw Exception('Failed to update order status: ${response.statusCode} ${response.body}');
      }
    } catch (error) {
      _showSnackbar(context, 'An error occurred while updating the order status: $error');
      throw Exception('An error occurred while updating the order status: $error');
    }
  }

  // Method to display a snackbar
  void _showSnackbar(BuildContext context, String message, {Color color = Colors.black}) {
    final snackBar = SnackBar(
      content: Text(message),
      backgroundColor: color,
    );
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
    _outboundOrders = [];
    notifyListeners();
  }

  Future<void> searchOrdersByID(String orderId) async {
    String encodedOrderId = Uri.encodeComponent(orderId.trim());

    final prefs = await SharedPreferences.getInstance();
    final warehouseId = prefs.getString('warehouseId') ?? '';

    // log('searchOrdersByID');
    String url = '${await Constants.getBaseUrl()}/orders?marketplace=Shopify,Woocommerce&isOutBound=false&order_id=$encodedOrderId';
    final token = await _getToken();
    if (token == null) return;

    Logger().e('searchOrdersByID: $url');

    try {
      isLoading = true;
      notifyListeners();

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _outboundOrders = (data['orders'] as List).map((order) => Order.fromJson(order)).toList();
        // _outboundOrders = [Order.fromJson(data)];
      } else {
        _outboundOrders = [];
      }
    } catch (e) {
      log('Search orders error: $e');
      _outboundOrders = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> getOrdersByPhone(String phone) async {
    String url = 'https://inventory-api.ko-tech.in/orders?phone=$phone';
    final token = await _getToken();
    if (token == null) return;

    try {
      // isLoading = true;
      // notifyListeners();

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<Order> orders = (data['orders'] as List).map((orderJson) => Order.fromJson(orderJson)).toList();
        allCount = orders.length;

        List<Order> dispatchOrders = orders.where((order) => order.orderStatus == 9).toList();
        dispatchCount = dispatchOrders.length;

        List<Order> rtoOrders = orders.where((order) => order.orderStatus == 11).toList();
        rtoCount = rtoOrders.length;

        // Logger().e('all orders: $allCount');
        // Logger().e('dispatchOrders: $dispatchCount');
        // Logger().e('rtoOrders: $rtoCount');

        notifyListeners();

        // Use dispatchOrders and rtoOrders as needed
      } else {
        dispatchCount = null;
        rtoCount = null;
      }
    } catch (e) {
      log('Search orders error: $e');
      // outboundOrders = [];
      dispatchCount = null;
      rtoCount = null;
    } finally {
      // isLoading = false;
      notifyListeners();
    }
  }

  Future<void> searchOrdersByPhone(String phone) async {
    log('searchOrdersByPhone');
    final prefs = await SharedPreferences.getInstance();
    final warehouseId = prefs.getString('warehouseId') ?? '';

    String url = '${await Constants.getBaseUrl()}/orders?marketplace=Shopify,Woocommerce&isOutBound=false&phone=${phone.trim()}';
    final token = await _getToken();
    if (token == null) return;

    log('url: $url');

    try {
      isLoading = true;
      notifyListeners();

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        log('data: $data');
        _outboundOrders = (data['orders'] as List).map((order) => Order.fromJson(order)).toList();
        await getOrdersByPhone(phone);
        // dispatchCount = await getDispatchOrders(phone);
        // rtoCount = await getRtoOrders(phone);
        log('readyOrders: $outboundOrders');
      } else {
        resetOrderData();      }
    } catch (e) {
      log('Search orders error: $e');
      resetOrderData();    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> sendSingleCall(BuildContext context, String orderId) async {
    String url = '${await Constants.getBaseUrl()}/orders/call';

    final token = await _getToken();

    // final prefs = await SharedPreferences.getInstance();
    // String? email = prefs.getString('email');

    final body = {
      'order_id': orderId,
    };

    log('body hai: $body');

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: <String, String>{
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );
      log('Started Calling:');

      final res = jsonDecode(response.body);
      log('Response body: $res');

      if (response.statusCode == 200) {
        _showSnackbar(context, res['message'], color: Colors.green);
        // _showStatusDialog(context, orderId);
        log('Call Proceeded');
        return true;
      } else {
        _showSnackbar(context, res['error'], color: Colors.red);
        log('Failed to send phone number. Status code: ${response.statusCode}');
        return false;
      }
    } catch (error) {
      log('Error calling: $error');
      _showSnackbar(context, 'Error calling: $error');
      return false;
    } finally {
      notifyListeners();
    }
  }

  Future<bool> updateCallStatus(BuildContext context, String orderId, String callStatus) async {
    String url = '${await Constants.getBaseUrl()}/orders/callStatus';
    final token = await _getToken();

    if (token == null) {
      _showSnackbar(context, 'No token provided', color: Colors.red);
      return false;
    }

    final body = {
      'call_status': callStatus,
      'order_id': orderId,
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: <String, String>{
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      final res = jsonDecode(response.body);

      log('status update res: $res');

      if (response.statusCode == 200) {
        _showSnackbar(context, res['message'], color: Colors.green);
        return true;
      } else {
        _showSnackbar(context, res['error'], color: Colors.red);
        return false;
      }
    } catch (error) {
      log('Error updating call status: $error');
      _showSnackbar(context, 'Error updating call status: $error');
      return false;
    } finally {
      notifyListeners();
    }
  }

  String _selectedValue = "not answered"; // Default selected value

  void _showStatusDialog(BuildContext context, String orderId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        String tempValue = _selectedValue; // Temporary value to update inside dialog

        // enum: ["not answered", "answered", "not reach","busy"],

        return AlertDialog(
          title: const Text("Select Status"),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile(
                    title: const Text("Not Answered"),
                    value: "not answered",
                    groupValue: tempValue,
                    onChanged: (value) {
                      setState(() => tempValue = value.toString());
                    },
                  ),
                  RadioListTile(
                    title: const Text("Answered"),
                    value: "answered",
                    groupValue: tempValue,
                    onChanged: (value) {
                      setState(() => tempValue = value.toString());
                    },
                  ),
                  RadioListTile(
                    title: const Text("Unreachable"),
                    value: "not reach",
                    groupValue: tempValue,
                    onChanged: (value) {
                      setState(() => tempValue = value.toString());
                    },
                  ),
                  RadioListTile(
                    title: const Text("Busy"),
                    value: "busy",
                    groupValue: tempValue,
                    onChanged: (value) {
                      setState(() => tempValue = value.toString());
                    },
                  ),
                ],
              );
            },
          ),
          actions: [
            // TextButton(
            //   child: const Text("Cancel"),
            //   onPressed: () => Navigator.pop(context),
            // ),
            TextButton(
              child: const Text("Ok"),
              onPressed: () async {
                _selectedValue = tempValue; // Save selected value
                notifyListeners();
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return const AlertDialog(
                      content: Row(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(width: 16),
                          Text('Updating Status'),
                        ],
                      ),
                    );
                  },
                );
                final res = await updateCallStatus(context, orderId, tempValue);
                if (res) {
                  Navigator.pop(context);
                  Navigator.pop(context);
                  await fetchOrders();
                }
              },
            ),
          ],
        );
      },
    );
  }
}
