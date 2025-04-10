import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:inventory_management/constants/constants.dart';
import 'package:inventory_management/model/orders_model.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RoutingProvider with ChangeNotifier {
  bool allSelected = false;

  int selectedItemsCount = 0;

  List<bool> _selectedOrders = [];

  List<Order> readyOrders = [];

  String? _selectedCourier;
  String? _selectedPayment;
  String? _selectedFilter;
  String? _selectedMarketplace;
  String? _selectedOrderType;
  String? _selectedCustomerType;
  String _expectedDeliveryDate = '';
  String _paymentDateTime = '';
  String _normalDate = '';

  int totalReadyPages = 1;
  int currentPageReady = 1;
  bool isLoading = false;

  List<bool> get selectedOrders => _selectedOrders;

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
    allSelected = false;

    selectedOrders.fillRange(0, selectedOrders.length, false);

    selectedItemsCount = 0;

    notifyListeners();
  }

  void resetData() {
    readyOrders = [];
    currentPageReady = 1;
    totalReadyPages = 1;
    notifyListeners();
  }

  Future<void> fetchOrders({int page = 1, DateTime? date, String? market}) async {
    log('routing fetchOrders data: $date');
    log('routing fetchOrders market: $market');

    if (page < 1 || page > totalReadyPages) {
      print('Invalid page number for orders: $page');
      return;
    }

    isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final warehouseId = prefs.getString('warehouseId') ?? '';

    String readyOrdersUrl = '${await Constants.getBaseUrl()}/orders/getHoldOrders?page=$page';

    if (date != null) {
      String formattedDate = DateFormat('yyyy-MM-dd').format(date);
      readyOrdersUrl += '&date=$formattedDate';
    }

    if (market != null && market != 'All') {
      readyOrdersUrl += '&marketplace=$market';
    }

    log("routing url: $readyOrdersUrl");

    final token = await _getToken();

    if (token == null || token.isEmpty) {
      isLoading = false;
      notifyListeners();
      log('Token is missing. Please log in again.');
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(readyOrdersUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      log('status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        readyOrders = (jsonData['orders'] as List).map((order) => Order.fromJson(order)).toList();
        totalReadyPages = jsonData['totalPages'] ?? 1;
        currentPageReady = page;

        log("routing orders: $readyOrders");

        resetSelections();
        _selectedOrders = List<bool>.filled(readyOrders.length, false);
        readyOrders = readyOrders;
      } else {
        resetData();
        throw Exception('Failed to load orders: ${response.body}');
      }
    } catch (e) {
      resetData();
      log('Error fetching orders: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> searchOrders(String orderId) async {
    final prefs = await SharedPreferences.getInstance();
    final warehouseId = prefs.getString('warehouseId') ?? '';
    final encodedOrderId = Uri.encodeComponent(orderId);

    final url = Uri.parse('${await Constants.getBaseUrl()}/orders/getHoldOrders?order_id=$encodedOrderId');
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
        List<dynamic> orders = data['orders'] ?? [];
        if (orders.isEmpty) {
          readyOrders = [Order.fromJson(data)];
        } else {
          readyOrders = orders.map((order) => Order.fromJson(order)).toList();
        }
      } else {
        resetData();
      }
    } catch (e) {
      log('Search ready orders error: $e');
      resetData();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<String> routeOrders(BuildContext context, List<String> orderIds) async {
    String baseUrl = await Constants.getBaseUrl();
    String url = '$baseUrl/microdealer/Reassign';
    // String url = '$baseUrl/orders/updateHoldOrders';
    final String? token = await _getToken();
    setConfirmStatus(true);
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

    log('route: $url');

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: body,
      );

      log('Response status: ${response.statusCode}');

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        await fetchOrders();
        resetSelections();
        setConfirmStatus(false);
        notifyListeners();

        return responseData['message'] + "$orderIds" ?? 'Orders Confirmed successfully';
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
    selectedItemsCount = isSelected ? readyOrders.length : 0;
    _selectedOrders = List<bool>.filled(readyOrders.length, isSelected);

    notifyListeners();
  }

  void toggleOrderSelectionReady(bool value, int index) {
    if (index >= 0 && index < _selectedOrders.length) {
      _selectedOrders[index] = value;
      selectedItemsCount = _selectedOrders.where((selected) => selected).length;

      allSelected = selectedItemsCount == readyOrders.length;

      notifyListeners();
    }
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

  // Future<void> fetchOrdersByMarketplace(String marketplace, int page, {DateTime? date}) async {
  //   String baseUrl = await Constants.getBaseUrl();
  //
  //   String url = '$baseUrl/orders/getHoldOrders?marketplace=$marketplace&page=$page';
  //
  //   if (date != null || date == 'Select Date') {
  //     String formattedDate = DateFormat('yyyy-MM-dd').format(date!);
  //     url += '&date=$formattedDate';
  //   }
  //
  //   log("url: $url");
  //
  //   String? token = await _getToken();
  //   if (token == null) {
  //     print('Token is null, unable to fetch orders.');
  //     return;
  //   }
  //
  //   try {
  //     isLoading = true;
  //     notifyListeners();
  //
  //     final response = await http.get(
  //       Uri.parse(url),
  //       headers: {
  //         'Authorization': 'Bearer $token',
  //         'Content-Type': 'application/json',
  //       },
  //     );
  //
  //     print('Response status: ${response.statusCode}');
  //     print('Response body: ${response.body}');
  //
  //     if (response.statusCode == 200) {
  //       final jsonResponse = jsonDecode(response.body);
  //       List<Order> orders = (jsonResponse['orders'] as List).map((orderJson) => Order.fromJson(orderJson)).toList();
  //
  //       Logger().e("length: ${orders.length}");
  //
  //       readyOrders = orders;
  //       currentPageReady = page;
  //       totalReadyPages = jsonResponse['totalPages'];
  //       notifyListeners();
  //     } else if (response.statusCode == 401) {
  //       print('Unauthorized access - Token might be expired or invalid.');
  //     } else if (response.statusCode == 404) {
  //       readyOrders = [];
  //       notifyListeners();
  //
  //       print('Orders not found - Check the filter type.');
  //     } else {
  //       throw Exception('Failed to load orders: ${response.statusCode}');
  //     }
  //   } catch (e) {
  //     log('Error fetching orders: $e');
  //   } finally {
  //     isLoading = false;
  //     notifyListeners();
  //   }
  // }
}
