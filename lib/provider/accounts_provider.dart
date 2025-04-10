import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:inventory_management/Custom-Files/utils.dart';
import 'package:inventory_management/constants/constants.dart';
import 'package:inventory_management/model/orders_model.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccountsProvider with ChangeNotifier {
  int totalOrdersAccounts = 0;
  int totalOrdersInvoiced = 0;
  bool _isLoading = false;
  bool allSelectedAccounts = false;
  bool allSelectedInvoiced = false;
  List<bool> _selectedAccounts = [];
  List<bool> _selectedInvoiced = [];
  int selectedAccountOrderCount = 0;
  int selectedInvoicedOrderCount = 0;
  List<Order> _orders = [];
  List<Order> _ordersBooked = [];
  int _currentPage = 1;
  int _totalPages = 1;
  final PageController _pageController = PageController();
  final TextEditingController _textEditingController = TextEditingController();
  final TextEditingController accountsSearch = TextEditingController();
  final TextEditingController invoiceSearch = TextEditingController();
  String selectedSearchType = 'Order ID';

  List<bool> get selectedAccounts => _selectedAccounts;
  List<bool> get selectedInvoiced => _selectedInvoiced;
  List<Order> get orders => _orders;
  bool get isLoading => _isLoading;

  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  PageController get pageController => _pageController;
  TextEditingController get textEditingController => _textEditingController;

  bool isUpdatingOrder = false;
  bool isCancel = false;

  List<bool> selectedBookedItems = List.generate(40, (index) => false);
  // bool selectAllBooked = false;
  bool isLoadingBooked = false;
  List<Order> get ordersBooked => _ordersBooked;
  int currentPageBooked = 1;
  int totalPagesBooked = 1;
  final PageController _pageControllerBooked = PageController();

  String selectedDate = 'Select Date';
  DateTime? picked;
  String selectedCourier = 'All';
  String? selectedPaymentMode = 'Payment Mode';

  void resetFilterData() {
    selectedDate = 'Select Date';
    picked = null;
    selectedCourier = 'All';
    selectedPaymentMode = 'Payment Mode';
    selectedSearchType = 'Order ID';
    notifyListeners();
  }

  void resetAccounts() {
    _orders = [];
    _totalPages = 1;
    _currentPage = 1;
    _selectedAccounts = [];
    allSelectedAccounts = false;
    notifyListeners();
  }

  void resetBookedOrders() {
    _ordersBooked = [];
    totalPagesBooked = 1;
    currentPageBooked = 1;
    selectedBookedItems = List.generate(40, (index) => false);
    allSelectedInvoiced = false;
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

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void toggleOrderSelectionAccounts(int index, bool value) {
    if (index >= 0 && index < _selectedAccounts.length) {
      _selectedAccounts[index] = value;
      selectedAccountOrderCount = _selectedAccounts.where((selected) => selected).length;
      allSelectedAccounts = selectedAccountOrderCount == _orders.length;

      notifyListeners();
    }
  }

  // void handleRowCheckboxChange(int index, bool isSelected) {
  //   _selectedAccounts[index] = isSelected;
  //
  //   if (!isSelected) {
  //     _selectAllAccounts = false;
  //   } else {
  //     _selectAllAccounts = _selectedAccounts.every((element) => element);
  //   }
  //
  //   notifyListeners();
  // }

  void setCurrentPage(int value) {
    _currentPage = value;
    notifyListeners();
  }

  void setCurrentBookedPage(int value) {
    currentPageBooked = value;
    notifyListeners();
  }

  void toggleSelectAllAccounts(bool value) {
    allSelectedAccounts = value;
    selectedAccountOrderCount = value ? _orders.length : 0;
    _selectedAccounts = List<bool>.filled(_orders.length, value);
    notifyListeners();
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

  bool _isCloning = false;
  bool get isCloning => _isCloning;

  void setCloning(bool value) {
    _isCloning = value;
    notifyListeners();
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

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchOrdersWithStatus2();
        clearAllSelections();
        return responseData['message'] + ": ${responseData['newOrders'][0]['order_id']}" ?? 'Orders clone successfully';
      } else {
        return responseData['message'] ?? 'Failed to clone orders';
      }
    } catch (error) {
      log('catched error: $error');
      return 'An error occurred: $error';
    } finally {
      setCloning(false);
      notifyListeners();
    }
  }

  Future<String> cancelOrders(BuildContext context, List<String> orderIds) async {
    String baseUrl = await Constants.getBaseUrl();
    String cancelOrderUrl = '$baseUrl/orders/cancel';

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken') ?? '';
    setCancelStatus(true);
    notifyListeners();

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

      print('Response status: ${response.statusCode}');

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return responseData['message'] ?? 'Orders cancelled successfully';
      } else {
        return responseData['message'] ?? 'Failed to cancel orders';
      }
    } catch (error) {
      print('Error during API request: $error');
      return 'An error occurred: $error';
    } finally {
      setCancelStatus(false);
      notifyListeners();
    }
  }

  Future<void> fetchOrdersWithStatus2() async {
    accountsSearch.clear();

    setLoading(true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken') ?? '';
    final warehouseId = prefs.getString('warehouseId') ?? '';
    var url = '${await Constants.getBaseUrl()}/orders?warehouse=$warehouseId&orderStatus=2';

    if (picked != null) {
      String formattedDate = DateFormat('yyyy-MM-dd').format(picked!);
      url += '&date=$formattedDate';
    }
    if (selectedPaymentMode != null && selectedPaymentMode != 'Payment Mode') {
      url += '&payment_mode=$selectedPaymentMode';
    }
    if (selectedCourier != 'All') {
      url += '&marketplace=$selectedCourier';
    }

    url += '&page=$_currentPage';

    Logger().e('fetchOrdersWithStatus2 url: $url');

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<Order> orders = (data['orders'] as List).map((order) => Order.fromJson(order)).toList();
        log(orders.toString());

        totalOrdersAccounts = data['totalOrders'] ?? 0;
        _totalPages = data['totalPages'];
        _orders = orders;
        _currentPage = data['currentPage'];

        _selectedAccounts = List<bool>.filled(_orders.length, false);

        print('Total Orders Fetched from Page $_currentPage: ${orders.length}');
      } else {
        resetAccounts();
      }
    } catch (e) {
      log("catched error: $e");
      resetAccounts();
    } finally {
      setLoading(false);
      notifyListeners();
    }
  }

  void resetSelections() {
    _selectedAccounts.fillRange(0, _selectedAccounts.length, false);
    allSelectedAccounts = false;

    _selectedInvoiced.fillRange(0, _selectedAccounts.length, false);
    allSelectedInvoiced = false;

    selectedAccountOrderCount = 0;
    selectedInvoicedOrderCount = 0;

    notifyListeners();
  }

  Future<List<Order>> searchOrders(String query) async {
    if (query.isEmpty) {
      await fetchOrdersWithStatus2();
      return _orders;
    }

    _isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken') ?? '';
    final warehouseId = prefs.getString('warehouseId') ?? '';

    String encodedOrderId = Uri.encodeComponent(query.trim());

    String url = '${await Constants.getBaseUrl()}/orders?warehouse=$warehouseId&orderStatus=2';

    if (selectedSearchType == "Order ID") {
      url += '&order_id=$encodedOrderId';
    } else {
      url += '&transaction_number=$query';
    }

    Logger().e('searchOrders url: $url');

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

        if (jsonData != null) {
          _totalPages = jsonData['totalPages'] ?? 0;
          _orders = (jsonData['orders'] as List).map((orderJson) => Order.fromJson(orderJson)).toList();
          resetSelections();
          _selectedAccounts = List<bool>.filled(_orders.length, false);
        }
      } else {
        resetAccounts();
      }
    } catch (error) {
      log('Error searching failed orders: $error');
      resetAccounts();
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    return _orders;
  }

  Future<bool> statusUpdate(
    BuildContext context,
  ) async {
    setUpdatingOrder(true);
    notifyListeners();
    final selectedOrderIds = _orders
        .asMap()
        .entries
        .where((entry) => _selectedAccounts[entry.key])
        .map((entry) => entry.value.orderId)
        .toList();

    if (selectedOrderIds.isEmpty) {
      Utils.showSnackBar(context, 'No orders selected to update', isError: true);
      notifyListeners();
      return false;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken') ?? '';
    String url = '${await Constants.getBaseUrl()}/orders/invoice';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'orderIds': selectedOrderIds}),
      );

      final res = jsonDecode(response.body);

      log('Account Section Status Update Response :- ${response.body}');

      if (response.statusCode == 200) {
        Utils.showSnackBar(context, res['message'] ?? '', color: Colors.green);
        return true;
      } else {
        Utils.showSnackBar(context, res['message'] ?? '', color: Colors.red);
        return false;
      }
    } catch (error) {
      log('Error updating order status: $error');
      Utils.showSnackBar(context, 'Error while updating orders', isError: true);
      return false;
    } finally {
      setUpdatingOrder(false);
      notifyListeners();
    }
  }

  void setLoadingBookedOrders(bool value) {
    isLoadingBooked = value;
    notifyListeners();
  }

  void clearSearchResults() {
    _ordersBooked = [];
    notifyListeners();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }

  Future<bool> writeRemark(BuildContext context, String id, String msg) async {
    final token = await _getToken();
    if (token == null || token.isEmpty) {
      print('Token is missing. Please log in again.');
      return false;
    }

    final prefs = SharedPreferences.getInstance();
    String? email = await prefs.then((prefs) => prefs.getString('email'));

    final url = '${await Constants.getBaseUrl()}/orders/$id';
    try {
      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          "messages": {"accountMessage": msg, "timestamp": DateTime.now().toIso8601String(), "author": email}
        }),
      );

      log("remark response: ${response.statusCode}");

      if (response.statusCode == 200) {
        Logger().e('body: ${response.body}');
        return true;
      } else {
        log('Failed to update order: ${response.body}');
        return false;
      }
    } catch (error) {
      log('Error updating order: $error');
      return false;
    }
  }

  Future<void> fetchInvoicedOrders(int page) async {
    invoiceSearch.clear();
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken') ?? '';
    final warehouseId = prefs.getString('warehouseId') ?? '';

    String url = '${await Constants.getBaseUrl()}/orders?warehouse=$warehouseId&checkInvoice=true';

    if (picked != null) {
      String formattedDate = DateFormat('yyyy-MM-dd').format(picked!);
      url += '&date=$formattedDate';
    }
    if (selectedPaymentMode != null && selectedPaymentMode != 'Payment Mode') {
      url += '&payment_mode=$selectedPaymentMode';
    }
    if (selectedCourier != 'All') {
      url += '&marketplace=$selectedCourier';
    }
    url += '&page=$page';

    Logger().e('fetchInvoicedOrders url: $url');

    try {
      setLoadingBookedOrders(true);

      clearAllSelections();

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      Logger().e('account provider');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        List<Order> orders = (jsonResponse['orders'] as List).map((orderJson) => Order.fromJson(orderJson)).toList();

        Logger().e(jsonResponse['orders'][0]['isBooked']['status']);

        _ordersBooked = orders;
        currentPageBooked = page;
        totalPagesBooked = jsonResponse['totalPages'] ?? 0;
        totalOrdersInvoiced = jsonResponse['totalOrders']?? 0;

        resetSelections();
        _selectedInvoiced = List<bool>.filled(_ordersBooked.length, false);
        allSelectedInvoiced=false;
      } else {
        resetBookedOrders();
        throw Exception('Failed to load orders: ${response.statusCode}');
      }
    } catch (e,s) {
      log('Error fetching orders: $e\n\n$s');
      resetBookedOrders();
    } finally {
      setLoadingBookedOrders(false);
      notifyListeners();
    }
  }

  Future<void> searchInvoicedOrders(String query, String searchType) async {
    setLoadingBookedOrders(true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken') ?? '';
    final warehouseId = prefs.getString('warehouseId') ?? '';

    String url = '${await Constants.getBaseUrl()}/orders?warehouse=$warehouseId&checkInvoice=true';

    if (searchType == "Order ID") {
      String encodedOrderId = Uri.encodeComponent(query.trim());
      url += '&order_id=$encodedOrderId';
    } else {
      url += '&transaction_number=$query';
    }

    log('searchBookedOrders url: $url');

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _ordersBooked = (data['orders'] as List).map((orderJson) => Order.fromJson(orderJson)).toList();
        resetSelections();
        _selectedInvoiced = List<bool>.filled(_ordersBooked.length, false);

        log('Orders found: $_ordersBooked');
      } else {
        resetBookedOrders();
      }
    } catch (e) {
      log('e: $e');
      resetBookedOrders();
    } finally {
      setLoadingBookedOrders(false);
      notifyListeners();
    }
  }

  void toggleOrderSelectionBooked(String? orderId, bool isSelected) {
    int index = _ordersBooked.indexWhere((order) => order.orderId == orderId);

    if (index >= 0 && index < _ordersBooked.length) {
      _selectedInvoiced[index] = isSelected;
      _ordersBooked[index].isSelected = isSelected;

      selectedInvoicedOrderCount = _selectedInvoiced.where((selected) => selected).length;
      allSelectedInvoiced = selectedInvoicedOrderCount == _ordersBooked.length;

      notifyListeners();
    }
  }

  void toggleBookedSelectAll(bool? value) {
    allSelectedInvoiced = value ?? false;
    selectedInvoicedOrderCount = value == true ? _ordersBooked.length : 0;
    _selectedInvoiced = List<bool>.filled(_ordersBooked.length, value ?? false);

    for (int i = 0; i < _ordersBooked.length; i++) {
      _ordersBooked[i].isSelected = value ?? false;
    }
    notifyListeners();
  }

  void clearAllSelections() {
    selectedBookedItems.fillRange(0, selectedBookedItems.length, false);
    allSelectedInvoiced = false;
    notifyListeners();
  }

  PageController get pageControllerBooked => _pageControllerBooked;
}
