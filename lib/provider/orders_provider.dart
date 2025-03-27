import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:inventory_management/Custom-Files/utils.dart';
import 'package:inventory_management/constants/constants.dart';
import 'package:inventory_management/model/orders_model.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import '../Api/auth_provider.dart';
import '../dashboard.dart';
import 'chat_provider.dart';

class OrdersProvider with ChangeNotifier {
  bool allSelectedReady = false;
  bool allSelectedFailed = false;
  int selectedReadyItemsCount = 0;
  int selectedFailedItemsCount = 0;
  List<bool> _selectedReadyOrders = [];
  List<bool> _selectedFailedOrders = [];
  List<Order> _readyOrders = [];
  List<Order> _failedOrders = [];
  int _currentPageReady = 1;
  int _currentPageFailed = 1;
  int _totalFailedPages = 1;
  int _totalReadyPages = 1;
  String? _selectedCourier;
  String? _selectedPayment;
  String? _selectedFilter;
  String? _selectedMarketplace;
  String? _selectedOrderType;
  String? _selectedCustomerType;
  String _expectedDeliveryDate = '';
  String _paymentDateTime = '';
  String _normalDate = '';
  bool confirmOrderByCSV = false;
  String _progressMessage = '';
  IO.Socket? _socket;
  final ValueNotifier<double> progressNotifier = ValueNotifier<double>(0);
  String selectedReadyDate = 'Select Date';
  String selectedFailedDate = 'Select Date';
  String selectedReadyCourier = 'All';
  String selectedFailedCourier = 'All';
  DateTime? readyPicked, failedPicked;
  late TextEditingController searchControllerReady;
  late TextEditingController searchControllerFailed;

  String get progressMessage => _progressMessage;

  List<Order> get readyOrders => _readyOrders;
  List<Order> get failedOrders => _failedOrders;
  int get currentPageReady => _currentPageReady;
  int get totalReadyPages => _totalReadyPages;
  int get currentPageFailed => _currentPageFailed;
  int get totalFailedPages => _totalFailedPages;

  bool _isReadyLoading = false;
  bool _isFailedLoading = false;

  bool get isReadyLoading => _isReadyLoading;
  bool get isFailedLoading => _isFailedLoading;

  List<bool> get selectedFailedOrders => _selectedFailedOrders;

  List<bool> get selectedReadyOrders => _selectedReadyOrders;

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

  bool _isCloning = false;
  bool get isCloning => _isCloning;

  OrdersProvider() {
    searchControllerReady = TextEditingController();
    searchControllerFailed = TextEditingController();
  }

  void resetProgress() {
    _progressMessage = '';
    notifyListeners();
  }

  void resetReadyFilterData() {
    selectedReadyDate = 'Select Date';
    selectedReadyCourier = 'All';
    readyPicked = null;
    notifyListeners();
  }

  void resetFailedFilterData() {
    // searchControllerFailed.clear();
    selectedFailedDate = 'Select Date';
    selectedFailedCourier = 'All';
    failedPicked = null;
    notifyListeners();
  }

  void resetReady() {
    _readyOrders = [];
    _selectedReadyOrders = [];
    _currentPageReady = 1;
    _totalReadyPages = 1;
    notifyListeners();
  }

  void resetFailed() {
    _failedOrders = [];
    _selectedFailedOrders = [];
    _currentPageFailed = 1;
    _totalFailedPages = 1;
    notifyListeners();
  }

  void setCloning(bool value) {
    _isCloning = value;
    notifyListeners();
  }

  void setReadyLoading(bool value) {
    _isReadyLoading = value;
    notifyListeners();
  }

  void setFailedLoading(bool value) {
    _isFailedLoading = value;
    notifyListeners();
  }

