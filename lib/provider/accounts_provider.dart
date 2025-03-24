import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:inventory_management/constants/constants.dart';
import 'package:inventory_management/model/orders_model.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccountsProvider with ChangeNotifier {
  bool _isLoading = false;
  bool _selectAll = false;
  List<bool> _selectedProducts = [];
  int selectedItemsCount = 0;
  List<Order> _orders = [];
  List<Order> _ordersBooked = [];
  int _currentPage = 1;
  int _totalPages = 1;
  final PageController _pageController = PageController();
  final TextEditingController _textEditingController = TextEditingController();
  Timer? _debounce;
  final TextEditingController accountsSearch = TextEditingController();
  final TextEditingController invoiceSearch = TextEditingController();
  String selectedSearchType = 'Order ID';

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
  bool isCancel = false;

  List<bool> selectedBookedItems = List.generate(40, (index) => false);
  bool selectAllBooked = false;
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
    _selectedProducts = [];
    _selectAll = false;
    notifyListeners();
  }

  void resetBookedOrders() {
    _ordersBooked = [];
    totalPagesBooked = 1;
    currentPageBooked = 1;
    selectedBookedItems = List.generate(40, (index) => false);
    selectAllBooked = false;
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

  void handleRowCheckboxChange(int index, bool isSelected) {
    _selectedProducts[index] = isSelected;

    if (!isSelected) {
      _selectAll = false;
    } else {
      _selectAll = _selectedProducts.every((element) => element);
    }

    notifyListeners();
  }

  void setCurrentPage(int value) {
    _currentPage = value;
    notifyListeners();
  }

  void setCurrentBookedPage(int value) {
    currentPageBooked = value;
    notifyListeners();
  }

  void toggleSelectAll(bool value) {
    _selectAll = value;
    _selectedProducts = List<bool>.generate(_orders.length, (index) => _selectAll);
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
    // if (accountsSearch.text.trim().isNotEmpty) {
    //   searchOrders(accountsSearch.text.trim(), selectedSearchType);
    //   return;
    // }

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

        _totalPages = data['totalPages'];
        _orders = orders;
        _currentPage = data['currentPage'];

        _selectedProducts = List<bool>.filled(_orders.length, false);

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

  // void onSearchChanged(String query) {
  //   if (_debounce?.isActive ?? false) _debounce!.cancel();
  //   _debounce = Timer(const Duration(milliseconds: 500), () {
  //     if (query.isEmpty) {
  //       fetchOrdersWithStatus2();
  //     } else {
  //       searchOrders(query, 'Order ID');
  //     }
  //   });
  // }

  Future<List<Order>> searchOrders(String query, String searchType) async {
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

    if (searchType == "Order ID") {
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

      print('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData != null) {
          // if (searchType == "Order ID") {
          // _orders = [Order.fromJson(jsonData)];
          // } else {
          _orders = (jsonData['orders'] as List).map((orderJson) => Order.fromJson(orderJson)).toList();
          // }
          // } else {
          //   log('No data found in response.');
        }

        _orders = orders;
        print('Orders fetched: ${orders.length}');
      } else {
        print('Failed to load orders: ${response.statusCode}');
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
    final selectedOrderIds =
        _orders.asMap().entries.where((entry) => _selectedProducts[entry.key]).map((entry) => entry.value.orderId).toList();

    if (selectedOrderIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No orders selected to update')),
      );
      setUpdatingOrder(false);
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

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Orders updated successfully')),
        );

        return true;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update orders')),
        );
        return false;
      }
    } catch (error) {
      print('Error updating order status: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error while updating orders')),
      );
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

    final url = '${await Constants.getBaseUrl()}/orders/$id';
    try {
      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          "messages": {"accountMessage": msg}
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
    // if(invoiceSearch.text.trim().isNotEmpty) {
    //   searchInvoicedOrders(invoiceSearch.text.trim(), selectedSearchType);
    // }
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
        totalPagesBooked = jsonResponse['totalPages'];
      } else {
        resetBookedOrders();
        throw Exception('Failed to load orders: ${response.statusCode}');
      }
    } catch (e) {
      log('Error fetching orders: $e');
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

        // if (searchType == "Order ID") {
        // _ordersBooked = [Order.fromJson(data)];
        // } else {
        _ordersBooked = (data['orders'] as List).map((orderJson) => Order.fromJson(orderJson)).toList();
        // }

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

  void handleRowCheckboxChangeBooked(String? orderId, bool isSelected) {
    int index;
    index = ordersBooked.indexWhere((order) => order.orderId == orderId);
    if (index != -1) {
      selectedBookedItems[index] = isSelected;
      ordersBooked[index].isSelected = isSelected;
    }

    selectAllBooked = selectedBookedItems.every((item) => item);
    notifyListeners();
  }

  void toggleBookedSelectAll(bool? value) {
    selectAllBooked = value!;
    selectedBookedItems.fillRange(0, selectedBookedItems.length, selectAllBooked);
    for (int i = 0; i < ordersBooked.length; i++) {
      ordersBooked[i].isSelected = selectAllBooked;
    }
    notifyListeners();
  }

  void clearAllSelections() {
    selectedBookedItems.fillRange(0, selectedBookedItems.length, false);
    selectAllBooked = false;
    notifyListeners();
  }

  PageController get pageControllerBooked => _pageControllerBooked;

  // void goToBookedPage(int page) {
  //   if (page < 1 || page > totalPagesBooked) return;
  //   currentPageBooked = page;
  //   print('Current booked page set to: $currentPageBooked');
  //   fetchInvoicedOrders(currentPageBooked);
  //   notifyListeners();
  // }
}
