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

class AllOrdersProvider with ChangeNotifier {
  final TextEditingController searchController = TextEditingController();
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

  bool get isLoading => _isLoading;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  PageController get pageController => _pageController;
  TextEditingController get textEditingController => _textEditingController;

  int get selectedCount => _selectedProducts.where((isSelected) => isSelected).length;

  List<bool> selectedItems = List.generate(40, (index) => false);
  List<Order> get ordersBooked => _orders;

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

    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    final body = json.encode({
      'orderIds': orderIds,
    });

    try {
      final response = await http.post(
        Uri.parse(Uri.encodeFull(cancelOrderUrl)),
        headers: headers,
        body: body,
      );

      print('Response status: ${response.statusCode}');
      //print('Response body: ${response.body}');

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        await fetchAllOrders(page: _currentPage);
        setRefreshingOrders(false);
        setCancelStatus(false);
        notifyListeners();

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
        fetchAllOrders(page: _currentPage);
      } else {
        searchOrders(query);
      }
    });
  }

  ///////////////////////////////////////////////////////////////////////////////

  void setRefreshingOrders(bool value) {
    isRefreshingOrders = value;
    notifyListeners();
  }

  void clearSearchResults() {
    _orders = [];
    notifyListeners();
  }

  Future<String> fetchDelhiveryTrackingStatus(String awb) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken') ?? '';
    String delhiveryURL = '${await Constants.getBaseUrl()}/orders/track?waybill=$awb';

    try {
      final response = await http.get(
        Uri.parse(Uri.encodeFull(delhiveryURL)),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      log('sss: ${response.statusCode}');
      debugPrint('rrr: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);

        final status = jsonResponse['ShipmentData']?[0]?['Shipment']?['Status']?['Status']?.toString() ?? '';

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
    const String body = '{"email": "Katyayanitech@gmail.com", "password": "Ship@5679"}';

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

    if(token.isEmpty) return '';

    String shipURL = 'https://apiv2.shiprocket.in/v1/external/courier/track/awb/$awb';

    try {
      final response = await http.get(
        Uri.parse(shipURL),
        headers: {
          "Content-Type": "application/json",
          'Authorization': token,
        },
      );

      log('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);

        final status = jsonResponse['tracking_data']['shipment_track'][0]['current_status'].toString() ?? '';

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

  Future<void> fetchAllOrders({int page = 1, DateTime? date, String? status, String? marketplace}) async {
    searchController.clear();
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken') ?? '';
    final warehouseId = prefs.getString('warehouseId') ?? '';

    String url = '${await Constants.getBaseUrl()}/orders?warehouse=$warehouseId&page=$page&isSalesApproved=true';

    if (date != null) {
      String formattedDate = DateFormat('yyyy-MM-dd').format(date);
      url += '&date=$formattedDate';
    }

    if (status != 'all' && status != null) {
      url += '&orderStatus=$status';
    }

    if (marketplace != 'All' && marketplace != null) {
      url += '&marketplace=$marketplace';
    }

    log('fetchAllOrders url: $url');
    try {
      _isLoading = true;
      setRefreshingOrders(true);
      notifyListeners();

      clearAllSelections();

      final response = await http.get(
        Uri.parse(Uri.encodeFull(url)),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      log('status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        List<Order> orders = (jsonResponse['orders'] as List).map((order) => Order.fromJson(order)).toList();

        _orders = orders;
        _currentPage = page;
        _totalPages = jsonResponse['totalPages'];
      } else {
        _orders = [];
        _totalPages = 1;
        _currentPage = 1;
        log('Orders not found');
        throw Exception('Failed to load orders: ${response.statusCode}');
      }
    } catch (e) {
      _orders = [];
      _totalPages = 1;
      _currentPage = 1;
      log('Error fetching orders: $e');
    } finally {
      _isLoading = false;
      setRefreshingOrders(false);
      notifyListeners();
    }
  }

  Future<List<Map<String, String>>> getTrackingStatuses() async {
    String baseUrl = '${await Constants.getBaseUrl()}/status';

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken') ?? '';

    try {
      final response = await http.get(
        Uri.parse(Uri.encodeFull(baseUrl)),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        statuses = (jsonResponse as List).map((data) {
          return {
            data['status'].split('_').map((w) => '${w[0].toUpperCase()}${w.substring(1)}').join(' ').toString():
                data['status_id'].toString(),
          };
        }).toList();

        return statuses;
      } else if (response.statusCode == 401) {
        print('Unauthorized access - Token might be expired or invalid.');
        return [];
      } else if (response.statusCode == 404) {
        log('Tracking Sttuses not found');
        return [];
      } else {
        log('Failed to load orders: ${response.statusCode}');
        return [];
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
    String encodedOrderId = Uri.encodeComponent(orderId);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken') ?? '';
    final warehouseId = prefs.getString('warehouseId') ?? '';

    final url = '${await Constants.getBaseUrl()}/orders?warehouse=$warehouseId&order_id=$encodedOrderId&isSalesApproved=true';
    log('search all orders url: $url');
    final mainUrl = Uri.parse(url);
    log('parsed url: $mainUrl');

    try {
      _isLoading = true;
      notifyListeners();

      final response = await http.get(
        mainUrl,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        Logger().e('this is order id: ${data['order_id']}');

        if(data['orders'] is List) {
          _orders = (data['orders'] as List).map((order) => Order.fromJson(order)).toList();
        } else {
          _orders = [Order.fromJson(data)];
        }

        // _orders = [Order.fromJson(data)];
        notifyListeners();
      } else {
        _orders = [];
      }
    } catch (e, s) {
      log('catched error: $e $s');
      _orders = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

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

  void toggleSelectAll(bool? value) {
    _selectAll = value!;
    _selectedProducts.fillRange(0, _selectedProducts.length, _selectAll);
    for (int i = 0; i < _orders.length; i++) {
      _orders[i].isSelected = _selectAll;
    }
    notifyListeners();
  }

  void clearAllSelections() {
    selectedItems.fillRange(0, selectedItems.length, false);
    _selectAll = false;
    notifyListeners();
  }

  void goToPage(int page, {DateTime? date, String? status, String? marketplace}) {
    if (page < 1 || page > totalPages) return;
    _currentPage = page;
    print('Current booked page set to: $_currentPage');
    fetchAllOrders(page: _currentPage, date: date, status: status, marketplace: marketplace);
    notifyListeners();
  }

  Future<String?> getInventoryItems() async {
    _isLoading = true;
    notifyListeners();

    String baseUrl = await Constants.getBaseUrl();
    String downloadUrl = '$baseUrl/inventory/download';

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken') ?? '';

      final response = await http.post(
        Uri.parse(Uri.encodeFull(downloadUrl)),
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
        print('Failed to get download URL. Status code: ${response.statusCode}');
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