  void toggleConfirmOrders(bool value) {
    confirmOrderByCSV = value;
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

  void selectPayment(String paymentMode) {
    _selectedPayment = paymentMode;
    notifyListeners();
  }

  void setInitialPaymentMode(String paymentMode) {
    _selectedPayment = paymentMode ?? '';
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

  void setInitialMarketplace(String? marketplace) {
    _selectedMarketplace = (marketplace == null || marketplace.isEmpty) ? null : marketplace;
    notifyListeners();
  }

  void selectCourier(String? courier) {
    _selectedCourier = courier;
    notifyListeners();
  }

  void setInitialCourier(String? courier) {
    _selectedCourier = (courier == null || courier.isEmpty) ? null : courier;
    notifyListeners();
  }

  void resetSelections() {
    allSelectedReady = false;
    allSelectedFailed = false;

    selectedReadyOrders.fillRange(0, selectedReadyOrders.length, false);
    selectedFailedOrders.fillRange(0, selectedFailedOrders.length, false);

    selectedReadyItemsCount = 0;
    selectedFailedItemsCount = 0;

    notifyListeners();
  }

  Future<Map<String, dynamic>> updateOrder(String id, Map<String, dynamic> updatedData) async {
    final token = await _getToken();

    if (token == null || token.isEmpty) {
      return {"success": false, "message": "No auth token found"};
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

      final res = jsonDecode(response.body);

      if (response.statusCode == 200) {
        Logger().e('Order updated successfully');

        notifyListeners();
        return {"success": true, "message": res['message']};
      } else if (response.statusCode == 400) {
        final responseBody = json.decode(response.body);
        if (responseBody['message'] == 'orderId and status are required.') {
          log('Error: Order ID and status are required.');
        }
      } else {
        log('Failed to update order: ${response.body}');
        return {"success": false, "message": res['message']};
      }
    } catch (error, s) {
      log('Error updating order: $error \n\n$s');
      return {"success": false, "message": "An error occurred: $error"};
    } finally {
      notifyListeners();
    }
    return {};
  }

  Future<bool> writeRemark(String id, String msg) async {
    final token = await _getToken();

    if (token == null || token.isEmpty) {
      return false;
    }

    final url = '${await Constants.getBaseUrl()}/orders?order_id=$id';

    final prefs = await SharedPreferences.getInstance();
    String? email = prefs.getString('email');

    log('Writing Remark for order id $id at URL :- $url');

    // final body = {
    //   "messages": {
    //     "confirmerMessage": msg,
    //     "timestamp": DateTime.now().toIso8601String(),
    //     "author": email ?? "Unknown",
    //   }
    // };

    final body = {
      "messages": {
        "confirmerMessage": [
          {
            "message": msg,
            "timestamp": DateTime.now().toIso8601String(),
            "author": email ?? "Unknown",
          }
        ]
      }
    };

    final payload = jsonEncode(body);

    log('Remark Payload :- $payload');

    try {
      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: payload,
      );

      if (response.statusCode == 200) {
        log('Remark Submitted Successfully :)');
        return true;
      } else {
        log('Failed to submit remark with status code ${response.statusCode} and response as ${response.body}');
        return false;
      }
    } catch (error, s) {
      log('Error submitting remark: $error\n$s');
      return false;
    } finally {
      notifyListeners();
    }
  }

  Future<void> fetchFailedOrders({int page = 1}) async {
    searchControllerFailed.clear();
    log("called");

    if (page < 1 || page > totalFailedPages) {
      return;
    }
    // if(searchControllerFailed.text.trim().isNotEmpty) {
    //   searchFailedOrders(searchControllerFailed.text.trim());
    //   return;
    // }
    setFailedLoading(true);

    final prefs = await SharedPreferences.getInstance();
    final warehouseId = prefs.getString('warehouseId') ?? '';

    var failedOrdersUrl = '${await Constants.getBaseUrl()}/orders?warehouse=$warehouseId&orderStatus=0&page=$page';

    if (failedPicked != null) {
      String formattedDate = DateFormat('yyyy-MM-dd').format(failedPicked!);
      failedOrdersUrl += '&date=$formattedDate';
    }

    if (selectedFailedCourier != 'All') {
      failedOrdersUrl += '&marketplace=$selectedFailedCourier';
    }

    final token = await _getToken();

    if (token == null || token.isEmpty) {
      setFailedLoading(false);

      return;
    }

    try {
      final responseFailed = await http.get(
        Uri.parse(failedOrdersUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (responseFailed.statusCode == 200) {
        final jsonData = json.decode(responseFailed.body);

        _failedOrders = (jsonData['orders'] as List).map((order) => Order.fromJson(order)).toList();
        _totalFailedPages = (jsonData['totalPages'] as int?) ?? 1;
        _currentPageFailed = page;

        resetSelections();
        _selectedFailedOrders = List<bool>.filled(failedOrders.length, false);
        // _failedOrders = failedOrders;
        notifyListeners();
      } else {
        resetFailed();
        log('Failed to load failed orders: ${responseFailed.body}');
      }
    } catch (e) {
      resetFailed();
      log('Error fetching failed orders: $e');
    } finally {
      setFailedLoading(false);
    }
  }

  Future<void> fetchReadyOrders({int page = 1}) async {
    // searchControllerReady.clear();
    log('fetchReadyOrders');
    if (page < 1 || page > totalReadyPages) {
      return;
    }
    // if(searchControllerReady.text.trim().isNotEmpty) {
    //   searchReadyToConfirmOrders(searchControllerReady.text.trim());
    //   return;
    // }

    setReadyLoading(true);

    final prefs = await SharedPreferences.getInstance();
    final warehouseId = prefs.getString('warehouseId') ?? '';

    var readyOrdersUrl = '${await Constants.getBaseUrl()}/orders?warehouse=$warehouseId&orderStatus=1&page=$page&find=true';

    if (readyPicked != null) {
      String formattedDate = DateFormat('yyyy-MM-dd').format(readyPicked!);
      readyOrdersUrl += '&date=$formattedDate';
    }

    if (selectedReadyCourier != 'All') {
      readyOrdersUrl += '&marketplace=$selectedReadyCourier';
    }

    log("readyOrdersUrl: $readyOrdersUrl");

    final token = await _getToken();

    if (token == null || token.isEmpty) {
      setReadyLoading(false);

      return;
    }

    try {
      final responseReady = await http.get(Uri.parse(readyOrdersUrl), headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      });

      if (responseReady.statusCode == 200) {
        final jsonData = json.decode(responseReady.body);

        List<Order> rOrders = [];

        List<dynamic> orders = jsonData['orders'] ?? [];

        for (var order in orders) {
          try {
            rOrders.add(Order.fromJson(order));
          } catch (e, s) {
            log('Error parsing order :- $e\n$s');
          }
        }

        // _readyOrders = (jsonData['orders'] as List).map((order) => Order.fromJson(order)).toList();
        _readyOrders = rOrders;
        _totalReadyPages = jsonData['totalPages'] ?? 1;
        _currentPageReady = page;

        resetSelections();
        _selectedReadyOrders = List<bool>.filled(readyOrders.length, false);

        notifyListeners();
      } else {
        resetReady();
        log('Failed to load ready orders: ${responseReady.body}');
      }
    } catch (e, s) {
      resetReady();
      log('\nError fetching ready orders: $e\n\n$s\n\n');
    } finally {
      setReadyLoading(false);
    }
  }

  Future<String> cloneOrders(BuildContext context, List<String> orderIds) async {
    String baseUrl = await Constants.getBaseUrl();
    String cloneOrderUrl = '$baseUrl/orders/clone';
    final String? token = await _getToken();
    setCloning(true);

    if (token == null) {
      setCloning(false);
      return 'No auth token found';
    }

    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    final body = json.encode({
      'orderIds': orderIds,
    });

    try {
      final response = await http.post(
        Uri.parse(cloneOrderUrl),
        headers: headers,
        body: body,
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchReadyOrders();
        resetSelections();
        return responseData['message'] + ": ${responseData['newOrders'][0]['order_id']}" ?? 'Orders clone successfully';
      } else {
        log('Cloning Response :- ${response.statusCode} ### ${response.body}');
        return responseData['message'] ?? 'Failed to clone orders';
      }
    } catch (error, s) {
      log('Cloning Error: $error\n$s');
      return 'An error occurred: $error';
    } finally {
      setCloning(false);
      notifyListeners();
    }
  }


  void initializeSocket(BuildContext context) async {
    _progressMessage = '';

    if (_socket != null && _socket!.connected) {
      log('Socket already connected. Skipping initialization.');
      return;
    }

    try {
      final baseUrl = await Constants.getBaseUrl();
      final email = await AuthProvider().getEmail();

      _socket ??= IO.io(
        baseUrl,
        IO.OptionBuilder().setTransports(['websocket']).disableAutoConnect().setQuery({'email': email}).build(),
      );

      _socket?.onConnect((_) {
        log('Connected to Socket.IO');
        _showSnackBar('Connected to server', color: Colors.green);
      });

      _socket?.on('csv-file-uploading-err', (data) {
        setConfirmStatus(false);
        _progressMessage = data['message'];
        log('CSV Error: $_progressMessage');
        _showSnackBar(_progressMessage, color: Colors.red);
      });

      _socket?.off('csv-file-uploading');
      _socket?.on('csv-file-uploading', (data) {
        setConfirmStatus(true);
        _progressMessage = data['message'];
        if (data['progress'] != null) {
          double newProgress = double.tryParse(data['progress'].toString()) ?? 0;
          progressNotifier.value = newProgress;
        }
      });

      _socket?.on('csv-file-uploaded', (data) async {
        _progressMessage = data['message'];
        log('CSV file uploaded: $data'); // This is working
        setConfirmStatus(false);
        _showSnackBar(_progressMessage, color: Colors.green); // Debug this
        resetSelections();
        await fetchReadyOrders();
      });

      _socket?.connect();
      log('Socket connection initiated');
    } catch (e) {
      log('Error in _initializeSocket: $e');
      _showSnackBar('Failed to connect to server', color: Colors.red);
    } finally {
      notifyListeners();
    }
  }

  void _showSnackBar(String message, {Color? color}) {
    log('Attempting to show SnackBar: $message');
    if (globalScaffoldKey.currentState == null) {
      log('Error: ScaffoldMessengerState is null');
      return;
    }
    log('Showing SnackBar with message: $message');
    final context = globalScaffoldKey.currentState!.context;

    Utils.showSnackBar(context, message, details: message, color: color);
  }

  @override
  void dispose() {
    _socket?.disconnect();
    _socket?.dispose();
    super.dispose();
  }

  Future<String> confirmOrders(BuildContext context, List<String> orderIds) async {
    String baseUrl = await Constants.getBaseUrl();
    String confirmOrderUrl = '$baseUrl/orders/confirm';
    final String? token = await _getToken();

    if (token == null) {
      return 'No auth token found';
    }

    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    final body = json.encode({
      'orderIds': orderIds,
    });

    log('Confirming Orders Payload :- $body');

    final url = Uri.parse(confirmOrderUrl);

    log('Confirming Order with URL :- $url');

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: body,
      );

      final responseData = json.decode(response.body);

      log('Confirming Response :- $responseData');

      if (response.statusCode == 200) {
        log('Order Confirmed Successfully :)');
        return responseData['message'] + "$orderIds" ?? 'Orders Confirmed successfully';
      } else {
        log('Failed to Confirm Order with Status Code ${response.statusCode} and Response as ${response.body}');
        return responseData['errors'][0]['errors'][0] ?? 'Failed to confirm orders';
      }
    } catch (error) {
      Logger().e('Error during API request: $error');
      return 'An error occurred: $error';
    } finally {
      notifyListeners();
    }
  }

