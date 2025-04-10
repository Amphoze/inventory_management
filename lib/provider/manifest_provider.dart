import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:inventory_management/Custom-Files/colors.dart';
import 'package:inventory_management/constants/constants.dart';
import 'package:inventory_management/model/manifest_model.dart';
import 'package:inventory_management/model/orders_model.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../Custom-Files/utils.dart';

class ManifestProvider extends ChangeNotifier {
  int totalOrders = 0;
  final TextEditingController manifestController = TextEditingController();
  final TextEditingController manifestedController = TextEditingController();
  bool _isLoading = false;
  bool _selectAll = false;
  List<bool> _selectedProducts = [];
  List<Order> _orders = [];
  List<Manifest> _manifests = [];
  int _currentPage = 1;
  int _currentPageManifested = 1;
  int _totalPages = 1;
  int _totalManifestedPages = 1;
  final PageController _pageController = PageController();
  final TextEditingController _textEditingController = TextEditingController();
  Timer? _debounce;

  // Getters
  bool get selectAll => _selectAll;
  List<bool> get selectedProducts => _selectedProducts;
  List<Order> get orders => _orders;
  List<Manifest> get manifests => _manifests;
  bool get isLoading => _isLoading;
  int get currentPage => _currentPage;
  int get currentPageManifested => _currentPageManifested;
  int get totalPages => _totalPages;
  int get totalManifestedPages => _totalManifestedPages;
  PageController get pageController => _pageController;
  TextEditingController get textEditingController => _textEditingController;
  int get selectedCount => _selectedProducts.where((isSelected) => isSelected).length;

  // Loading states
  bool isRefreshingOrders = false;
  bool isCreatingManifest = false;
  bool isCancel = false;

  // Dispose controllers and timers
  @override
  void dispose() {
    manifestController.dispose();
    manifestedController.dispose();
    _pageController.dispose();
    _textEditingController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // State setters
  void setRefreshingOrders(bool value) {
    isRefreshingOrders = value;
    notifyListeners();
  }

  void setCreatingManifest(bool value) {
    isCreatingManifest = value;
    notifyListeners();
  }

  void setCancelStatus(bool status) {
    isCancel = status;
    notifyListeners();
  }

  void toggleSelectAll(bool value) {
    _selectAll = value;
    _selectedProducts = List.filled(_orders.length, value);
    notifyListeners();
  }

  void toggleProductSelection(int index, bool value) {
    if (index >= 0 && index < _selectedProducts.length) {
      _selectedProducts[index] = value;
      _selectAll = _selectedProducts.every((selected) => selected);
      notifyListeners();
    }
  }

  Future<String> cancelOrders(BuildContext context, List<String> orderIds) async {
    if (orderIds.isEmpty) return 'No orders selected';

    setCancelStatus(true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken') ?? '';
      final response = await http.post(
        Uri.parse('${await Constants.getBaseUrl()}/orders/cancel'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'orderIds': orderIds}),
      );

      final responseData = json.decode(response.body);
      if (response.statusCode == 200) {
        await fetchOrdersWithStatus8();
        return responseData['message'] ?? 'Orders cancelled successfully';
      }
      return responseData['message'] ?? 'Failed to cancel orders';
    } catch (error) {
      log('Cancel orders error: $error');
      return 'An error occurred: $error';
    } finally {
      setCancelStatus(false);
    }
  }

