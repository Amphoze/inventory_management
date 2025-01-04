import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:inventory_management/constants/constants.dart';
import 'package:inventory_management/model/orders_model.dart';
import 'package:logger/logger.dart';
// import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AllOrdersProvider with ChangeNotifier {
  bool _isLoading = false;
  bool _selectAll = false;
  final List<bool> _selectedProducts = [];
  int selectedItemsCount = 0;
  List<Order> _orders = [];
  int _currentPage = 1;
  int _totalPages = 1;
  final PageController _pageController = PageController();
  final TextEditingController _textEditingController = TextEditingController();
  Timer? _debounce;
  bool isUpdatingOrder = false;
  bool isRefreshingOrders = false;
  bool isCancel = false;
  List<Map<String, String>> statuses = [];

  bool get selectAll => _selectAll;
  List<bool> get selectedProducts => _selectedProducts;
  // List<Map<String,String>> get statuses => _statuses;
  bool get isLoading => _isLoading;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  PageController get pageController => _pageController;
  TextEditingController get textEditingController => _textEditingController;

  int get selectedCount =>
      _selectedProducts.where((isSelected) => isSelected).length;

  // New variables for booked orders
  List<bool> selectedItems = List.generate(40, (index) => false);
  List<Order> get ordersBooked => _orders;

  List<Order> BookedOrders = [];

  void setCancelStatus(bool status) {
    isCancel = status;
    notifyListeners();
  }

  // void setUpdatingOrder(bool value) {
  //   isUpdatingOrder = value;
  //   notifyListeners();
  // }

  // void setRefreshingOrders(bool value) {
  //   isRefreshingOrders = value;
  //   notifyListeners();
  // }

  // void handleRowCheckboxChange(int index, bool isSelected) {
  //   _selectedProducts[index] = isSelected;

  //   // If any individual checkbox is unchecked, deselect "Select All"
  //   if (!isSelected) {
  //     _selectAll = false;
  //   } else {
  //     // If all boxes are checked, select "Select All"
  //     _selectAll = _selectedProducts.every((element) => element);
  //   }

  //   notifyListeners();
  // }

  // void toggleSelectAll(bool value) {
  //   _selectAll = value;
  //   _selectedProducts =
  //       List<bool>.generate(_orders.length, (index) => _selectAll);
  //   notifyListeners();
  // }

  // void goToPage(int page) {
  //   if (page < 1 || page > _totalPages) return;
  //   _currentPage = page;
  //   print('Current page set to: $_currentPage'); // Debugging line
  //   fetchAllOrders();
  //   notifyListeners();
  // }

  // Format date
  // String formatDate(DateTime date) {
  //   String year = date.year.toString();
  //   String month = date.month.toString().padLeft(2, '0');
  //   String day = date.day.toString().padLeft(2, '0');
  //   return '$day-$month-$year';
  // }

  // String formatDateTime(DateTime date) {
  //   String year = date.year.toString();
  //   String month = date.month.toString().padLeft(2, '0');
  //   String day = date.day.toString().padLeft(2, '0');
  //   String hour = date.hour.toString().padLeft(2, '0');
  //   String minute = date.minute.toString().padLeft(2, '0');
  //   String second = date.second.toString().padLeft(2, '0');

  //   return '$day-$month-$year $hour:$minute:$second';
  // }

  Future<String> cancelOrders(
      BuildContext context, List<String> orderIds) async {
    String baseUrl = await ApiUrls.getBaseUrl();
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
        await fetchAllOrders(
            page:
                _currentPage); // Assuming fetchOrders is a function that reloads the orders
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

  void onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.isEmpty) {
        // If query is empty, reload all orders
        fetchAllOrders(page: _currentPage);
      } else {
        searchOrders(query); // Trigger the search after the debounce period
      }
    });
  }

  ///////////////////////////////////////////////////////////////////////////////// BOOKED

  void setRefreshingOrders(bool value) {
    isRefreshingOrders = value;
    notifyListeners();
  }

  void clearSearchResults() {
    _orders = BookedOrders;
    notifyListeners();
  }

  Future<String> fetchDelhiveryTrackingStatus(String awb) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken') ?? '';
    String delhiveryURL =
        '${await ApiUrls.getBaseUrl()}/orders/track/?waybill=$awb';

    try {
      final response = await http.get(
        Uri.parse(delhiveryURL),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      // Log response for debugging
      log('sss: ${response.statusCode}');
      debugPrint('rrr: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        log('body: $jsonResponse');
        final status = jsonResponse['ShipmentData'][0]['Shipment']['Status']
                    ['Status']
                .toString() ??
            '';

        log('sss: $status');

        return status;
      } else if (response.statusCode == 401) {
        print('Unauthorized access - Token might be expired or invalid.');
      } else if (response.statusCode == 404) {
        print('Status not found');
      } else {
        throw Exception('Failed to load status: ${response.statusCode}');
      }
    } catch (e) {
      log('Error fetching status: $e');
    }

    return 'n/a';
  }

  Future<String> fetchShiprocketToken() async {
    const String url = 'https://apiv2.shiprocket.in/v1/external/auth/login';
    const String body =
        '{"email": "Katyayanitech@gmail.com", "password": "Ship@5679"}';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return jsonResponse['token'];
      } else {
        throw Exception('Failed to load token: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching token: $e');
      return '';
    }
  }

  Future<String> fetchShiprocketTrackingStatus(String awb) async {
    String token = await fetchShiprocketToken();

    String shipURL =
        'https://apiv2.shiprocket.in/v1/external/courier/track/awb/$awb';

    try {
      final response = await http.get(
        Uri.parse(shipURL),
        headers: {
          "Content-Type": "application/json",
          'Authorization': token,
        },
      );

      // Log response for debugging
      log('Response status: ${response.statusCode}');
      log('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);

        final status = jsonResponse['tracking_data']['shipment_track'][0]
                    ['current_status']
                .toString() ??
            '';

        log('status: $status');
        return status;
      } else if (response.statusCode == 401) {
        print('Unauthorized access - Token might be expired or invalid.');
      } else if (response.statusCode == 404) {
        print('Orders not found');
      } else {
        throw Exception('Failed to load orders: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching orders: $e');
    } finally {}

    return '';
  }

  Future<void> fetchAllOrders({int page = 1, DateTime? date}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken') ?? '';

    log('called');

    String url = '${await ApiUrls.getBaseUrl()}/orders?page=$page';

    if (date != null) {
      String formattedDate = DateFormat('yyyy-MM-dd').format(date);
      url += '&date=$formattedDate';
    }

    try {
      // Set loading state based on order type
      _isLoading = true;
      setRefreshingOrders(true);
      notifyListeners();

      clearAllSelections();

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      // Log response for debugging
      log('status: ${response.statusCode}');
      print('body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        List<Order> orders = (jsonResponse['orders'] as List)
            .map((order) => Order.fromJson(order))
            .toList();

        // Logger().e(jsonResponse['orders'][0]['isBooked']['status']);

        _orders = orders;
        _currentPage = page;
        _totalPages = jsonResponse['totalPages'];

        log('orders: $_orders');
      } else if (response.statusCode == 401) {
        print('Unauthorized access - Token might be expired or invalid.');
      } else if (response.statusCode == 404) {
        print('Orders not found');
      } else {
        throw Exception('Failed to load orders: ${response.statusCode}');
      }
    } catch (e) {
      log('Error fetching orders: $e');
    } finally {
      _isLoading = false;
      setRefreshingOrders(false);
      notifyListeners();
    }
  }

  Future<void> fetchOrdersByMarketplace(
      String marketplace, int page, DateTime? date, String status) async {
    log("$marketplace, $page");
    String baseUrl = '${await ApiUrls.getBaseUrl()}/orders';
    String url =
        '$baseUrl?marketplace=$marketplace&orderStatus=$status&page=$page';

    if (date != null) {
      String formattedDate = DateFormat('yyyy-MM-dd').format(date);
      url += '&date=$formattedDate';
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken') ?? '';

    try {
      _isLoading = true;
      setRefreshingOrders(true);
      notifyListeners();

      // Clear checkboxes when a new page is fetched
      clearAllSelections();

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      // Log response for debugging
      log('Response status: ${response.statusCode}');
      log('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        List<Order> orders = (jsonResponse['orders'] as List)
            .map((orderJson) => Order.fromJson(orderJson))
            .toList();

        // Logger().e("length: ${orders.length}");

        _orders = orders;
        _currentPage = page; // Track current page for B2B
        _totalPages =
            jsonResponse['totalPages']; // Assuming API returns total pages
      } else if (response.statusCode == 401) {
        print('Unauthorized access - Token might be expired or invalid.');
      } else if (response.statusCode == 404) {
        _orders = [];
        notifyListeners();

        log('Orders not found');
      } else {
        throw Exception('Failed to load orders: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching orders: $e');
    } finally {
      _isLoading = false;
      setRefreshingOrders(false);
      notifyListeners();
    }
  }

  Future<void> fetchOrdersByStatus(
      String marketplace, int page, DateTime? date, String status) async {
    log("$status, $marketplace, $date, $page");
    String baseUrl = '${await ApiUrls.getBaseUrl()}/orders';

    String url = '$baseUrl?orderStatus=$status&page=$page';

    if (marketplace != 'All') {
      url += '&marketplace=$marketplace';
    }

    if (date != null) {
      String formattedDate = DateFormat('yyyy-MM-dd').format(date);
      url += '&date=$formattedDate';
    }

    Logger().e(url);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken') ?? '';

    try {
      _isLoading = true;
      setRefreshingOrders(true);
      notifyListeners();

      // Clear checkboxes when a new page is fetched
      clearAllSelections();

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      // Log response for debugging
      log('Response status: ${response.statusCode}');
      log('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        List<Order> orders = (jsonResponse['orders'] as List)
            .map((orderJson) => Order.fromJson(orderJson))
            .toList();

        // Logger().e("length: ${orders.length}");

        _orders = orders;
        _currentPage = page; // Track current page for B2B
        _totalPages =
            jsonResponse['totalPages']; // Assuming API returns total pages
      } else if (response.statusCode == 401) {
        print('Unauthorized access - Token might be expired or invalid.');
      } else if (response.statusCode == 404) {
        _orders = [];
        notifyListeners();

        log('Orders not found');
      } else {
        throw Exception('Failed to load orders: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching orders: $e');
    } finally {
      _isLoading = false;
      setRefreshingOrders(false);
      notifyListeners();
    }
  }

  Future<List<Map<String, String>>> getTrackingStatuses() async {
    String baseUrl = '${await ApiUrls.getBaseUrl()}/status';

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken') ?? '';

    try {
      final response = await http.get(
        Uri.parse(baseUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        statuses = (jsonResponse as List).map((data) {
          return {
            data['status']
                .split('_')
                .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
                .join(' ')
                .toString(): data['status_id'].toString(),
            // 'statusId': data['status_id'].toString(),
          };
        }).toList();

        return statuses;
        // _statuses = statuses;
      } else if (response.statusCode == 401) {
        print('Unauthorized access - Token might be expired or invalid.');
        return [];
      } else if (response.statusCode == 404) {
        log('Tracking Sttuses not found');
        return [];
      } else {
        log('Failed to load orders: ${response.statusCode}');
        return [];
        // throw Exception('Failed to load orders: ${response.statusCode}');
      }
    } catch (e) {
      log('Error fetching orders: $e');
      return [];
    } finally {
      log('_statuses: $statuses');
      notifyListeners();
    }
  }

  Future<void> searchOrders(String orderId) async {
    final url =
        Uri.parse('${await ApiUrls.getBaseUrl()}/orders?order_id=$orderId');
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken') ?? '';

    try {
      _isLoading = true;
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
        print(response.body);

        _orders = [Order.fromJson(data)];
        print(response.body);
      } else {
        _orders = [];
      }
    } catch (e) {
      _orders = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Handle individual row checkbox change for booked orders
  void handleRowCheckboxChangeBooked(String? orderId, bool isSelected) {
    int index;
    index = ordersBooked.indexWhere((order) => order.orderId == orderId);
    if (index != -1) {
      selectedItems[index] = isSelected;
      ordersBooked[index].isSelected = isSelected;
    }

    _selectAll = selectedProducts.every((item) => item);
    notifyListeners();
  }

  // Toggle select all checkboxes for booked orders
  void toggleSelectAll(bool? value) {
    _selectAll = value!;
    _selectedProducts.fillRange(0, _selectedProducts.length, _selectAll);
    for (int i = 0; i < _orders.length; i++) {
      _orders[i].isSelected = _selectAll;
    }
    notifyListeners();
  }

  // Clear all checkboxes for booked orders
  void clearAllSelections() {
    selectedItems.fillRange(0, selectedItems.length, false);
    _selectAll = false;
    notifyListeners();
  }

  void goToPage(int page) {
    if (page < 1 || page > totalPages) return;
    _currentPage = page;
    print('Current booked page set to: $_currentPage');
    fetchAllOrders(page: _currentPage);
    notifyListeners();
  }

  Future<String?> getInventoryItems() async {
    _isLoading = true;
    notifyListeners();

    String baseUrl = await ApiUrls.getBaseUrl();
    String downloadUrl = '$baseUrl/inventory/download';

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken') ?? '';

      final response = await http.post(
        Uri.parse(downloadUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData.containsKey('downloadUrl')) {
          return responseData['downloadUrl'];
        } else {
          print('Download URL not found in response');
          return null;
        }
      } else {
        print(
            'Failed to get download URL. Status code: ${response.statusCode}');
        return null;
      }
    } catch (error) {
      print('Error during download request: $error');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