  Future<String> cancelOrders(BuildContext context, List<String> orderIds) async {
    String baseUrl = await Constants.getBaseUrl();
    String cancelOrderUrl = '$baseUrl/orders/cancel';
    final String? token = await _getToken();
    setCancelStatus(true);
    notifyListeners();

    if (token == null) {
      return 'No auth token found';
    }

    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    final body = json.encode({
      'orderIds': orderIds,
    });

    try {
      final response = await http.post(
        Uri.parse(cancelOrderUrl),
        headers: headers,
        body: body,
      );

      final responseData = json.decode(response.body);

      log('Cancelling Order Response :- $responseData with status code :- ${response.statusCode}');

      if (response.statusCode == 200) {
        await fetchReadyOrders();
        resetSelections();
        notifyListeners();

        log('Order Cancelled Successfully :)');

        return responseData['message'] ?? 'Orders cancelled successfully';
      } else {
        return responseData['message'] ?? 'Failed to cancel orders';
      }
    } catch (error) {
      notifyListeners();

      return 'An error occurred: $error';
    } finally {
      setCancelStatus(false);
    }
  }

  void toggleSelectAllReady(bool isSelected) {
    allSelectedReady = isSelected;
    selectedReadyItemsCount = isSelected ? readyOrders.length : 0;
    _selectedReadyOrders = List<bool>.filled(readyOrders.length, isSelected);

    notifyListeners();
  }