  Future<void> fetchOrdersWithStatus8({DateTime? date, String? courier = 'All'}) async {
    manifestController.clear();
    _isLoading = true;
    setRefreshingOrders(true);
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken') ?? '';
      final warehouseId = prefs.getString('warehouseId') ?? '';
      String url = '${await Constants.getBaseUrl()}/orders?warehouse=$warehouseId&orderStatus=8&page=$_currentPage';

      if (date != null) url += '&date=${DateFormat('yyyy-MM-dd').format(date)}';
      if (courier != 'All') url += '&bookingCourier=$courier';

      final response = await http.get(Uri.parse(url), headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _orders = (data['orders'] as List?)?.map((order) => Order.fromJson(order)).toList() ?? [];
        _totalPages = data['totalPages'] ?? 1;
        totalOrders = data['totalOrders'] ?? 0;
        _selectedProducts = List.filled(_orders.length, false);
      } else {
        _resetOrders();
      }
    } catch (e, s) {
      log('Fetch orders error: $e, Stack: $s');
      _resetOrders();
    } finally {
      _isLoading = false;
      setRefreshingOrders(false);
      notifyListeners();
    }
  }

  Future<void> fetchCreatedManifests(int page) async {
    manifestedController.clear();
    _isLoading = true;
    setRefreshingOrders(true);
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken') ?? '';
      final response = await http.get(
        Uri.parse('${await Constants.getBaseUrl()}/manifest?page=$page'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'];
        _manifests = (data['manifest'] as List?)?.map((m) => Manifest.fromJson(m)).toList() ?? [];
        _totalPages = data['totalPages'] ?? 1;
        _currentPage = data['currentPage'] ?? 1;
      } else {
        _resetManifests();
      }
    } catch (e, s) {
      log('Fetch manifests error: $e, Stack: $s');
      _resetManifests();
    } finally {
      _isLoading = false;
      setRefreshingOrders(false);
      notifyListeners();
    }
  }

  Future<void> searchManifests(String query) async {
    if (query.trim().isEmpty) {
      await fetchCreatedManifests(_currentPageManifested);
      return;
    }

    _isLoading = true;
    setRefreshingOrders(true);
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken') ?? '';
      final response = await http.get(
        Uri.parse('${await Constants.getBaseUrl()}/manifest?manifestId=$query'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'];
        _manifests = (data?['manifest'] as List?)?.map((m) => Manifest.fromJson(m)).toList() ?? [];
        _totalPages = data?['totalPages'] ?? 1;
        _currentPage = data?['currentPage'] ?? 1;
      } else {
        _resetManifests();
      }
    } catch (e, s) {
      log('Search manifests error: $e, Stack: $s');
      _resetManifests();
    } finally {
      _isLoading = false;
      setRefreshingOrders(false);
      notifyListeners();
    }
  }

  Future<void> createManifest(BuildContext context, String deliveryPartner) async {
    if (deliveryPartner == 'All') {
      Utils.showSnackBar(context, 'Please select a delivery courier', isError: true);
      return;
    }

    final selectedOrderIds = _orders.asMap().entries
        .where((entry) => _selectedProducts[entry.key])
        .map((entry) => entry.value.orderId)
        .toList();

    if (selectedOrderIds.isEmpty) {
      Utils.showSnackBar(context, 'No orders selected', isError: true);
      return;
    }

    setCreatingManifest(true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken') ?? '';
      final response = await http.post(
        Uri.parse('${await Constants.getBaseUrl()}/manifest'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'orderIds': selectedOrderIds,
          'deliveryPartner': deliveryPartner,
        }),
      );

      final res = json.decode(response.body);
      if (response.statusCode == 201 || response.statusCode == 200) {
        Utils.showSnackBar(context, res['message'] ?? 'Manifest created', color: AppColors.cardsgreen);
        await fetchOrdersWithStatus8();
      } else {
        Utils.showSnackBar(context, res['error'] ?? 'Failed to create manifest', isError: true);
      }
    } catch (error) {
      Utils.showSnackBar(context, 'Error creating manifest', details: error.toString(), isError: true);
    } finally {
      setCreatingManifest(false);
    }
  }

  void handleRowCheckboxChange(int index, bool isSelected) {
    if (index >= 0 && index < _selectedProducts.length) {
      _selectedProducts[index] = isSelected;
      _selectAll = _selectedProducts.every((selected) => selected);
      notifyListeners();
    }
  }

  Future<void> fetchOrdersByBookingCourier(String courier, int page, {DateTime? date}) async {
    if (courier.isEmpty) return;

    _isLoading = true;
    setRefreshingOrders(true);
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken') ?? '';
      String url = '${await Constants.getBaseUrl()}/orders?orderStatus=8&bookingCourier=$courier&page=$page';
      if (date != null) url += '&date=${DateFormat('yyyy-MM-dd').format(date)}';

      final response = await http.get(Uri.parse(url), headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _orders = (data['orders'] as List?)?.map((order) => Order.fromJson(order)).toList() ?? [];
        _totalPages = data['totalPages'] ?? 1;
        _selectedProducts = List.filled(_orders.length, false);
      } else {
        _resetOrders();
      }
    } catch (e) {
      _resetOrders();
    } finally {
      _isLoading = false;
      setRefreshingOrders(false);
      notifyListeners();
    }
  }

  void onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      searchOrders(query);
    });
  }

  Future<List<Order>> searchOrders(String query) async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken') ?? '';
      final warehouseId = prefs.getString('warehouseId') ?? '';
      final url = query.isEmpty
          ? '${await Constants.getBaseUrl()}/orders?warehouse=$warehouseId&orderStatus=8'
          : '${await Constants.getBaseUrl()}/orders?warehouse=$warehouseId&orderStatus=8&order_id=$query';

      final response = await http.get(Uri.parse(url), headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      });

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        _orders = (jsonData['orders'] as List?)?.map((order) => Order.fromJson(order)).toList() ?? [];
        _selectedProducts = List.filled(_orders.length, false);
        _selectAll = false;
      } else {
        _resetOrders();
      }
    } catch (error) {
      log('Search orders error: $error');
      _resetOrders();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return _orders;
  }

  void goToPage(int page) {
    if (page >= 1 && page <= _totalPages) {
      _currentPage = page;
      fetchOrdersWithStatus8();
    }
  }

  String formatDate(DateTime date) => DateFormat('dd-MM-yyyy').format(date);

  // Helper methods
  void _resetOrders() {
    _orders = [];
    _currentPage = 1;
    _totalPages = 1;
    _selectedProducts = [];
    _selectAll = false;
  }

  void _resetManifests() {
    _manifests = [];
    _currentPage = 1;
    _totalPages = 1;
  }
}