  void toggleSelectAllFailed(bool isSelected) {
    allSelectedFailed = isSelected;
    selectedFailedItemsCount = isSelected ? failedOrders.length : 0;
    _selectedFailedOrders = List<bool>.filled(failedOrders.length, isSelected);

    notifyListeners();
  }

  void toggleOrderSelectionFailed(bool value, int index) {
    if (index >= 0 && index < _selectedFailedOrders.length) {
      _selectedFailedOrders[index] = value;
      selectedFailedItemsCount = _selectedFailedOrders.where((selected) => selected).length;

      allSelectedFailed = selectedFailedItemsCount == failedOrders.length;

      notifyListeners();
    }
  }

  void toggleOrderSelectionReady(bool value, int index) {
    if (index >= 0 && index < _selectedReadyOrders.length) {
      _selectedReadyOrders[index] = value;
      selectedReadyItemsCount = _selectedReadyOrders.where((selected) => selected).length;

      allSelectedReady = selectedReadyItemsCount == readyOrders.length;

      notifyListeners();
    }
  }

  Future<void> approveFailedOrders(BuildContext context) async {
    setUpdating(true);
    notifyListeners();
    Logger().e('failedOrders: $failedOrders');

    final List<String> failedOrderIds =
        failedOrders.asMap().entries.where((entry) => _selectedFailedOrders[entry.key]).map((entry) => entry.value.orderId).toList();
    Logger().e('failedOrderIds: $failedOrderIds');

    if (failedOrderIds.isEmpty) {
      _showSnackbar(context, 'No orders selected to update.');
      return;
    }

    for (String orderId in failedOrderIds) {
      await updateOrderStatus(context, orderId, 1);
    }

    await fetchFailedOrders();

    allSelectedFailed = false;
    _selectedFailedOrders = List<bool>.filled(failedOrders.length, false);
    selectedFailedItemsCount = 0;
    setUpdating(false);
    notifyListeners();
  }

  Future<void> updateReadyToConfirmOrders(BuildContext context) async {
    final List<String> readyOrderIds =
        readyOrders.asMap().entries.where((entry) => _selectedReadyOrders[entry.key]).map((entry) => entry.value.orderId).toList();

    if (readyOrderIds.isEmpty) {
      _showSnackbar(context, 'No orders selected to update.');
      return;
    }

    for (String orderId in readyOrderIds) {
      await updateOrderStatus(context, orderId, 2);
    }

    await fetchReadyOrders();

    allSelectedReady = false;
    _selectedReadyOrders = List<bool>.filled(readyOrders.length, false);
    selectedReadyItemsCount = 0;

    notifyListeners();
  }

  Future<void> updateOrderStatus(BuildContext context, String orderId, int newStatus) async {
    final String? token = await _getToken();
    if (token == null) {
      _showSnackbar(context, 'No auth token found');
      return;
    }

    final String url = '${await Constants.getBaseUrl()}/orders/ApprovedFailed?order_id=$orderId';

    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      if (response.statusCode == 200) {
        _showSnackbar(context, 'Order status updated successfully with $orderId');

        await fetchFailedOrders();
        await fetchReadyOrders();
      } else {
        final errorResponse = json.decode(response.body);
        String errorMessage = errorResponse['message'] ?? 'Failed to update order status';
        _showSnackbar(context, errorMessage);
        log('Failed to update order status: ${response.statusCode} ${response.body}');
      }
    } catch (error) {
      _showSnackbar(context, 'An error occurred while updating the order status: $error');
      log('An error occurred while updating the order status: $error');
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
    _readyOrders = [];
    _failedOrders = [];
    notifyListeners();
  }

  Future<void> searchReadyToConfirmOrders(String orderId) async {
    String encodedOrderId = Uri.encodeComponent(orderId.trim());

    final prefs = await SharedPreferences.getInstance();
    final warehouseId = prefs.getString('warehouseId') ?? '';

    final url = Uri.parse('${await Constants.getBaseUrl()}/orders?warehouse=$warehouseId&orderStatus=1&order_id=$encodedOrderId&find=true');
    final token = await _getToken();
    if (token == null) return;

    log('Ready to Confirm URL: $url');

    try {
      setReadyLoading(true);

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // log('data: $data');
        _readyOrders = (data['orders'] as List).map((order) => Order.fromJson(order)).toList();
        // _readyOrders = [Order.fromJson(data)];
        log('selectedReadyOrders: $selectedReadyOrders');
      } else {
        resetReady();
      }
    } catch (e) {
      log('Search ready orders error: $e');
      resetReady();
    } finally {
      setReadyLoading(false);
    }
  }

  Future<void> searchFailedOrders(String orderId) async {
    String encodedOrderId = Uri.encodeComponent(orderId.trim());
    final prefs = await SharedPreferences.getInstance();
    final warehouseId = prefs.getString('warehouseId') ?? '';

    final url = Uri.parse('${await Constants.getBaseUrl()}/orders?warehouse=$warehouseId&orderStatus=0&order_id=$encodedOrderId');
    final token = await _getToken();
    if (token == null) return;

    Logger().e('searchFailedOrders url: $url');

    try {
      setFailedLoading(true);

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final res = jsonDecode(response.body);

        _failedOrders = (res['orders'] as List).map((order) => Order.fromJson(order)).toList();
        // _failedOrders = [Order.fromJson(res)];
      } else {
        resetFailed();
      }
    } catch (e) {
      Logger().e('Search failed orders error: $e');
      resetFailed();
    } finally {
      setFailedLoading(false);
    }
  }

  Future<bool> connectWithSupport(BuildContext context, String orderId, String message) async {
    final token = await _getToken();
    try {
      var response = await http.post(
        Uri.parse('${await Constants.getBaseUrl()}/orders/connectWithSupport'),
        body: jsonEncode({
          'orderIds': [orderId],
          'message': message,
        }),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final responseData = json.decode(response.body);

      log('connect body: $responseData');

      if (response.statusCode == 200) {
        await Provider.of<ChatProvider>(context, listen: false).sendMessageForOrder(
          orderId: orderId,
          message: message,
        );
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  void showSnackBar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        backgroundColor: color,
      ),
    );
  }

  Future<Map<String, dynamic>> splitOrder(String orderId, List<String> productSkus, {String weightLimit = ""}) async {
    final token = await _getToken();
    if (token == null || token.isEmpty) {
      return {'success': false};
    }

    if (productSkus.isEmpty) {
      return {'success': false};
    }

    try {
      var response = await http.post(
        Uri.parse('${await Constants.getBaseUrl()}/splitOrder?order_id=$orderId'),
        body: jsonEncode({
          'product_sku': productSkus,
          'weightLimit': weightLimit,
        }),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final responseData = json.decode(response.body);

      log('split code: ${response.statusCode}');
      log('split order body: $responseData');

      if (response.statusCode == 200) {
        return {'success': true, 'message': responseData['orders']};
      } else {
        return {'success': false, 'message': responseData['message']};
      }
    } catch (e) {
      return {'success': false};
    }
  }
}
